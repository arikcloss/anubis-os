#!/usr/bin/env bash
# =============================================================================
# set-permissions.sh
# =============================================================================
# Sets correct permissions on all files shipped by the `files` module.
# BlueBuild's `files` module copies files with their repo-side permissions,
# which may not be correct for system files. This script enforces the right
# modes as a single source of truth.
#
# Uses safe_chmod() which only acts on paths that exist, so it survives
# partial file deployments and is fully idempotent.
# =============================================================================
set -euo pipefail
trap 'echo "[set-permissions] FAILED at line $LINENO" >&2' ERR

echo "[set-permissions] Setting file permissions..."

# --- Helper: chmod only if path exists, warn otherwise ---------------------
safe_chmod() {
    local mode="$1"; shift
    for path in "$@"; do
        if [[ -e "$path" ]]; then
            chmod "$mode" "$path"
        else
            echo "  notice: $path not found, skipping chmod $mode" >&2
        fi
    done
}

# --- ujust integration -----------------------------------------------------
safe_chmod 644 /usr/share/ublue-os/just/60-anubis.just

# --- Sysctl hardening ------------------------------------------------------
safe_chmod 644 /etc/sysctl.d/80-anubis-hardening.conf

# --- anubis-os scripts (runtime, executed by systemd) ---------------------
safe_chmod 755 /usr/share/anubis-os/scripts/anubis-pick-wallpaper.sh
safe_chmod 755 /usr/share/anubis-os/scripts/setup-ohmybash-user.sh
safe_chmod 755 /usr/lib/anubis-os/first-boot/install-fastfetch-config.sh

# --- systemd unit files ----------------------------------------------------
safe_chmod 644 /usr/lib/systemd/system/anubis-first-boot-wallpaper.service
safe_chmod 644 /usr/lib/systemd/system/anubis-setup-user.service
safe_chmod 644 /usr/lib/systemd/system/anubis-fastfetch-firstboot.service

# --- Wallpapers ------------------------------------------------------------
if [[ -d /usr/share/backgrounds/anubis-os ]]; then
    chmod 644 /usr/share/backgrounds/anubis-os/* 2>/dev/null || true
    echo "  Set wallpapers to 644"
fi

# --- dconf overrides -------------------------------------------------------
safe_chmod 644 /etc/dconf/db/local.d/00-anubis-extensions
safe_chmod 644 /etc/dconf/db/local.d/01-anubis-gdm-logo
safe_chmod 644 /etc/dconf/db/local.d/locks/anubis-gdm-logo

# --- Logos (pixmaps + hicolor icons) ---------------------------------------
safe_chmod 644 /usr/share/pixmaps/anubis-logo.png
safe_chmod 644 /usr/share/pixmaps/anubis-logo-white.png
# hicolor icon theme
if [[ -d /usr/share/icons/hicolor ]]; then
    find /usr/share/icons/hicolor -type f -exec chmod 644 {} + 2>/dev/null || true
    echo "  Set hicolor icons to 644"
fi

# --- Plymouth theme --------------------------------------------------------
if [[ -d /usr/share/plymouth/themes/anubis ]]; then
    chmod 755 /usr/share/plymouth/themes/anubis
    chmod 644 /usr/share/plymouth/themes/anubis/* 2>/dev/null || true
    echo "  Set Plymouth theme permissions"
fi

# --- Fastfetch config + ASCII art ------------------------------------------
safe_chmod 644 /usr/share/fastfetch/anubis-config.jsonc
safe_chmod 644 /usr/share/fastfetch/anubis-ascii.txt

# --- profile.d snippet -----------------------------------------------------
safe_chmod 644 /etc/profile.d/anubis-fastfetch.sh

# --- Desktop file (Update System launcher) ---------------------------------
safe_chmod 644 /usr/share/applications/anubis-update.desktop

# --- Anaconda installer sidebar (for ISO builds) ---------------------------
safe_chmod 644 /usr/share/anaconda/pixmaps/rhel-sidebar.png

echo "[set-permissions] All done."
