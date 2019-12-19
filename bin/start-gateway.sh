#!/bin/sh

set -e

mkdir -m 0700 -p /run/sshd

USER_HOME=/farcaster/home/cloud-tunnel
chmod go-rwx ${USER_HOME}
chown -R cloud-tunnel:cloud-tunnel ${USER_HOME}
exec /usr/sbin/sshd -D -e -f /farcaster/etc/ssh/sshd_config
