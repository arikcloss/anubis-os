#!/usr/bin/env bash
set -euo pipefail

PROFILE=/etc/dconf/profile/user

mkdir -p /etc/dconf/profile
if [[ ! -f "$PROFILE" ]]; then
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE"
elif ! grep -q '^system-db:local$' "$PROFILE"; then
    echo 'system-db:local' >> "$PROFILE"
fi

mkdir -p /etc/dconf/db/local.d

# Ativar todas as extensões instaladas + wallpaper global
cat > /etc/dconf/db/local.d/00-anubis-extensions << 'DCONF'
[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'appindicatorsupport@rgcjonas.gmail.com', 'blur-my-shell@aunetx', 'logomenu@aryan_k', 'caffeine@patapon.info', 'paperwm@paperwm.github.com']
disable-user-extensions=false

[org/gnome/shell/extensions/logomenu]
logo-icon-system-name=''
menu-button-icon='Custom_Image'
custom-icon='/usr/share/pixmaps/anubis-logo.png'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-wallpaper.png'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-wallpaper.png'
picture-options='zoom'
DCONF

dconf update
