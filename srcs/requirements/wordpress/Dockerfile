FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	adduser -u 82 -D -S -G www-data www-data; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html; \
	apk add --no-cache  \
		curl \
		tar \
		php82 \
		php82-gd \
		php82-zip \
		php82-fpm \
		php82-phar \
		php82-exif \
		php82-intl \
		php82-ctype \
		php82-redis \
		php82-bcmath \
		php82-mysqli \
		php82-tokenizer; \
	version='6.8.1'; \
	mkdir -p /usr/src; \
	curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress;

WORKDIR /var/www/html

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm82"]
