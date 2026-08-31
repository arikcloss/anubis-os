# /etc/profile.d/anubis-fastfetch.sh
# Anubis Linux: alias `ff` and `fastfetch` to use the branded Anubis config.
# Falls back gracefully if fastfetch isn't installed (e.g. during early
# bootstrap stages) so this never breaks login shells.
#
# Coverage: on Fedora, /etc/profile sources /etc/profile.d/*.sh for login
# shells, and /etc/bashrc (sourced by the default ~/.bashrc from skel) also
# sources /etc/profile.d/*.sh for interactive non-login bash shells. That
# covers both cases for bash out of the box.
#
# zsh does NOT source /etc/profile.d by default, so users on zsh won't get
# this alias from here. If zsh support is added later, add the same two
# alias lines directly to /etc/zshrc (or a zsh-specific snippet sourced by
# it) rather than relying on this file.

if command -v fastfetch >/dev/null 2>&1; then
    alias ff='fastfetch --config /usr/share/fastfetch/anubis-config.jsonc'
    alias fastfetch='fastfetch --config /usr/share/fastfetch/anubis-config.jsonc'
fi
