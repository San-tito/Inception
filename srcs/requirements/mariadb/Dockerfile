FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
    addgroup -g 101 -S mysql; \
    adduser -S -D -H -u 101 -s /sbin/nologin -G mysql -g mysql mysql; \
    apk add --no-cache \
        mariadb \
	mariadb-client \
	mariadb-server-utils;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["mariadbd", "--user=mysql", "--console", "--skip-name-resolve", "--skip-networking=0;"]
