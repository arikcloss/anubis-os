<div align="center">

<img src="https://github.com/user-attachments/assets/14a4ad1b-5c09-4f65-b186-6b246e2f88e3" width="140" alt="anubis-os logo" />

# AnubisOS

**A clean Fedora. Minimal GNOME, Fedora kernel, nothing you don't need.**

[![build](https://github.com/arikcloss/anubis-os/actions/workflows/build.yml/badge.svg)](https://github.com/arikcloss/anubis-os/actions/workflows/build.yml)
[![iso](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml/badge.svg)](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da?logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Base: Silverblue](https://img.shields.io/badge/Base-Silverblue_Main-3584e4?logo=gnome&logoColor=white)](https://silverblue.fedoraproject.org/)
[![Stars](https://img.shields.io/github/stars/arikcloss/anubis-os?style=social)](https://github.com/arikcloss/anubis-os/stargazers)

</div>

---

## What is this?

anubis-os is an immutable OCI image built on [Universal Blue](https://universal-blue.org/) — the same base as Bazzite, Bluefin, and Aurora. The goal: the cleanest possible system from Fedora. GNOME, yes. But no bloat.

### The philosophy

**Minimal.** A usable GTK4 base (Files, Terminal, Firefox, Htop, Editor, Calculator, Archive Manager, LibreOffice) + GNOME Circle apps via Flatpak + Homebrew and some security tools. No Maps, Weather, Calendar, Music, Photos, Videos, etc.

**Performant.** Fedora kernel + tuned, irqbalance, zram — all preconfigured to run well on old hardware (1st-gen Intel Core), new hardware, and everything in between.

**Stable.** Every script is idempotent, uses `set -euo pipefail` with error traps, and logs every step. The image and ISO share the same recipe — zero drift between what you test in a container and what boots from ISO.

**Harmonious.** The image build and ISO build are separate but chained workflows. The ISO is generated from the already-published image, not from the recipe directly.

---

## Supported hardware

| Hardware | How to enable |
|----------|---------------|
| Generic x86_64 (1st-gen Intel Core → current, all AMD64) | Works out of the box |
| MacBook Air/Pro Intel 2013–2017 (Broadcom Wi-Fi) | `ujust install-broadcom-wifi` then reboot |
| MacBook Air/Pro Intel 2013–2017 (FaceTime HD webcam) | `ujust install-facetimehd-webcam` then reboot |
| Other laptops with Broadcom 43xx | `ujust install-broadcom-wifi` then reboot |

---

## What's included

### GUI apps (base GTK4, installed via RPM — work offline)

These are baked into the system image. They're there on first boot, no internet needed.

| App | What it does |
|-----|--------------|
| **Nautilus** | File manager (GNOME Files) |
| **Blackbox Terminal** | Terminal emulator |
| **Firefox** | Web browser |
| **Htop** | Process monitor |
| **GNOME Text Editor** | Text editor (GTK4) |
| **GNOME Console** | GNOME's terminal (kgx) |
| **GNOME Calculator** | Calculator |
| **File Roller** | Archive manager |
| **LibreOffice** | Office suite |

### GNOME Circle / productivity (Flatpak, installed on first boot)

These don't have RPMs in Fedora, so they're managed via `flatpak preinstall` (declared in `/usr/share/flatpak/preinstall.d/`): **Mission Center**, **Gradio**, **Wike**, **Bazaar** (Flatpak manager), **Amberol**, **Obsidian**, **VSCodium**, **Eyedropper**, **Fragments**, **Iotas**. They show up automatically after first boot once you have network.

> **Technical note:** In an immutable OSTree image, `/var/lib/flatpak` isn't committed to the image, so Flatpaks can't be 100% embedded offline. The `anubis-flatpak-preinstall` service installs them automatically on first boot — no manual step needed. What needs to be instant/offline stays in RPM.

### Kernel & Performance

| Component | What it does |
|-----------|--------------|
| **Fedora Kernel** | Stable Fedora kernel (no third-party patches) |
| **tuned + tuned-ppd** | Adaptive performance/battery profiles (integrated into GNOME power settings) |
| **irqbalance** | Distributes IRQs across CPUs for lower latency |
| **zram-generator** | Compressed swap in RAM — biggest performance win for 2-8 GB systems |
| **gamemode** | CPU/governor optimization on demand |

### Security tools

A lean set of defensive and network analysis tools, direct in RPM:

```
nmap  nmap-ncat  tcpdump  whois  traceroute  net-tools  bind-utils
firewalld  firejail  clamav  rkhunter  aide
git  vim  curl  wget  python3  python3-pip
```

For heavy pentesting tools (metasploit, hashcat, wireshark, hydra, sqlmap, etc.):

```bash
ujust install-pentest-tools
```

This creates a Distrobox container with the full toolkit — the immutable base stays clean.

### Terminal & Shell

- **Oh My Bash** — installed on first boot (via systemd service)
- **Starship** — custom prompt, installed on first boot
- **fastfetch** — system info when you open terminal (with Anubis ASCII art)
- **Homebrew** — user-space package manager that doesn't touch the OSTree

---

## Installation

### Rebase from any Universal Blue or Silverblue system

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/arikcloss/anubis-os:latest
```

Reboot after. On next boot, the system runs first-use setup (Oh My Bash, Starship, fastfetch config, wallpaper).

### Broadcom Wi-Fi hardware (MacBook 2013-2017, some Dell/HP)

```bash
ujust install-broadcom-wifi
systemctl reboot
```

### FaceTime HD Webcam (MacBook 2013-2017)

```bash
ujust install-facetimehd-webcam
systemctl reboot
```

### Install via ISO

Download the ISO from the [Actions page](https://github.com/arikcloss/anubis-os/actions/workflows/iso.yml) (artifact `iso-anubis-os`), flash to USB with `dd` or Ventoy, and boot.

The ISO installs the exact same ostree image that `rebase` would pull — zero drift.

### Verify image signature

```bash
cosign verify ghcr.io/arikcloss/anubis-os \
  --certificate-identity-regexp=https://github.com/arikcloss \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

---

## Repository structure

```
anubis-os/
├── recipes/
│   └── recipe.yml                 # single image (Fedora 44 + minimal GNOME)
├── files/
│   ├── scripts/                   # build-time scripts (run by BlueBuild)
│   │   ├── 00-debloat-gnome.sh    # removes default GNOME apps (Calendar, Maps, etc.)
│   │   ├── setup-os-release.sh    # branding: /etc/os-release → "Anubis OS"
│   │   ├── setup-hostname.sh      # hostname → "anubis"
│   │   ├── setup-logo.sh          # replaces Fedora logos with Anubis logo
│   │   ├── setup-plymouth.sh      # boot splash theme + initramfs rebuild
│   │   ├── setup-wallpaper.sh     # removes stock wallpapers, installs Anubis collection
│   │   ├── enable-gnome-extensions-defaults.sh  # dconf profile + compiles DB
│   │   ├── setup-ohmybash.sh      # .bashrc skeleton + first-boot script
│   │   ├── set-permissions.sh     # ensures correct permissions on all files
│   │   └── enable-first-boot-units.sh  # enables first-boot services
│   └── system/                    # static files copied to / in the image
│       ├── etc/
│       │   ├── dconf/db/local.d/  # GNOME defaults (extensions, wallpaper, GDM logo)
│       │   ├── sysctl.d/          # kernel hardening
│       │   ├── profile.d/         # fastfetch alias
│       │   ├── systemd/           # zram-generator config
│       │   └── tuned/             # active tuned profile
│       └── usr/
│           ├── lib/systemd/system/   # first-boot units (5 services)
│           ├── lib/anubis-os/        # first-boot scripts
│           ├── share/backgrounds/    # Anubis wallpapers
│           ├── share/flatpak/preinstall.d/  # GNOME Circle apps (flatpak preinstall)
│           ├── share/fastfetch/      # config + ASCII art
│           ├── share/pixmaps/        # logos
│           ├── share/icons/          # hicolor icons
│           ├── share/ublue-os/just/  # custom ujust commands
│           └── share/applications/   # "Update System" .desktop
├── .github/workflows/
│   ├── build.yml                 # builds image → GHCR
│   └── iso.yml                   # generates ISO from published image
├── cosign.pub                    # public key for signature verification
└── README.md
```

---

## ujust commands

anubis-os includes custom commands via `ujust`:

```bash
# Performance
ujust detect-cpu                 # identifies CPU
ujust set-tuned-profile          # switches performance profile

# Security
ujust enable-hardened-profile    # aggressive hardening (mitigations, nosmt, etc.)
ujust run-aide-check             # checks file integrity
ujust run-rootkit-scan           # scans for rootkits
ujust install-pentest-tools      # pentesting toolkit in Distrobox container

# Desktop
ujust reroll-wallpaper           # changes wallpaper randomly
ujust list-extensions            # lists GNOME extensions

# Gaming (opt-in — nothing gaming in base image)
ujust setup-gaming               # installs Steam + ProtonUp-Qt + Heroic via Flatpak

# System
ujust update-all                 # updates everything (rpm-ostree + flatpak + brew + fwupd)
ujust cleanup-flatpaks           # removes unused runtimes
ujust roll-back                  # shows deployments + how to rollback
ujust show-system-info           # runs fastfetch
```

---

## Local build

```bash
# Install BlueBuild CLI
brew install blue-build/tap/bluebuild
# or
cargo install blue-build

# Build the image
bluebuild build recipes/recipe.yml

# Generate ISO from published image
bluebuild generate-iso --output-dir iso-out \
  image ghcr.io/arikcloss/anubis-os:44
```

---

## Customization

### Add packages to base system

Edit `recipe.yml` and rebuild via GitHub Actions or locally.

### Install something once without rebuild

```bash
# Persistent in base system (use sparingly)
rpm-ostree install <package>

# Via Homebrew (no sudo, doesn't touch OS)
brew install <package>

# Via Flatpak (sandboxed apps)
flatpak install flathub <app-id>
```

---

## Stability architecture

Every script in `files/scripts/` follows these rules:

1. **`set -euo pipefail`** — fails on any error, undefined variable, or broken pipe.
2. **`trap '... ERR'`** — logs the exact line where the script failed.
3. **Idempotent** — safe to run on every build. Uses `cp -n`, `grep -q || echo`, `|| true` for non-critical operations.
4. **Prerequisite checks** — verifies files/directories exist before operating.
5. **Logging** — each step prints what it's doing with prefix `[script-name]`.
6. **Non-fatal warnings** — non-critical operations fail with warning, don't break the build.

The GNOME debloat (`00-debloat-gnome.sh`) is especially robust: it filters to only installed packages and removes them one by one, so it survives package renames between Fedora versions.

---

## Contributing

Issues and PRs welcome. Found a Flatpak with wrong ID, a script breaking the build, or an extension with outdated UUID — open an issue.

---

<div align="center">

Made with [Universal Blue](https://universal-blue.org/) · Based on [Fedora Silverblue](https://silverblue.fedoraproject.org/)

</div>
