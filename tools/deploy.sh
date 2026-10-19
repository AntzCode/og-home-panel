#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Install the panel, with its autostart entry, and (re)start it: on a phone
# over SSH, or on the phone this runs on.
# Usage: tools/deploy.sh [user@host]   (default user@172.16.42.1)
#        tools/deploy.sh --local       (on the phone itself)
set -e
cd "$(dirname "$0")/.."
desktop=com.antzcode.og_home_panel.desktop
# The autostart generator looks up Exec= without ~/.local/bin, so the entry
# gets an absolute Exec=.

if [ "$1" = "--local" ]; then
    packages="gtk4-layer-shell wtype"
    if command -v apk >/dev/null; then
        missing=
        for package in $packages; do
            apk info -e "$package" >/dev/null || missing="$missing $package"
        done
        if [ -n "$missing" ]; then
            echo "Installing$missing (sudo asks for your password)"
            sudo apk add $missing
        fi
    else
        echo "Not Alpine/postmarketOS: make sure these are installed:" \
             "$packages, PyGObject, GTK 4, libadwaita, libatspi, libfeedback"
    fi
    mkdir -p ~/.local/bin ~/.config/autostart
    install -m 755 og-home-panel tools/dev-restart.sh ~/.local/bin/
    sed "s|^Exec=.*|Exec=$HOME/.local/bin/og-home-panel|" data/$desktop \
        > ~/.config/autostart/$desktop
    ~/.local/bin/dev-restart.sh
    echo "og-home-panel is installed and running. It starts at every login."
    exit
fi

host=${1:-user@172.16.42.1}
ssh "$host" 'mkdir -p ~/.local/bin ~/.config/autostart'
scp -q og-home-panel tools/dev-restart.sh "$host":.local/bin/
ssh "$host" "sed \"s|^Exec=.*|Exec=\$HOME/.local/bin/og-home-panel|\" \
    > ~/.config/autostart/$desktop" < data/$desktop
ssh "$host" '~/.local/bin/dev-restart.sh'
