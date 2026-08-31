#!/usr/bin/env bash
set -euo pipefail

# Define o hostname padrão da imagem
echo "anubis" > /etc/hostname

# Também via hostnamectl para garantir que o pretty name apareça
mkdir -p /etc/machine-info
cat > /etc/machine-info << 'MACHINEINFO'
PRETTY_HOSTNAME=anubis
MACHINEINFO
