import QtQuick
import Quickshell
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
  readonly property string statePath: {
    var home = Quickshell.env("HOME") || ""
    var xdg = Quickshell.env("XDG_STATE_HOME")
    var base = (xdg && xdg.length) ? xdg : (home + "/.local/state")
    return base + "/omarchy/ink.mode"
  }

  property string mode: "normal"
  property string desiredMode: "normal"
  property bool stateLoaded: false
  property bool restorePending: false

  function refresh() {
    if (!statusProbe.running)
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
    runApply(next, quiet === true)
  }

  function restore() {
    setMode(root.desiredMode, true)
  }

  function runApply(mode, quiet) {
    if (applyProcess.running) {
      root.restorePending = true
      return
    }
    var args = [root.cycleScript, mode]
    if (quiet)
      args.push("--quiet")
    applyProcess.command = args
    applyProcess.running = true
  }

  function syncFromDiskThenRestore(live) {
    if (desiredProbe.running)
      return
    pendingLive = live
    desiredProbe.running = true
  }

  property string pendingLive: ""

  Process {
    id: desiredProbe
    command: [root.cycleScript, "desired"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var saved = InkModel.normalize(String(text).trim())
        root.desiredMode = saved
        root.stateLoaded = true
        if (root.pendingLive !== "") {
          var live = root.pendingLive
          root.pendingLive = ""
          if (live !== saved)
            root.restore()
          else
            root.mode = live
        } else if (saved !== "normal" || root.mode !== saved) {
          root.restore()
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.desiredMode = "normal"
        root.mode = "normal"
        root.stateLoaded = true
        root.pendingLive = ""
      }
    }
  }

  Process {
    id: statusProbe
    command: [root.cycleScript, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var live = InkModel.normalize(String(text).trim())
        root.syncFromDiskThenRestore(live)
      }
    }
  }

  Process {
    id: applyProcess
    onExited: function() {
      if (root.restorePending) {
        root.restorePending = false
        root.restore()
        return
      }
      root.refresh()
    }
  }

  Timer {
    interval: 1000
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
