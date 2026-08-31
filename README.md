# Ink Mode

I tried a color e-ink reader once. Loved the muted palette. Did not love the price.

That look is what I wanted for reading and coding: color, just quieter. Desktop themes get you most of the way there. Then you open a webpage or a YouTube tab and the difference is almost painful — calm editor, neon everything else.

So I wondered: what if the *whole* screen just got a little desaturated? Not another theme. A filter.

**Color Ink** keeps hue but takes the punch out, the way print holds color without glow. **Ink** goes further: warm grayscale, like newsprint. **Normal** is the unfiltered display, one click away when you actually want the fireworks.

An [Omarchy](https://omarchy.org) bar widget and service. Last mode is restored after login and after Style changes.

| Mode | Look |
|---|---|
| **Normal** | Unfiltered color |
| **Color Ink** | Soft, print-like color |
| **Ink** | Warm grayscale, like newsprint |

## Install

```bash
omarchy plugin add https://github.com/bradjinks/omarchy-ink-mode.git --enable
```

That puts a chip on the right of the bar. Click it to cycle **Normal → Color Ink → Ink → Normal**. No extra packages: it uses Hyprland’s screen shader, which Omarchy already has.

Optional Hyprland bind (add to `~/.config/hypr/bindings.lua`):

```lua
o.bind(
  "SUPER + CTRL + SHIFT + N",
  "Cycle ink mode",
  os.getenv("HOME") .. "/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh"
)
```

## Remove

Switch to **Normal** first so the screen filter is cleared, then:

```bash
omarchy plugin remove jinxnet.inkMode
```

That uninstalls the plugin and takes the chip off the bar. It does not edit a Hyprland bind you added by hand.

Disabling without removing (`omarchy plugin disable jinxnet.inkMode`) leaves an active filter in place until you switch to Normal, or reload Hyprland with no shader set.

Optional leftovers:

- `~/.local/state/omarchy/inkMode` — last saved mode
- the optional bind in `~/.config/hypr/bindings.lua`

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
~/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh           # cycle
~/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh status    # live Hyprland shader
~/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh color-ink
~/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh ink
~/.config/omarchy/plugins/jinxnet.inkMode/cycle.sh normal
```

## Tweaking Color Ink

Edit `shaders/color-ink.frag` and change `SATURATION` (1.0 = unchanged, 0.0 = grayscale). Then cycle away from Color Ink and back, or reload Hyprland.

## Notes

- The last mode is saved in `~/.local/state/omarchy/inkMode` and restored on login, after Style changes, and after `hyprctl reload`.
- Some exclusive-fullscreen games skip Hyprland and will not be filtered.
- Switch to Normal before disabling the plugin if you want the filter cleared immediately.

## License

MIT
