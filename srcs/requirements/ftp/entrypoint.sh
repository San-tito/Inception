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
	if [ ! -d /home/$FTP_USER ]; then
		addgroup -S "$FTP_USER" > /dev/null 2>&1
		adduser -D -G "$FTP_USER" -h "/home/$FTP_USER" -s "/bin/false" "$FTP_USER" > /dev/null 2>&1
		mkdir -p /home/$FTP_USER
		chown -R "$FTP_USER":"$FTP_USER" /home/$FTP_USER
		echo "$FTP_USER:$FTP_PASS" | chpasswd
	fi
	if [ ! -f /etc/vsftpd.conf ]; then
		log "Configuring vsftpd"
		cat > /etc/vsftpd.conf <<-EOF
		background=NO
		listen_ipv6=NO
		listen=YES
		session_support=NO
		anonymous_enable=NO
		local_enable=YES
		allow_writeable_chroot=YES
		chroot_local_user=YES
		guest_enable=NO
		local_umask=022
		passwd_chroot_enable=YES
		use_localtime=YES
		dirlist_enable=YES
		dirmessage_enable=NO
		hide_ids=YES
		write_enable=YES
		connect_from_port_20=NO
		ftp_data_port=20
		max_clients=0
		max_per_ip=0
		pasv_address=0.0.0.0
		pasv_addr_resolve=YES
		pasv_promiscuous=YES
		pasv_enable=YES
		pasv_max_port=21110
		pasv_min_port=21100
		port_enable=YES
		seccomp_sandbox=NO
		EOF
	fi
	log "Ftp Server init process done. Ready for start up."
}

if [ "$1" = 'vsftpd' ]; then
	log "Entrypoint script for Ftp Server started."

	ftp_init

	verify_minimum_env
fi

exec "$@"
