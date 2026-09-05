#!/bin/bash
# Cycle compositor ink modes: Normal → P3 → sRGB → Wide Gamut → Neo → Color Ink → Ink → Normal.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
srgb="$dir/shaders/srgb.frag"
p3="$dir/shaders/p3.frag"
wide="$dir/shaders/wide.frag"
neo16="$dir/shaders/neo16.frag"
color_ink="$dir/shaders/color-ink.frag"
ink="$dir/shaders/ink.frag"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy"
state_file="$state_dir/inkMode"

current() {
  hyprctl getoption decoration:screen_shader -j 2>/dev/null || true
}

mode_from_hypr() {
  local json="$1"
  if printf '%s' "$json" | grep -q 'color-ink.frag'; then
    printf 'color-ink'
  elif printf '%s' "$json" | grep -q 'neo16.frag'; then
    printf 'neo16'
  elif printf '%s' "$json" | grep -q 'wide.frag'; then
    printf 'wide'
  elif printf '%s' "$json" | grep -q 'srgb.frag'; then
    printf 'srgb'
  elif printf '%s' "$json" | grep -q 'p3.frag'; then
    printf 'p3'
  elif printf '%s' "$json" | grep -q '/ink.frag' || printf '%s' "$json" | grep -q 'ink.frag'; then
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
      normal|color-ink|ink|p3|srgb|wide|neo16) printf '%s' "$saved" ;;
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
    p3)
      set_shader "$p3"
      write_desired p3
      [[ $quiet == true ]] || notify "P3" "DCI-P3 wide gamut, print-like color"
      ;;
    srgb)
      set_shader "$srgb"
      write_desired srgb
      [[ $quiet == true ]] || notify "sRGB" "Standard BT.709 faithful color"
      ;;
    wide)
      set_shader "$wide"
      write_desired wide
      [[ $quiet == true ]] || notify "Wide Gamut" "Adobe-like wide gamut, warm desaturation"
      ;;
    neo16)
      set_shader "$neo16"
      write_desired neo16
      [[ $quiet == true ]] || notify "Neo" "Warm-shifted wide gamut, softer contrast"
      ;;
    color-ink)
      set_shader "$color_ink"
      write_desired color-ink
      [[ $quiet == true ]] || notify "Color Ink" "Soft, print-like color"
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
    normal) printf 'p3' ;;
    p3) printf 'srgb' ;;
    srgb) printf 'wide' ;;
    wide) printf 'neo16' ;;
    neo16) printf 'color-ink' ;;
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
  normal|p3|srgb|wide|neo16|color-ink|ink)
    apply "$cmd"
    ;;
  cycle)
    apply "$(next_mode "$desired")"
    ;;
  *)
    echo "Usage: cycle.sh [cycle|status|desired|restore|normal|p3|srgb|wide|neo16|color-ink|ink] [--quiet]" >&2
    exit 1
    ;;
esac