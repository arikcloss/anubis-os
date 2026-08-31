#!/usr/bin/env bash
set -euo pipefail
# Copia .bashrc e configs para usuários reais (uid >= 1000)
while IFS=: read -r user _ uid _ _ home _; do
    [[ "$uid" -ge 1000 ]] || continue
    [[ -d "$home" ]] || continue
    cp -n /etc/skel/.bashrc "$home/.bashrc" 2>/dev/null || true
    mkdir -p "$home/.config/fastfetch" "$home/.config"
    cp -n /etc/skel/.config/fastfetch/config.jsonc \
        "$home/.config/fastfetch/config.jsonc" 2>/dev/null || true
    cp -n /etc/skel/.config/starship.toml \
        "$home/.config/starship.toml" 2>/dev/null || true
    chown -R "$user:$user" "$home/.bashrc" \
        "$home/.config/fastfetch" \
        "$home/.config/starship.toml" 2>/dev/null || true
done < /etc/passwd
