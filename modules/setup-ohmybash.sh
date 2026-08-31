#!/usr/bin/env bash
set -euo pipefail

# Instala Oh My Bash globalmente em /usr/share/oh-my-bash
# e configura .bashrc padrão no /etc/skel para novos usuários

OH_MY_BASH_DIR=/usr/share/oh-my-bash

if [[ ! -d "$OH_MY_BASH_DIR" ]]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git \
        "$OH_MY_BASH_DIR"
fi

# .bashrc padrão para novos usuários
cat > /etc/skel/.bashrc << 'BASHRC'
# Anubis OS — .bashrc padrão
export OSH=/usr/share/oh-my-bash
OSH_THEME="font"
DISABLE_AUTO_UPDATE="true"
completions=(git)
aliases=(general)
plugins=(git)
source "$OSH/oh-my-bash.sh"

# Starship prompt (sobrepõe o tema do OMB se instalado)
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Fastfetch ao abrir terminal
if command -v fastfetch &>/dev/null; then
    fastfetch
fi
BASHRC

# Fastfetch config padrão
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
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "shell",
        "display",
        "de",
        "wm",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "battery",
        "break",
        "colors"
    ]
}
FFCONF

# Starship config padrão
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/starship.toml << 'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[░▒▓](color_orange)\
[ 🐺 $os ](bg:color_orange fg:color_fg0)\
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
format = '[$time]($style) '
time_format = "%H:%M"
style = "bold yellow"

[fill]
symbol = ' '

[character]
success_symbol = '[❯](bold color_purple)'
error_symbol = '[❯](bold red)'
STARSHIP
