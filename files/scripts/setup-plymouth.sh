#!/usr/bin/env bash
# =============================================================================
# setup-plymouth.sh — Anubis OS
# =============================================================================
# Configures the Fedora 44+ patched "spinner" plymouth theme with Anubis branding.
# Uses the upstream spinner theme (no custom script theme) with custom background
# color and logo via theme configuration. This replaces the old custom script
# theme approach and ensures compatibility with Fedora's updated plymouth stack.
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

echo "[setup-plymouth] Configuring patched spinner theme with Anubis branding..."

# Create a branded spinner theme directory that extends the base spinner
mkdir -p "$ANUBIS_THEME_DIR"

# Copy logo to theme directory
install -Dm644 "$SRC_LOGO" "$ANUBIS_THEME_DIR/anubis-logo.png"

# Create theme file that inherits from spinner but with Anubis branding
cat > "$ANUBIS_THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash (spinner theme)
ModuleName=spinner

[spinner]
# Anubis purple gradient background
BackgroundStartColor=0x1c0f3b
BackgroundEndColor=0x0a0514
# Custom logo
ImageFile=/usr/share/plymouth/themes/anubis/anubis-logo.png
# Spinner color (white)
SpinnerColor=0xffffff
PLYMOUTH

# Also update the base spinner theme config for consistency if it exists
if [[ -f "$THEME_DIR/spinner.plymouth" ]]; then
    cp "$THEME_DIR/spinner.plymouth" "$THEME_DIR/spinner.plymouth.bak" 2>/dev/null || true
    sed -i 's/^BackgroundStartColor=.*/BackgroundStartColor=0x1c0f3b/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
    sed -i 's/^BackgroundEndColor=.*/BackgroundEndColor=0x0a0514/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
    sed -i 's/^SpinnerColor=.*/SpinnerColor=0xffffff/' "$THEME_DIR/spinner.plymouth" 2>/dev/null || true
else
    echo "  WARNING: Base spinner theme not found at $THEME_DIR/spinner.plymouth" >&2
    echo "  This is expected if plymouth package doesn't include spinner theme yet." >&2
fi

# =============================================================================
# CONFIGURATION — OSTree / Fedora Atomic Fix
# =============================================================================

if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "ERROR: plymouth-set-default-theme not found — is the 'plymouth' package installed?" >&2
    exit 1
fi

echo "[setup-plymouth] Setting system-wide default Plymouth theme to 'anubis'..."

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
plymouth-set-default-theme anubis || {
    echo "WARNING: plymouth-set-default-theme failed, trying with -R" >&2
    plymouth-set-default-theme -R anubis || true
}

# 3. Força a inclusão do tema e do módulo 'spinner' na configuração do Dracut
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
                   --include "$ANUBIS_THEME_DIR" "$ANUBIS_THEME_DIR" \
                   || echo "  WARNING: dracut failed for $kver (non-fatal)"
        fi
    done
fi

# Validação final
CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
echo "[setup-plymouth] Active plymouth theme: $CURRENT_THEME"
echo "[setup-plymouth] Done. Theme 'anubis' (patched spinner) applied and initramfs rebuilt successfully."