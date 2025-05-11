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

adminer_init() {
	if [ ! -e adminer.php ]; then
		log "Adminer not found in $PWD, copying from /usr/src/adminer.php"
		mv /usr/src/adminer.php adminer.php
		if [ "$uid" = '0' ]; then
			chown "$user:$group" adminer.php
		fi
	fi
}

if [ "$1" = 'php-fpm82' ]; then
	log "Entrypoint script for Adminer started."

	setup_env "$@"

	adminer_init
fi

exec "$@"
