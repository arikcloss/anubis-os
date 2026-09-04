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
#    Runs as the real user (not root) to clone Oh My Bash and set up configs.
#    Starship is now pre-installed in the base image (RPM).
#    Idempotent: skips if already done.
# =============================================================================
install -Dm755 /dev/stdin \
    /usr/share/anubis-os/scripts/setup-ohmybash-user.sh << 'USERSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "[anubis-setup-user] Setting up Oh My Bash and configs..."

# --- Oh My Bash ---
OH_MY_BASH_DIR="$HOME/.oh-my-bash"
if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git \
        "$OH_MY_BASH_DIR"
    echo "  Cloned Oh My Bash to $OH_MY_BASH_DIR"
else
    echo "  Oh My Bash already present, skipping clone"
fi

# --- Starship prompt (pre-installed via RPM) ---
if command -v starship &>/dev/null; then
    echo "  Starship found at $(command -v starship)"
else
    echo "  WARNING: Starship not found in PATH — should be pre-installed" >&2
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

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

# --- PATH: include user-local bin (where Starship gets installed) ---
export PATH="$HOME/.local/bin:$PATH"

# --- History settings (Ubuntu/Fedora style) ---
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# --- Window size check ---
shopt -s checkwinsize

# --- Make less more friendly for non-text input files ---
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# --- Color support for ls, grep, etc. ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- Useful aliases ---
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# --- Oh My Bash (optional, theme overridden by Starship) ---
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
[┌─](fg:#8b5cf6)\
[ $os ](fg:#8b5cf6 bold)\
[ $directory ](fg:#a78bfa)\
[ $git_branch$git_status ](fg:#d8b4fe)\
$fill\
[ $time ](fg:#6d28d9)\
\n[└─$ ](fg:#8b5cf6 bold)"""

[palettes.anubis]
color_fg0 = '#1a0a2e'
color_purple = '#8b5cf6'
color_lavender = '#a78bfa'
color_deep_purple = '#6d28d9'
color_light_purple = '#d8b4fe'

[os]
disabled = false
format = '[ $symbol ](fg:#8b5cf6 bold)'
symbol = '󰣇'

[directory]
style = "fg:#a78bfa"
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = " "
style = "fg:#d8b4fe"

[git_status]
style = "fg:#f87171"
conflicted = "="
ahead = "↑"
behind = "↓"
diverged = "↕"
untracked = "?"
stashed = "$"
modified = "!"
deleted = "×"

[time]
disabled = false
format = ' [ $time ](fg:#6d28d9)'
time_format = "%H:%M"
style = "fg:#6d28d9"

[cmd_duration]
disabled = false
min_time = 2000
format = ' [ took $duration ](fg:#6d28d9)'

[character]
success_symbol = '[❯](fg:#8b5cf6 bold)'
error_symbol = '[❯](fg:#ef4444 bold)'
vicmd_symbol = '[❮](fg:#f59e0b bold)'

[fill]
symbol = " "

[username]
style_user = "fg:#8b5cf6 bold"
style_root = "fg:#ef4444 bold"
format = '[$user](fg:#a78bfa)@'
disabled = false

[hostname]
ssh_only = true
format = '[$hostname](fg:#a78bfa) '
disabled = false
STARSHIP

echo "  Wrote /etc/skel/.config/starship.toml"

echo "[setup-ohmybash] Done."
