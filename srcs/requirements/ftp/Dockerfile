FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	addgroup -S -g 1000 vsftpd; \
	adduser -S -G vsftpd -u 999 vsftpd; \
	apk add --no-cache vsftpd;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD [ "vsftpd", "/etc/vsftpd/vsftpd.conf" ]
