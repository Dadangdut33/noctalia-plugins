import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool valueReverseScroll: cfg.reverseScroll ?? defaults.reverseScroll ?? false
  property bool valueWrapAroundColumns: cfg.wrapAroundColumns ?? defaults.wrapAroundColumns ?? true
  property string valueIconColor: cfg.iconColor ?? defaults.iconColor ?? "primary"
  property bool valueCombineButtons: cfg.combineButtons ?? defaults.combineButtons ?? false
  property bool valueCompactMode: cfg.compactMode ?? defaults.compactMode ?? false
  property string valueSplitRightClickAction: cfg.splitRightClickAction ?? defaults.splitRightClickAction ?? "move-column"
  property string valueSplitMiddleClickAction: cfg.splitMiddleClickAction ?? defaults.splitMiddleClickAction ?? "open-context-menu"
  property string valueCombinedMiddleClickAction: cfg.combinedMiddleClickAction ?? defaults.combinedMiddleClickAction ?? "open-context-menu"
  property bool valueHideTooltip: cfg.hideTooltip ?? defaults.hideTooltip ?? false
  readonly property var mouseActionOptions: [
    { "key": "none", "name": "none" },
    { "key": "open-context-menu", "name": "open-context-menu" },
    { "key": "move-column", "name": "move-column" },
    { "key": "close-window", "name": "close-window" }
  ]
  readonly property var combinedMiddleMouseActionOptions: [
    { "key": "none", "name": "none" },
    { "key": "open-context-menu", "name": "open-context-menu" },
    { "key": "move-column-left", "name": "move-column-left" },
    { "key": "move-column-right", "name": "move-column-right" },
    { "key": "close-window", "name": "close-window" }
  ]

  spacing: Style.marginL

  NToggle {
    label: "Reverse scroll direction"
    description: "Invert scroll behavior for left/right focus actions."
    checked: root.valueReverseScroll
    onToggled: checked => root.valueReverseScroll = checked
  }

  NToggle {
    label: "Wrap around columns"
    description: "When reaching the edge, move to the first/last column instead of stopping."
    checked: root.valueWrapAroundColumns
    onToggled: checked => root.valueWrapAroundColumns = checked
  }

  NComboBox {
    label: "Icon color"
    description: "Choose a Noctalia theme color preset for the arrow icons."
    model: Color.colorKeyModel
    currentKey: root.valueIconColor
    onSelected: key => root.valueIconColor = key
  }


  NToggle {
    label: "Compact mode"
    description: "Use smaller arrow buttons in split mode (ignored when combine buttons is enabled)."
    checked: root.valueCompactMode
    enabled: !root.valueCombineButtons
    onToggled: checked => root.valueCompactMode = checked
  }

  NComboBox {
    label: "Right-click action"
    description: "Action for right click when buttons are split."
    model: root.mouseActionOptions
    currentKey: root.valueSplitRightClickAction
    enabled: !root.valueCombineButtons
    onSelected: key => root.valueSplitRightClickAction = key
  }

  NComboBox {
    label: "Middle-click action"
    description: "Action for middle click when buttons are split."
    model: root.mouseActionOptions
    currentKey: root.valueSplitMiddleClickAction
    enabled: !root.valueCombineButtons
    onSelected: key => root.valueSplitMiddleClickAction = key
  }

  NToggle {
    label: "Combine buttons"
    description: "Use one combined button: left click focuses left, right click focuses right."
    checked: root.valueCombineButtons
    onToggled: checked => root.valueCombineButtons = checked
  }

  NComboBox {
    label: "Combined middle-click action"
    description: "Action for middle click when combine buttons is enabled."
    model: root.combinedMiddleMouseActionOptions
    currentKey: root.valueCombinedMiddleClickAction
    enabled: root.valueCombineButtons
    onSelected: key => root.valueCombinedMiddleClickAction = key
  }

  NToggle {
    label: "Hide tooltip"
    description: "Disable all hover tooltips for this widget."
    checked: root.valueHideTooltip
    onToggled: checked => root.valueHideTooltip = checked
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NiriFocusArrows", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.reverseScroll = root.valueReverseScroll;
    pluginApi.pluginSettings.wrapAroundColumns = root.valueWrapAroundColumns;
    pluginApi.pluginSettings.iconColor = root.valueIconColor;
    pluginApi.pluginSettings.combineButtons = root.valueCombineButtons;
    pluginApi.pluginSettings.compactMode = root.valueCompactMode;
    pluginApi.pluginSettings.splitRightClickAction = root.valueSplitRightClickAction;
    pluginApi.pluginSettings.splitMiddleClickAction = root.valueSplitMiddleClickAction;
    pluginApi.pluginSettings.combinedMiddleClickAction = root.valueCombinedMiddleClickAction;
    pluginApi.pluginSettings.hideTooltip = root.valueHideTooltip;
    pluginApi.saveSettings();
  }
}
