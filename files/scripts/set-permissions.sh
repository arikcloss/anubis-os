#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[set-permissions] FAILED at line $LINENO" >&2' ERR

# Helper: chmod only if path exists
safe_chmod() {
    local mode="$1"; shift
    for path in "$@"; do
        if [[ -e "$path" ]]; then
            chmod "$mode" "$path"
        else
            echo "Warning: $path not found, skipping chmod $mode" >&2
        fi
    done
}

# ujust integration
safe_chmod 644 /usr/share/ublue-os/just/60-anubis.just

# Sysctl hardening
safe_chmod 644 /etc/sysctl.d/80-anubis-hardening.conf

# Wallpaper picker + services
safe_chmod 755 /usr/share/anubis-os/scripts/anubis-pick-wallpaper.sh
safe_chmod 755 /usr/share/anubis-os/scripts/setup-ohmybash-user.sh
safe_chmod 644 /usr/lib/systemd/system/anubis-first-boot-wallpaper.service
safe_chmod 644 /usr/lib/systemd/system/anubis-setup-user.service

# Wallpapers
if [[ -d /usr/share/backgrounds/anubis-os ]]; then
    chmod 644 /usr/share/backgrounds/anubis-os/*
fi

# dconf override
safe_chmod 644 /etc/dconf/db/local.d/00-anubis-extensions

# Logos
safe_chmod 644 /usr/share/pixmaps/anubis-logo.png
safe_chmod 644 /usr/share/pixmaps/anubis-logo-white.png

# Plymouth theme
if [[ -d /usr/share/plymouth/themes/anubis ]]; then
    chmod 755 /usr/share/plymouth/themes/anubis
    chmod 644 /usr/share/plymouth/themes/anubis/*
fi

# Fastfetch config
safe_chmod 644 /etc/skel/.config/fastfetch/config.jsonc

# Oh My Bash user script (written by setup-ohmybash.sh)
safe_chmod 755 /usr/share/anubis-os/scripts/setup-ohmybash-user.sh

# Logo Menu extension — optional, only if extension was installed
if [[ -f /usr/share/gnome-shell/extensions/logomenu@aryan_k/media/logo.svg ]]; then
    chmod 644 /usr/share/gnome-shell/extensions/logomenu@aryan_k/media/logo.svg
fi

# Update launcher
safe_chmod 644 /usr/share/applications/anubis-update.desktop
safe_chmod 644 /usr/share/icons/hicolor/scalable/apps/anubis-update.svg

echo "[set-permissions] All done."
