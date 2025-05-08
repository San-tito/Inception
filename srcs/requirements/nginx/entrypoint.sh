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
	if [ ! -f /etc/nginx/ssl/$DOMAIN_NAME.crt ] || [ ! -f /etc/nginx/ssl/$DOMAIN_NAME.key ]; then
		log "Generating SSL certificates"
		mkdir -p /etc/nginx/ssl
		openssl req -x509 -nodes -days 365 \
			-newkey rsa:2048 \
			-keyout /etc/nginx/ssl/$DOMAIN_NAME.key \
			-out /etc/nginx/ssl/$DOMAIN_NAME.crt \
			-subj "/C=ES/ST=Catalonia/L=Barcelona/O=42/OU=42Barcelona/CN=$DOMAIN_NAME" >/dev/null 2>&1
		log "SSL certificates generated"
	fi
}

verify_minimum_env() {
	if [ -z "$DOMAIN_NAME" ] || [ -z "$FPM_HOST" ]; then
		error $'Nginx is unitialized and options are not specified\n\tYou need to specify DOMAIN_NAME and FPM_HOST' 
	fi
}

nginx_init() {
	if ! grep 'server {' /etc/nginx/nginx.conf > /dev/null 2>&1; then
		log "Configuring server"
		sed -i "/http {/a \\
		server {\\
			listen 443 ssl;\\
			server_name $DOMAIN_NAME;\\
			ssl_certificate /etc/nginx/ssl/$DOMAIN_NAME.crt;\\
			ssl_certificate_key /etc/nginx/ssl/$DOMAIN_NAME.key;\\
			root /var/www/html;\\
			index index.html index.php;\\
			location / {\\
				try_files \$uri \$uri/ /index.php\$is_args\$args;\\
			}\\
			location ~ \\\.php\$ {\\
				include fastcgi_params;\\
				fastcgi_pass $FPM_HOST;\\
				fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\\
			}\\
		}" /etc/nginx/nginx.conf
		sed -i 's/ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3/ssl_protocols TLSv1.2 TLSv1.3/g' /etc/nginx/nginx.conf
	fi
	log "Nginx init process done. Ready for start up."
}

if [ "$1" = "nginx" ]; then
	log "Entrypoint script for Nginx Server started."

	setup_config

	verify_minimum_env

	generate_ssl

	nginx_init
fi

exec "$@"
