FROM alpine:3.21

LABEL maintainer="sguzman <sguzman@student.42barcelona.com>"

WORKDIR /var/www/html

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/sh", "-c", "true"]
