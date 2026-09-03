#!/usr/bin/env bash
# =============================================================================
# enable-first-boot-units.sh
# =============================================================================
# Enables the systemd oneshot services that run on first boot to set up
# per-user state (wallpaper, Oh My Bash, fastfetch config). These services
# are shipped as static files by the `files` module and must be enabled here
# (after the files module has copied them into /usr/lib/systemd/system/).
#
# Services enabled:
#   • anubis-first-boot-wallpaper.service  — picks a random wallpaper on boot
#   • anubis-setup-user.service            — installs Oh My Bash + Starship
#   • anubis-fastfetch-firstboot.service   — seeds fastfetch config for
#                                            existing users on first boot
#   • anubis-reapply-user-config.service   — re-applies user config on updates
#   • anubis-flatpak-preinstall.service    — installs GNOME Circle Flatpaks
#
# IDEMPOTENT: `systemctl enable` is a no-op if already enabled.
# =============================================================================
set -euo pipefail
trap 'echo "[enable-first-boot-units] FAILED at line $LINENO" >&2' ERR

echo "[enable-first-boot-units] Enabling first-boot services..."

SERVICES=(
    anubis-first-boot-wallpaper.service
    anubis-setup-user.service
    anubis-fastfetch-firstboot.service
    anubis-reapply-user-config.service
    anubis-flatpak-preinstall.service
)

for svc in "${SERVICES[@]}"; do
    unit_path="/usr/lib/systemd/system/$svc"
    if [[ ! -f "$unit_path" ]]; then
        echo "  WARNING: $svc not found at $unit_path" >&2
        echo "           Did the files module run and copy the unit file?" >&2
        # Non-fatal: the service just won't run. Better than failing the build.
        continue
    fi
    if systemctl enable "$svc" 2>/dev/null; then
        echo "  ✓ Enabled $svc"
    else
        echo "  ⊘ $svc already enabled or enable failed (non-fatal)"
    fi
done

echo "[enable-first-boot-units] Done."
