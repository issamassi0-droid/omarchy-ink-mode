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
  onCycleScriptChanged: if (!root.stateLoaded) root.loadDesired()

  property string mode: "normal"
  property string desiredMode: "normal"
  property bool stateLoaded: false
  property bool applying: false
  property double lastApplyAt: 0
  property int loadAttempts: 0

  readonly property int applyGraceMs: 1500
  readonly property int settleMs: 900
  readonly property int maxLoadAttempts: 10

  function loadDesired() {
    if (desiredProbe.running)
      return
    if (!root.cycleScript || root.cycleScript.indexOf("/") !== 0)
      return
    desiredProbe.running = true
  }

  function refresh() {
    if (root.applying || statusProbe.running || desiredProbe.running || diskProbe.running)
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

    // A keybind that calls cycle.sh updates the compositor and the state
    // file without going through this service. Re-read the file before
    // treating the mismatch as a Hyprland reload that should be reverted.
    if (diskProbe.running)
      return
    diskProbe.pendingLive = live
    diskProbe.running = true
  }

  Process {
    id: desiredProbe
    command: [root.cycleScript, "desired"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text).trim()
        if (raw !== "normal" && raw !== "color-ink" && raw !== "ink" && raw !== "lighten" && raw !== "vibrance")
          return
        var saved = InkModel.normalize(raw)
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
      if (exitCode === 0 || root.stateLoaded)
        return
      root.loadAttempts += 1
      if (root.loadAttempts >= root.maxLoadAttempts) {
        root.desiredMode = "normal"
        root.mode = "normal"
        root.stateLoaded = true
        return
      }
      loadRetry.restart()
    }
  }

  Process {
    id: diskProbe
    property string pendingLive: "normal"
    command: [root.cycleScript, "desired"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text).trim()
        if (raw !== "normal" && raw !== "color-ink" && raw !== "ink" && raw !== "lighten" && raw !== "vibrance")
          return
        var saved = InkModel.normalize(raw)
        var live = InkModel.normalize(diskProbe.pendingLive)
        if (live === saved) {
          root.desiredMode = saved
          root.mode = saved
          settleTimer.stop()
          return
        }
        if (saved !== root.desiredMode) {
          root.setMode(saved, true)
          return
        }
        // Hyprland reload (theme change, omarchy update) clears the shader.
        // Wait until it stays cleared before putting the filter back.
        settleTimer.restart()
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

  Timer {
    id: loadRetry
    interval: 400
    repeat: false
    onTriggered: root.loadDesired()
  }

  // ensureService injects `manifest` after createObject. Wait one tick so
  // pluginDir is the real plugin path before the first desired-state probe.
  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: root.loadDesired()
  }

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
