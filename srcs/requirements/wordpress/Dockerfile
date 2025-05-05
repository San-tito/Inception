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
	sha1='52d5f05c96a9155f78ed84700264307e5dea14b4'; \
	curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-6.8.1.tar.gz"; \
	echo "$sha1 *wordpress.tar.gz" | sha1sum -c -; \
	mkdir -p /usr/src/; \
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm82"]
