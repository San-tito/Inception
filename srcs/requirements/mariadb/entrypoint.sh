#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

verify_minimum_env() {
	if [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER"] || [ -z "$MARIADB_PASSWORD"] || [ -z "$MARIADB_ROOT_PASSWORD"]; then
		error $'Database is uninitialized and options are not specified\n\tYou need to specify MARIADB_DATABASE, MARIADB_USER, MARIADB_PASSWORD and MARIADB_ROOT_PASSWORD'
	fi
}

create_db_directories() {
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
}

init_database_dir() {
	log "Initializing database files"
	mariadb-install-db --user=mysql --ldata=/var/lib/mysql
	log "Database files initialized"
}

setup_env() {
	DATABASE_ALREADY_EXISTS=
	if [ -d "/var/lib/mysql/mysql" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi
}

setup_db() {
	log "Securing system users"
	mariadbd --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 <<-EOSQL
		SET @orig_sql_log_bin= @@SESSION.SQL_LOG_BIN;
		SET @@SESSION.SQL_LOG_BIN=0;
		SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

		DROP USER IF EXISTS root@'127.0.0.1', root@'::1';
		EXECUTE IMMEDIATE CONCAT('DROP USER IF EXISTS root@\'', @@hostname,'\'');
		
		SET PASSWORD FOR 'root'@'localhost'= PASSWORD('$MARIADB_ROOT_PASSWORD');
		CREATE USER 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		GRANT PROXY ON ''@'%' TO 'root'@'%' WITH GRANT OPTION;
		SET @@SESSION.SQL_LOG_BIN=@orig_sql_log_bin;
		CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;
		CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
		GRANT ALL ON \`${MARIADB_DATABASE//_/\\_}\`.* TO '$MARIADB_USER'@'%';
	EOSQL
}

mariadb_init()
{
	init_database_dir "$@"

	setup_db

	log "MariaDB init process done. Ready for start up."
}

if [ "$1" = 'mariadbd' ]; then
	log "Entrypoint script for MariaDB Server started."

	setup_env "$@"
	create_db_directories

	if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
		verify_minimum_env

		mariadb_init "$@"
	fi
fi

exec "$@"
