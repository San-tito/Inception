#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

setup_env() {
	uid="$(id -u)"
	gid="$(id -g)"
	if [ "$uid" = '0' ]; then
		user='www-data'
		group='www-data'
	else
		user="$uid"
		group="$gid"
	fi
}

verify_minimum_env() {
	if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ]; then
		error $'Wordpress is unitialized and options are not specified\n\tYou need to specify WORDPRESS_DB_NAME, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD and WORDPRESS_DB_HOST'
	fi
}

wordpress_init() {
	if [ ! -e index.php ]; then
		if [ "$uid" = '0' ]; then
			chown "$user:$group" .
		fi
		echo "WordPress not found in $PWD, copying files from /usr/src/wordpress"
		sourceTarArgs="--create --file - --directory /usr/src/wordpress --owner $user --group $group"
		targetTarArgs="--extract --file -"
		tar $sourceTarArgs . | tar $targetTarArgs
		log "Completed copying files to $PWD"
	fi

	if [ ! -s wp-config.php ]; then
		log "No 'wp-config.php' found in $PWD, creating new one."

		cp -R /usr/src/wordpress/wp-config-sample.php wp-config.php
		sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$WORDPRESS_DB_NAME' );/" wp-config.php
		sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$WORDPRESS_DB_USER' );/" wp-config.php
		sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$WORDPRESS_DB_PASSWORD' );/" wp-config.php
		sed -i "s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', '$WORDPRESS_DB_HOST' );/" wp-config.php

		if [ "$uid" = '0' ]; then
			chown -R "$user":"$group" wp-config.php
		fi
	fi
	log "WordPress init process done. Ready for start up."
}

if [ "$1" = 'php-fpm' ]; then
	log "Entrypoint script for WordPress started."

	setup_env "$@"

	verify_minimum_env

	wordpress_init
fi

exec "$@"
