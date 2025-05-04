#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

setup_config() {
	if [ ! -f /etc/nginx/nginx.conf ]; then
		error "Cannot modify /etc/nginx/nginx.conf"
	fi
}

generate_ssl() {
	log "Generating SSL certificates"
	mkdir -p /etc/nginx/ssl
	openssl req -x509 -nodes -days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=Catalonia/L=Barcelona/O=42/OU=42Barcelona/CN=sguzman.42.fr" >/dev/null 2>&1

	if [ ! -f /etc/nginx/ssl/nginx.key ]; then
		error "Cannot create SSL key"
	fi

	log "SSL certificates generated"
}

nginx_init() {
	log "Configuring server"
	sed -i '/http {/a \
	server {\
		listen 443 ssl;\
		server_name sguzman.42.fr;\
		ssl_certificate /etc/nginx/ssl/nginx.crt;\
		ssl_certificate_key /etc/nginx/ssl/nginx.key;\
	}' /etc/nginx/nginx.conf
	sed -i 's/ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3/ssl_protocols TLSv1.2 TLSv1.3/g' /etc/nginx/nginx.conf
	log "Nginx init process done. Ready for start up."
}

if [ "$1" = "nginx" ]; then
	log "Entrypoint script for Nginx Server started."

	setup_config

	generate_ssl

	nginx_init
fi

exec "$@"
