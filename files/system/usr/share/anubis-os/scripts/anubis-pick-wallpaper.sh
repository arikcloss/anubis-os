#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
STATE_DIR=/var/lib/anubis-os
STATE_FILE="$STATE_DIR/.wallpaper-set"

# Collect all wallpaper files
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" \
    -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) \
    | sort)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Pick a random wallpaper
PICK="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
URI="file://$PICK"

# Apply via gsettings for the first human user (UID >= 1000)
USER_NAME=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')

if [[ -n "$USER_NAME" ]]; then
    USER_ID=$(id -u "$USER_NAME")
    DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"
    export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
    sudo -u "$USER_NAME" gsettings set org.gnome.desktop.background picture-uri      "$URI" || true
    sudo -u "$USER_NAME" gsettings set org.gnome.desktop.background picture-uri-dark "$URI" || true
    sudo -u "$USER_NAME" gsettings set org.gnome.desktop.background picture-options  'zoom'  || true
fi

mkdir -p "$STATE_DIR"
echo "$PICK" > "$STATE_FILE"
