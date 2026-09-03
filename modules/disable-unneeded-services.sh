#!/usr/bin/env bash
# =============================================================================
# disable-unneeded-services.sh
# =============================================================================
# Disables GNOME/system services that consume RAM but aren't needed by most users.
# Users can re-enable them via ujust commands if needed.
#
# Services disabled:
#   - bluetooth.service / bluetooth.target          (enable via: ujust enable-bluetooth)
#   - tracker-miner-fs-3.service                    (file indexing — heavy RAM)
#   - tracker-extract-3.service                     (file metadata extraction)
#   - cups.service / cups-browsed.service           (printing — enable via: ujust enable-printing)
#   - avahi-daemon.service                          (mDNS/Bonjour — rarely needed)
#   - geoclue.service                               (location services — privacy/ram)
#   - ModemManager.service                          (modem management — laptops only)
#   - fprintd.service                               (fingerprint reader — if no hardware)
#   - upower.service                                (power stats — handled by systemd)
#   - accounts-daemon.service                       (user accounts — GDM handles this)
#   - packagekit.service                            (software updates — we use rpm-ostree)
#   - gnome-software.service                        (app store — we use flatpak/cli)
#
# IDEMPOTENT: safe to run on every build. systemctl disable is a no-op if already disabled.
# =============================================================================
set -euo pipefail
trap 'echo "[disable-unneeded-services] FAILED at line $LINENO" >&2' ERR

echo "[disable-unneeded-services] Disabling unneeded services to reduce RAM usage..."

SERVICES_TO_DISABLE=(
    # Bluetooth (heavy, many users don't need it)
    "bluetooth.service"
    "bluetooth.target"

    # Tracker file indexing (major RAM consumer)
    "tracker-miner-fs-3.service"
    "tracker-extract-3.service"

    # Printing (cups + cups-browsed)
    "cups.service"
    "cups-browsed.service"

    # mDNS/Bonjour
    "avahi-daemon.service"

    # Location services
    "geoclue.service"

    # Modem management
    "ModemManager.service"

    # Fingerprint reader
    "fprintd.service"

    # Power statistics (systemd handles power now)
    "upower.service"

    # User accounts daemon (GDM handles this)
    "accounts-daemon.service"

    # PackageKit (we use rpm-ostree + flatpak)
    "packagekit.service"

    # GNOME Software (app store — we use flatpak/cli)
    "gnome-software.service"
)

DISABLED=0
ALREADY_DISABLED=0
NOT_FOUND=0

for svc in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl list-unit-files --full | grep -q "^$svc"; then
        if systemctl is-enabled "$svc" &>/dev/null; then
            systemctl disable "$svc" 2>/dev/null && {
                echo "  ✓ Disabled: $svc"
                ((DISABLED++))
            } || {
                echo "  ⊘ Failed to disable: $svc"
            }
        else
            ((ALREADY_DISABLED++))
        fi
    else
        ((NOT_FOUND++))
    fi
done

echo "[disable-unneeded-services] Disabled $DISABLED, already disabled $ALREADY_DISABLED, not found $NOT_FOUND."

# Also mask services that are commonly pulled in by other units
# Masking prevents them from being started even as dependencies.
MASK_SERVICES=(
    "tracker-miner-fs-3.service"
    "tracker-extract-3.service"
)

for svc in "${MASK_SERVICES[@]}"; do
    if systemctl list-unit-files --full | grep -q "^$svc"; then
        systemctl mask "$svc" 2>/dev/null && echo "  ✓ Masked: $svc" || true
    fi
done

# Disable GNOME Shell search providers that use tracker
# This prevents GNOME from trying to use tracker for file search
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/02-anubis-disable-tracker << 'DCONF'
[org/freedesktop/tracker/miner/files]
index-on-battery=false
index-on-battery-first-time=false
crawl-interval=-1
enable-monitors=false

[org/gnome/desktop/search-providers]
disable-external=false
DCONF

echo "[disable-unneeded-services] Done."