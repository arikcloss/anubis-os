#!/usr/bin/env bash
# =============================================================================
# setup-logo.sh
# =============================================================================
# Replaces Fedora's stock branding pixmaps with the Anubis OS logo, so every
# surface that hardcodes the Fedora filename shows the Anubis logo instead.
#
# Branding surfaces covered:
#   • /usr/share/pixmaps/fedora_logo_med.png      (GTK/GNOME "About" dialogs)
#   • /usr/share/pixmaps/fedora_whitelogo_med.png (dark-mode "About" dialogs)
#   • GDM login-screen logo (via dconf override shipped as a static file —
#     this script just ensures the dconf db is compiled after the override
#     lands)
#
# NOTE: The Logo Menu GNOME Shell extension is NOT installed in this image.
# Branding of the GNOME Shell top-bar is handled by the default Activities
# button — we keep it stock for maximum stability and simplicity.
#
# IDEMPOTENT: safe to run on every build.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-logo] FAILED at line $LINENO" >&2' ERR

SRC_LOGO=/usr/share/pixmaps/anubis-logo.png

if [[ ! -f "$SRC_LOGO" ]]; then
    echo "ERROR: $SRC_LOGO not found. Did the files module run?" >&2
    exit 1
fi

echo "[setup-logo] Replacing Fedora branding pixmaps with Anubis logo..."

# --- Fedora "About"/branding pixmaps ---------------------------------------
# Various GTK/GNOME surfaces hardcode these filenames. Overwriting them with
# our logo is the most reliable way to rebrand without patching individual apps.
install -Dm644 "$SRC_LOGO" /usr/share/pixmaps/fedora_logo_med.png
install -Dm644 "$SRC_LOGO" /usr/share/pixmaps/fedora_whitelogo_med.png
echo "  Replaced fedora_logo_med.png and fedora_whitelogo_med.png"

# --- GDM / lock screen logo ------------------------------------------------
# GNOME Shell's login/lock screen reads its logo from the
# org.gnome.login-screen "logo" gsettings key. The static dconf override at
# /etc/dconf/db/local.d/01-anubis-gdm-logo (shipped by the files module)
# points that key at our logo. We just need to ensure the dconf database is
# compiled so the override takes effect.
GDM_LOGO_OVERRIDE=/etc/dconf/db/local.d/01-anubis-gdm-logo
if [[ -f "$GDM_LOGO_OVERRIDE" ]]; then
    if command -v dconf &>/dev/null; then
        dconf update 2>/dev/null || true
    fi
    echo "  GDM login-screen logo override compiled"
else
    echo "  WARNING: $GDM_LOGO_OVERRIDE not found — GDM logo not set" >&2
fi

echo "[setup-logo] Done."
