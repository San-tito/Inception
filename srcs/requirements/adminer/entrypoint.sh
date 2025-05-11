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

configure_fpm() {
	if [ ! -e /etc/php82/php-fpm.d/docker.conf ]; then
		log "Configuring PHP-FPM"
		echo "[global]" > /etc/php82/php-fpm.d/docker.conf
		echo "daemonize = no" >> /etc/php82/php-fpm.d/docker.conf
		echo "[www]" >> /etc/php82/php-fpm.d/docker.conf
		echo "user = $user" >> /etc/php82/php-fpm.d/docker.conf
		echo "group = $group" >> /etc/php82/php-fpm.d/docker.conf
		sed -i 's/listen = 127\.0\.0\.1:9000/listen = 9000/' /etc/php82/php-fpm.d/www.conf
		log "PHP-FPM configuration completed."
	fi
}

adminer_init() {
	if [ ! -e adminer.php ]; then
		log "Adminer not found in $PWD, copying from /usr/src/adminer.php"
		mv /usr/src/adminer.php adminer.php
		if [ "$uid" = '0' ]; then
			chown "$user:$group" adminer.php
		fi
	fi
	log "Adminer init process done. Ready for start up."
}

if [ "$1" = 'php-fpm82' ]; then
	log "Entrypoint script for Adminer started."

	setup_env "$@"

	configure_fpm	

	adminer_init
fi

exec "$@"
