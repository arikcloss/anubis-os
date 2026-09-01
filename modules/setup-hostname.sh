#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-hostname] FAILED at line $LINENO" >&2' ERR

mkdir -p /etc
echo "anubis" > /etc/hostname

# /etc/machine-info can end up as a directory in some base images — nuke it first
rm -rf /etc/machine-info
cat > /etc/machine-info << 'MACHINEINFO'
PRETTY_HOSTNAME="anubis-os"
ICON_NAME="computer"
MACHINEINFO

echo "[setup-hostname] Done — hostname set to anubis."
