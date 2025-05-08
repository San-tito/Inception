#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

if [ "$1" = 'redis-server' ]; then
	log "Entrypoint script for Redis Server started."

	log "Redis Server init process done. Ready for start up."
fi

exec "$@"
