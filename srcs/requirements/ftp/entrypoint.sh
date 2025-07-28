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
	if ! getent passwd "$FTP_USER"; then
		adduser --disabled-password "$FTP_USER"
		mkdir -p /home/$FTP_USER
		echo "$FTP_USER" >> /etc/vsftpd/vsftpd.userlist
		echo "$FTP_USER:$FTP_PASS" | chpasswd
		chown -R "$FTP_USER":"$FTP_USER" /home/$FTP_USER
		usermod --home /home/$FTP_USER "$FTP_USER"
	fi
	if [ ! -f /etc/vsftpd.conf ]; then
		log "Configuring vsftpd"
		cat > /etc/vsftpd.conf <<-EOF
		listen=YES
		listen_ipv6=NO
		background=NO
		local_enable=YES
		local_root=/home/$FTP_USER
		userlist_deny=NO
		userlist_enable=YES
		userlist_file=/etc/vsftpd/vsftpd.userlist
		write_enable=YES
		pasv_enable=YES
		pasv_min_port=5000
		pasv_max_port=5010
		anonymous_enable=NO
		no_anon_password=NO
		anon_upload_enable=NO
		anon_mkdir_write_enable=NO
		guest_enable=NO
		chroot_local_user=YES
		chroot_list_enable=NO
		allow_writeable_chroot=YES
		port_enable=YES
		listen_port=21
		listen_address=0.0.0.0
		hide_ids=NO
		dirmessage_enable=YES
		pam_service_name=vsftpd
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
