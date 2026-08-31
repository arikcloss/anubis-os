#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[enable-first-boot-units] FAILED at line $LINENO" >&2' ERR

for svc in anubis-first-boot-wallpaper.service anubis-setup-user.service; do
    if [[ ! -f "/usr/lib/systemd/system/$svc" ]]; then
        echo "ERROR: $svc not found in /usr/lib/systemd/system/ — did the files module run first?" >&2
        exit 1
    fi
    systemctl enable "$svc"
    echo "Enabled $svc"
done
