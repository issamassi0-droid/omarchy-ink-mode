function normalize(mode) {
  if (mode === "color-ink" || mode === "ink" || mode === "normal" || mode === "p3" || mode === "srgb" || mode === "wide" || mode === "neo16") return mode
  return "normal"
}

function fromHyprctl(output) {
  var text = String(output === undefined || output === null ? "" : output)
  if (text.indexOf("color-ink.frag") !== -1) return "color-ink"
  if (text.indexOf("/ink.frag") !== -1 || text.indexOf("ink.frag") !== -1) return "ink"
  if (text.indexOf("p3.frag") !== -1) return "p3"
  if (text.indexOf("srgb.frag") !== -1) return "srgb"
  if (text.indexOf("wide.frag") !== -1) return "wide"
  if (text.indexOf("neo16.frag") !== -1) return "neo16"
  return "normal"
}

function nextMode(mode) {
  if (mode === "normal") return "p3"
  if (mode === "p3") return "srgb"
  if (mode === "srgb") return "wide"
  if (mode === "wide") return "neo16"
  if (mode === "neo16") return "color-ink"
  if (mode === "color-ink") return "ink"
  return "normal"
}

function label(mode) {
  if (mode === "p3") return "P3"
  if (mode === "srgb") return "sRGB"
  if (mode === "wide") return "Wide Gamut"
  if (mode === "neo16") return "Neo"
  if (mode === "color-ink") return "Color Ink"
  if (mode === "ink") return "Ink"
  return "Normal"
}

function description(mode) {
  if (mode === "p3") return "DCI-P3 wide gamut, print-like color"
  if (mode === "srgb") return "Standard BT.709 faithful color"
  if (mode === "wide") return "Adobe-like wide gamut, warm desaturation"
  if (mode === "neo16") return "Warm-shifted wide gamut, softer contrast"
  if (mode === "color-ink") return "Soft, print-like color"
  if (mode === "ink") return "Warm grayscale, like newsprint"
  return "Unfiltered color"
}

if (typeof module !== "undefined") {
  module.exports = {
    normalize: normalize,
    fromHyprctl: fromHyprctl,
    nextMode: nextMode,
    label: label,
    description: description
  }
}
