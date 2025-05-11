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
	if [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ]; then
		error $'Ftp Server is unitialized and options are not specified\n\tYou need to specify FTP_USER and FTP_PASS' 
	fi
}

ftp_init()
{
	log "Ftp Server init process done. Ready for start up."
}

if [ "$1" = 'vsftpd' ]; then
	log "Entrypoint script for Ftp Server started."

	ftp_init

	verify_minimum_env
fi

exec "$@"
