#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

if [[ ! -f /usr/share/pixmaps/anubis-logo.png ]]; then
    echo "ERROR: /usr/share/pixmaps/anubis-logo.png not found. Did the files module run?" >&2
    exit 1
fi

THEME_DIR=/usr/share/plymouth/themes/anubis
mkdir -p "$THEME_DIR"

install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    "$THEME_DIR/anubis-logo.png"

cat > "$THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

# Solid dark background (no broken Image.Text trick), centered logo with a
# smooth fade-in, and a small animated "loading" dot row under the logo so
# there's clear progress feedback even on a fast boot.
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
logo_sprite.SetY(screen_height / 2 - logo_scaled.GetHeight() / 2 - 20);
logo_sprite.SetZ(10);
logo_sprite.SetOpacity(0);

# --- three progress dots below the logo --------------------------------
dot_count  = 3;
dot_radius = 5;
dot_gap    = 24;
dots = [];
for (i = 0; i < dot_count; i++) {
    dot_image = Image.Text("\u25CF", 0.85, 0.85, 0.9, 1, 16);
    dot_sprite = Sprite(dot_image);
    dot_x = screen_width / 2 + (i - (dot_count - 1) / 2) * dot_gap - dot_image.GetWidth() / 2;
    dot_y = screen_height / 2 + logo_scaled.GetHeight() / 2 + 36;
    dot_sprite.SetX(dot_x);
    dot_sprite.SetY(dot_y);
    dot_sprite.SetZ(10);
    dot_sprite.SetOpacity(0.15);
    dots[i] = dot_sprite;
}

# --- animation: fade the logo in, then pulse the dots in sequence ------
global.t = 0;

fun refresh_callback() {
    global.t++;

    # Logo fade-in over the first ~30 frames (~1s at 30fps)
    if (global.t < 30) {
        logo_sprite.SetOpacity(global.t / 30);
    } else {
        logo_sprite.SetOpacity(1);
    }

    # Dot pulse: one dot brightens at a time, cycling
    cycle_len = 24;
    active = Math.Int(global.t / 8) % dot_count;
    for (i = 0; i < dot_count; i++) {
        if (i == active) {
            dots[i].SetOpacity(1);
        } else {
            dots[i].SetOpacity(0.2);
        }
    }
}

Plymouth.SetRefreshFunction(refresh_callback);

# --- keep dots visible through password prompts on encrypted disks -----
fun display_password_callback(prompt, bullets) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
SCRIPT

# --- Apply the theme AND rebuild the initramfs --------------------------
# This is the step the previous version was missing. Plymouth themes are
# embedded in the initramfs, not read live from disk at boot, so simply
# flipping the /etc/plymouth/plymouthd.conf / default.plymouth symlink
# (what `plymouth-set-default-theme anubis` alone does) has no visible
# effect — the old initramfs (with the old/default theme baked in) keeps
# getting booted. `-R` makes plymouth-set-default-theme set the theme AND
# immediately regenerate the initramfs via dracut, so the change is
# actually baked into the image this build produces — and since this
# script reruns on every image build, it's reapplied on every subsequent
# rpm-ostree rebase/update too, not just the first install.
if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "ERROR: plymouth-set-default-theme not found — is the 'plymouth' package installed?" >&2
    exit 1
fi

plymouth-set-default-theme -R anubis

# Belt-and-suspenders: explicitly confirm the theme made it into the
# initramfs plymouth will actually boot from, and fail loudly if not,
# rather than silently shipping an image with the wrong splash.
KVER=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core 2>/dev/null | tail -1 || true)
if [[ -n "$KVER" && -f "/boot/initramfs-${KVER}.img" ]]; then
    if ! lsinitrd "/boot/initramfs-${KVER}.img" 2>/dev/null | grep -q 'themes/anubis'; then
        echo "ERROR: anubis plymouth theme not found in initramfs after rebuild." >&2
        exit 1
    fi
    echo "[setup-plymouth] Verified anubis theme is present in initramfs-${KVER}.img"
fi

echo "[setup-plymouth] Done."
