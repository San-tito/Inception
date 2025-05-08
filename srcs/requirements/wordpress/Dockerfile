FROM php:8.1-fpm-alpine

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -eux; \
apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		freetype-dev \
		icu-dev \
		imagemagick-dev libheif-dev \
		libavif-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
	; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		intl \
		mysqli \
		zip \
	; \
	apk del --no-network .build-deps; \
	version='6.8.1'; \
	curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
