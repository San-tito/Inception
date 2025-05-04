#!/bin/bash

set -eo pipefail

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		error "Both $var and $fileVar are set (but are exclusive)"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

_mariadb_file_env() {
	local var="$1"; shift
	local maria="MARIADB_${var#MYSQL_}"
	file_env "$var" "$@"
	file_env "$maria" "${!var}"
	if [ "${!maria:-}" ]; then
		export "$var"="${!maria}"
	fi
}

get_config() {
	local conf="$1"; shift
	"$@" --verbose --help 2>/dev/null \
		| awk -v conf="$conf" '$1 == conf && /^[^ \t]/ { sub(/^[^ \t]+[ \t]+/, ""); print; exit }'
}

temp_server_start() {
	log "Starting temporary server"
	"$@" --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}" --wsrep_on=OFF \
		--expire-logs-days=0 \
		--loose-innodb_buffer_pool_load_at_startup=0 \
		&
	declare -g MARIADB_PID
	MARIADB_PID=$!
	log "Waiting for server startup"
	local i
	for i in {30..0}; do
		if process_sql --database=mysql \
			<<<'SELECT 1' &> /dev/null; then
			break
		fi
		sleep 1
	done
	if [ "$i" = 0 ]; then
		error "Unable to start server."
	fi
	log "Temporary server started."
}

temp_server_stop() {
	log "Stopping temporary server"
	kill "$MARIADB_PID"
	wait "$MARIADB_PID"
	log "Temporary server stopped"
}

verify_minimum_env() {
	if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
		error $'Database is uninitialized and password option is not specified\n\tYou need to specify one of MARIADB_ROOT_PASSWORD, MARIADB_ROOT_PASSWORD_HASH, MARIADB_ALLOW_EMPTY_ROOT_PASSWORD and MARIADB_RANDOM_ROOT_PASSWORD'
	fi
}

create_db_directories() {
	local user; user="$(id -u)"

	mkdir -p "$DATADIR"

	if [ "$user" = "0" ]; then
		find "$DATADIR" \! -user mysql -exec chown mysql: '{}' +
	fi
}

init_database_dir() {
	log "Initializing database files"
	installArgs=( --datadir="$DATADIR" --rpm --auth-root-authentication-method=normal )

	mariadb-install-db "${installArgs[@]}" \
		--skip-test-db \
		--old-mode='UTF8_IS_UTF8MB3' \
		--default-time-zone=SYSTEM --enforce-storage-engine= \
		--skip-log-bin \
		--expire-logs-days=0 \
		--loose-innodb_buffer_pool_load_at_startup=0 \
		--loose-innodb_buffer_pool_dump_at_shutdown=0
	log "Database files initialized"
}

setup_env() {
	declare -g DATADIR SOCKET PORT
	DATADIR="$(get_config 'datadir' "$@")"
	SOCKET="$(get_config 'socket' "$@")"
	PORT="$(get_config 'port' "$@")"

	_mariadb_file_env 'MYSQL_ROOT_HOST' '%'
	_mariadb_file_env 'MYSQL_DATABASE'
	_mariadb_file_env 'MYSQL_USER'
	_mariadb_file_env 'MYSQL_PASSWORD'
	_mariadb_file_env 'MYSQL_ROOT_PASSWORD'

	declare -g DATABASE_ALREADY_EXISTS
	if [ -d "$DATADIR/mysql" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi
}

process_sql() {
	shift
	mariadb --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" "$@"
}

docker_setup_db() {
	local rootCreate=
	if [ -n "$MARIADB_ROOT_HOST" ] && [ "$MARIADB_ROOT_HOST" != 'localhost' ]; then
		read -r -d '' rootCreate <<-EOSQL || true
			CREATE USER 'root'@'${MARIADB_ROOT_HOST}' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'${MARIADB_ROOT_HOST}' WITH GRANT OPTION ;
			GRANT PROXY ON ''@'%' TO 'root'@'${MARIADB_ROOT_HOST}' WITH GRANT OPTION;
		EOSQL
	fi
	local rootLocalhostPass="SET PASSWORD FOR 'root'@'localhost'= PASSWORD('${MARIADB_ROOT_PASSWORD}');"
	local createDatabase=
	if [ -n "$MARIADB_DATABASE" ]; then
		log "Creating database ${MARIADB_DATABASE}"
		createDatabase="CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;"
	fi

	local createUser=
	local userGrants=
	if  [ -n "$MARIADB_PASSWORD" ] || [ -n "$MARIADB_PASSWORD_HASH" ] && [ -n "$MARIADB_USER" ]; then
		log "Creating user ${MARIADB_USER}"
		createUser="CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';"
		if [ -n "$MARIADB_DATABASE" ]; then
			log "Giving user ${MARIADB_USER} access to schema ${MARIADB_DATABASE}"
			userGrants="GRANT ALL ON \`${MARIADB_DATABASE//_/\\_}\`.* TO '$MARIADB_USER'@'%';"
		fi
	fi

	log "Securing system users"
	process_sql --database=mysql --binary-mode <<-EOSQL
		-- Securing system users shouldn't be replicated
		SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
		SET @@SESSION.SQL_LOG_BIN=0;
                -- we need the SQL_MODE NO_BACKSLASH_ESCAPES mode to be clear for the password to be set
		SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

		DROP USER IF EXISTS root@'127.0.0.1', root@'::1';
		EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');

		${rootLocalhostPass}
		${rootCreate}
		-- end of securing system users, rest of init now...
		SET @@SESSION.SQL_LOG_BIN=@orig_sql_log_bin;
		-- create users/databases
		${createDatabase}
		${createUser}
		${userGrants}
	EOSQL
}

mariadb_init()
{
	init_database_dir "$@"

	temp_server_start "$@"

	docker_setup_db

	temp_server_stop

	log "MariaDB init process done. Ready for start up."
}

if [ "$1" = 'mariadbd' ]; then
	log "Entrypoint script for MariaDB Server started."

	setup_env "$@"
	create_db_directories

	if [ "$(id -u)" = "0" ]; then
		log "Switching to dedicated user 'mysql'"
		exec gosu mysql "${BASH_SOURCE[0]}" "$@"
	fi

	if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
		verify_minimum_env

		mariadb_init "$@"
	fi
fi

exec "$@"

