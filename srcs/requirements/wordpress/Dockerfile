FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x \
	addgroup -S www-data; \
    adduser -u 82 -D -S -G www-data www-data; \
    apk add --no-cache \
		curl \
		tar \
        php82 \
		php82-fpm \
		php82-opcache \
		php82-bcmath \
		php82-exif \
		php82-gd \
		php82-intl \
		php82-mysqli \
		php82-zip; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html; \
	curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-6.8.1.tar.gz"; \
	tar --strip-components=1 -xzf wordpress.tar.gz -C /var/www/html; \
	rm wordpress.tar.gz;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm82", "-F", "-R"]
