折腾过彩色电子墨水屏以后，爱不释手。尤其是那种柔和而有层次感的调色，很想给你的阅读和编码桌面也弄一个：不是别的，而是一个整体屏幕的柔光滤镜。

**Lighten** 是微妙的压色，介于 Normal 和 Color Ink 之间，更接近日常观感。**Enhance** 保留大部分色彩出力，在中间调加入柔和提亮而不剧烈，适合希望保留更多原味但又不太过生猛的情形。**Color Ink** 保留色相但对纯度做了克制，像印刷品那样。**Ink** 更进一步，呈现暖灰色调，如报纸印品。**Normal** 即为“完全放开”的日常状态。

这是一种 Omarchy bar widget 和服务。登录后和更换主题时会恢复上一次的模式。

| 模式 | 外观 |
|---|---|
| **Normal** | 未做处理的日常色彩 |
| **Lighten** | 微妙压色，更日常 |
| **Enhance** | 稍微提亮中间调，但又不太剧烈 |
| **Color Ink** | 柔和的色相，纯度克制（类似印刷） |
| **Ink** | 暖灰色调，如报纸印品 |

## 安装

```bash
omarchy plugin add https://github.com/bradjinks/omarchy-ink-mode.git --enable
```

这会在右侧栏嵌入一个小按钮。点击它，会按照 **Normal → Lighten → Enhance → Color Ink → Ink → Normal** 的顺序轮转。

可选 Hyprland 绑定（添加到 `~/.config/hypr/bindings.lua`）：

```lua
o.bind("SUPER + CTRL + SHIFT + N", "Cycle ink mode", "omarchy-shell inkMode cycle")
```

走插件服务能让换到下一种模式后右侧小按钮保持同步。如果 Shell 还没起来，直接用 `cycle.sh` 更稳妥（下面是同一脚本，路径维持一致）。

## 卸载

先切到 Normal，把滤镜清空，然后再：

```bash
omarchy plugin remove jinxnet.inkmode
```

这会移除插件，并把右侧栏上的小按钮摘下来。你手动添加的绑定不会被改掉。

## 命令行/脚本用法

插件启用且 `omarchy-shell` 运行中时：

```bash
omarchy-shell inkMode status          # {"mode":"color-ink","desired":"color-ink"}
omarchy-shell inkMode cycle           # 循环：Normal → Lighten → Enhance → Color Ink → Ink → Normal
omarchy-shell inkMode set lighten     # 以下是可选模式：lighten/ enhance/ color-ink/ ink/ normal
omarchy-shell inkMode refresh
```

`cycle.sh` 无论 IPC 是否开启都能工作，适合直接绑定到按键：

```bash
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh           # 循环
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh status    # 当前 Hyprland 滤镜状态
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh color-ink
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh lighten
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh ink
~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh normal
```

## CLI 层说明（系统范围）

Fedora 的 `cycle.sh` 脚本会替你对整个屏幕层面的 OpenGL 滤镜进行调度（即基于 Hyprland 的 `decoration.screen_shader`）。日常使用推荐走 Omarchy 的 `omarchy-shell inkMode set …` 或 `cycle.sh`，而将 `omarchy-shell` 保持在后台守护（用户目录下的 `bin/omarchy-shell` 或系统安装路径如 `/usr/local/bin/omarchy-shell`）即可自动轮换。

## 调整 Ink 色调（Color Ink / Enhance）

- `shaders/color-ink.frag`：修改 `SATURATION`（1.0 = 不动，0.0 = 灰度）
- `shaders/enhance.frag`：调整 `VIBRANCE`（boost 动作）、`GAMMA`（中间调亮度）等

改完 cycle 离开再回来，或者直接 reload Hyprland 即可应用。

## 文件与缓存

- `~/.local/state/omarchy/inkMode`：记录上次保存的模式
- `~/.config/omarchy/plugins/jinxnet.inkmode/shaders/*`：GLSL 滤镜实现
- `~/.config/omarchy/plugins/jinxnet.inkmode/cycle.sh`：CLI/脚本入口脚本

## 注意事项

- 上次模式会在登录、主题变更以及 `hyprctl reload` 后恢复。
- 部分独占全屏游戏会绕过 Hyprland，从而无法被滤镜覆盖。
- 卸载插件前请先把模式切回 Normal，以免长时间保留滤镜残留影响体验。

## 许可证

MIT