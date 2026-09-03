# =============================================================================
# 60-anubis.just — custom ujust commands for anubis-os
# =============================================================================
# Run `ujust` with no args to see the full menu (including ublue's built-ins).
# =============================================================================

# -----------------------------------------------------------------------------
# Performance
# -----------------------------------------------------------------------------

[group('Performance')]
detect-cpu:
    @echo "Detected CPU:"
    @lscpu | grep "Model name"

[group('Performance')]
set-tuned-profile:
    #!/usr/bin/env bash
    echo "Available tuned profiles:"
    tuned-adm list 2>/dev/null || echo "tuned-adm not found"
    echo ""
    read -p "Enter profile name (e.g. balanced/powersave/throughput-performance/desktop): " profile
    sudo tuned-adm profile "$profile"
    echo "✓ Active profile: $(tuned-adm active)"

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

[group('Security')]
enable-hardened-profile:
    #!/usr/bin/env bash
    set -e
    echo "Enabling aggressive security hardening profile..."
    echo "  • Kernel mitigations + disable SMT (hyperthreading)"
    echo "  • OpenSnitch application firewall (if installed)"
    echo "  • ClamAV + freshclam"
    echo "  • AIDE file integrity baseline"
    echo "  • firewalld"
    echo ""
    sudo rpm-ostree kargs --append=mitigations=auto,nosmt
    # OpenSnitch isn't installed in the base; only enable it if present.
    sudo systemctl enable --now opensnitch 2>/dev/null || echo "  (OpenSnitch not installed — skipping; install via 'dnf install opensnitch')"
    sudo systemctl enable --now clamav-freshclam.timer
    sudo systemctl enable --now firewalld
    sudo aide --init
    echo ""
    echo "⚠ Reboot required for kernel arg changes: systemctl reboot"

[group('Security')]
disable-hardened-profile:
    #!/usr/bin/env bash
    set -e
    echo "Disabling aggressive security profile (reverting to balanced defaults)..."
    sudo rpm-ostree kargs --remove=mitigations=auto,nosmt 2>/dev/null || true
    sudo systemctl disable --now opensnitch 2>/dev/null || true
    echo "✓ Done. Reboot required: systemctl reboot"

# -----------------------------------------------------------------------------
# Services (enable/disable optional services)
# -----------------------------------------------------------------------------

[group('Services')]
enable-bluetooth:
    #!/usr/bin/env bash
    set -e
    echo "Enabling Bluetooth..."
    sudo systemctl unmask bluetooth.service 2>/dev/null || true
    sudo systemctl enable --now bluetooth.service
    sudo systemctl enable --now bluetooth.target 2>/dev/null || true
    echo "✓ Bluetooth enabled. You may need to restart your session."

[group('Services')]
disable-bluetooth:
    #!/usr/bin/env bash
    set -e
    echo "Disabling Bluetooth..."
    sudo systemctl disable --now bluetooth.service 2>/dev/null || true
    sudo systemctl disable --now bluetooth.target 2>/dev/null || true
    sudo systemctl mask bluetooth.service 2>/dev/null || true
    echo "✓ Bluetooth disabled."

[group('Services')]
enable-printing:
    #!/usr/bin/env bash
    set -e
    echo "Enabling printing (CUPS)..."
    sudo systemctl unmask cups.service 2>/dev/null || true
    sudo systemctl unmask cups-browsed.service 2>/dev/null || true
    sudo systemctl enable --now cups.service
    sudo systemctl enable --now cups-browsed.service 2>/dev/null || true
    echo "✓ Printing enabled."

[group('Services')]
disable-printing:
    #!/usr/bin/env bash
    set -e
    echo "Disabling printing (CUPS)..."
    sudo systemctl disable --now cups.service 2>/dev/null || true
    sudo systemctl disable --now cups-browsed.service 2>/dev/null || true
    sudo systemctl mask cups.service 2>/dev/null || true
    sudo systemctl mask cups-browsed.service 2>/dev/null || true
    echo "✓ Printing disabled."

[group('Services')]
enable-tracker:
    #!/usr/bin/env bash
    set -e
    echo "Enabling Tracker file indexing (may increase RAM usage)..."
    sudo systemctl unmask tracker-miner-fs-3.service 2>/dev/null || true
    sudo systemctl unmask tracker-extract-3.service 2>/dev/null || true
    sudo systemctl enable --now tracker-miner-fs-3.service 2>/dev/null || true
    sudo systemctl enable --now tracker-extract-3.service 2>/dev/null || true
    echo "✓ Tracker enabled. Indexing will start in background."

[group('Services')]
disable-tracker:
    #!/usr/bin/env bash
    set -e
    echo "Disabling Tracker file indexing..."
    sudo systemctl disable --now tracker-miner-fs-3.service 2>/dev/null || true
    sudo systemctl disable --now tracker-extract-3.service 2>/dev/null || true
    sudo systemctl mask tracker-miner-fs-3.service 2>/dev/null || true
    sudo systemctl mask tracker-extract-3.service 2>/dev/null || true
    echo "✓ Tracker disabled."

[group('Services')]
enable-avahi:
    #!/usr/bin/env bash
    set -e
    echo "Enabling Avahi (mDNS/Bonjour)..."
    sudo systemctl enable --now avahi-daemon.service
    echo "✓ Avahi enabled."

[group('Services')]
disable-avahi:
    #!/usr/bin/env bash
    set -e
    echo "Disabling Avahi (mDNS/Bonjour)..."
    sudo systemctl disable --now avahi-daemon.service
    echo "✓ Avahi disabled."

[group('Services')]
enable-geoclue:
    #!/usr/bin/env bash
    set -e
    echo "Enabling Geoclue (location services)..."
    sudo systemctl enable --now geoclue.service
    echo "✓ Geoclue enabled."

[group('Services')]
disable-geoclue:
    #!/usr/bin/env bash
    set -e
    echo "Disabling Geoclue (location services)..."
    sudo systemctl disable --now geoclue.service
    echo "✓ Geoclue disabled."

[group('Services')]
enable-modemmanager:
    #!/usr/bin/env bash
    set -e
    echo "Enabling ModemManager (cellular modem support)..."
    sudo systemctl enable --now ModemManager.service
    echo "✓ ModemManager enabled."

[group('Services')]
disable-modemmanager:
    #!/usr/bin/env bash
    set -e
    echo "Disabling ModemManager..."
    sudo systemctl disable --now ModemManager.service
    echo "✓ ModemManager disabled."

[group('Services')]
enable-fprintd:
    #!/usr/bin/env bash
    set -e
    echo "Enabling fprintd (fingerprint reader)..."
    sudo systemctl enable --now fprintd.service
    echo "✓ fprintd enabled."

[group('Services')]
disable-fprintd:
    #!/usr/bin/env bash
    set -e
    echo "Disabling fprintd..."
    sudo systemctl disable --now fprintd.service
    echo "✓ fprintd disabled."

[group('Services')]
list-services:
    #!/usr/bin/env bash
    echo "=== anubis-os optional services ==="
    echo ""
    for svc in bluetooth.service cups.service tracker-miner-fs-3.service avahi-daemon.service geoclue.service ModemManager.service fprintd.service; do
        STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
        ENABLED=$(systemctl is-enabled "$svc" 2>/dev/null || echo "disabled")
        printf "  %-30s  active: %-8s  enabled: %s\n" "$svc" "$STATUS" "$ENABLED"
    done
    echo ""
    echo "Use 'ujust enable-<service>' or 'ujust disable-<service>' to toggle."

# -----------------------------------------------------------------------------
# Cybersecurity toolkit (pentesting — opt-in, runs in a container)
# -----------------------------------------------------------------------------

[group('Security')]
run-aide-check:
    sudo aide --check

[group('Security')]
run-rootkit-scan:
    sudo rkhunter --check --sk

[group('Security')]
update-clamav-db:
    sudo freshclam

[group('Security')]
clamav-scan-home:
    #!/usr/bin/env bash
    echo "Scanning home directory for malware..."
    clamscan -r --infected ~ | tail -5

# -----------------------------------------------------------------------------
# Cybersecurity toolkit (pentesting — opt-in, runs in a container)
# -----------------------------------------------------------------------------

[group('Security')]
install-pentest-tools:
    #!/usr/bin/env bash
    set -e
    echo "Creating a Distrobox container with full pentesting toolkit..."
    echo "This keeps heavy tools (metasploit, hashcat, wireshark, sqlmap, etc.)"
    echo "out of the immutable base image."
    echo ""
    if ! command -v distrobox &>/dev/null; then
        echo "Installing distrobox..."
        sudo rpm-ostree install distrobox
        echo "Reboot required before continuing. Run this command again after reboot."
        exit 0
    fi
    distrobox create --name anubis-pentest --image fedora:latest --yes || true
    # Install packages one at a time so a package that isn't in Fedora's repos
    # (e.g. metasploit) doesn't abort the whole install. Only Fedora-available
    # packages are attempted.
    distrobox enter --name anubis-pentest -- bash -c '
        pkgs="nmap nmap-ncat wireshark-cli tcpdump hashcat john hydra sqlmap nikto gobuster python3-pip git vim"
        for p in $pkgs; do
            sudo dnf install -y "$p" 2>/dev/null && echo "  ✓ $p" || echo "  ⊘ $p skipped (not in Fedora repos)"
        done
        echo "✓ Pentest toolkit (Fedora-available subset) installed in container anubis-pentest"
        echo "  NOTE: metasploit-framework is not in Fedora repos — install it via the distrobox wrapper."
    '
    echo ""
    echo "To enter the pentest environment: distrobox enter anubis-pentest"

# -----------------------------------------------------------------------------
# Hardware enablement
# -----------------------------------------------------------------------------

[group('Hardware')]
install-broadcom-wifi:
    #!/usr/bin/env bash
    set -e
    echo "Installing Broadcom Wi-Fi driver (akmod-wl + kmod-wl + broadcom-wl)..."
    echo "For MacBook Air/Pro 2013-2017 and other Broadcom 43xx devices."
    echo ""
    sudo rpm-ostree install akmod-wl kmod-wl broadcom-wl
    echo ""
    echo "✓ Installed. Reboot required: systemctl reboot"
    echo "After reboot, Wi-Fi should work automatically."

[group('Hardware')]
install-facetimehd-webcam:
    #!/usr/bin/env bash
    set -e
    echo "Installing FaceTime HD webcam driver (MacBook 2013-2017)..."
    echo "Requires COPR repo: dani/facetimehd"
    echo ""
    # Add the COPR repo file to /etc/yum.repos.d/, then install the packages.
    # (rpm-ostree install does NOT accept a repo URL — the .repo file must be
    # dropped into place first.)
    VER=$(rpm -E %fedora)
    sudo curl -fsSL \
      "https://copr.fedorainfracloud.org/coprs/dani/facetimehd/repo/fedora-${VER}/dani-facetimehd-fedora-${VER}.repo" \
      -o "/etc/yum.repos.d/dani-facetimehd-fedora-${VER}.repo"
    sudo rpm-ostree install akmod-facetimehd facetimehd-firmware
    echo ""
    echo "✓ Installed. Reboot required: systemctl reboot"

# -----------------------------------------------------------------------------
# Desktop / personalization
# -----------------------------------------------------------------------------

[group('Desktop')]
reroll-wallpaper:
    #!/usr/bin/env bash
    sudo rm -f /var/lib/anubis-os/.wallpaper-set
    sudo systemctl start anubis-first-boot-wallpaper.service
    echo "New wallpaper applied — log out/in if it doesn't refresh immediately."

[group('Desktop')]
list-extensions:
    gnome-extensions list

[group('Desktop')]
enable-extension:
    #!/usr/bin/env bash
    echo "Installed extensions:"
    gnome-extensions list --enabled
    echo ""
    read -p "Enter extension UUID to enable: " uuid
    gnome-extensions enable "$uuid" && echo "✓ Enabled $uuid"

[group('Desktop')]
disable-extension:
    #!/usr/bin/env bash
    echo "Enabled extensions:"
    gnome-extensions list --enabled
    echo ""
    read -p "Enter extension UUID to disable: " uuid
    gnome-extensions disable "$uuid" && echo "✓ Disabled $uuid"

# -----------------------------------------------------------------------------
# Gaming (opt-in — nothing gaming-related is in the base image)
# -----------------------------------------------------------------------------

[group('Gaming')]
setup-gaming:
    #!/usr/bin/env bash
    set -e
    echo "Installing gaming tools (Steam, ProtonUp-Qt, Heroic) via Flatpak..."
    flatpak install -y flathub com.valvesoftware.Steam
    flatpak install -y flathub net.davidotek.pupgui2
    flatpak install -y flathub com.heroicgameslauncher.hgl
    echo "✓ Gaming tools installed."
    echo ""
    echo "For Steam games that need anti-cheat, you may also need:"
    echo "  ujust enable-gamescope-session"

[group('Gaming')]
enable-gamescope-session:
    #!/usr/bin/env bash
    echo "To use the Gamescope session:"
    echo "  1. Install Steam: ujust setup-gaming"
    echo "  2. Log out"
    echo "  3. At the GDM login screen, click the gear icon"
    echo "  4. Select 'Gamescope Session'"
    echo "  5. Log in — Steam launches in big-picture mode"

# -----------------------------------------------------------------------------
# System maintenance
# -----------------------------------------------------------------------------

[group('System')]
update-all:
    #!/usr/bin/env bash
    set -e
    echo "=== Updating rpm-ostree (system) ==="
    rpm-ostree upgrade
    echo ""
    echo "=== Updating Flatpaks ==="
    flatpak update -y
    echo ""
    echo "=== Updating Homebrew ==="
    if command -v brew &>/dev/null; then
        brew update && brew upgrade
    else
        echo "  (brew not yet set up — run 'brew setup' after first boot)"
    fi
    echo ""
    echo "=== Updating firmware ==="
    fwupdmgr refresh || true
    fwupdmgr update -y || true
    echo ""
    echo "✓ All updates complete. Reboot if kernel/system was updated."

[group('System')]
brew-doctor:
    #!/usr/bin/env bash
    if command -v brew &>/dev/null; then
        brew doctor
    else
        echo "Homebrew not yet set up. It installs on first boot."
        echo "If you're on first boot and it's not ready, run:"
        echo "  /home/linuxbrew/.linuxbrew/bin/brew shellenv >> ~/.bashrc"
    fi

[group('System')]
cleanup-flatpaks:
    #!/usr/bin/env bash
    set -e
    echo "Removing unused Flatpak runtimes (frees disk space)..."
    flatpak uninstall --unused -y
    echo "✓ Done."

[group('System')]
show-system-info:
    @fastfetch

[group('System')]
roll-back:
    #!/usr/bin/env bash
    echo "Recent deployments:"
    rpm-ostree status
    echo ""
    echo "To roll back to the previous deployment:"
    echo "  sudo rpm-ostree rollback"
    echo "  systemctl reboot"
