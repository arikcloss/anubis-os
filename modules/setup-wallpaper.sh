#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
mkdir -p "$WALLPAPER_DIR"

# O wallpaper já deve estar em files/system/usr/share/backgrounds/anubis-os/
# Este script garante permissões e configura como padrão do GDM também

# Wallpaper global para GDM (tela de login / seleção de idioma)
GDMCONF=/etc/dconf/db/gdm.d
mkdir -p "$GDMCONF"

cat > "$GDMCONF/01-anubis-wallpaper" << 'GDMCONF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-01-fire-forest.jpg'
picture-options='zoom'
GDMCONF

# Profile do GDM para ler o db gdm
GDM_PROFILE=/etc/dconf/profile/gdm
if [[ ! -f "$GDM_PROFILE" ]]; then
    cat > "$GDM_PROFILE" << 'PROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
PROFILE
fi

dconf update
