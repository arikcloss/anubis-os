#!/usr/bin/env bash
# =============================================================================
# setup-wallpaper.sh
# =============================================================================
# Installs the Anubis OS wallpaper set and removes stock GNOME/Fedora
# wallpapers so Settings > Background shows ONLY the Anubis collection.
#
# The default wallpaper URI (for new users, the lock screen, and GDM) is set
# by the STATIC dconf file at /etc/dconf/db/local.d/00-anubis-extensions
# (shipped by the files module). This script does NOT write dconf wallpaper
# values — it only:
#   1. Verifies the wallpaper files actually landed (fail loudly if not).
#   2. Removes stock GNOME/Fedora wallpapers (debloat).
#   3. Sets up the GDM dconf profile so GDM reads its wallpaper from
#      system-db:gdm (where we ship a separate override for the login screen).
#   4. Compiles the dconf database.
#
# IDEMPOTENT: safe to run on every build.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-wallpaper] FAILED at line $LINENO" >&2' ERR

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
XML_FILE=/usr/share/gnome-background-properties/anubis-os.xml
DEFAULT_WALLPAPER="$WALLPAPER_DIR/anubis-wallpaper.png"

echo "[setup-wallpaper] Setting up Anubis wallpaper collection..."

# --- Verify the wallpaper files landed --------------------------------------
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

WALLPAPER_COUNT=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | wc -l)
echo "  $WALLPAPER_COUNT wallpaper(s) present in $WALLPAPER_DIR"

# --- Remove stock GNOME / Fedora wallpapers (debloat) ----------------------
# These directories ship with Fedora Silverblue and add ~50-100MB of images
# the user will never look at. Removing them keeps Settings > Background
# clean (only Anubis wallpapers show up).
echo "  Removing stock GNOME wallpapers..."
rm -rf /usr/share/backgrounds/gnome 2>/dev/null || true
# Fedora versioned wallpaper dirs (f40, f41, f44, etc.)
find /usr/share/backgrounds -maxdepth 1 -type d -name 'f[0-9]*' \
    -exec rm -rf {} + 2>/dev/null || true
# Stock gnome-background-properties entries that point at removed dirs
# (otherwise they'd leave dead/broken thumbnails in Settings > Background).
find /usr/share/gnome-background-properties -maxdepth 1 -type f \
    ! -name 'anubis-os.xml' -exec rm -f {} + 2>/dev/null || true

# --- GDM login-screen wallpaper --------------------------------------------
# GDM reads its settings from a SEPARATE dconf profile (system-db:gdm, not
# system-db:local). We need to:
#   1. Create the gdm dconf profile file (if missing)
#   2. Ship a wallpaper override in /etc/dconf/db/gdm.d/
# The override file content is generated here because it's tightly coupled
# to the wallpaper verification above (we only write it after confirming the
# wallpaper exists).
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
    mkdir -p /etc/dconf/profile
    cat > "$GDM_PROFILE" << 'GDMPROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROFILE
    echo "  Created GDM dconf profile"
else
    echo "  GDM dconf profile already exists"
fi

# --- Compile dconf database ------------------------------------------------
if command -v dconf &>/dev/null; then
    dconf update 2>/dev/null || true
    echo "  dconf database compiled"
fi

echo "[setup-wallpaper] Done."
