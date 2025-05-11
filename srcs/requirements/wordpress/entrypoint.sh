#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

setup_env() {
	uid="$(id -u)"
	gid="$(id -g)"
	if [ "$uid" = '0' ]; then
		user='www-data'
		group='www-data'
	else
		user="$uid"
		group="$gid"
	fi
}

verify_minimum_env() {
	if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_NAME" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ]; then
		error $'Wordpress is unitialized and options are not specified\n\tYou need to specify WORDPRESS_DB_NAME, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD and WORDPRESS_DB_HOST'
	fi
}

configure_fpm() {
	if [ ! -e /etc/php82/php-fpm.d/docker.conf ]; then
		log "Configuring PHP-FPM"
		echo "[global]" > /etc/php82/php-fpm.d/docker.conf
		echo "daemonize = no" >> /etc/php82/php-fpm.d/docker.conf
		echo "[www]" >> /etc/php82/php-fpm.d/docker.conf
		echo "user = $user" >> /etc/php82/php-fpm.d/docker.conf
		echo "group = $group" >> /etc/php82/php-fpm.d/docker.conf
		sed -i 's/listen = 127\.0\.0\.1:9000/listen = 9000/' /etc/php82/php-fpm.d/www.conf
		log "PHP-FPM configuration completed."
	fi
}

wordpress_init() {
	if [ ! -e index.php ]; then
		if [ "$uid" = '0' ]; then
			chown "$user:$group" .
		fi
		echo "WordPress not found in $PWD, copying files from /usr/src/wordpress"
		sourceTarArgs="--create --file - --directory /usr/src/wordpress --owner $user --group $group"
		targetTarArgs="--extract --file -"
		tar $sourceTarArgs . | tar $targetTarArgs
		log "Completed copying files to $PWD"
	fi

	if [ ! -s wp-config.php ]; then
		log "No 'wp-config.php' found in $PWD, creating new one."

		curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

		wp () { 
			log $(php82 wp-cli.phar "$@" 2>&1) 
		}

		wp config create \
			--dbname="$WORDPRESS_DB_NAME" \
			--dbuser="$WORDPRESS_DB_USER" \
			--dbpass="$WORDPRESS_DB_PASSWORD" \
			--dbhost="$WORDPRESS_DB_HOST"

		wp core install \
			--title="$WORDPRESS_DB_NAME" \
			--url="$WORDPRESS_URL" \
			--admin_user="$WORDPRESS_DB_USER" \
			--admin_password="$WORDPRESS_DB_PASSWORD" \
			--admin_email="$WORDPRESS_DB_USER@example.com"
	
		if [ "$WORDPRESS_REDIS_HOST" ]; then
			wp config set WP_REDIS_HOST "$WORDPRESS_REDIS_HOST"
			wp plugin install redis-cache --activate
			wp redis enable
		fi

		if [ "$uid" = '0' ]; then
			chown -R "$user":"$group" wp-config.php
		fi
	fi
	log "WordPress init process done. Ready for start up."
}

if [ "$1" = 'php-fpm82' ]; then
	log "Entrypoint script for WordPress started."

	setup_env "$@"

	verify_minimum_env

	configure_fpm	

	wordpress_init
fi

exec "$@"
