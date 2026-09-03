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
    @echo ""
    @echo "anubis-os ships the GENERIC CachyOS kernel for broad compatibility."
    @echo "CPU-tuned variants are available if you need maximum performance:"
    @echo "  ujust switch-kernel-znver3   (AMD Zen 3: Ryzen 5000, EPYC Milan)"
    @echo "  ujust switch-kernel-znver4   (AMD Zen 4: Ryzen 7000, EPYC Genoa)"
    @echo "  ujust switch-kernel-generic  (revert to generic, default)"

# CPU-tuned CachyOS kernels. These override the generic kernel with one
# compiled with -march=znver3/znver4 for the target microarchitecture.
# Only switch if your CPU matches — a wrong march = illegal instruction crash.

[group('Performance')]
switch-kernel-znver3:
    #!/usr/bin/env bash
    set -e
    echo "Switching to CachyOS kernel optimized for AMD Zen 3..."
    sudo rpm-ostree override remove kernel-cachyos kernel-cachyos-devel 2>/dev/null || true
    sudo rpm-ostree install kernel-cachyos-znver3 kernel-cachyos-znver3-devel
    echo "✓ Done. Reboot required: systemctl reboot"

[group('Performance')]
switch-kernel-znver4:
    #!/usr/bin/env bash
    set -e
    echo "Switching to CachyOS kernel optimized for AMD Zen 4..."
    sudo rpm-ostree override remove kernel-cachyos kernel-cachyos-devel 2>/dev/null || true
    sudo rpm-ostree install kernel-cachyos-znver4 kernel-cachyos-znver4-devel
    echo "✓ Done. Reboot required: systemctl reboot"

[group('Performance')]
switch-kernel-generic:
    #!/usr/bin/env bash
    set -e
    echo "Switching back to generic CachyOS kernel..."
    sudo rpm-ostree override remove \
        kernel-cachyos-znver3 kernel-cachyos-znver3-devel \
        kernel-cachyos-znver4 kernel-cachyos-znver4-devel 2>/dev/null || true
    sudo rpm-ostree install kernel-cachyos kernel-cachyos-devel
    echo "✓ Done. Reboot required: systemctl reboot"

[group('Performance')]
enable-scx-scheduler:
    #!/usr/bin/env bash
    set -e
    echo "Enabling sched-ext scheduler (scx_bpfland)..."
    echo "This replaces the CFS scheduler with a BPF-based one that improves"
    echo "desktop responsiveness under load."
    sudo systemctl enable --now scx_bpfland 2>/dev/null || \
        sudo systemctl enable --now scx_lavd 2>/dev/null || \
        echo "No scx scheduler available — install scx-scheds first"
    echo "✓ Enabled. Disable with: ujust disable-scx-scheduler"

[group('Performance')]
disable-scx-scheduler:
    #!/usr/bin/env bash
    set -e
    echo "Disabling sched-ext scheduler (reverting to CFS)..."
    sudo systemctl disable --now scx_bpfland scx_lavd 2>/dev/null || true
    echo "✓ Disabled. Reboot for full effect."

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
    echo "  • OpenSnitch application firewall"
    echo "  • ClamAV + freshclam"
    echo "  • AIDE file integrity baseline"
    echo "  • firewalld"
    echo ""
    sudo rpm-ostree kargs --append=mitigations=auto,nosmt
    sudo systemctl enable --now opensnitch
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
    distrobox enter --name anubis-pentest -- bash -c '
        sudo dnf install -y \
            nmap nmap-ncat wireshark tcpdump \
            metasploit-framework hashcat john \
            hydra sqlmap nikto gobuster \
            dirb dirbuster ffuf \
            python3-pip git vim \
            && echo "✓ Pentest toolkit installed in container anubis-pentest"
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
    sudo rpm-ostree install \
      https://copr.fedorainfracloud.org/coprs/dani/facetimehd/repo/fedora-$(rpm -E %fedora)/dani-facetimehd-fedora-$(rpm -E %fedora).repo
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
