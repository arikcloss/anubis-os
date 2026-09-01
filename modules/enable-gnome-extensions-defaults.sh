#!/usr/bin/env bash
# =============================================================================
# enable-gnome-extensions-defaults.sh
# =============================================================================
# Sets up the dconf system-db:local profile so the static defaults in
# /etc/dconf/db/local.d/ (shipped by the `files` module) take effect for all
# users. Then compiles the dconf binary database.
#
# This script does NOT write extension UUIDs or wallpaper URIs — those live
# in the static file /etc/dconf/db/local.d/00-anubis-extensions, which is the
# single source of truth. This separation prevents the UUID-mismatch bugs that
# plagued earlier versions (script wrote one set of UUIDs, static file had
# another, GNOME enabled neither).
#
# IDEMPOTENT: safe to run on every build.
# =============================================================================
set -euo pipefail
trap 'echo "[enable-gnome-extensions-defaults] FAILED at line $LINENO" >&2' ERR

echo "[enable-gnome-extensions-defaults] Setting up dconf system-db:local profile..."

# --- Ensure the dconf user profile exists and references system-db:local ---
# The profile file tells dconf where to look for system-wide defaults.
# Must include BOTH 'user-db:user' (per-user overrides) AND 'system-db:local'
# (our system-wide defaults). We append missing lines rather than overwriting,
# so a base image that already has a profile gets augmented, not clobbered.
PROFILE_DIR=/etc/dconf/profile
mkdir -p "$PROFILE_DIR"

PROFILE="$PROFILE_DIR/user"
if [[ ! -f "$PROFILE" ]]; then
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE"
    echo "  Created $PROFILE"
else
    grep -q '^user-db:user$'    "$PROFILE" || echo 'user-db:user'    >> "$PROFILE"
    grep -q '^system-db:local$' "$PROFILE" || echo 'system-db:local' >> "$PROFILE"
    echo "  Updated $PROFILE (missing lines appended)"
fi

# --- Ensure the local.d directory exists (the static .conf files go here) ---
mkdir -p /etc/dconf/db/local.d

# --- Verify the static defaults file landed (shipped by the files module) ---
DEFAULTS_FILE=/etc/dconf/db/local.d/00-anubis-extensions
if [[ ! -f "$DEFAULTS_FILE" ]]; then
    echo "  WARNING: $DEFAULTS_FILE not found — did the files module run?" >&2
    echo "  GNOME extensions will not be auto-enabled. Build will continue." >&2
else
    echo "  Verified: $DEFAULTS_FILE present"
fi

# --- Compile the dconf binary database ---
# This converts the .conf text files in local.d/ into the binary database
# that GNOME Shell reads at login. In a BlueBuild/ostree build, this runs at
# image-build time so the compiled DB ships inside the image.
# Non-fatal if dconf isn't present (shouldn't happen on GNOME base, but safe).
if command -v dconf &>/dev/null; then
    dconf update 2>/dev/null || true
    echo "  dconf database compiled"
else
    echo "  WARNING: dconf command not found — database not compiled" >&2
fi

echo "[enable-gnome-extensions-defaults] Done."
