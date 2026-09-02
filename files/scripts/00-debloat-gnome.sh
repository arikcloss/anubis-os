#!/usr/bin/env bash
# =============================================================================
# 00-debloat-gnome.sh
# =============================================================================
# Strips the Silverblue base image down to bare GNOME shell + control center.
# Removes every default GNOME app the user didn't ask for (Calendar, Weather,
# Maps, Clocks, Contacts, Music, Photos, Videos, Calculator, etc.) plus
# redundant system utilities replaced by htop/blackbox-terminal.
#
# WHY A SCRIPT, NOT A RECIPE `remove:` KEY:
#   `rpm-ostree override remove` fails the ENTIRE batch if any single package
#   is missing or has a dependent that can't be removed. Fedora renames and
#   reshuffles packages between releases (e.g. eog → loupe, gnome-photos →
#   gnome-loupe), so a hardcoded list in the recipe would break the build on
#   the next Fedora version. This script filters to only installed packages
#   and removes them one-by-one with error tolerance, so it survives package
#   renames and base image changes.
#
# IDEMPOTENT: safe to run on every build. Packages already absent are skipped.
# =============================================================================
set -euo pipefail
trap 'echo "[00-debloat-gnome] FAILED at line $LINENO" >&2' ERR

echo "[00-debloat-gnome] Scanning for removable GNOME apps..."

# --- Packages to remove ----------------------------------------------------
# This list covers the default GNOME app set shipped in Fedora Silverblue 42+.
# Each entry is a package NAME (not a filename). If a package doesn't exist
# in this Fedora version, it's simply skipped.
PACKAGES_TO_REMOVE=(
    # --- GNOME apps the user doesn't want ---
    gnome-calendar
    gnome-weather
    gnome-maps
    gnome-clocks
    gnome-contacts
    gnome-music
    gnome-photos
    gnome-videos
    ptyxis
    totem                  # gnome-videos backend
    gnome-software         # updates go through `ujust update-all`
    gnome-characters
    gnome-font-viewer
    gnome-connections
    gnome-boxes
    gnome-logs
    gnome-system-monitor  # replaced by htop
    gnome-calculator
    gnome-text-editor     # user can install via flatpak if needed
    gnome-tour
    gnome-user-docs
    gnome-user-share
    # --- Media viewers/editors ---
    evince                # Document Viewer
    eog                   # Image Viewer (Eye of GNOME)
    loupe                 # Image Viewer (newer Fedora replacement for eog)
    snapshot              # Camera
    simple-scan           # Document Scanner
    # --- Misc ---
    malcontent            # Parental controls
    rygel                 # UPnP/DLNA media sharing
    yelp                  # Help viewer
    baobab                # Disk Usage Analyzer
    gnome-disk-utility    # Disks (use lsblk/blkid instead)
    # --- Default Flatpaks baked into the base image (if any) ---
    # These are handled separately below — flatpak uninstall, not rpm-ostree.
)

# --- Filter to only installed packages -------------------------------------
# rpm -q exits non-zero if a package isn't installed; we collect only the
# ones that ARE installed so the override-remove batch never fails on a
# missing package.
INSTALLED=()
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        INSTALLED+=("$pkg")
    fi
done

if [[ ${#INSTALLED[@]} -eq 0 ]]; then
    echo "[00-debloat-gnome] Nothing to remove — base image is already clean."
else
    echo "[00-debloat-gnome] Removing ${#INSTALLED[@]} packages:"
    printf '  %s\n' "${INSTALLED[@]}"

    # Remove one at a time. This is slightly slower than a single batch but
    # FAR more resilient: if gnome-photos has a dependent that gnome-music
    # doesn't, we still remove gnome-music instead of failing the whole build.
    REMOVED=0
    FAILED=0
    for pkg in "${INSTALLED[@]}"; do
        if rpm-ostree override remove "$pkg" &>/dev/null; then
            echo "  ✓ removed: $pkg"
            ((REMOVED++)) || true
        else
            # Package has a dependent or can't be removed — non-fatal.
            echo "  ⊘ skipped (has dependent or locked): $pkg"
            ((FAILED++)) || true
        fi
    done
    echo "[00-debloat-gnome] Removed $REMOVED package(s), skipped $FAILED."
fi

# --- Remove default Flatpaks shipped by the base image ---------------------
# The ublue silverblue-main image may ship Flatpaks we don't want (e.g.
# Firefox Flatpak when we install the RPM version, or Ptyxis Flatpak when
# we install blackbox-terminal). Uninstall them so the app grid stays clean.
echo "[00-debloat-gnome] Removing unwanted default Flatpaks..."

FLATPAKS_TO_REMOVE=(
    "app/org.gnome.Ptyxis/x86_64/stable"
    "app/org.mozilla.firefox/x86_64/stable"
    "app/io.github.celluloid_player.Celluloid/x86_64/stable"
    "app/org.gnome.Calendar/x86_64/stable"
    "app/org.gnome.Weather/x86_64/stable"
    "app/org.gnome.Maps/x86_64/stable"
    "app/org.gnome.Clocks/x86_64/stable"
    "app/org.gnome.Contacts/x86_64/stable"
    "app/org.gnome.Music/x86_64/stable"
    "app/org.gnome.Photos/x86_64/stable"
    "app/org.gnome.Totem/x86_64/stable"
    "app/org.gnome.Calculator/x86_64/stable"
    "app/org.gnome.Characters/x86_64/stable"
    "app/org.gnome.Fonts/x86_64/stable"
    "app/org.gnome.Logs/x86_64/stable"
    "app/org.gnome.Extensions/x86_64/stable"
    "app/org.gnome.Connections/x86_64/stable"
    "app/org.gnome.Boxes/x86_64/stable"
    "app/org.gnome.SimpleScan/x86_64/stable"
    "app/org.gnome.Evince/x86_64/stable"
    "app/org.gnome.Loupe/x86_64/stable"
    "app/org.gnome.Snapshot/x86_64/stable"
    "app/org.gnome.Tour/x86_64/stable"
    "app/org.gnome.Yelp/x86_64/stable"
    "app/org.gnome.Baobab/x86_64/stable"
    "app/org.gnome.DiskUtility/x86_64/stable"
)

for fp in "${FLATPAKS_TO_REMOVE[@]}"; do
    # --noninteractive so it doesn't prompt; || true so a missing Flatpak
    # doesn't fail the build.
    flatpak uninstall -y --noninteractive "$fp" 2>/dev/null || true
done

echo "[00-debloat-gnome] Done. The image now contains only Nautilus,"
echo "                    Blackbox-terminal, Firefox, Htop, and Bazaar."
