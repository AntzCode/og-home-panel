# og-home-panel

Android-style Back, app switcher and quick actions for Linux phones, shown as a bar at the bottom of the screen. Goal: the missing piece that makes a Linux phone feel like home. See README.md for user-facing behavior.

- Repo: `github.com/AntzCode/og-home-panel` (private until the first release)
- App ID: `com.antzcode.og_home_panel`. Underscores, because the ID is also a D-Bus name and object path, and hyphens aren't allowed there. Use `og-home-panel` everywhere else: the command, the systemd unit, the layer-shell namespace and the CSS class.
- License: GPL-3.0-or-later. Every source file starts with an SPDX header.

## Current state

A single Python script, `og-home-panel` (GTK 4 + gtk4-layer-shell + PyGObject), that runs on **Phosh**. It has been tested on a OnePlus 6 with Nura (postmarketOS) v26.06: phosh 0.55, phoc 0.55.1, Stevia OSK 0.55, GTK 4.22.

## Design decisions (and why)

- **Layer `OVERLAY`, not `TOP`.** On `TOP`, Phosh's opened overview and the Stevia keyboard covered the panel, because same-layer surfaces stack in the order they were raised. Phoc reserves the overlay layer's exclusive zone first, so the others now sit above the panel.
- **Hidden while locked.** The lock screen is also on the overlay layer. The panel follows logind's `LockedHint` on the user's display session, which Phosh sets on lock. Don't use `org.gnome.ScreenSaver`: on Phosh its "active" state follows screen blanking, so it turns false when the screen wakes on the lock screen. Keep a reference to the system bus connection; GIO holds it only weakly, and its signal subscriptions die with it.
- **Keyboard mode `NONE`.** The panel never takes focus, so injected keys reach the app.
- **Exclusive zone = the bar's measured height only.** It's measured on map, because the theme's button padding makes the bar taller than `BAR_HEIGHT` (52 px vs 44 on the test phone).
- **The quick-actions row is a separate layer surface**, with exclusive zone -1 and a bottom margin equal to the bar's height, so it overlaps the app instead of resizing it. It used to be a revealer inside the bar's window, but resizing a layer-shell window doesn't work well: after the row collapsed, the window kept its height (the bar floated above the bottom edge), and resetting the default size broke the width, either right away or after a rotation. A bar surface that never resizes avoids all of that. The row overlaps the bottom row of the Stevia keyboard. That's intended: the user doesn't want the app or the keyboard to resize or jump when the row opens or closes.
- **Keys are sent with `wtype`**, using the virtual-keyboard protocol, which phoc supports.
- **gtk4-layer-shell must load before libwayland.** The script re-executes itself with `LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so.0`. The file is `.so.0`; a wrong path is silently ignored. Once loaded, the panel takes it out of `LD_PRELOAD` again, so the processes it starts don't inherit it: Firefox, opened from an About link, aborted with GTK 4 loaded next to its GTK 3.
- **Back uses AT-SPI**, because Wayland has no API for whether an app has back history:
  1. If the Phosh overview is focused (app `phosh`), toggle it closed with Super+A.
  2. If the window is a dialog, alert or file chooser, send Escape.
  3. Otherwise search depth-first for a push or toggle button whose name matches `^(go )?back\b`, skipping web page, terminal and text subtrees (`SKIP_ROLES`), which is what makes it fast. If the button is enabled and visible, press it with `do_action(0)`.
  4. If there's none, open the overview with Super+A. That's "send to background", as on Android.
  - Taps queue up in the AT-SPI helper and run one after another.
  - Pressing Firefox's Back through AT-SPI took about 0.8 s, so apps in `BACK_KEY_APPS` get Alt+Left after the availability check. The search itself takes about 0.1–0.2 s in Firefox.
- **AT-SPI runs in a helper process**: the same script, started by the panel with `--atspi-helper`. libatspi attaches the connections it opens lazily (the a11y bus at init, and each app's peer-to-peer bus) to `g_main_context_default()`. `Atspi.set_main_context` only moves the ones that already exist. In the GTK process, that meant AT-SPI traffic ran on GTK's main loop: first a segfault with a worker thread, then `g_source_unref` warnings, lost events and a ~15 s first call with a dedicated thread and context. The helper has a single-threaded GLib loop of its own. The pipes carry one line per message: the panel sends `back <tap time>` on the helper's stdin, and the helper sends `drawer 0|1` on stdout; its logs go to stderr. The panel restarts the helper 2 s after it exits.
- **Hidden while Phosh's quick-settings drawer is open.** The drawer is on the `TOP` layer, under the panel, so the panel covered its bottom row. Phosh doesn't publish the drawer state. The helper watches the drawer's drag handle instead: a `drawing area` in the `phosh panel` frame, which is showing only while the drawer is open. It uses `register_with_app`, so only Phosh sends events. The helper re-attaches when `org.gnome.Shell` reappears on the bus (a Phosh restart). The panel hides once the drawer has settled open, not during the drag.
- **Rotate offer, like Android's.** While rotation is locked (`org.gnome.settings-daemon.peripherals.touchscreen orientation-lock`) and the accelerometer's orientation (iio-sensor-proxy `AccelerometerOrientation`) stops matching the display's transform, a rotate button replaces ⋯ for `ROTATE_OFFER_SECONDS`. In fullscreen, where the bar is hidden, the offer shows as a lone floating button instead (its own layer surface, exclusive zone -1), because rotating a fullscreen video is the main use. `place_floating` anchors it to the screen edges that are physically at the bottom and right as the phone is held now, so it sits in the bottom-right of the view-to-be. It also turns the icon to match (`-gtk-icon-transform`). The turn is `(target - current) % 4` quarter turns clockwise; transform 1 is upright with the phone's top pointing right. Tapping it applies the current monitor setup with the new transform through `org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig`, method 2 (persistent); Phosh ignores method 1 (temporary). The orientation-to-transform map (`left-up` → 1, `right-up` → 3) was checked on the phone. The accelerometer is claimed only while the screen is unlocked. Stevia shows itself again on every rotation, without any `SetVisible` call: it rebuilds for the new size and comes back visible. So if it was closed before, the panel closes it again when it reappears within `OSK_RESHOW_SECONDS`. polkit allows the claim only from the active session: it works from the panel's systemd user unit, but not from an SSH shell.
- **App switcher (Apps long press).** Phosh has no Alt+Tab, so the panel builds its own: the `wlr-foreign-toplevel` client (`ToplevelWatcher`, which also does the fullscreen check) tracks each window's title, app ID and states, orders them by when each was last activated, and switches with `activate(wl_seat)`, binding a seat for that. The list is its own layer surface covering the screen above the bar (exclusive zone -1), with a dimmed background that closes it on tap. Icons come from the window's `.desktop` file, matched by app ID, then by `StartupWMClass`. A tap opens the overview, as before. Phosh focuses the overview's search field when it opens, which brings up Stevia over the app grid, so the panel closes the keyboard again if it shows within `OSK_RESHOW_SECONDS` (`keep_osk_closed`, shared with rotation). Tapping the search field still opens it.
- **Menus are sheets** (`SheetMenu`): a layer surface covering the screen above the bar, with the rows along the bottom and a dimmed background that closes it on tap. The app switcher and the panel menu (⋯ long press) are both sheets; only one menu, or the quick-actions row, is open at a time. Back closes an open menu.
- **About uses libadwaita's `AdwAboutDialog`**, to match GNOME apps (Calculator, Calendar). The app is an `Adw.Application`, for libadwaita's styles. An `AdwDialog` shows inside a window, so `AboutScreen` is a layer surface (`Adw.Window`) covering the screen above the bar that hosts it and hides when the dialog closes. It stops at the bar, like the sheets: the bar stacks above it and covered the dialog's bottom. Its links open through `activate-link` with no parent window: GTK's default handler made phoc drop the panel's connection ("Protocol error"), most likely by exporting the layer surface's handle as if it were a toplevel. libadwaita doesn't need a GNOME compositor, so this also works on Plasma.
- **Restart after a crash.** The process that's launched (by autostart or `dev-restart.sh`) is a small supervisor that loads no GTK: it runs the panel as a child (`--panel`) and restarts it 2 s after a non-zero exit or crash signal. A clean exit, SIGTERM or SIGINT ends both, so stopping the unit or scope still works. It gives up after more than `MAX_RESTARTS` within a minute (e.g. no compositor), rather than looping. It works the same with any launcher and desktop, which `Restart=` on the transient unit wouldn't, since autostart runs the panel in a gnome-session scope.
- **Haptics** use feedbackd (`Lfb`, event `button-pressed`) on touch down, so a tap is felt before its action finishes. They don't play in the silent profile, by design.

## Planned architecture (not built yet)

Restructure before adding more Phosh-only features:

```
core/               Python package: AT-SPI back logic, actions
  backends/         phosh.py, plasma.py, wlroots.py, gnome.py
panel/              GTK layer-shell front end (Phosh, Plasma Mobile, Sway/Sxmo)
gnome-extension/    GNOME Shell extension (JavaScript). Mutter has no layer-shell
data/  tools/  docs/
```

- A shell backend provides: send keys, open the overview or app view, toggle the OSK, detect lock, haptics.
- Plasma (KWin) has no virtual-keyboard protocol for ordinary apps: use `ydotool` or KWin's fake input. Its OSK is Maliit, via KWin's VirtualKeyboard D-Bus. Use `org.freedesktop.ScreenSaver` there.
- The GNOME extension can't import Python. When it's built, `core` becomes a small D-Bus service that both front ends call. Don't build the D-Bus split before then.
- Lomiri (Ubuntu Touch) is out of scope.

## Roadmap / open items

- Autostart is installed by `deploy.sh` (absolute `Exec=`, since the systemd autostart generator ignores `~/.local/bin`). Still to do: test it across a reboot.
- Back rules for GTK and Kirigami apps: probe real apps for their Back-button names.
- Later: replace the Phosh home bar instead of sitting above it. That needs a patched phosh.
- The core/backends split (above).

Related but tracked elsewhere (device setup, not this product): Ctrl and Alt in Stevia's normal layout, per-app scale-to-fit, and the haptics udev fix.

## Conventions

- Python 3, PyGObject. Match the existing style: module-level helpers, short docstrings, comments only where the reason isn't obvious.
- US English in code, comments and docs. UI text is US English too (global project). The UI is currently icons only.
- Keep device-specific material out of this repo.

## Developing and testing

- `tools/deploy.sh [user@host]` copies the script to the phone and restarts it as the transient systemd user unit `og-home-panel`. Logs: `ssh … journalctl --user -u og-home-panel`.
- Pitfalls:
  - Over SSH, `nohup … &` gets killed when the session ends. Use `systemd-run --user`, which `dev-restart.sh` does.
  - `pkill -f <name>` inside `ssh host '…'` matches the remote shell itself and kills it.
  - `gsettings` and D-Bus over SSH need `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus`.
- Screenshots: `gdbus call --session -d org.gnome.Shell.Screenshot -o /org/gnome/Shell/Screenshot -m org.gnome.Shell.Screenshot.Screenshot false false /tmp/x.png`. **Always ask the user before taking one.** The screen can show private data.
- Adding to an app's Back support: probe its AT-SPI tree first (active window, buttons with their names and states) rather than guessing.
