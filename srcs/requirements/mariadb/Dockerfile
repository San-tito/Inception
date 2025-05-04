FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x \
    && addgroup -g 101 -S mysql \
    && adduser -S -D -H -u 101 -s /sbin/nologin -G mysql -g mysql mysql \
    && apk add --no-cache \
		su-exec \
        mariadb \
		mariadb-client \
	&& rm -rf /var/lib/mysql \
	&& mkdir -p /var/lib/mysql /run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /run/mysqld \
	&& chmod 1777 /run/mysqld

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306

CMD ["mariadbd"]
