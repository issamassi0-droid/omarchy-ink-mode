# Ink Mode

An [Omarchy](https://omarchy.org) bar widget that filters the whole screen — UI, browsers, and video — through Hyprland's compositor shader.

Three modes, one click:

| Mode | Look |
|---|---|
| **Normal Mode** | Full saturation. Default after login or reload. |
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

## Tweaking Color Ink

Edit `shaders/color-ink.frag` and change `SATURATION` (1.0 = unchanged, 0.0 = grayscale). Then cycle away from Color Ink and back, or reload Hyprland.

## Notes

- Login and `hyprctl reload` return to **Normal Mode**. The last choice is not saved.
- Some exclusive-fullscreen games skip Hyprland and will not be filtered.
- Switch to Normal Mode before disabling the plugin if you want the filter cleared immediately.

## License

MIT
