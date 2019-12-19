FROM python:3.7-slim

ARG REMOTE_TUN_ID=5000
ARG CLOUD_TUN_ID=5001

RUN set -ex \
    && mkdir -p /build

COPY bin etc /build/

RUN set -ex \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        --no-install-recommends --no-install-suggests \
        openssh-client \
        openssh-server \
        xxd \
    && mkdir -p /run/sshd \
    && apt-get clean \
    \
    && mkdir -p -m 0711 /farcaster \
    && mkdir -p -m 0711 /farcaster/bin \
    && mkdir -p -m 0711 /farcaster/etc/ssh \
    && mkdir -m 0700 /farcaster/share \
    && mkdir -m 0711 /farcaster/run \
    && mkdir -m 0711 /farcaster/home \
    \
    && groupadd -g $REMOTE_TUN_ID remote-tunnel \
    && useradd -g remote-tunnel -u $REMOTE_TUN_ID \
        -m -d /farcaster/home/remote-tunnel remote-tunnel \
    \
    && chown -R remote-tunnel:remote-tunnel /farcaster/home/remote-tunnel \
    && chmod -R 0700 /farcaster/home/remote-tunnel \
    \
    && groupadd -g $CLOUD_TUN_ID cloud-tunnel \
    && useradd -g cloud-tunnel -u $CLOUD_TUN_ID \
        -m -d /farcaster/home/cloud-tunnel cloud-tunnel \
    \
    && set +x \
        && tmp_pass=$(dd if=/dev/urandom bs=1 count=32 | xxd -p -c32); \
            usermod -p $tmp_pass cloud-tunnel \
    && set -x \
    && chown -R cloud-tunnel:cloud-tunnel /farcaster/home/cloud-tunnel \
    && chmod -R 0700 /farcaster/home/cloud-tunnel \
    && mv /build/*.sh /farcaster/bin/ \
    && mv /build/ssh/* /farcaster/etc/ssh/ \
    && chmod +x /farcaster/bin/* \
    \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /build

EXPOSE 2222
