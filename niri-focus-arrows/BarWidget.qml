import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Injected by Noctalia's plugin loader.
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  property string pendingAction: "focus-column-left"
  property string queuedAction: ""
  property string lastAction: ""
  property double lastTriggerMs: 0
  property bool combinedHovered: false
  property bool combinedPressed: false

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string screenName: screen?.name || ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real segmentSize: Style.toOdd(capsuleHeight * 0.9)

  readonly property bool reverseScroll: cfg.reverseScroll ?? defaults.reverseScroll ?? false
  readonly property bool wrapAroundColumns: cfg.wrapAroundColumns ?? defaults.wrapAroundColumns ?? true
  readonly property bool combineButtons: cfg.combineButtons ?? defaults.combineButtons ?? false
  readonly property bool compactMode: cfg.compactMode ?? defaults.compactMode ?? false
  readonly property bool hideTooltip: cfg.hideTooltip ?? defaults.hideTooltip ?? false
  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "primary"
  readonly property real combinedPaddingX: (combineButtons && !isBarVertical) ? Style.marginS * 2 : 0
  readonly property real combinedPaddingY: (combineButtons && isBarVertical) ? Style.marginS * 2 : 0

  readonly property color iconColor: iconColorKey === "none" ? Color.mOnSurface : Color.resolveColorKey(iconColorKey)
  readonly property color hoverBgColor: Qt.alpha(iconColor, 0.16)
  readonly property color pressedBgColor: Qt.alpha(iconColor, 0.28)
  readonly property real splitSegmentSize: (compactMode && !combineButtons) ? Style.toOdd(segmentSize * 0.78) : segmentSize
  readonly property real splitIconSize: (compactMode && !combineButtons) ? Style.fontSizeM : Style.fontSizeL

  readonly property real contentWidth: (isBarVertical ? capsuleHeight : (combineButtons ? segmentSize : (splitSegmentSize * 2))) + combinedPaddingX
  readonly property real contentHeight: (isBarVertical ? (combineButtons ? segmentSize : (splitSegmentSize * 2)) : capsuleHeight) + combinedPaddingY

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // Run one Niri action at a time and queue the latest request while busy.
  function queueNiriAction(action) {
    const now = Date.now();

    if (action === lastAction && (now - lastTriggerMs) < 150) {
      return;
    }

    if (actionProcess.running) {
      queuedAction = action;
      return;
    }

    lastAction = action;
    lastTriggerMs = now;
    pendingAction = action;
    actionProcess.running = true;
  }

  function triggerFromScroll(delta) {
    if (delta === 0) {
      return;
    }

    var goLeft = delta > 0;
    if (reverseScroll) {
      goLeft = !goLeft;
    }

    queueNiriAction(resolveColumnAction(goLeft ? "left" : "right"));
  }

  function resolveColumnAction(direction) {
    if (direction === "left") {
      return wrapAroundColumns ? "focus-column-left-or-last" : "focus-column-left";
    }

    return wrapAroundColumns ? "focus-column-right-or-first" : "focus-column-right";
  }

  function showWidgetTooltip(target, text) {
    if (hideTooltip) {
      return;
    }
    TooltipService.show(target, text, BarService.getTooltipDirection(root.screenName));
  }

  function hideWidgetTooltip() {
    if (hideTooltip) {
      return;
    }
    TooltipService.hide();
  }

  Process {
    id: actionProcess
    running: false
    command: ["niri", "msg", "action", root.pendingAction]

    onExited: (exitCode) => {
      if (exitCode !== 0) {
        Logger.w(
          "NiriFocusArrows",
          "Failed to run niri action",
          root.pendingAction,
          "exitCode:",
          exitCode
        );
      }

      if (root.queuedAction !== "") {
        // Execute the most recent queued action after current process exits.
        const nextAction = root.queuedAction;
        root.queuedAction = "";
        root.queueNiriAction(nextAction);
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": "Widget settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "settings" && pluginApi?.manifest) {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: root.combineButtons ? (root.combinedPressed ? root.pressedBgColor : (root.combinedHovered ? root.hoverBgColor : Style.capsuleColor)) : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Global mouse layer:
    // - Wheel: navigate columns
    // - Right click (split mode): open widget context menu
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.RightButton

      onWheel: (wheel) => {
        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y :
                      (wheel.angleDelta.x !== 0 ? wheel.angleDelta.x :
                       (wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.pixelDelta.x));
        root.triggerFromScroll(delta);
        wheel.accepted = true;
      }

      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton && !root.combineButtons) {
          PanelService.showContextMenu(contextMenu, root, screen);
        }
      }
    }

    Item {
      anchors.centerIn: parent
      width: root.segmentSize
      height: root.segmentSize
      visible: root.combineButtons

      // Combined mode: one hit target
      // Left click -> left, Right click -> right, Middle click -> settings menu.
      Rectangle {
        anchors.fill: parent
        radius: Style.radiusM
        color: "transparent"

        Loader {
          anchors.centerIn: parent
          sourceComponent: root.isBarVertical ? combinedIconsVertical : combinedIconsHorizontal
        }
      }

      MouseArea {
        id: combinedMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
          if (mouse.button === Qt.MiddleButton) {
            PanelService.showContextMenu(contextMenu, root, screen);
          } else if (mouse.button === Qt.RightButton) {
            root.queueNiriAction(root.resolveColumnAction("right"));
          } else {
            root.queueNiriAction(root.resolveColumnAction("left"));
          }
        }

        onEntered: {
          root.combinedHovered = true;
          root.showWidgetTooltip(parent, "Left click: focus left | Right click: focus right | Middle click: widget settings");
        }

        onExited: {
          root.combinedHovered = false;
          root.combinedPressed = false;
          root.hideWidgetTooltip();
        }

        onPressed: root.combinedPressed = true
        onReleased: root.combinedPressed = false
        onCanceled: root.combinedPressed = false
      }
    }

    Component {
      id: combinedIconsHorizontal

      Row {
        spacing: Style.marginXXS

        NIcon {
          icon: "chevron-left"
          color: root.iconColor
          pointSize: Style.fontSizeM
          applyUiScale: true
        }

        NIcon {
          icon: "chevron-right"
          color: root.iconColor
          pointSize: Style.fontSizeM
          applyUiScale: true
        }
      }
    }

    Component {
      id: combinedIconsVertical

      Column {
        spacing: 0

        NIcon {
          icon: "chevron-left"
          color: root.iconColor
          pointSize: Style.fontSizeM
          applyUiScale: true
        }

        NIcon {
          icon: "chevron-right"
          color: root.iconColor
          pointSize: Style.fontSizeM
          applyUiScale: true
        }
      }
    }

    Row {
      // Split mode (horizontal bar): left and right buttons side-by-side.
      visible: !root.combineButtons && !root.isBarVertical
      anchors.centerIn: parent
      spacing: 0

      Rectangle {
        width: root.splitSegmentSize
        height: root.splitSegmentSize
        radius: Style.radiusM
        color: leftMouseArea.pressed ? root.pressedBgColor : (leftMouseArea.containsMouse ? root.hoverBgColor : "transparent")

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-left"
          color: root.iconColor
          pointSize: root.splitIconSize
          applyUiScale: true
        }

        MouseArea {
          id: leftMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: root.queueNiriAction(root.resolveColumnAction("left"))
          onEntered: root.showWidgetTooltip(parent, "Focus column left")
          onExited: root.hideWidgetTooltip()
        }
      }

      Rectangle {
        width: root.splitSegmentSize
        height: root.splitSegmentSize
        radius: Style.radiusM
        color: rightMouseArea.pressed ? root.pressedBgColor : (rightMouseArea.containsMouse ? root.hoverBgColor : "transparent")

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-right"
          color: root.iconColor
          pointSize: root.splitIconSize
          applyUiScale: true
        }

        MouseArea {
          id: rightMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: root.queueNiriAction(root.resolveColumnAction("right"))
          onEntered: root.showWidgetTooltip(parent, "Focus column right")
          onExited: root.hideWidgetTooltip()
        }
      }
    }

    Column {
      // Split mode (vertical bar): left and right buttons stacked.
      visible: !root.combineButtons && root.isBarVertical
      anchors.centerIn: parent
      spacing: 0

      Rectangle {
        width: root.splitSegmentSize
        height: root.splitSegmentSize
        radius: Style.radiusM
        color: leftMouseAreaVertical.pressed ? root.pressedBgColor : (leftMouseAreaVertical.containsMouse ? root.hoverBgColor : "transparent")

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-left"
          color: root.iconColor
          pointSize: root.splitIconSize
          applyUiScale: true
        }

        MouseArea {
          id: leftMouseAreaVertical
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: root.queueNiriAction(root.resolveColumnAction("left"))
          onEntered: root.showWidgetTooltip(parent, "Focus column left")
          onExited: root.hideWidgetTooltip()
        }
      }

      Rectangle {
        width: root.splitSegmentSize
        height: root.splitSegmentSize
        radius: Style.radiusM
        color: rightMouseAreaVertical.pressed ? root.pressedBgColor : (rightMouseAreaVertical.containsMouse ? root.hoverBgColor : "transparent")

        NIcon {
          anchors.centerIn: parent
          icon: "chevron-right"
          color: root.iconColor
          pointSize: root.splitIconSize
          applyUiScale: true
        }

        MouseArea {
          id: rightMouseAreaVertical
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: root.queueNiriAction(root.resolveColumnAction("right"))
          onEntered: root.showWidgetTooltip(parent, "Focus column right")
          onExited: root.hideWidgetTooltip()
        }
      }
    }
  }
}
