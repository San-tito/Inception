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
	chown -R mysql:mysql /var/lib/mysql
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
		USE mysql;
		FLUSH PRIVILEGES ;
		GRANT ALL ON *.* TO 'root'@'%' identified by '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION ;
		GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION ;
		SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MARIADB_ROOT_PASSWORD}') ;
		DROP DATABASE IF EXISTS test ;
		FLUSH PRIVILEGES ;
		CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;
		GRANT ALL ON \`$MARIADB_DATABASE\`.* to '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';
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
