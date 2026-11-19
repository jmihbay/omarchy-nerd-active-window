import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "AppGlyph.js" as AppGlyph

BarWidget {
  id: root
  moduleName: "jmihbay.nerd-active-window"
  readonly property string userRulesDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
    + "/omarchy/nerd-active-window"
  readonly property var userGlyphs: AppGlyph.parseRules(userGlyphFile.text(), "icons-rules.json")
  readonly property var userVectors: AppGlyph.parseRules(userVectorFile.text(), "vector-icons-rules.json")
  readonly property var defaultGlyphs: AppGlyph.parseRules(defaultGlyphFile.text(), "default-icons-rules.json")
  readonly property var defaultVectors: AppGlyph.parseRules(defaultVectorFile.text(), "default-vector-icons-rules.json")
  readonly property var icon: AppGlyph.selectIcon(appClass, initialClass, userGlyphs, userVectors, defaultGlyphs, defaultVectors)
  readonly property var vectorRule: icon.vector
  property var activeApp: ({})
  property bool refreshPending: false
  readonly property string appClass: String(activeApp.class || "")
  readonly property string initialClass: String(activeApp.initialClass || "")
  readonly property string title: String(activeApp.title || appClass)
  readonly property string screenName: {
    var window = root.QsWindow.window
    return window && window.screen ? window.screen.name : ""
  }

  function scheduleRefresh() { debounce.restart() }
  function refresh() {
    if (query.running) { refreshPending = true; return }
    query.command = ["python3", decodeURIComponent(Qt.resolvedUrl("ActiveApp.py").toString().replace(/^file:\/\//, "")), screenName]
    query.running = true
  }
  Component.onCompleted: scheduleRefresh()
  onScreenNameChanged: scheduleRefresh()

  FileView {
    id: defaultGlyphFile
    path: Qt.resolvedUrl("default-icons-rules.json")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: defaultVectorFile
    path: Qt.resolvedUrl("default-vector-icons-rules.json")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: userGlyphFile
    path: root.userRulesDir + "/icons-rules.json"
    printErrors: false
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: userVectorFile
    path: root.userRulesDir + "/vector-icons-rules.json"
    printErrors: false
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  Timer { id: debounce; interval: 50; onTriggered: root.refresh() }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && /^(activewindow|activewindowv2|workspace|workspacev2|focusedmon|focusedmonv2|openwindow|closewindow|movewindow|movewindowv2|activespecial|activespecialv2|pin|changefloatingmode|monitoradded|monitorremoved|windowtitle|windowtitlev2)$/.test(String(event.name))) root.scheduleRefresh()
    }
  }
  Process {
    id: query
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.activeApp = JSON.parse(text) } catch (error) { root.activeApp = ({}) }
      }
    }
    onExited: {
      if (root.refreshPending) { root.refreshPending = false; root.scheduleRefresh() }
    }
  }

  visible: appClass !== ""
  implicitWidth: visible ? barSize : 0
  implicitHeight: barSize

  BarIconButton {
    id: appButton
    iconComponent: root.vectorRule ? vectorIcon : null
    anchors.fill: parent
    bar: root.bar
    text: root.icon.glyph
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Style.bar.iconFont
    centerFigures: false
    fixedWidth: root.barSize
    fixedHeight: root.barSize
    pressable: false
    tooltipText: AppGlyph.tooltipText(root.title, root.appClass)
  }

  Component {
    id: vectorIcon
    Shape {
      implicitWidth: root.vectorRule?.width ?? 1
      implicitHeight: root.vectorRule?.height ?? 1
      width: Style.bar.iconCanvas
      height: Style.bar.iconCanvas
      fillMode: Shape.PreserveAspectFit
      horizontalAlignment: Shape.AlignHCenter
      verticalAlignment: Shape.AlignVCenter
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeWidth: -1
        fillColor: appButton.foreground
        fillRule: ShapePath.OddEvenFill
        PathSvg { path: root.vectorRule?.path ?? "" }
      }
    }
  }
}
