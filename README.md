# OG Home Panel

The missing piece that makes a Linux phone feel like home: Android-style **Back**, an **app switcher** and **quick actions** (copy, paste, undo…) in a bar at the bottom of the screen.

Status: early development. It runs on Phosh. Plasma Mobile, wlroots shells (Sway/Sxmo) and GNOME Shell are planned.

- Author: [AntzCode](https://github.com/AntzCode)
- Repository: <https://github.com/AntzCode/og-home-panel>
- Issues and feature requests: <https://github.com/AntzCode/og-home-panel/issues>

## Buttons

| Button | Tap | Long press |
|---|---|---|
| Back | Presses the app's own Back button. If there is none, the app goes to the background and the overview opens | Escape |
| Apps | Opens the app overview, with the keyboard closed | Shows the running apps, like Alt+Tab: tap one to switch to it. The most recently used is nearest the bar. Tap the space above the list, Back or Apps to close it. With no apps running, it opens the app overview instead |
| Keyboard | Shows or hides the on-screen keyboard | |
| ⋯ | Shows a row of quick actions: undo, redo, cut, copy, paste, select word, select all | Opens or closes the panel menu. Opening it closes the quick-actions row |
| Rotate | Appears in place of ⋯ for 4 seconds when you turn the phone while screen rotation is locked. Tap it to rotate the screen to match. In fullscreen, where the bar is hidden, it floats on its own in the bottom-right corner, as you're holding the phone | |

The panel menu has:

- **Fit *app* to the screen**: for an app whose window is too big for the screen, turns on Phosh's scale-to-fit for the app you're in, which shrinks the window until all of it shows. Once it's on, the item turns it off again (*Stop fitting…*).
- **About OG Home Panel**

Every button gives a short haptic tick (via feedbackd) as you touch it.

Long-press select all to deselect (in text fields; a whole web page can only be deselected by tapping it).

The quick-actions row sits above the bar and overlaps the app (and the on-screen keyboard's bottom row), so nothing resizes or jumps when it opens or closes.

The panel hides itself on the lock screen, while the quick-settings drawer is pulled down, and while the focused app is fullscreen.

## How Back works

Wayland has no API that tells you whether an app has back history. og-home-panel reads the focused window's accessibility tree (AT-SPI) instead:

1. If the Phosh overview is open, close it.
2. If the focused window is a dialog, send Escape.
3. If the window has an enabled, visible button named "Back" or "Go back", press it. For apps where a direct AT-SPI press is slow (Firefox), send Alt+Left instead.
4. Otherwise open the overview, leaving the app running in the background.

## Requirements (Phosh)

- Python 3 with PyGObject, GTK 4, libadwaita, libatspi and libfeedback (Lfb) typelibs
- [gtk4-layer-shell](https://github.com/wmww/gtk4-layer-shell)
- [wtype](https://github.com/atx/wtype)

On postmarketOS / Nura:

```sh
sudo apk add gtk4-layer-shell wtype
```

## Install (manual, for now)

```sh
mkdir -p ~/.local/bin ~/.config/autostart
cp og-home-panel ~/.local/bin/
# Autostart doesn't search ~/.local/bin, so give Exec= the full path.
sed "s|^Exec=.*|Exec=$HOME/.local/bin/og-home-panel|" \
    data/com.antzcode.og_home_panel.desktop \
    > ~/.config/autostart/com.antzcode.og_home_panel.desktop
```

## Development

Deploy to a phone over USB networking and restart the panel:

```sh
tools/deploy.sh                 # default user@172.16.42.1
```

To choose icons: open About and tap its icon 10 times. A browser of every symbolic icon in the installed theme opens; tap one to see its name.

On the phone it runs as the transient systemd user unit `og-home-panel`. Logs: `journalctl --user -u og-home-panel`.

## License

Copyright 2026 AntzCode.

og-home-panel is free software, licensed under the GNU General Public License, version 3 or later (GPL-3.0-or-later). See [LICENSE](LICENSE).
