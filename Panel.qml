import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Templates.js" as Templates

// Bar widget + popup for best-practice prompt skeletons. One entry point
// serves both roles, matching the first-party rich widgets (tailscale, audio):
// the bar mounts this Panel, the BarIconButton below is its bar face, and the
// KeyboardPanel is the popup it anchors.
//
// Interactions: left = popup · right = copy the current prompt without opening
// · middle = next template · scroll = cycle templates.
Panel {
  id: root
  moduleName: "olly.prompt-guide"
  ipcTarget: "olly.prompt-guide"
  manageIpc: false

  // ---------------------------------------------------------------- theme
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // ---------------------------------------------------------------- config
  readonly property string iconGlyph: setting("icon", "󰛨")
  readonly property int panelWidth: Math.max(280, parseInt(setting("panelWidth", 420), 10) || 420)
  readonly property int editorHeight: Math.max(100, parseInt(setting("editorHeight", 200), 10) || 200)
  readonly property bool showTips: setting("showTips", true) !== false

  // ---------------------------------------------------------------- state
  property string selectedId: Templates.templates()[0].id
  // id -> edited prompt text. Only ids the user actually touched are stored,
  // so an untouched template keeps following the shipped copy when it changes.
  property var drafts: ({})
  property bool draftsLoaded: false
  property bool editorReady: false
  property string statusText: ""

  readonly property var activeTemplate: Templates.byId(selectedId)
  readonly property bool dirty: editorReady && editor.text !== activeTemplate.body

  function draftFor(id) {
    var stored = drafts[id]
    return (typeof stored === "string") ? stored : Templates.byId(id).body
  }

  // Push the stored draft into the editor. Guarded on `editorReady` because
  // the state file can finish loading before the popup's item tree exists;
  // the editor's own completion handler re-runs this, so neither order loses.
  function syncEditor() {
    if (editorReady) editor.text = draftFor(selectedId)
  }

  function selectTemplate(id) {
    if (id === selectedId) return
    captureDraft()
    selectedId = id
    syncEditor()
    statusText = ""
    scheduleSave()
  }

  function cycleTemplate(step) {
    var list = Templates.templates()
    var next = (Templates.indexOfId(selectedId) + step + list.length) % list.length
    selectTemplate(list[next].id)
  }

  // Fold the editor's current text back into `drafts`. Reassigning the whole
  // object (rather than mutating in place) is what makes `dirty` and the
  // persisted snapshot re-evaluate — QML doesn't signal on key writes.
  function captureDraft() {
    if (!editorReady) return
    var next = {}
    for (var key in drafts) next[key] = drafts[key]
    if (editor.text === Templates.byId(selectedId).body) delete next[selectedId]
    else next[selectedId] = editor.text
    drafts = next
  }

  function resetTemplate() {
    if (!editorReady) return
    editor.text = activeTemplate.body
    captureDraft()
    scheduleSave()
    flash("Reset to template")
  }

  // printf | wl-copy rather than passing the prompt as an argument: it keeps
  // the bytes exact (no trailing newline added, no argv mangling of the fenced
  // code blocks) and matches how the first-party panels copy.
  function copyText(value) {
    if (!value || value.length === 0) return
    Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(value) + " | wl-copy"])
  }

  function copyPrompt() {
    if (!editorReady) return
    copyText(editor.text)
    flash("Copied to clipboard")
  }

  // Keyboard hand-off into the editor. Parking the caret at the end matters:
  // TextEdit starts it at position 0, so without this the first keystroke after
  // pressing `e` lands in front of the prompt instead of after it.
  function focusEditor() {
    if (!editorReady) return
    editor.forceActiveFocus()
    editor.cursorPosition = editor.length
  }

  function flash(message) {
    statusText = message
    statusTimer.restart()
  }

  // ------------------------------------------------------------- lifecycle
  function open() {
    root.controller.show()
  }

  function close() {
    captureDraft()
    scheduleSave()
    root.controller.hide()
  }

  // The base Panel would register open/close/toggle for us, but a keybind is
  // the natural way to reach "copy the prompt I already wrote" without opening
  // anything — so this handler owns the target and adds the plugin's verbs.
  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function copy(): string { root.copyPrompt(); return "ok" }
    function next(): string { root.cycleTemplate(1); return root.selectedId }
    function previous(): string { root.cycleTemplate(-1); return root.selectedId }
    function reset(): string { root.resetTemplate(); return "ok" }
    function select(id: string): string {
      root.selectTemplate(Templates.byId(id).id)
      return root.selectedId
    }
    function current(): string { return root.selectedId }
    function prompt(): string { return root.editorReady ? editor.text : "" }
  }

  Timer {
    id: statusTimer
    interval: 1800
    onTriggered: root.statusText = ""
  }

  // ----------------------------------------------------------- persistence
  //
  // A single JSON file in the shell's own state directory, written atomically
  // and debounced. `onLoadFailed` matters as much as `onLoaded`: on first run
  // there is no file, and without marking the load complete the first save
  // would be suppressed forever and drafts would never persist.
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/prompt-guide.json"

  function loadState(raw) {
    try {
      var json = JSON.parse(raw || "{}")
      var stored = Util.isPlainObject(json.drafts) ? json.drafts : {}
      var next = {}
      for (var key in stored) {
        if (typeof stored[key] === "string") next[key] = stored[key]
      }
      drafts = next
      if (typeof json.selected === "string") selectedId = Templates.byId(json.selected).id
    } catch (e) {
      drafts = {}
    }
    draftsLoaded = true
    syncEditor()
  }

  function scheduleSave() {
    if (draftsLoaded) saveTimer.restart()
  }

  function flushState() {
    if (!draftsLoaded) return
    stateFile.setText(JSON.stringify({ version: 1, selected: selectedId, drafts: drafts }, null, 2) + "\n")
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
    onLoadFailed: root.loadState("")
  }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: root.flushState()
  }

  // ------------------------------------------------------------- bar face
  //
  // The bar sizes each slot from its mounted item's implicit size, so the root
  // has to carry the button's — without this the slot collapses to 0x0 and the
  // icon never paints, even though the popup still opens over IPC.
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconGlyph
    tooltipText: "Prompt guide"

    onPressed: function(code) {
      if (code === Qt.RightButton) root.copyPrompt()
      else if (code === Qt.MiddleButton) root.cycleTemplate(1)
      else root.toggle()
    }
    onWheelMoved: function(delta) { root.cycleTemplate(delta > 0 ? -1 : 1) }
  }

  // ---------------------------------------------------------------- popup
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(root.panelWidth))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(680))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // The editor and the open dropdown own keys while focused; without this
      // every keystroke typed into the prompt would also drive the panel's own
      // j/k/c/r shortcuts.
      blocked: editor.activeFocus || picker.popupOpen

      onMoveRequested: function(dx, dy) { if (dy !== 0) root.cycleTemplate(dy) }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.focusEditor()
      onTextKey: function(t) {
        var key = t.toLowerCase()
        if (key === "c") root.copyPrompt()
        else if (key === "r") root.resetTemplate()
        else if (key === "e") root.focusEditor()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Prompt guide"
          meta: root.activeTemplate.hint
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: root.iconGlyph
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Dropdown {
          id: picker
          width: parent.width
          label: "Template"
          fontFamily: root.fontFamily
          foreground: root.foreground
          accent: root.accent
          options: Templates.options()
          value: root.selectedId
          onChanged: function(value) { root.selectTemplate(value) }
        }

        // Editable prompt. Painted as a control surface by hand rather than
        // with Ui.TextField, which is single-line by contract.
        BorderSurface {
          id: editorSurface
          width: parent.width
          height: Style.space(root.editorHeight)
          radius: Style.cornerRadius
          padding: Style.spacing.md
          color: Style.controlFill(editor.activeFocus, editorHover.hovered, root.foreground, root.accent)
          borderSpec: Border.controlSpec(editor.activeFocus ? "focus" : (editorHover.hovered ? "hover-cursor" : "normal"), root.foreground, root.accent)

          HoverHandler { id: editorHover }

          Flickable {
            id: editorFlick
            anchors.fill: parent
            anchors.topMargin: editorSurface.contentTopInset
            anchors.rightMargin: editorSurface.contentRightInset
            anchors.bottomMargin: editorSurface.contentBottomInset
            anchors.leftMargin: editorSurface.contentLeftInset
            contentWidth: width
            contentHeight: editor.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            // Keep the caret in view while typing: a Flickable does not follow
            // a TextEdit cursor on its own, so a long prompt would type off the
            // bottom edge.
            function ensureCursorVisible() {
              var r = editor.cursorRectangle
              if (r.y < contentY) contentY = r.y
              else if (r.y + r.height > contentY + height) contentY = r.y + r.height - height
            }

            TextEdit {
              id: editor
              width: editorFlick.width
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: TextEdit.Wrap
              textFormat: TextEdit.PlainText
              selectByMouse: true
              selectByKeyboard: true
              persistentSelection: true
              selectionColor: Style.selectionFillFor(root.foreground, root.accent)
              selectedTextColor: root.foreground
              activeFocusOnPress: true

              Component.onCompleted: {
                root.editorReady = true
                root.syncEditor()
              }

              onCursorRectangleChanged: editorFlick.ensureCursorVisible()
              onTextChanged: {
                root.captureDraft()
                root.scheduleSave()
              }

              Keys.onPressed: function(event) {
                // Esc hands keys back to the panel (a second Esc then closes
                // it); Ctrl+Enter is copy-and-go.
                if (event.key === Qt.Key_Escape) {
                  keyCatcher.forceActiveFocus()
                  event.accepted = true
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                           && (event.modifiers & Qt.ControlModifier)) {
                  root.copyPrompt()
                  event.accepted = true
                }
              }
            }
          }
        }

        Item {
          width: parent.width
          implicitHeight: actions.implicitHeight

          Row {
            id: actions
            spacing: Style.spacing.controlGap

            Button {
              text: "Copy"
              iconText: "󰆏"
              bordered: true
              focusable: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              tooltipText: "Copy the prompt (c)"
              onClicked: root.copyPrompt()
            }

            Button {
              text: "Reset"
              iconText: "󰑐"
              bordered: true
              focusable: true
              enabled: root.dirty
              opacity: root.dirty ? 1 : 0.45
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              tooltipText: "Discard edits and restore the template (r)"
              onClicked: root.resetTemplate()
            }
          }

          Text {
            textFormat: Text.PlainText
            anchors.right: parent.right
            anchors.verticalCenter: actions.verticalCenter
            text: root.statusText !== "" ? root.statusText : (root.dirty ? "edited" : "")
            color: root.statusText !== "" ? root.accent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption

            Behavior on color { ColorAnimation { duration: 160 } }
          }
        }

        PanelSeparator {
          visible: root.showTips
          foreground: root.foreground
        }

        PanelSectionHeader {
          visible: root.showTips
          text: "Best practice"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Column {
          id: tips
          visible: root.showTips
          width: parent.width
          spacing: Style.spacing.sm

          Repeater {
            model: root.activeTemplate.tips

            Row {
              id: tipRow
              required property string modelData
              width: tips.width
              spacing: Style.spacing.md

              Text {
                textFormat: Text.PlainText
                text: "•"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                textFormat: Text.PlainText
                width: tipRow.width - tipRow.spacing - Style.space(8)
                text: tipRow.modelData
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: root.showTips
          width: parent.width
          topPadding: Style.spacing.xs
          text: "c copy · r reset · e edit · j/k template · Esc close"
          color: Qt.darker(root.foreground, 2.0)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
