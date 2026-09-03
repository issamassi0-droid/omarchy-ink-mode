#!/bin/bash
# Cycle compositor ink modes: Normal → Lighten → Color Ink → Ink → Normal.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
color_ink="$dir/shaders/color-ink.frag"
lighten="$dir/shaders/lighten.frag"
ink="$dir/shaders/ink.frag"
vibrance="$dir/shaders/vibrance.frag"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy"
state_file="$state_dir/inkMode"

current() {
  hyprctl getoption decoration:screen_shader -j 2>/dev/null || true
}

mode_from_hypr() {
  local json="$1"
  if printf '%s' "$json" | grep -q 'color-ink.frag'; then
    printf 'color-ink'
  elif printf '%s' "$json" | grep -q 'vibrance.frag'; then
    printf 'vibrance'
  elif printf '%s' "$json" | grep -q 'lighten.frag'; then
    printf 'lighten'
  elif printf '%s' "$json" | grep -q '/ink.frag'; then
    printf 'ink'
  elif printf '%s' "$json" | grep -q 'ink.frag'; then
    printf 'ink'
  else
    printf 'normal'
  fi
}

read_desired() {
  if [[ -r $state_file ]]; then
    local saved
    saved=$(tr -d '[:space:]' <"$state_file")
    case "$saved" in
      normal|color-ink|ink|lighten|vibrance) printf '%s' "$saved" ;;
      *) printf 'normal' ;;
    esac
  else
    printf 'normal'
  fi
}

write_desired() {
  mkdir -p "$state_dir"
  printf '%s\n' "$1" >"$state_file"
}

set_shader() {
  hyprctl eval "hl.config({ [\"decoration.screen_shader\"] = \"$1\" })" >/dev/null
  # Shader changes can sit unseen until the next damaged frame (e.g. mouse move).
  hyprctl eval "hl.dsp.force_renderer_reload()" >/dev/null 2>&1 || true
}

notify() {
  omarchy notification send "$1" "$2" >/dev/null 2>&1 || true
}

quiet=false
args=()
for arg in "$@"; do
  if [[ $arg == --quiet ]]; then
    quiet=true
  else
    args+=("$arg")
  fi
done
set -- "${args[@]+"${args[@]}"}"

apply() {
  case "$1" in
    vibrance)
      set_shader "$vibrance"
      write_desired vibrance
      [[ $quiet == true ]] || notify "Vibrance" "Lifted color, reduced gamma"
      ;;
    color-ink)
      set_shader "$color_ink"
      write_desired color-ink
      [[ $quiet == true ]] || notify "Color Ink" "Soft, print-like color"
      ;;
    lighten)
      set_shader "$lighten"
      write_desired lighten
      [[ $quiet == true ]] || notify "Lighten" "Subtly muted color"
      ;;
    ink)
      set_shader "$ink"
      write_desired ink
      [[ $quiet == true ]] || notify "Ink" "Warm grayscale, like newsprint"
      ;;
    normal|*)
      set_shader ""
      write_desired normal
      [[ $quiet == true ]] || notify "Normal" "Unfiltered color"
      ;;
  esac
}

next_mode() {
  case "$1" in
    normal) printf 'lighten' ;;
    lighten) printf 'vibrance' ;;
    vibrance) printf 'color-ink' ;;
    color-ink) printf 'ink' ;;
    *) printf 'normal' ;;
  esac
}

cmd="${1:-cycle}"
live="$(mode_from_hypr "$(current)")"
desired="$(read_desired)"

case "$cmd" in
  status)
    printf '%s\n' "$live"
    ;;
  desired)
    printf '%s\n' "$desired"
    ;;
  restore)
    apply "$desired"
    ;;
  normal|lighten|vibrance|color-ink|ink)
    apply "$cmd"
    ;;
  cycle)
    apply "$(next_mode "$desired")"
    ;;
  *)
    echo "Usage: cycle.sh [cycle|status|desired|restore|normal|lighten|vibrance|color-ink|ink] [--quiet]" >&2
    exit 1
    ;;
esac
