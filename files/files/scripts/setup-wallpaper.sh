#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-wallpaper] FAILED at line $LINENO" >&2' ERR

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
XML_FILE=/usr/share/gnome-background-properties/anubis-os.xml
DEFAULT_WALLPAPER="$WALLPAPER_DIR/anubis-wallpaper.png"

# The wallpapers and the gnome-background-properties XML are shipped
# statically by the `files` module (files/system/usr/share/backgrounds/...
# and files/system/usr/share/gnome-background-properties/anubis-os.xml).
# This script just verifies they actually landed before relying on them,
# rather than silently shipping a broken Settings > Background page.
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "ERROR: $WALLPAPER_DIR not found. Did the files module run?" >&2
    exit 1
fi
if [[ ! -f "$XML_FILE" ]]; then
    echo "ERROR: $XML_FILE not found. Did the files module run?" >&2
    exit 1
fi
if [[ ! -f "$DEFAULT_WALLPAPER" ]]; then
    echo "ERROR: default wallpaper $DEFAULT_WALLPAPER not found." >&2
    exit 1
fi

WALLPAPER_COUNT=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | wc -l)
echo "[setup-wallpaper] $WALLPAPER_COUNT wallpaper(s) present in $WALLPAPER_DIR"

# --- Remove GNOME / Fedora stock wallpapers ----------------------------
rm -rf /usr/share/backgrounds/gnome
# Fedora versioned dirs (f40, f41, f44, etc.)
find /usr/share/backgrounds -maxdepth 1 -type d -name 'f[0-9]*' -exec rm -rf {} + 2>/dev/null || true
# Stock gnome-background-properties entries that point at the dirs above
# would otherwise leave dead/broken thumbnails in Settings > Background.
find /usr/share/gnome-background-properties -maxdepth 1 -type f \
    ! -name 'anubis-os.xml' -exec rm -f {} + 2>/dev/null || true

# --- User session default (Settings > Background) -----------------------
# Sets the default for new users; anyone can still pick any of the other
# Anubis wallpapers from the XML list above in Settings > Background.
LOCAL_DCONF_DIR=/etc/dconf/db/local.d
mkdir -p "$LOCAL_DCONF_DIR"
cat > "$LOCAL_DCONF_DIR/01-anubis-wallpaper" << GDMWALL
[org/gnome/desktop/background]
picture-uri='file://${DEFAULT_WALLPAPER}'
picture-uri-dark='file://${DEFAULT_WALLPAPER}'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file://${DEFAULT_WALLPAPER}'
GDMWALL

LOCAL_PROFILE=/etc/dconf/profile/user
if [[ ! -f "$LOCAL_PROFILE" ]]; then
    cat > "$LOCAL_PROFILE" << 'LOCALPROFILE'
user-db:user
system-db:local
LOCALPROFILE
fi

# --- GDM login background -----------------------------------------------
GDM_DCONF_DIR=/etc/dconf/db/gdm.d
mkdir -p "$GDM_DCONF_DIR"
cat > "$GDM_DCONF_DIR/01-anubis-wallpaper" << GDMWALL
[org/gnome/desktop/background]
picture-uri='file://${DEFAULT_WALLPAPER}'
picture-uri-dark='file://${DEFAULT_WALLPAPER}'
picture-options='zoom'
GDMWALL

GDM_PROFILE=/etc/dconf/profile/gdm
if [[ ! -f "$GDM_PROFILE" ]]; then
    cat > "$GDM_PROFILE" << 'GDMPROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROFILE
fi

# Compile dconf — non-fatal if dconf not present at build time
dconf update 2>/dev/null || true

echo "[setup-wallpaper] Done."
