# OG Home Panel

This was the missing piece and now I feel at home again. Linux phones have no system-wide Back button, no quick way to jump between apps, and no easy copy and paste. OG Home Panel puts the buttons you're used to into a bar at the bottom of the screen, and they work in every app.

- **Back that knows the app.** It presses the app's own Back button, closes dialogs, and sends the app to the background when there's nowhere left to go back to.
- **App switcher.** Long-press Apps for your running apps, most recent first, like Alt+Tab.
- **Quick actions for text.** Undo, redo, cut, copy, paste, select word and select all, one tap away, without hunting through on-screen keyboard layouts.
- **Keyboard button.** Show or hide the on-screen keyboard whenever you need it.
- **Rotate on request.** With rotation locked, turn the phone and a rotate button appears for a few seconds, as on Android, even over a fullscreen video.
- **Fit to the screen.** One tap shrinks an app that's too big for the phone's screen until all of it shows.
- **Out of the way when it should be.** It hides on the lock screen, under the quick settings, in fullscreen, and in any app you choose, such as the camera.
- **Feels like a button.** A haptic tick on every touch, and nothing on screen jumps around when the quick actions open.

Status: early development, but in daily use on Phosh. Plasma Mobile, wlroots shells (Sway/Sxmo) and GNOME Shell are planned.

- Author: [AntzCode](https://github.com/AntzCode)
- Repository: <https://github.com/AntzCode/og-home-panel>
- Issues and feature requests: <https://github.com/AntzCode/og-home-panel/issues>

## Install

On the phone, open a terminal and run:

```sh
cd /tmp && wget -O og-home-panel.zip https://github.com/AntzCode/og-home-panel/archive/refs/heads/main.zip && unzip -o og-home-panel.zip && sh og-home-panel-main/tools/deploy.sh --local
```

It downloads the latest version, installs what it needs (on postmarketOS, `gtk4-layer-shell` and `wtype`, which asks for your password), and starts the panel. From then on it starts by itself at every login. Run the same line again to update.

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
- **Hide the buttons in *app***: hides the panel whenever that app is in front, for apps that need the whole screen, such as a camera. The floating rotate button still appears there.
- **Settings**: lists the apps the panel hides in, each with a button to show the panel there again.
- **About OG Home Panel**

Every button gives a short haptic tick (via feedbackd) as you touch it.

Long-press select all to deselect (in text fields; a whole web page can only be deselected by tapping it).

The quick-actions row sits above the bar and overlaps the app (and the on-screen keyboard's bottom row), so nothing resizes or jumps when it opens or closes.

The panel hides itself on the lock screen, while the quick-settings drawer is pulled down, while the focused app is fullscreen, and in the apps you've hidden it in. Settings are saved in `~/.config/og-home-panel/settings.json`.

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

On postmarketOS / Nura, the install line adds what's missing. By hand:

```sh
sudo apk add gtk4-layer-shell wtype
```

## Install by hand

From a copy of this repository:

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
tools/deploy.sh --local         # on the phone itself (what the install line runs)
```

To choose icons: open About and tap its icon 10 times. A browser of every symbolic icon in the installed theme opens; tap one to see its name.

On the phone it runs as the transient systemd user unit `og-home-panel`. Logs: `journalctl --user -u og-home-panel`.

## License

Copyright 2026 AntzCode.

og-home-panel is free software, licensed under the GNU General Public License, version 3 or later (GPL-3.0-or-later). See [LICENSE](LICENSE).
