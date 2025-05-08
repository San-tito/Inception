FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	addgroup -S -g 1000 redis; \
	adduser -S -G redis -u 999 redis; \
	apk add --no-cache redis; \
	mkdir /data; \
	chown -R redis:redis /data;

WORKDIR /data

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["redis-server"]
