#!/usr/bin/env bash
set -euo pipefail

# ujust
chmod 644 /usr/share/ublue-os/just/60-anubis.just 2>/dev/null || true

# sysctl hardening
chmod 644 /etc/sysctl.d/80-anubis-hardening.conf 2>/dev/null || true

# Wallpaper script + unit
chmod 755 /usr/share/anubis-os/scripts/anubis-pick-wallpaper.sh 2>/dev/null || true
chmod 644 /usr/lib/systemd/system/anubis-first-boot-wallpaper.service 2>/dev/null || true

# Wallpapers
chmod 644 /usr/share/backgrounds/anubis-os/* 2>/dev/null || true

# dconf extension override
chmod 644 /etc/dconf/db/local.d/00-anubis-extensions 2>/dev/null || true

# Logo
chmod 644 /usr/share/pixmaps/anubis-logo.png 2>/dev/null || true
chmod 644 /usr/share/pixmaps/anubis-logo-white.png 2>/dev/null || true

# Plymouth theme
chmod 755 /usr/share/plymouth/themes/anubis 2>/dev/null || true
chmod 644 /usr/share/plymouth/themes/anubis/* 2>/dev/null || true

# Fastfetch config
chmod 644 /etc/skel/.config/fastfetch/config.jsonc 2>/dev/null || true

# Oh My Bash install script
chmod 755 /usr/share/anubis-os/scripts/setup-ohmybash-user.sh 2>/dev/null || true

# Logo Menu extension logo
chmod 644 /usr/share/gnome-shell/extensions/logomenu@aryan_k/media/logo.svg 2>/dev/null || true
