#!/usr/bin/env bash
set -euo pipefail

# Substitui logos do Fedora pela logo do Anubis OS
install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_logo_med.png

install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_whitelogo_med.png

# Logo Menu extension — substitui o SVG padrão pela logo Anubis
# O Logo Menu usa um SVG ou PNG dependendo da versão instalada
LOGO_MENU_DIR=$(find /usr/share/gnome-shell/extensions -maxdepth 2 \
    -name "logomenu*" -type d 2>/dev/null | head -1)

if [[ -n "$LOGO_MENU_DIR" ]]; then
    # Copiar como PNG e também gerar um SVG wrapper se necessário
    install -Dm644 /usr/share/pixmaps/anubis-logo.png \
        "${LOGO_MENU_DIR}/media/logo.png"
    # Criar SVG wrapper que embute o PNG
    cat > "${LOGO_MENU_DIR}/media/logo.svg" << 'LOGOSVG'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="64" height="64" viewBox="0 0 64 64">
  <image xlink:href="/usr/share/pixmaps/anubis-logo.png"
         x="0" y="0" width="64" height="64"/>
</svg>
LOGOSVG
fi
