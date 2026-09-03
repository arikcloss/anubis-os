#!/usr/bin/env bash
# =============================================================================
# setup-plymouth.sh — Anubis OS
# =============================================================================
# Configures Plymouth boot splash with Anubis branding.
# Tries Fedora 44+ patched "spinner" theme first; falls back to "script" theme
# if spinner module is not available in the installed plymouth package.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

SRC_LOGO=/usr/share/pixmaps/anubis-logo.png

if [[ ! -f "$SRC_LOGO" ]]; then
    echo "ERROR: $SRC_LOGO not found. Did the files module run?" >&2
    exit 1
fi

THEME_DIR=/usr/share/plymouth/themes/spinner
ANUBIS_THEME_DIR=/usr/share/plymouth/themes/anubis

echo "[setup-plymouth] Configuring Plymouth theme with Anubis branding..."

# Check if spinner module exists
USE_SPINNER=false
if [[ -f /usr/lib64/plymouth/spinner.so ]] || [[ -f /usr/lib/plymouth/spinner.so ]]; then
    USE_SPINNER=true
    echo "[setup-plymouth] Spinner module found, using spinner theme"
else
    echo "[setup-plymouth] Spinner module NOT found, falling back to script theme"
fi

# Create branded theme directory
mkdir -p "$ANUBIS_THEME_DIR"
install -Dm644 "$SRC_LOGO" "$ANUBIS_THEME_DIR/anubis-logo.png"

if [[ "$USE_SPINNER" == "true" ]]; then
    # Spinner theme configuration
    cat > "$ANUBIS_THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash (spinner theme)
ModuleName=spinner

[spinner]
BackgroundStartColor=0x1c0f3b
BackgroundEndColor=0x0a0514
ImageFile=/usr/share/plymouth/themes/anubis/anubis-logo.png
SpinnerColor=0xffffff
PLYMOUTH
    THEME_NAME="anubis"
    MODULE_NAME="spinner"
else
    # Script theme configuration (fallback)
    cat > "$ANUBIS_THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash (script theme)
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

    # Script theme: solid dark background, centered logo, smooth fade-in
    cat > "$ANUBIS_THEME_DIR/anubis.script" << 'SCRIPT'
Window.SetBackgroundTopColor(0.07, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.03, 0.03, 0.04);

screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

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

global.t = 0;

fun refresh_callback() {
    global.t++;
    if (global.t < 30) {
        logo_sprite.SetOpacity(global.t / 30);
    } else {
        logo_sprite.SetOpacity(1);
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

fun display_password_callback(prompt, bullets) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
SCRIPT
    THEME_NAME="anubis"
    MODULE_NAME="script"
fi

# Also update the base theme config for consistency if it exists
if [[ -f "$THEME_DIR/spinner.plymouth" ]]; then
    cp "$THEME_DIR/spinner.plymouth" "$THEME_DIR/spinner.plymouth.bak" 2>/dev/null || true
    if [[ "$USE_SPINNER" == "true" ]]; then
        sed -i 's/^BackgroundStartColor=.*/BackgroundStartColor=0x1c0f3b/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
        sed -i 's/^BackgroundEndColor=.*/BackgroundEndColor=0x0a0514/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
        sed -i 's/^SpinnerColor=.*/SpinnerColor=0xffffff/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
    fi
fi

# =============================================================================
# CONFIGURATION — OSTree / Fedora Atomic Fix
# =============================================================================

if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "ERROR: plymouth-set-default-theme not found — is the 'plymouth' package installed?" >&2
    exit 1
fi

echo "[setup-plymouth] Setting system-wide default Plymouth theme to '$THEME_NAME' (module: $MODULE_NAME)..."

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
plymouth-set-default-theme "$THEME_NAME" || {
    echo "WARNING: plymouth-set-default-theme failed, trying with -R" >&2
    plymouth-set-default-theme -R "$THEME_NAME" || true
}

# 3. Força a inclusão do tema e do módulo na configuração do Dracut
mkdir -p /etc/dracut.conf.d/
cat > /etc/dracut.conf.d/99-anubis-plymouth.conf << EOF
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
            
            dracut --force \
                   --kver "$kver" \
                   --add "plymouth" \
                   --include "$ANUBIS_THEME_DIR" "$ANUBIS_THEME_DIR" \
                   || echo "  WARNING: dracut failed for $kver (non-fatal)"
        fi
    done
fi

# Validação final
CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
echo "[setup-plymouth] Active plymouth theme: $CURRENT_THEME (module: $MODULE_NAME)"
echo "[setup-plymouth] Done. Theme '$THEME_NAME' applied and initramfs rebuilt successfully."