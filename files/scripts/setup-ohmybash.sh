#!/usr/bin/env bash
set -euo pipefail

# Oh My Bash and Starship cannot be fetched at image build time (no network).
# Instead, we ship a user-setup script that runs on first boot via
# anubis-setup-user.service (enabled by enable-first-boot-units.sh).

# ── User setup script (runs at first boot as the real user) ──────────────
install -Dm755 /dev/stdin \
    /usr/share/anubis-os/scripts/setup-ohmybash-user.sh << 'USERSCRIPT'
#!/usr/bin/env bash
set -euo pipefail

OH_MY_BASH_DIR="$HOME/.oh-my-bash"

if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git \
        "$OH_MY_BASH_DIR"
fi

# Install Starship to ~/.local/bin if not already present
if ! command -v starship &>/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://starship.rs/install.sh | sh -s -- \
        --bin-dir "$HOME/.local/bin" --yes
fi

# Only overwrite .bashrc if not yet customised
if ! grep -q 'oh-my-bash' "$HOME/.bashrc" 2>/dev/null; then
    cp /etc/skel/.bashrc "$HOME/.bashrc"
fi

# Copy starship config if not present
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    mkdir -p "$HOME/.config"
    cp /etc/skel/.config/starship.toml "$HOME/.config/starship.toml"
fi
USERSCRIPT

# ── Default .bashrc placed in /etc/skel for new users ────────────────────
cat > /etc/skel/.bashrc << 'BASHRC'
# Anubis OS — .bashrc

export PATH="$HOME/.local/bin:$PATH"
export OSH="$HOME/.oh-my-bash"

if [[ -f "$OSH/oh-my-bash.sh" ]]; then
    OSH_THEME="font"
    DISABLE_AUTO_UPDATE="true"
    completions=(git)
    aliases=(general)
    plugins=(git)
    source "$OSH/oh-my-bash.sh"
fi

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi
BASHRC

# ── Fastfetch config ──────────────────────────────────────────────────────
mkdir -p /etc/skel/.config/fastfetch
cat > /etc/skel/.config/fastfetch/config.jsonc << 'FFCONF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "/usr/share/pixmaps/anubis-logo.png",
        "type": "kitty",
        "width": 24,
        "height": 12
    },
    "display": {
        "color": {
            "keys": "magenta",
            "title": "magenta"
        }
    },
    "modules": [
        "title", "separator", "os", "host", "kernel", "uptime",
        "shell", "display", "de", "wm", "terminal",
        "cpu", "gpu", "memory", "disk", "battery", "break", "colors"
    ]
}
FFCONF

# ── Starship config ───────────────────────────────────────────────────────
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
format = '[$time] '
time_format = "%H:%M"

[fill]
symbol = ' '

[character]
success_symbol = '[❯](bold color_purple)'
error_symbol = '[❯](bold red)'
STARSHIP
