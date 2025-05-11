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
	if [ -z "$FTP_PASS" ]; then
		error $'Ftp Server is unitialized and options are not specified\n\tYou need to specify FTP_PASS' 
	fi
}

ftp_init()
{
	echo "ftp:$FTP_PASS" | /usr/sbin/chpasswd
	if [ ! -f /etc/vsftpd.conf ]; then
		log "Configuring vsftpd"
		echo "listen=YES" >> /etc/vsftpd.conf
		echo "local_enable=YES" >> /etc/vsftpd.conf
		echo "chroot_local_user=YES" >> /etc/vsftpd.conf
		echo "anonymous_enable=NO" >> /etc/vsftpd.conf
		echo "write_enable=YES" >> /etc/vsftpd.conf
		echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf
		echo "seccomp_sandbox=NO" >> /etc/vsftpd.conf
	fi
	log "Ftp Server init process done. Ready for start up."
}

if [ "$1" = 'vsftpd' ]; then
	log "Entrypoint script for Ftp Server started."

	ftp_init

	verify_minimum_env
fi

exec "$@"
