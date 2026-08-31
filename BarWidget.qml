import QtQuick
import Quickshell.Io
import qs.Ui
import "InkModel.js" as InkModel

BarWidget {
  id: root
  moduleName: "ink.mode"

  readonly property var service: bar && bar.shell && typeof bar.shell.firstPartyServiceFor === "function"
    ? bar.shell.firstPartyServiceFor("ink.mode")
    : null

  readonly property string cycleScript: {
    var url = Qt.resolvedUrl("cycle.sh").toString()
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  property string fallbackMode: "normal"
  readonly property string mode: service ? InkModel.normalize(service.mode) : fallbackMode

  readonly property string glyph: {
    if (mode === "color-ink") return "󰢵"
    if (mode === "ink") return "󰏪"
    return "󰏘"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function cycle() {
    if (service && typeof service.cycle === "function") {
      service.cycle()
      return
    }
    if (!cycleProc.running)
      cycleProc.running = true
  }

  function refreshFallback() {
    if (!statusProc.running)
      statusProc.running = true
  }

  Component.onCompleted: {
    if (!service)
      refreshFallback()
  }

  Timer {
    interval: 1500
    running: root.service === null
    repeat: true
    onTriggered: root.refreshFallback()
  }

  Process {
    id: statusProc
    command: [root.cycleScript, "desired"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.fallbackMode = InkModel.normalize(String(text).trim())
      }
    }
  }

  Process {
    id: cycleProc
    command: [root.cycleScript, "cycle"]
    onExited: root.refreshFallback()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    active: root.mode !== "normal"
    tooltipText: InkModel.label(root.mode) + " — click to cycle"
    onPressed: function() { root.cycle() }
  }
}
