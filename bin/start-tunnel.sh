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

_debug=0
if [ "$(echo ${FARCASTER_DEBUG} | grep -P '(1|on|enable|true)')" != "" ]; then
        set -x
        echo "I am: $(id)"
        _debug=1
fi

AGENT_HUB_HOST=$(echo ${FARCASTER_AGENT_HUB} | cut -d ':' -f 1)
AGENT_HUB_PORT=$(echo ${FARCASTER_AGENT_HUB} | cut -d ':' -f 2)

if [ ! -d "${USER_SECRETS_PATH}" ]; then
    mkdir -p -m 0711 -- "$(dirname ${USER_SECRETS_PATH})"
    cp -a -- "${SECRETS_PATH}" "${USER_SECRETS_PATH}"
    chmod -R go-rwx -- "${USER_SECRETS_PATH}"
    chown -R remote-tunnel:remote-tunnel -- "${USER_SECRETS_PATH}"
else
    echo "${USER_SECRETS_PATH} already exists. Not setting up secrets..."
fi

if [ "${_debug}" = "1" ]; then
    for d in / /run /run/farcaster /run/farcaster/secrets \
        /farcaster /farcaster/restricted /farcaster/restricted/secrets; do
        echo "${d}"
        ls -la "${d}" || /bin/su -s /bin/sh remote-tunnel -c "ls -la ${d}" || echo "denied"
    done
fi

exec /bin/su - -s /bin/sh remote-tunnel -c \
    "/usr/bin/ssh -N -F ${BASE_PATH}/etc/ssh/ssh_config \
    -i ${USER_SECRETS_PATH}/identity_file \
    -o CertificateFile=${USER_SECRETS_PATH}/identity_file-cert.pub \
    -p ${AGENT_HUB_PORT} ${AGENT_HUB_HOST} -R *:0:${FARCASTER_REMOTE_GATEWAY}"
