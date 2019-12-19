FROM python:3-alpine

ARG REMOTE_TUN_ID=5000
ARG CLOUD_TUN_ID=5001

RUN set -ex \
    && mkdir -p /build

COPY bin etc /build/

RUN set -ex \
    && apk add openssh-server openssh-client \
    \
    && mkdir -p -m 0711 /farcaster \
    && mkdir -p -m 0711 /farcaster/bin \
    && mkdir -p -m 0711 /farcaster/etc/ssh \
    && mkdir -m 0700 /farcaster/share \
    && mkdir -m 0711 /farcaster/run \
    && mkdir -m 0711 /farcaster/home \
    \
    && addgroup -g $REMOTE_TUN_ID remote-tunnel \
    && adduser -G remote-tunnel -D \
        -h /farcaster/home/remote-tunnel -u $REMOTE_TUN_ID \
        -g "Farcaster remote tunnel" \
	    remote-tunnel \
    && chown -R remote-tunnel:remote-tunnel /farcaster/home/remote-tunnel \
    && chmod -R 0700 /farcaster/home/remote-tunnel \
    \
    && addgroup -g $CLOUD_TUN_ID cloud-tunnel \
    && adduser -G cloud-tunnel -D \
        -h /farcaster/home/cloud-tunnel -u $CLOUD_TUN_ID \
        -g "Farcaster cloud tunnel" \
        cloud-tunnel \
    && set +x \
        && tmp_pass=$(dd if=/dev/urandom bs=1 count=32 | xxd -p -c32); \
            printf "$tmp_pass\n$tmp_pass\n" | passwd -u cloud-tunnel \
    && set -x \
    && chown -R cloud-tunnel:cloud-tunnel /farcaster/home/cloud-tunnel \
    && chmod -R 0700 /farcaster/home/cloud-tunnel \
    && mv /build/*.sh /farcaster/bin/ \
    && mv /build/ssh/* /farcaster/etc/ssh/ \
    && chmod +x /farcaster/bin/* \
    \
    && rm -rf /build

EXPOSE 2222
