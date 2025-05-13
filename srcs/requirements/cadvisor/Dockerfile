FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

RUN set -x; \
	apk add --no-cache  \
		curl; \
	version='0.50.0'; \
	curl -o cadvisor -fL "https://github.com/google/cadvisor/releases/download/v$version/cadvisor-v$version-linux-amd64"; \
	chmod +x cadvisor;

CMD ["./cadvisor", "--v=1", "--stderrthreshold=0"]
