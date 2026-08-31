import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "InkModel.js" as InkModel

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginDir: {
    if (manifest && manifest.__sourceDir)
      return String(manifest.__sourceDir).replace(/\/$/, "")
    var url = Qt.resolvedUrl("cycle.sh").toString()
    return decodeURIComponent(url.replace(/^file:\/\//, "")).replace(/\/cycle\.sh$/, "")
  }

  readonly property string cycleScript: root.pluginDir + "/cycle.sh"

  property string mode: "normal"
  property string desiredMode: "normal"
  property bool stateLoaded: false
  property bool applying: false
  property double lastApplyAt: 0

  readonly property int applyGraceMs: 1500
  readonly property int settleMs: 900

  function refresh() {
    if (root.applying || statusProbe.running || desiredProbe.running)
      return
    statusProbe.running = true
  }

  function cycle() {
    setMode(InkModel.nextMode(root.desiredMode), false)
  }

  function setMode(mode, quiet) {
    var next = InkModel.normalize(mode)
    root.desiredMode = next
    root.mode = next
    root.stateLoaded = true
    settleTimer.stop()
    runApply(next, quiet === true)
  }

  function runApply(mode, quiet) {
    if (applyProcess.running) {
      applyProcess.pendingMode = mode
      applyProcess.pendingQuiet = quiet
      applyProcess.hasPending = true
      return
    }
    root.applying = true
    root.lastApplyAt = Date.now()
    var args = [root.cycleScript, mode]
    if (quiet)
      args.push("--quiet")
    applyProcess.command = args
    applyProcess.running = true
  }

  function inApplyGrace() {
    return (Date.now() - root.lastApplyAt) < root.applyGraceMs
  }

  function considerLive(live) {
    if (!root.stateLoaded || root.applying)
      return

    if (live === root.desiredMode) {
      root.mode = live
      settleTimer.stop()
      return
    }

    // Hyprland reload (theme change, omarchy update) clears the shader.
    // Wait until it stays cleared before putting the filter back.
    settleTimer.restart()
  }

  Process {
    id: desiredProbe
    command: [root.cycleScript, "desired"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var saved = InkModel.normalize(String(text).trim())
        root.desiredMode = saved
        root.mode = saved
        root.stateLoaded = true
        if (saved !== "normal")
          root.runApply(saved, true)
        else
          root.refresh()
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.desiredMode = "normal"
        root.mode = "normal"
        root.stateLoaded = true
      }
    }
  }

  Process {
    id: statusProbe
    command: [root.cycleScript, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.considerLive(InkModel.normalize(String(text).trim()))
      }
    }
  }

  Process {
    id: applyProcess
    property bool hasPending: false
    property string pendingMode: "normal"
    property bool pendingQuiet: true

    onExited: function() {
      root.applying = false
      root.lastApplyAt = Date.now()
      if (applyProcess.hasPending) {
        applyProcess.hasPending = false
        root.runApply(applyProcess.pendingMode, applyProcess.pendingQuiet)
      }
    }
  }

  Timer {
    id: settleTimer
    interval: root.settleMs
    repeat: false
    onTriggered: {
      if (root.applying)
        return
      if (root.desiredMode === "normal")
        return
      if (root.inApplyGrace()) {
        restart()
        return
      }
      root.runApply(root.desiredMode, true)
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name)
        return
      if (String(event.name) === "configreloaded")
        root.refresh()
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: desiredProbe.running = true

  IpcHandler {
    target: "inkMode"

    function status(): string {
      return JSON.stringify({ mode: root.mode, desired: root.desiredMode })
    }

    function refresh(): void {
      root.refresh()
    }

    function cycle(): string {
      root.cycle()
      return root.desiredMode
    }

    function set(mode: string): string {
      root.setMode(mode, false)
      return root.desiredMode
    }
  }
}
