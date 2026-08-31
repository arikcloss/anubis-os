#!/usr/bin/env bash
set -euo pipefail

# Instala tema Plymouth baseado na logo Anubis
THEME_DIR=/usr/share/plymouth/themes/anubis
mkdir -p "$THEME_DIR"

# 1. CORREÇÃO DE SEGURANÇA: Garante que a logo exista ou usa uma cópia relativa
# Se anubis-logo.png estiver dentro de 'files/system/usr/share/pixmaps/' no seu repo,
# ela já estará no /usr/share/pixmaps/ no momento em que este script rodar.
if [ -f "/usr/share/pixmaps/anubis-logo.png" ]; then
    install -Dm644 /usr/share/pixmaps/anubis-logo.png "$THEME_DIR/anubis-logo.png"
else
    echo "[WARN] /usr/share/pixmaps/anubis-logo.png não encontrada. Verifique sua pasta 'files'."
fi

# Tema Plymouth (.plymouth)
cat > "$THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

# Script de animação do Plymouth (.script)
cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
# Fundo Roxo Escuro / Preto Anubis
# CORREÇÃO: No Plymouth, Window.SetBackgroundTopColor/BottomColor é mais seguro e performático que criar um retângulo gigante.
Window.SetBackgroundTopColor(0.1, 0.05, 0.18); 
Window.SetBackgroundBottomColor(0.1, 0.05, 0.18);

# Carregar e renderizar a logo centralizada
wallpaper_image = Image("anubis-logo.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

scale = Math.Min(screen_width / wallpaper_image.GetWidth(), screen_height / wallpaper_image.GetHeight());
scaled = wallpaper_image.Scale(wallpaper_image.GetWidth() * scale * 0.4, wallpaper_image.GetHeight() * scale * 0.4);

sprite = Sprite(scaled);
sprite.SetX(screen_width  / 2 - scaled.GetWidth()  / 2);
sprite.SetY(screen_height / 2 - scaled.GetHeight() / 2);
SCRIPT

# Registrar e ativar o tema
plymouth-set-default-theme anubis 2>/dev/null || \
    ln -sf "$THEME_DIR/anubis.plymouth" /usr/share/plymouth/themes/default.plymouth || true
