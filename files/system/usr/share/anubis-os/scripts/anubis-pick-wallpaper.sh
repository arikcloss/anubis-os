#!/usr/bin/env bash
# =============================================================================
# anubis-pick-wallpaper.sh
# =============================================================================
# Picks a random wallpaper from the Anubis collection and applies it as the
# default for the first human user (UID >= 1000). Runs at first boot via
# systemd oneshot service.
#
# Idempotent: skips if state file exists (managed by service ConditionPathExists).
# =============================================================================
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

echo "[anubis-pick-wallpaper] Selected wallpaper: $PICK"

# Apply via gsettings for the first human user (UID >= 1000)
# Need to find user with active D-Bus session
USER_NAME=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')

if [[ -n "$USER_NAME" ]]; then
    USER_ID=$(id -u "$USER_NAME")
    DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"
    
    # Check if user has an active session
    if [[ -S "/run/user/${USER_ID}/bus" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
        runuser -u "$USER_NAME" -- gsettings set org.gnome.desktop.background picture-uri      "$URI" || true
        runuser -u "$USER_NAME" -- gsettings set org.gnome.desktop.background picture-uri-dark "$URI" || true
        runuser -u "$USER_NAME" -- gsettings set org.gnome.desktop.background picture-options  'zoom'  || true
        echo "  Applied wallpaper for user: $USER_NAME"
    else
        echo "  User $USER_NAME has no active D-Bus session; wallpaper will apply on next login"
        # The dconf defaults in 00-anubis-extensions will apply on first login
    fi
fi

mkdir -p "$STATE_DIR"
echo "$PICK" > "$STATE_FILE"
echo "[anubis-pick-wallpaper] Done."
