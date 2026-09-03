#!/usr/bin/env bash
# /usr/lib/anubis-os/first-boot/reapply-user-config.sh
#
# Re-applies user configuration (Oh My Bash, Starship, fastfetch, wallpaper)
# for existing users when the ostree deployment changes (after rpm-ostree update/rebase).
# This runs on EVERY boot but only acts if the deployment has changed.
#
# Strategy: Store the current deployment checksum in /var/lib/anubis-os/.last-deployment.
# If it differs from the current boot's deployment, re-run user setup for all users.

set -euo pipefail

STATE_DIR=/var/lib/anubis-os
LAST_DEPLOYMENT_FILE="$STATE_DIR/.last-deployment"

# Get current deployment identifier
CURRENT_DEPLOYMENT=$(rpm-ostree status --json 2>/dev/null | jq -r '.deployments[0].checksum // empty' 2>/dev/null || echo "")

if [[ -z "$CURRENT_DEPLOYMENT" ]]; then
    # Fallback: use boot ID + kernel version as deployment identifier
    CURRENT_DEPLOYMENT=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null | cut -c1-8)
    CURRENT_DEPLOYMENT="${CURRENT_DEPLOYMENT}-$(uname -r)"
fi

mkdir -p "$STATE_DIR"

# Check if deployment changed
if [[ -f "$LAST_DEPLOYMENT_FILE" ]]; then
    LAST_DEPLOYMENT=$(cat "$LAST_DEPLOYMENT_FILE")
    if [[ "$LAST_DEPLOYMENT" == "$CURRENT_DEPLOYMENT" ]]; then
        # Same deployment — nothing to do
        exit 0
    fi
    echo "[reapply-user-config] Deployment changed: $LAST_DEPLOYMENT -> $CURRENT_DEPLOYMENT"
else
    echo "[reapply-user-config] First run on this deployment: $CURRENT_DEPLOYMENT"
fi

# Update deployment marker
echo "$CURRENT_DEPLOYMENT" > "$LAST_DEPLOYMENT_FILE"

# Re-apply configs for all real users (UID >= 1000)
echo "[reapply-user-config] Re-applying user configurations..."

while IFS=: read -r _user _pass uid _gid _gecos home _shell; do
    if (( uid < 1000 )) || (( uid >= 65534 )) || [[ ! -d "$home" ]]; then
        continue
    fi

    echo "  Processing user: $_user (UID $uid)"

    # --- Oh My Bash + Starship ---
    # Re-run the user setup script if Oh My Bash or Starship is missing
    OH_MY_BASH_DIR="$home/.oh-my-bash"
    STARSHIP_BIN="$home/.local/bin/starship"

    NEED_SETUP=false
    if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
        NEED_SETUP=true
    fi
    if ! command -v starship &>/dev/null && [[ ! -x "$STARSHIP_BIN" ]]; then
        NEED_SETUP=true
    fi

    if [[ "$NEED_SETUP" == "true" ]]; then
        echo "    Setting up Oh My Bash + Starship..."
        runuser -u "$_user" -- /usr/share/anubis-os/scripts/setup-ohmybash-user.sh 2>/dev/null || true
    fi

    # --- Fastfetch config ---
    FF_CONFIG="$home/.config/fastfetch/config.jsonc"
    SYSTEM_FF_CONFIG="/usr/share/fastfetch/anubis-config.jsonc"
    if [[ -f "$SYSTEM_FF_CONFIG" && ! -f "$FF_CONFIG" ]]; then
        mkdir -p "$(dirname "$FF_CONFIG")"
        cp "$SYSTEM_FF_CONFIG" "$FF_CONFIG"
        owner=$(stat -c '%u:%g' "$home")
        chown "$owner" "$FF_CONFIG" "$(dirname "$FF_CONFIG")" 2>/dev/null || true
        echo "    Applied fastfetch config"
    fi

    # --- Wallpaper ---
    # Re-apply default wallpaper if user hasn't customized it
    # We check if the current wallpaper is one of ours; if not, skip
    USER_ID=$(id -u "$_user")
    DBUS_ADDR="unix:path=/run/user/${USER_ID}/bus"

    if [[ -S "/run/user/${USER_ID}/bus" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
        CURRENT_URI=$(sudo -u "$_user" gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" || echo "")
        # If wallpaper is not set or is the old default, re-apply
        if [[ -z "$CURRENT_URI" ]] || [[ "$CURRENT_URI" == "file:///usr/share/backgrounds/gnome/"* ]] || [[ "$CURRENT_URI" == "file:///usr/share/backgrounds/f"* ]]; then
            WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
            mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | sort)
            if [[ ${#WALLPAPERS[@]} -gt 0 ]]; then
                PICK="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
                URI="file://$PICK"
                sudo -u "$_user" gsettings set org.gnome.desktop.background picture-uri      "$URI" 2>/dev/null || true
                sudo -u "$_user" gsettings set org.gnome.desktop.background picture-uri-dark "$URI" 2>/dev/null || true
                sudo -u "$_user" gsettings set org.gnome.desktop.background picture-options  'zoom' 2>/dev/null || true
                echo "    Applied new wallpaper: $PICK"
            fi
        fi
    fi

done < /etc/passwd

echo "[reapply-user-config] Done."