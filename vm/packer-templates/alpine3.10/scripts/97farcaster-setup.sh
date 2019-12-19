set -e

cat << 'EOF' > /etc/init.d/farcaster-setup
#!/sbin/openrc-run

description="Run tasks required for Farcaster connectivity"

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

container=farcaster-tunnel
docker logs --tail 1 ${container} 2>&1 | \
        grep -E "Allocated port [0-9]+ for remote forward to gateway:2222"
if [ $? -eq 0 ]; then
        echo "Farcaster tunnel status: OK"
else
        echo "Farcaster tunnel status: ERROR"
        echo
        echo "Please contact Probely's support. Further details follow:"
        echo
        echo "-------------------- cut here --------------------"
        echo
        docker logs ${container}
        echo
        echo "-------------------- cut here --------------------"
fi
EOF

chmod +x /usr/local/bin/probely-farcaster-status
