#!/usr/bin/env bash
set -euo pipefail

# Sobrescreve o os-release para mostrar Anubis OS em vez de Fedora
# em: GNOME Settings > About, GDM, neofetch, fastfetch, etc.
cat > /usr/lib/os-release << 'OSRELEASE'
NAME="Anubis OS"
PRETTY_NAME="Anubis OS 44"
ID=anubis-os
ID_LIKE=fedora
VERSION_ID=44
VERSION="44"
VERSION_CODENAME=""
PLATFORM_ID="platform:f44"
HOME_URL="https://github.com/floatingskies/anubis-os"
SUPPORT_URL="https://github.com/floatingskies/anubis-os/issues"
BUG_REPORT_URL="https://github.com/floatingskies/anubis-os/issues"
LOGO=anubis-logo
ANSI_COLOR="0;38;2;139;92;246"
OSRELEASE

# Symlink /etc/os-release → /usr/lib/os-release (padrão systemd)
ln -sf /usr/lib/os-release /etc/os-release
