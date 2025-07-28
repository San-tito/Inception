FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	apk add --no-cache vsftpd \
	shadow;

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["vsftpd", "/etc/vsftpd.conf"]
