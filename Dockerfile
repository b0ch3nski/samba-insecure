# syntax=docker/dockerfile:1.11-labs
ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}
SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN apk add --update --no-cache \
        netcat-openbsd \
        samba-client \
        samba-server \
        avahi; \
    rm -rfv /etc/avahi/services/*

COPY init.sh /usr/local/bin/

EXPOSE 137-138/udp 139/tcp 445/tcp 5353/udp

CMD ["init.sh"]
