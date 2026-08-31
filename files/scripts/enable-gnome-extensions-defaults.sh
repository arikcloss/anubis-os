#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[enable-gnome-extensions-defaults] FAILED at line $LINENO" >&2' ERR

# Ensure dconf profile directory exists
mkdir -p /etc/dconf/profile

# Create or update the dconf user profile to reference the system 'local' db.
# Must include BOTH 'user-db:user' (per-user overrides) AND 'system-db:local'
# (system-wide defaults applied at build time). Original only handled
# system-db:local in the elif, which broke idempotency on rebuilds.
PROFILE=/etc/dconf/profile/user
if [[ ! -f "$PROFILE" ]]; then
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE"
else
    grep -q '^user-db:user$'    "$PROFILE" || echo 'user-db:user'    >> "$PROFILE"
    grep -q '^system-db:local$' "$PROFILE" || echo 'system-db:local' >> "$PROFILE"
fi

# Directory for system-wide dconf defaults
mkdir -p /etc/dconf/db/local.d

# Write GNOME Shell defaults: enabled extensions, Logo Menu config and wallpaper.
# NOTE: the UUIDs in 'enabled-extensions' MUST match the extensions installed by
# the bluebuild `gnome-extensions` module. Logo Menu UUID = logomenu@aryan_k.
cat > /etc/dconf/db/local.d/00-anubis-extensions << 'DCONF'
[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'appindicatorsupport@rgcjonas.gmail.com', 'blur-my-shell@aunetx', 'logomenu@aryan_k', 'caffeine@patapon.info', 'paperwm@paperwm.github.com']
disable-user-extensions=false

[org/gnome/shell/extensions/logomenu]
logo-icon-system-name=''
menu-button-icon='Custom_Image'
custom-icon='/usr/share/pixmaps/anubis-logo.png'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-options='zoom'
DCONF

# Compile the dconf binary database. In an ostree/bluebuild build, this runs
# at image-build time so the compiled DB ships inside the image.
dconf update 2>/dev/null || true

echo "[enable-gnome-extensions-defaults] All done."
