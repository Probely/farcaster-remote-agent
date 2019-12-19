#!/bin/bash -e

if [ "$(id -u)" != "0" ]; then
    echo "Sorry, but you need root privileges to run the installer."
    echo
    exit 1
fi

if [ "$1" == "--local" ] && [ "$2" != "" ]; then
    deploy_path="$2"
    docker_secrets_path="./secrets"
    install_init=0
else
    deploy_path=/var/lib/farcaster
    docker_secrets_path="${deploy_path}/secrets"
    install_init=1
fi

secrets_path="${deploy_path}/secrets"
echo "Installing Farcaster Remote Agent keys to ${secrets_path}..."

# Secrets
mkdir -m 0700 -p ${secrets_path}
rm -rf ${secrets_path}/remote-agent
mv ./keys ${secrets_path}/remote-agent
chmod -R go-rwx ${secrets_path}
chown -R root:root ${secrets_path}

# Containers
sed -i s#__SECRETS_PATH__#${docker_secrets_path}#g ./config/docker-compose.yml 

# Init
if [ "${install_init}" != "0" ]; then
    echo "Installing Farcaster init scripts..."
    svcname="farcaster-remote-agent"
    compose_path=/var/lib/docker-compose/${svcname}
    rm -rf ${compose_path}
    mkdir -p -m 0700 ${compose_path}
    mv ./config/* ${compose_path}
    rm -f /etc/init.d/docker-compose.${svcname}
    ln -s /etc/init.d/docker-compose /etc/init.d/docker-compose.${svcname}
    rc-update add docker-compose.${svcname} default
    /etc/init.d/docker-compose.${svcname} start
else
    mv ./config/* ${deploy_path}
fi

echo "Installation done!"
echo
