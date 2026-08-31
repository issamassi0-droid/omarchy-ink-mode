import QtQuick
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "ink.mode"

  property string mode: "normal"

  readonly property string cycleScript: {
    var url = Qt.resolvedUrl("cycle.sh").toString()
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  readonly property string glyph: {
    if (mode === "color-ink") return "󰢵"
    if (mode === "ink") return "󰏪"
    return "󰏘"
  }

  readonly property string modeLabel: {
    if (mode === "color-ink") return "Color Ink Mode"
    if (mode === "ink") return "Ink Mode"
    return "Normal Mode"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running)
      statusProc.running = true
  }

  function cycle() {
    if (!cycleProc.running)
      cycleProc.running = true
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: [root.cycleScript, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text).trim()
        if (next === "normal" || next === "color-ink" || next === "ink")
          root.mode = next
      }
    }
  }

  Process {
    id: cycleProc
    command: [root.cycleScript, "cycle"]
    onExited: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    active: root.mode !== "normal"
    tooltipText: root.modeLabel + " — click to cycle"
    onPressed: function() { root.cycle() }
  }
}
