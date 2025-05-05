#!/bin/bash

set -eo pipefail

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
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
	if [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER"] || [ -z "$MARIADB_PASSWORD"] || [ -z "$MARIADB_ROOT_PASSWORD"]; then
		error $'Database is uninitialized and options are not specified\n\tYou need to specify MARIADB_DATABASE, MARIADB_USER, MARIADB_PASSWORD and MARIADB_ROOT_PASSWORD'
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

	declare -g DATABASE_ALREADY_EXISTS
	if [ -d "$DATADIR/mysql" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi
}

process_sql() {
	shift
	mariadb --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" "$@"
}

setup_db() {
	log "Securing system users"
	process_sql --database=mysql --binary-mode <<-EOSQL
		SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
		SET @@SESSION.SQL_LOG_BIN=0;
		SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

		DROP USER IF EXISTS root@'127.0.0.1', root@'::1';
		EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');
		
		SET PASSWORD FOR 'root'@'localhost'= PASSWORD('${MARIADB_ROOT_PASSWORD}');
		CREATE USER 'root'@'%' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		GRANT PROXY ON ''@'%' TO 'root'@'%' WITH GRANT OPTION;
		SET @@SESSION.SQL_LOG_BIN=@orig_sql_log_bin;
		CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;
		CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';"
		GRANT ALL ON \`${MARIADB_DATABASE//_/\\_}\`.* TO '$MARIADB_USER'@'%';"
	EOSQL
}

mariadb_init()
{
	init_database_dir "$@"

	temp_server_start "$@"

	setup_db

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
