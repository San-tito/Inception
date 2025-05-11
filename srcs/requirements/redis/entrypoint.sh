#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

redis_init()
{
	sed -i 's/protected-mode yes/protected-mode no/' /etc/redis.conf
	sed -i 's/bind 127.0.0.1 -::1/bind * -::/' /etc/redis.conf

	log "Redis Server init process done. Ready for start up."
}

if [ "$1" = 'redis-server' ]; then
	log "Entrypoint script for Redis Server started."

	redis_init
fi

exec "$@"
