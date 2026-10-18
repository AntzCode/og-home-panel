#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copy the panel to a phone over SSH, install its autostart entry and
# restart it.
# Usage: tools/deploy.sh [user@host]   (default user@172.16.42.1)
set -e
host=${1:-user@172.16.42.1}
cd "$(dirname "$0")/.."
ssh "$host" 'mkdir -p ~/.local/bin ~/.config/autostart'
scp -q og-home-panel tools/dev-restart.sh "$host":.local/bin/
# The autostart generator looks up Exec= without ~/.local/bin, so make it
# absolute.
desktop=com.antzcode.og_home_panel.desktop
ssh "$host" "sed 's|^Exec=.*|Exec='\"\$HOME\"'/.local/bin/og-home-panel|' \
    > ~/.config/autostart/$desktop" < data/$desktop
ssh "$host" '~/.local/bin/dev-restart.sh'
