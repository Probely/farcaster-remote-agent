#!/bin/sh

set -e

mkdir -m 0700 -p /run/sshd
mkdir -m 0711 -p /run/farcaster

USER_HOME=/run/farcaster/home/cloud-tunnel
mkdir -m 0700 -p ${USER_HOME}
chown -R cloud-tunnel:cloud-tunnel ${USER_HOME}
exec /usr/sbin/sshd -D -e -f /farcaster/etc/ssh/sshd_config
