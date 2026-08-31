# Ink Mode

An [Omarchy](https://omarchy.org) bar widget and service that filters the whole screen — UI, browsers, and video — through Hyprland's compositor shader. Last mode is restored after login and after Style changes.

Three modes, one click:

| Mode | Look |
|---|---|
| **Normal Mode** | Full saturation. |
| **Color Ink Mode** | Muted color, slightly warm whites. |
| **Ink Mode** | Grayscale on warm gray paper. |

## Install

```bash
omarchy plugin add https://github.com/bradjinks/omarchy-ink-mode.git --enable
```

That puts a chip on the right of the bar. Click it to cycle **Normal → Color Ink → Ink → Normal**.

Optional Hyprland bind (add to `~/.config/hypr/bindings.lua`):

```lua
o.bind(
  "SUPER + CTRL + SHIFT + N",
  "Cycle ink mode",
  os.getenv("HOME") .. "/.config/omarchy/plugins/ink.mode/cycle.sh"
)
```

## CLI

The plugin needs to be enabled and `omarchy-shell` running.

```bash
omarchy-shell inkMode status          # {"mode":"color-ink","desired":"color-ink"}
omarchy-shell inkMode cycle           # Normal → Color Ink → Ink → Normal
omarchy-shell inkMode set color-ink   # or: ink  /  normal
omarchy-shell inkMode refresh
```

`cycle.sh` does the same from a script or keybind, including when IPC is down:

```bash
~/.config/omarchy/plugins/ink.mode/cycle.sh           # cycle
~/.config/omarchy/plugins/ink.mode/cycle.sh status    # live Hyprland shader
~/.config/omarchy/plugins/ink.mode/cycle.sh color-ink
~/.config/omarchy/plugins/ink.mode/cycle.sh ink
~/.config/omarchy/plugins/ink.mode/cycle.sh normal
```

## Tweaking Color Ink

Edit `shaders/color-ink.frag` and change `SATURATION` (1.0 = unchanged, 0.0 = grayscale). Then cycle away from Color Ink and back, or reload Hyprland.

## Notes

- The last mode is saved in `~/.local/state/omarchy/ink.mode` and restored on login, after Style changes, and after `hyprctl reload`.
- Some exclusive-fullscreen games skip Hyprland and will not be filtered.
- Switch to Normal Mode before disabling the plugin if you want the filter cleared immediately.

## License

MIT
