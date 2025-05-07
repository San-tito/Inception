FROM debian:12.10-slim

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -ex; \
	groupadd -g 101 mysql; \
	useradd -r -u 101 -g mysql -s /sbin/nologin -M mysql; \
	apt-get update; \
	mkdir -p /var/lib/mysql/mysql; \
	apt-get install -y --no-install-recommends gosu mariadb-server; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /var/lib/mysql; \
	mkdir -p /var/lib/mysql /run/mysqld; \
	chown -R mysql:mysql /var/lib/mysql /run/mysqld; \
	chmod 1777 /run/mysqld; \
	find /etc/mysql/ -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log|user\s)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/';

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["mariadbd"]
