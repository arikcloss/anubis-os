#!/usr/bin/env bash
# =============================================================================
# setup-ohmybash.sh
# =============================================================================
# Prepares the terminal/shell experience for anubis-os users:
#   1. Creates a first-boot user setup script that installs Oh My Bash and
#      Starship into each user's home directory (can't be done at build time
#      because it needs network + a real user account).
#   2. Writes the default .bashrc to /etc/skel (used for new user accounts).
#   3. Copies the system fastfetch config to /etc/skel (so new users get the
#      same branded config as the system-level one — single source of truth).
#   4. Writes the Starship prompt config to /etc/skel.
#
# The first-boot script is triggered by anubis-setup-user.service (enabled by
# enable-first-boot-units.sh). For existing users rebasing onto anubis-os,
# the service runs on first boot and installs Oh My Bash + Starship into
# their existing home directory.
#
# IDEMPOTENT: safe to run on every build. Uses cp -n (no-clobber) for user
# files so existing customizations are never overwritten.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-ohmybash] FAILED at line $LINENO" >&2' ERR

echo "[setup-ohmybash] Preparing terminal/shell skeleton..."

# =============================================================================
# 1. First-boot user setup script
#    Runs as the real user (not root) to clone Oh My Bash and install
#    Starship into their home directory. Idempotent: skips if already done.
# =============================================================================
install -Dm755 /dev/stdin \
    /usr/share/anubis-os/scripts/setup-ohmybash-user.sh << 'USERSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "[anubis-setup-user] Setting up Oh My Bash and Starship..."

# --- Oh My Bash ---
OH_MY_BASH_DIR="$HOME/.oh-my-bash"
if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git \
        "$OH_MY_BASH_DIR"
    echo "  Cloned Oh My Bash to $OH_MY_BASH_DIR"
else
    echo "  Oh My Bash already present, skipping clone"
fi

# --- Starship prompt ---
if ! command -v starship &>/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
    mkdir -p "$HOME/.local/bin"
    # Download and install Starship to ~/.local/bin (no sudo needed)
    if curl -fsSL https://starship.rs/install.sh | sh -s -- \
        --bin-dir "$HOME/.local/bin" --yes; then
        echo "  Installed Starship to ~/.local/bin/starship"
    else
        echo "  WARNING: Starship install failed — user can install later via 'brew install starship'" >&2
    fi
else
    echo "  Starship already installed, skipping"
fi

# --- .bashrc (only if not yet customised by the user) ---
if ! grep -q 'oh-my-bash' "$HOME/.bashrc" 2>/dev/null; then
    cp /etc/skel/.bashrc "$HOME/.bashrc"
    echo "  Copied default .bashrc from skel"
else
    echo "  .bashrc already customised, leaving as-is"
fi

# --- Starship config (only if user doesn't have one) ---
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    mkdir -p "$HOME/.config"
    cp /etc/skel/.config/starship.toml "$HOME/.config/starship.toml"
    echo "  Copied Starship config from skel"
fi

echo "[anubis-setup-user] Done."
USERSCRIPT

echo "  Created /usr/share/anubis-os/scripts/setup-ohmybash-user.sh"

# =============================================================================
# 2. Default .bashrc for new users (/etc/skel)
# =============================================================================
cat > /etc/skel/.bashrc << 'BASHRC'
# Anubis OS — default .bashrc
# Sourced by bash for interactive shells. Also copied to existing users'
# homes on first boot by anubis-setup-user.service (only if they don't
# already have a customised .bashrc).

# --- PATH: include user-local bin (where Starship gets installed) ---
export PATH="$HOME/.local/bin:$PATH"

# --- Oh My Bash ---
export OSH="$HOME/.oh-my-bash"
if [[ -f "$OSH/oh-my-bash.sh" ]]; then
    OSH_THEME="font"
    DISABLE_AUTO_UPDATE="true"
    completions=(git)
    aliases=(general)
    plugins=(git)
    source "$OSH/oh-my-bash.sh"
fi

# --- Starship prompt (overrides Oh My Bash theme if installed) ---
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# --- Fastfetch on terminal open (interactive shells only) ---
if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi
BASHRC

echo "  Wrote /etc/skel/.bashrc"

# =============================================================================
# 3. Fastfetch config for new users — copy the SYSTEM config
#    The system config at /usr/share/fastfetch/anubis-config.jsonc is the
#    single source of truth (branded ASCII art, privacy-conscious module list).
#    We copy it to skel so new users get the same config. Existing users
#    (rebase scenario) get it via anubis-fastfetch-firstboot.service.
# =============================================================================
SYSTEM_FF_CONFIG=/usr/share/fastfetch/anubis-config.jsonc
SKEL_FF_DIR=/etc/skel/.config/fastfetch
mkdir -p "$SKEL_FF_DIR"

if [[ -f "$SYSTEM_FF_CONFIG" ]]; then
    cp "$SYSTEM_FF_CONFIG" "$SKEL_FF_DIR/config.jsonc"
    echo "  Copied system fastfetch config to skel"
else
    echo "  WARNING: $SYSTEM_FF_CONFIG not found — skel fastfetch config not set" >&2
fi

# =============================================================================
# 4. Starship prompt config for new users
# =============================================================================
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/starship.toml << 'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[░▒▓](color_orange)\
[ $os ](bg:color_orange fg:color_fg0)\
[](bg:color_yellow fg:color_orange)\
[ $directory ](bg:color_yellow fg:color_fg0)\
[](fg:color_yellow bg:color_aqua)\
[ $git_branch$git_status ](bg:color_aqua fg:color_fg0)\
[](fg:color_aqua)\
$fill\
$cmd_duration\
[ $time ](fg:color_purple)\
\n$character"""

palette = 'anubis'

[palettes.anubis]
color_fg0 = '#1a0a2e'
color_orange = '#8b5cf6'
color_yellow = '#6d28d9'
color_aqua = '#4c1d95'
color_purple = '#a78bfa'

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[directory]
style = "fg:color_fg0 bg:color_yellow"
truncation_length = 3

[git_branch]
symbol = " "
style = "bg:color_aqua fg:color_fg0"

[git_status]
style = "bg:color_aqua fg:color_fg0"

[time]
disabled = false
format = 'at [$time]($style)'
time_format = "%H:%M"
style = "fg:color_purple"

[fill]
symbol = ' '

[character]
success_symbol = '[❯](bold color_purple)'
error_symbol = '[❯](bold red)'
STARSHIP

echo "  Wrote /etc/skel/.config/starship.toml"

echo "[setup-ohmybash] Done."
