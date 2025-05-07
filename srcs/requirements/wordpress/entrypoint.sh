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
	if [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ]; then
		error $'Wordpress is unitialized and options are not specified\n\tYou need to specify WORDPRESS_DB_NAME, WORDPRESS_DB_USER and WORDPRESS_DB_PASSWORD'
	fi
}

wordpress_init() {
	log "Configuring WordPress"
	#sed -i 's|^listen = .*|listen = 9000|' /etc/php82/php-fpm.d/www.conf
	echo -e "[global]\ndaemonize = no\n\n[www]\nlisten = 9000" > /etc/php82/php-fpm.d/docker.conf
	config=/var/www/html/wp-config.php
	cp -R /var/www/html/wp-config-sample.php $config
	if [ "$uid" = '0' ]; then
		chown -R "$user":"$group" $config
	fi
	sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$WORDPRESS_DB_NAME' );/" $config
	sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$WORDPRESS_DB_USER' );/" $config
	sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$WORDPRESS_DB_PASSWORD' );/" $config
	sed -i "s/define( 'DB_HOST', 'localhost' );;/define( 'DB_HOST', 'mariadb' );/" $config

	log "WordPress init process done. Ready for start up."
}

if [ "$1" = 'php-fpm82' ]; then
	log "Entrypoint script for WordPress started."

	setup_env "$@"

	verify_minimum_env

	wordpress_init
fi

exec "$@"
