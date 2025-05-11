FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	addgroup -g 1000 -S ftp; \
	adduser -S -D -H -u 1000 -h /home/ftp -s /sbin/nologin -G ftp ftp; \
	apk add --no-cache vsftpd;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["vsftpd"]
