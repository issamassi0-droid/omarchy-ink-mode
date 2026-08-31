#!/bin/bash
# Cycle compositor ink modes: Normal → Color Ink → Ink → Normal.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
color_ink="$dir/shaders/color-ink.frag"
ink="$dir/shaders/ink.frag"

current() {
  hyprctl getoption decoration:screen_shader -j 2>/dev/null || true
}

mode_from_current() {
  local json="$1"
  if printf '%s' "$json" | grep -q 'color-ink.frag'; then
    printf 'color-ink'
  elif printf '%s' "$json" | grep -q '/ink.frag'; then
    printf 'ink'
  elif printf '%s' "$json" | grep -q 'ink.frag'; then
    printf 'ink'
  else
    printf 'normal'
  fi
}

set_shader() {
  hyprctl eval "hl.config({ [\"decoration.screen_shader\"] = \"$1\" })" >/dev/null
}

notify() {
  omarchy notification send "$1" "$2" >/dev/null 2>&1 || true
}

apply() {
  case "$1" in
    color-ink)
      set_shader "$color_ink"
      notify "Color Ink Mode" "Muted color on the whole screen"
      ;;
    ink)
      set_shader "$ink"
      notify "Ink Mode" "Grayscale on warm paper"
      ;;
    normal|*)
      set_shader ""
      notify "Normal Mode" "Full saturation"
      ;;
  esac
}

cmd="${1:-cycle}"
now="$(mode_from_current "$(current)")"

case "$cmd" in
  status)
    printf '%s\n' "$now"
    ;;
  normal|color-ink|ink)
    apply "$cmd"
    ;;
  cycle)
    case "$now" in
      normal) apply color-ink ;;
      color-ink) apply ink ;;
      *) apply normal ;;
    esac
    ;;
  *)
    echo "Usage: cycle.sh [cycle|status|normal|color-ink|ink]" >&2
    exit 1
    ;;
esac
