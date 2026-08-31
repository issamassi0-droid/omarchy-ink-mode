function normalize(mode) {
  if (mode === "color-ink" || mode === "ink" || mode === "normal") return mode
  return "normal"
}

function fromHyprctl(output) {
  var text = String(output === undefined || output === null ? "" : output)
  if (text.indexOf("color-ink.frag") !== -1) return "color-ink"
  if (text.indexOf("/ink.frag") !== -1 || text.indexOf("ink.frag") !== -1) return "ink"
  return "normal"
}

function nextMode(mode) {
  if (mode === "normal") return "color-ink"
  if (mode === "color-ink") return "ink"
  return "normal"
}

function label(mode) {
  if (mode === "color-ink") return "Color Ink Mode"
  if (mode === "ink") return "Ink Mode"
  return "Normal Mode"
}

if (typeof module !== "undefined") {
  module.exports = {
    normalize: normalize,
    fromHyprctl: fromHyprctl,
    nextMode: nextMode,
    label: label
  }
}
