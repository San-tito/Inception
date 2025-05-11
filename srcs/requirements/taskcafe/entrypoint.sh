#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

taskcafe_init() {
	cd /usr/src/taskcafe/frontend
	yarn install
	yarn run build
	# ls /usr/src/taskcafe/
	log "Taskcafe frontend build completed."
}

if [ "$1" = 'echo' ]; then
	log "Entrypoint script for static started."

	taskcafe_init
fi

exec "$@"
