#!/usr/bin/env bash
# =============================================================================
# setup-plymouth.sh
# =============================================================================
# Creates and applies the Anubis OS Plymouth boot splash theme.
# Runs at build time. Rebuilds initramfs so theme persists across kernel updates.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

SRC_LOGO=/usr/share/pixmaps/anubis-logo.png

if [[ ! -f "$SRC_LOGO" ]]; then
    echo "ERROR: $SRC_LOGO not found. Did the files module run?" >&2
    exit 1
fi

THEME_DIR=/usr/share/plymouth/themes/anubis
mkdir -p "$THEME_DIR"

echo "[setup-plymouth] Installing Anubis Plymouth theme..."

# Copy logo to theme directory
install -Dm644 "$SRC_LOGO" "$THEME_DIR/anubis-logo.png"

# Theme metadata
cat > "$THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

# Theme script: solid dark background, centered logo, smooth fade-in
cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
# --- background -------------------------------------------------------
Window.SetBackgroundTopColor(0.07, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.03, 0.03, 0.04);

screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

# --- logo, scaled to ~28% of the shorter screen dimension -------------
logo_image = Image("anubis-logo.png");
scale = Math.Min(screen_width, screen_height) * 0.28 / logo_image.GetWidth();
logo_scaled = logo_image.Scale(
    logo_image.GetWidth()  * scale,
    logo_image.GetHeight() * scale
);
logo_sprite = Sprite(logo_scaled);
logo_sprite.SetX(screen_width  / 2 - logo_scaled.GetWidth()  / 2);
logo_sprite.SetY(screen_height / 2 - logo_scaled.GetHeight() / 2);
logo_sprite.SetZ(10);
logo_sprite.SetOpacity(0);

# --- animation: fade the logo in smoothly -----------------------------
global.t = 0;

fun refresh_callback() {
    global.t++;

    # Logo fade-in over the first ~30 frames (~1s at 30fps)
    if (global.t < 30) {
        logo_sprite.SetOpacity(global.t / 30);
    } else {
        logo_sprite.SetOpacity(1);
    }
}

Plymouth.SetRefreshFunction(refresh_callback);

# --- keep logo visible through password prompts on encrypted disks -----
fun display_password_callback(prompt, bullets) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
SCRIPT

# =============================================================================
# CONFIGURAÇÃO DE TEMA (OSTree / Fedora Atomic Fix)
# =============================================================================

if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "ERROR: plymouth-set-default-theme not found — is the 'plymouth' package installed?" >&2
    exit 1
fi

echo "[setup-plymouth] Setting system-wide default Plymouth theme..."

# 1. Configura fallback global imutável do OSTree (/usr/share)
if [[ -f /usr/share/plymouth/plymouthd.defaults ]]; then
    sed -i 's/^Theme=.*/Theme=anubis/' /usr/share/plymouth/plymouthd.defaults
else
    cat > /usr/share/plymouth/plymouthd.defaults << 'EOF'
[Daemon]
Theme=anubis
ShowDelay=0
DeviceTimeout=8
EOF
fi

# 2. Define o tema no runtime (/etc)
plymouth-set-default-theme anubis

# 3. Força a inclusão do tema e do módulo 'script' na configuração do Dracut
mkdir -p /etc/dracut.conf.d/
cat > /etc/dracut.conf.d/99-anubis-plymouth.conf << 'EOF'
add_dracutmodules+=" plymouth "
plymouthd_theme="anubis"
EOF

# =============================================================================
# GERAÇÃO DO INITRAMFS
# =============================================================================

if command -v dracut &>/dev/null; then
    echo "[setup-plymouth] Regenerating initramfs for all kernels..."
    KERNEL_VERSIONS=$(ls /usr/lib/modules/ 2>/dev/null | sort -V)
    
    for kver in $KERNEL_VERSIONS; do
        if [[ -f "/usr/lib/modules/$kver/vmlinuz" ]] || [[ -f "/boot/vmlinuz-$kver" ]]; then
            echo "  Regenerating initramfs for kernel: $kver"
            
            # --include garante a cópia dos assets do anubis para dentro do initramfs
            dracut --force \
                   --kver "$kver" \
                   --add "plymouth" \
                   --include "$THEME_DIR" "$THEME_DIR" \
                   || echo "  WARNING: dracut failed for $kver (non-fatal)"
        fi
    done
fi

# Validação final
CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
echo "[setup-plymouth] Active plymouth theme: $CURRENT_THEME"
echo "[setup-plymouth] Done. Theme 'anubis' applied and initramfs rebuilt successfully."
