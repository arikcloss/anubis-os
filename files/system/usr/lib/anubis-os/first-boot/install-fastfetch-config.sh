#!/usr/bin/env bash
# /usr/lib/anubis-os/first-boot/install-fastfetch-config.sh
#
# /etc/skel/.config/fastfetch/config.jsonc only applies to user accounts
# created AFTER this image is built (i.e. on `useradd`). Anyone rebasing
# an existing system onto anubis-os already has a home directory, so skel
# never reaches them. This script copies the branded config into every
# real user's home on first boot, but only if they don't already have a
# fastfetch config of their own — we never want to silently overwrite a
# file a user has customized.
#
# Idempotent: safe to run on every boot. Triggered once via the
# anubis-fastfetch-firstboot.service unit (ConditionFirstBoot=yes), but
# written defensively in case that condition is ever removed.

set -euo pipefail

SRC="/usr/share/fastfetch/anubis-config.jsonc"

if [[ ! -f "$SRC" ]]; then
    echo "anubis-os: $SRC not found, skipping fastfetch first-boot setup" >&2
    exit 0
fi

# Iterate over real (human) accounts: UID >= 1000, with a valid home dir,
# excluding system/service accounts like nobody.
while IFS=: read -r _user _pass uid _gid _gecos home _shell; do
    if (( uid < 1000 )) || [[ ! -d "$home" ]]; then
        continue
    fi

    dest_dir="$home/.config/fastfetch"
    dest_file="$dest_dir/config.jsonc"

    if [[ -e "$dest_file" ]]; then
        # User already has a config (from skel on a fresh account, or their
        # own customization) — leave it alone.
        continue
    fi

    mkdir -p "$dest_dir"
    cp "$SRC" "$dest_file"

    # Match ownership to the home directory so the user (not root) owns it.
    owner=$(stat -c '%u:%g' "$home")
    chown "$owner" "$dest_dir" "$dest_file"

done < /etc/passwd

exit 0
