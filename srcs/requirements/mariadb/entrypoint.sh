#!/bin/sh

set -e

log() {
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	printf '[Entrypoint]: %s\n' "$text"
}

error() {
	log "$@" >&2
	exit 1
}
set_env() {
	local var="$1"
	local def="${2:-}"
	eval val=\$$var
	if [ -z "$val" ] && [ -n "$def" ]; then
		val="$default"
	fi
	export "$var=$val"
}

setup_env() {
	DATADIR="$(get_config 'datadir' "$@")"
	SOCKET="$(get_config 'socket' "$@")"
	PORT="$(get_config 'port' "$@")"

	set_env 'MARIADB_ROOT_HOST' '%'
	set_env 'MARIADB_DATABASE'
	set_env 'MARIADB_USER'
	set_env 'MARIADB_PASSWORD'
	set_env 'MARIADB_ROOT_PASSWORD'

	set_env 'MARIADB_PASSWORD_HASH'
	set_env 'MARIADB_ROOT_PASSWORD_HASH'
	set_env 'MARIADB_REPLICATION_USER'
	set_env 'MARIADB_REPLICATION_PASSWORD'
	set_env 'MARIADB_REPLICATION_PASSWORD_HASH'
	set_env 'MARIADB_MASTER_HOST'
	set_env 'MARIADB_MASTER_PORT' '3306'

	if [ -d "$DATADIR/mysql" ]; then
		DATABASE_ALREADY_EXISTS=true
	fi
}

create_db_directories() {
	local user; user="$(id -u)"

	mkdir -p "$DATADIR"

	if [ "$user" = "0" ]; then
		find "$DATADIR" ! -user mysql -exec chown mysql: {} \;
	fi
}

get_config() {
	local conf="$1"; shift
	"$@" --verbose --help \
		| awk -v conf="$conf" '$1 == conf && /^[^ \t]/ { sub(/^[^ \t]+[ \t]+/, ""); print; exit }'
}

verify_minimum_env() {
	if [ -z "$MARIADB_ROOT_PASSWORD" ] && [ -z "$MARIADB_ROOT_PASSWORD_HASH" ] && [ -z "$MARIADB_ALLOW_EMPTY_ROOT_PASSWORD" ] && [ -z "$MARIADB_RANDOM_ROOT_PASSWORD" ]; then
		error $'Database is uninitialized and password option is not specified\n\tYou need to specify one of MARIADB_ROOT_PASSWORD, MARIADB_ROOT_PASSWORD_HASH, MARIADB_ALLOW_EMPTY_ROOT_PASSWORD and MARIADB_RANDOM_ROOT_PASSWORD'
	fi
	if [ -n "$MARIADB_ROOT_PASSWORD" ] || [ -n "$MARIADB_ALLOW_EMPTY_ROOT_PASSWORD" ] || [ -n "$MARIADB_RANDOM_ROOT_PASSWORD" ] && [ -n "$MARIADB_ROOT_PASSWORD_HASH" ]; then
		error "Cannot specify MARIADB_ROOT_PASSWORD_HASH and another MARIADB_ROOT_PASSWORD* option."
	fi
	if [ -n "$MARIADB_PASSWORD" ] && [ -n "$MARIADB_PASSWORD_HASH" ]; then
		error "Cannot specify MARIADB_PASSWORD_HASH and MARIADB_PASSWORD option."
	fi
}

setup_db() {
	mariadb --database=mysql --binary-mode --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" <<EOSQL
    -- Securing system users shouldn't be replicated
    SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
    SET @@SESSION.SQL_LOG_BIN=0;

    -- we need the SQL_MODE NO_BACKSLASH_ESCAPES mode to be clear for the password to be set
    SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

    DROP USER IF EXISTS root@'127.0.0.1', root@'::1';
    EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');

    ${rootLocalhostPass}
    ${rootCreate}
    ${mysqlAtLocalhost}
    ${mysqlAtLocalhostGrants}
    ${createDatabase}
    ${createUser}
    ${createReplicaUser}
    ${userGrants}
    ${changeMasterTo}

    -- end of securing system users, rest of init now...
    SET @@SESSION.SQL_LOG_BIN=@orig_sql_log_bin;
EOSQL
}

mariadb_init()
{
	log "Initializing database files"
	installArgs="--datadir=$DATADIR --rpm --auth-root-authentication-method=normal"
	mariadb-install-db $installArgs \
		--cross-bootstrap \
		--skip-test-db \
		--old-mode='UTF8_IS_UTF8MB3' \
		--default-time-zone=SYSTEM --enforce-storage-engine= \
		--skip-log-bin \
		--expire-logs-days=0 \
		--loose-innodb_buffer_pool_load_at_startup=0 \
		--loose-innodb_buffer_pool_dump_at_shutdown=0
	log "Database files initialized"
	setup_db

	echo
	log "MariaDB init process done. Ready for start up."
	echo
}


if [ "$1" = "mariadbd" ]; then
	setup_env "$@"
	create_db_directories

	if [ "$(id -u)" = "0" ]; then
		log "Switching to dedicated user 'mysql'"
		exec su-exec mysql $0 "$@"
	fi

	if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
		verify_minimum_env

		mariadb_init "$@"
	fi
fi

exec "$@"
