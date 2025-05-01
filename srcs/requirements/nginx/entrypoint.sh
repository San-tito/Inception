#!/bin/sh

set -e

log() {
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	printf '[Entrypoint]: %s\n' "$text"
}

if [ "$1" = "nginx" ]; then
	touch /etc/nginx/nginx.conf 2>/dev/null \
		|| { log "error: cannot modify /etc/nginx/nginx.conf"; exit 0; }
	log "Creating SSL certificate..."
	mkdir -p /etc/nginx/ssl
	openssl req -x509 -nodes -days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=Catalonia/L=Barcelona/O=42Barcelona/OU=42 School/CN=sguzman.42.fr" \
		|| { log "error: cannot create SSL certificate"; exit 0; }
    log "Configuration complete; ready for start up"
	# TIP: If you're not obligated to support ancient clients, remove TLSv1.1.
	# remove TLSv1.1 in /etc/nginx/nginx.conf ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
	sed -i 's/ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3/ssl_protocols TLSv1.2 TLSv1.3/g' /etc/nginx/nginx.conf
	# add server below http { in /etc/nginx/nginx.conf
	sed -i '/http {/a \
	server {\
		listen 443 ssl;\
		server_name sguzman.42.fr;\
		ssl_certificate /etc/nginx/ssl/nginx.crt;\
		ssl_certificate_key /etc/nginx/ssl/nginx.key;\
	}' /etc/nginx/nginx.conf
	cat /etc/nginx/nginx.conf
fi

exec "$@"
