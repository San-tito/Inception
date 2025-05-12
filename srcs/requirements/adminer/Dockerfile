FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	adduser -u 82 -D -S -G www-data www-data; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html; \
	apk add --no-cache  \
		curl; \
	version='5.2.1'; \
	mkdir -p /usr/src; \
	curl -o adminer.php -fL "https://github.com/vrana/adminer/releases/download/v$version/adminer-$version.php"; \
	mv adminer.php /usr/src/; \
	chown www-data:www-data /usr/src/adminer.php;

WORKDIR /var/www/html

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/sh", "-c", "true"]
