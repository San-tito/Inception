FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	apk add --no-cache  \
		curl \
		nodejs \
		yarn; \
	version='0.3.2'; \
	mkdir -p /usr/src; \
	curl -o taskcafe.tar.gz -fL "https://github.com/JordanKnott/taskcafe/archive/refs/tags/$version.tar.gz"; \
	tar -xzf taskcafe.tar.gz -C /usr/src/; \
	mv /usr/src/taskcafe-$version /usr/src/taskcafe; \
	rm taskcafe.tar.gz;

WORKDIR /var/www/html

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["echo"]
