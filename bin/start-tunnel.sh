#!/bin/sh -e

BASE_PATH=/farcaster
SECRETS_PATH=${BASE_PATH}/restricted/secrets
USER_SECRETS_PATH=/run/farcaster/secrets

if [ "${FARCASTER_AGENT_HUB}" = "" ]; then
    echo "Please set the FARCASTER_AGENT_HUB environment variable!"
    exit 1
fi

if [ "${FARCASTER_REMOTE_GATEWAY}" = "" ]; then
    echo "Please set the FARCASTER_REMOTE_GATEWAY environment variable!"
    exit 1
fi

AGENT_HUB_HOST=$(echo ${FARCASTER_AGENT_HUB} | cut -d ':' -f 1)
AGENT_HUB_PORT=$(echo ${FARCASTER_AGENT_HUB} | cut -d ':' -f 2)

mkdir -p -m 0711 ${USER_SECRETS_PATH}
cp -a ${SECRETS_PATH}/. ${USER_SECRETS_PATH}
chmod -R go-rwx ${USER_SECRETS_PATH}
chown -R remote-tunnel:remote-tunnel ${USER_SECRETS_PATH}

exec /bin/su - -s /bin/sh remote-tunnel -c \
    "/usr/bin/ssh -N -F ${BASE_PATH}/etc/ssh/ssh_config \
    -i ${USER_SECRETS_PATH}/identity_file \
    -o CertificateFile=${USER_SECRETS_PATH}/identity_file-cert.pub \
    -p ${AGENT_HUB_PORT} ${AGENT_HUB_HOST} -R *:0:${FARCASTER_REMOTE_GATEWAY}"
