#!/usr/bin/env bash
set -euo pipefail

systemctl enable anubis-first-boot-wallpaper.service 2>/dev/null || true
systemctl enable anubis-setup-user.service 2>/dev/null || true
