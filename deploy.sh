#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME="$(hostname -s)"
HOST_DIR="${SCRIPT_DIR}/${HOSTNAME}"

if [[ ! -d "${HOST_DIR}" ]]; then
    echo "Error: no config directory found for host '${HOSTNAME}' at ${HOST_DIR}"
    echo "Available hosts:"
    ls -1d "${SCRIPT_DIR}"/clh-hm90-* 2>/dev/null | xargs -n1 basename
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: this script must be run as root"
    exit 1
fi

echo "Deploying configs for ${HOSTNAME} from ${HOST_DIR}"

# network/interfaces -> /etc/network/interfaces
install -m 644 "${HOST_DIR}/network/interfaces" /etc/network/interfaces
echo "  installed /etc/network/interfaces"

# network/interfaces.d/loopbacks -> /etc/network/interfaces.d/loopbacks
mkdir -p /etc/network/interfaces.d
install -m 644 "${HOST_DIR}/network/interfaces.d/loopbacks" /etc/network/interfaces.d/loopbacks
echo "  installed /etc/network/interfaces.d/loopbacks"

# frr/frr.conf -> /etc/frr/frr.conf
install -o frr -g frr -m 640 "${HOST_DIR}/frr/frr.conf" /etc/frr/frr.conf
echo "  installed /etc/frr/frr.conf"

# frr/daemons -> /etc/frr/daemons
install -o frr -g frr -m 640 "${HOST_DIR}/frr/daemons" /etc/frr/daemons
echo "  installed /etc/frr/daemons"

# nftables/nftables.conf -> /etc/nftables.conf
install -m 644 "${HOST_DIR}/nftables/nftables.conf" /etc/nftables.conf
echo "  installed /etc/nftables.conf"

# sysctl/90-sysctl.conf -> /etc/sysctl.d/90-sysctl.conf
install -m 644 "${HOST_DIR}/sysctl/90-sysctl.conf" /etc/sysctl.d/90-sysctl.conf
echo "  installed /etc/sysctl.d/90-sysctl.conf"

echo ""
echo "All configs deployed. To apply without rebooting:"
echo "  sysctl --system                  # reload sysctl"
echo "  systemctl restart frr            # reload FRR/OSPF"
echo "  ifreload -a                      # reload network interfaces (ifupdown2)"
echo "  nft -f /etc/nftables.conf        # reload nftables"
