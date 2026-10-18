#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Run on the phone over SSH: (re)start the panel as a transient systemd user
# unit, so it survives the SSH session closing.
export XDG_RUNTIME_DIR=/run/user/$(id -u)
# Stop the autostarted copy too: a second launch only re-activates it.
# gnome-session runs it in a scope named after its PID.
systemctl --user stop og-home-panel \
    'app-gnome-com.antzcode.og_home_panel-*.scope' \
    app-com.antzcode.og_home_panel@autostart.service 2>/dev/null
systemctl --user reset-failed og-home-panel 2>/dev/null
systemd-run --user --unit=og-home-panel -E WAYLAND_DISPLAY=wayland-0 \
    "$HOME/.local/bin/og-home-panel"
