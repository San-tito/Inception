FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk add --no-cache \
        openssl \
		nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
