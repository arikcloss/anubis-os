# 60-anubis.just
# Custom ujust commands for anubis-os.
# Run `ujust` with no args to see the full menu.

# ---------------------------------------------------------------------
# CPU/kernel optimization — opt-in. Default kernel-cachyos build is the
# GENERIC variant for compatibility from 1st-gen Intel Core through
# current Intel/AMD. Switch to a CPU-tuned build only if it matches.
# ---------------------------------------------------------------------

[group('Performance')]
detect-cpu:
    @echo "Detected CPU:"
    @lscpu | grep "Model name"
    @echo ""
    @echo "If this is AMD Zen3 or newer, consider: ujust switch-kernel-znver3"
    @echo "If this is AMD Zen4, consider:           ujust switch-kernel-znver4"
    @echo "Older/older-Intel CPUs should stay on:    kernel-cachyos (generic, default)"

[group('Performance')]
switch-kernel-znver3:
    sudo rpm-ostree override remove kernel-cachyos kernel-cachyos-devel
    sudo rpm-ostree install kernel-cachyos-znver3 kernel-cachyos-znver3-devel
    echo "Reboot required: systemctl reboot"

[group('Performance')]
switch-kernel-znver4:
    sudo rpm-ostree override remove kernel-cachyos kernel-cachyos-devel
    sudo rpm-ostree install kernel-cachyos-znver4 kernel-cachyos-znver4-devel
    echo "Reboot required: systemctl reboot"

[group('Performance')]
switch-kernel-generic:
    sudo rpm-ostree override remove kernel-cachyos-znver3 kernel-cachyos-znver4
    sudo rpm-ostree install kernel-cachyos kernel-cachyos-devel
    echo "Reboot required: systemctl reboot"

[group('Performance')]
enable-scx-scheduler:
    sudo systemctl enable --now scx_lavd || sudo systemctl enable --now scx_bpfland

[group('Performance')]
disable-scx-scheduler:
    sudo systemctl disable --now scx_lavd scx_bpfland 2>/dev/null || true

# ---------------------------------------------------------------------
# Gaming
# ---------------------------------------------------------------------

[group('Gaming')]
setup-gaming-extras:
    flatpak install -y flathub net.davidotek.pupgui2
    flatpak install -y flathub com.heroicgameslauncher.hgl

[group('Gaming')]
enable-gamescope-session:
    @echo "Select 'Gamescope Session' at the GDM login screen to boot"
    @echo "straight into a SteamOS-style big-picture session."

[group('Gaming')]
gpu-tuning-ui:
    corectrl &

# ---------------------------------------------------------------------
# Security (defensive/privacy — no pentest tooling on this image)
# ---------------------------------------------------------------------

[group('Security')]
enable-hardened-profile:
    sudo rpm-ostree kargs --append=mitigations=auto,nosmt
    sudo systemctl enable --now opensnitch
    sudo systemctl enable --now clamav-freshclam.timer
    sudo systemctl enable --now firewalld
    sudo aide --init
    echo "Reboot required for kernel arg changes: systemctl reboot"

[group('Security')]
disable-hardened-profile:
    sudo rpm-ostree kargs --remove=mitigations=auto,nosmt
    sudo systemctl disable --now opensnitch
    echo "Reboot required: systemctl reboot"

[group('Security')]
run-aide-check:
    sudo aide --check

[group('Security')]
run-rootkit-scan:
    sudo rkhunter --check --skip-keypress

# ---------------------------------------------------------------------
# Desktop / personalization
# ---------------------------------------------------------------------

[group('Desktop')]
reroll-wallpaper:
    sudo rm -f /var/lib/anubis-os/.wallpaper-set
    sudo systemctl start anubis-first-boot-wallpaper.service
    @echo "New wallpaper applied — log out/in if it doesn't refresh immediately."

[group('Desktop')]
list-extensions:
    gnome-extensions list

# ---------------------------------------------------------------------
# Maintenance
# ---------------------------------------------------------------------

[group('System')]
brew-doctor:
    brew doctor

[group('System')]
anubis-update-all:
    rpm-ostree upgrade
    flatpak update -y
    brew update && brew upgrade
    fwupdmgr refresh && fwupdmgr update -y
