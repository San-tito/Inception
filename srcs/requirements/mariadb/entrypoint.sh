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
		val="$def"
	fi
	export "$var=$val"
}

maria_set_env() {
    var="$1"; shift
    maria=$(echo "$var" | sed 's/^MYSQL_/MARIADB_/')
    set_env "$var" "$@"
    set_env "$maria" "$(eval echo \$$var)"
    if [ -n "$(eval echo \$$maria)" ]; then
        export "$var=\$(eval echo \$$maria)"
    fi
}

setup_env() {
	DATADIR="$(get_config 'datadir' "$@")"
	SOCKET="$(get_config 'socket' "$@")"

	maria_set_env 'MYSQL_ROOT_HOST' '%'
	maria_set_env 'MYSQL_DATABASE'
	maria_set_env 'MYSQL_USER'
	maria_set_env 'MYSQL_PASSWORD'
	maria_set_env 'MYSQL_ROOT_PASSWORD'

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
	if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
		error $'Database is uninitialized and password option is not specified\n\tYou need to specify one of MARIADB_ROOT_PASSWORD'
	fi
}

setup_db() {
	if [ -n "$MARIADB_ROOT_HOST" ] && [ "$MARIADB_ROOT_HOST" != 'localhost' ]; then
		log "Setting root password for host $MARIADB_ROOT_HOST"
	fi
	local createUser
	if  [ -n "$MARIADB_PASSWORD" ] && [ -n "$MARIADB_USER" ]; then
		log "Creating user $MARIADB_USER"
		createUser="CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';"
	fi
	mariadb --database=mysql --binary-mode --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" <<EOSQL
    -- Securing system users shouldn't be replicated
    SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
    SET @@SESSION.SQL_LOG_BIN=0;

    -- we need the SQL_MODE NO_BACKSLASH_ESCAPES mode to be clear for the password to be set
    SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

    DROP USER IF EXISTS root@'127.0.0.1', root@'::1';
    EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');

    ${createUser}

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
