set -e

cat << 'EOF' > /etc/init.d/farcaster-setup
#!/sbin/openrc-run

description="Run several tasks required for Farcaster connectivity"

depend() {
	before net
	after sysctl
	use logger
}

start() {
	ebegin "Starting Farcaster setup tasks"
	_start_vm_tools
	_limit_ssh_connections
	eend $?
}

stop() {
	ebegin "Cleaning up Farcaster setup tasks"
}

_start_vm_tools() {
	vm_type=$(dmidecode -s system-product-name | tr '[:upper:]' '[:lower:]')

	case ${vm_type} in
		vmware*)
			/etc/init.d/open-vm-tools start
			;;
		virtualbox*)
			/etc/init.d/virtualbox-guest-additions start
			;;
	esac
}

_limit_ssh_connections() {
	ip_ranges="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
	for ip_range in ${ip_ranges}; do
		iptables -t filter -A INPUT -p tcp --dport 22 -s ${ip_range} -j ACCEPT
	done
	iptables -t filter -A INPUT -p tcp --dport 22 -j DROP
}
EOF

chmod +x /etc/init.d/farcaster-setup
rc-update add farcaster-setup default

cat << 'EOF' > /usr/local/bin/probely-farcaster-status
#!/bin/sh

TUNNEL_CONTAINER=farcaster-tunnel
docker logs ${TUNEL_CONTAINER} 2>/dev/null | \
	grep -E "Allocated port [0-9]+ for remote forward to gateway:2222"
if [ "$?" = "0" ]; then
	echo "Farcaster tunnel status: OK."
else
	echo "Farcaster tunnel status: ERROR."
	echo
	echo "Please contact support with the following information:"
	docker logs ${TUNNEL_CONTAINER}
fi
EOF

chmod +x /usr/local/bin/probely-farcaster-status
