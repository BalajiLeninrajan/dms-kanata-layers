import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Bar pill with the live layer name. The popout browses every layer's keymap.
PluginComponent {
    id: root

    layerNamespacePlugin: "kanata-layers"

    PluginGlobalVar {
        id: layerVar
        varName: "layer"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: connectedVar
        varName: "connected"
        defaultValue: false
    }

    PluginGlobalVar {
        id: keymapVar
        varName: "keymap"
        defaultValue: null
    }

    PluginGlobalVar {
        id: addressVar
        varName: "address"
        defaultValue: ""
    }

    readonly property string pillIcon: connectedVar.value ? "keyboard" : "keyboard_off"

    readonly property real keyUnit: 42
    readonly property real keyGap: 4
    readonly property real keymapWidth: {
        const km = keymapVar.value;
        if (!km)
            return 400;
        let widest = 0;
        for (const row of km.rows) {
            let w = 0;
            for (const k of row)
                w += keyUnit * k.units + keyGap * k.units;
            widest = Math.max(widest, w);
        }
        return widest;
    }
    readonly property real keymapHeight: keymapVar.value ? keymapVar.value.rows.length * (keyUnit + keyGap) : 200

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.pillIcon
                size: root.iconSize
                color: connectedVar.value ? Theme.surfaceText : Theme.surfaceVariantText
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: connectedVar.value
                text: layerVar.value
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.pillIcon
                size: root.iconSize
                color: connectedVar.value ? Theme.surfaceText : Theme.surfaceVariantText
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: connectedVar.value
                text: layerVar.value.slice(0, 3)
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            property string selected: layerVar.value || (keymapVar.value ? keymapVar.value.layerNames[0] : "")

            headerText: "Kanata layers"
            detailsText: !connectedVar.value ? "Not connected to kanata at " + addressVar.value + ". Is it running with --port?" : !keymapVar.value ? "Could not read the kanata config. Check the path in the plugin settings." : ""
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: keymapVar.value !== null

                Row {
                    spacing: Theme.spacingS

                    Repeater {
                        model: keymapVar.value ? keymapVar.value.layerNames : []

                        StyledRect {
                            required property string modelData
                            readonly property bool isSelected: modelData === popout.selected

                            width: chipText.implicitWidth + Theme.spacingM * 2
                            height: chipText.implicitHeight + Theme.spacingS * 2
                            radius: height / 2
                            color: isSelected ? Theme.primary : Theme.surfaceContainerHigh

                            StyledText {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData + (modelData === layerVar.value ? " •" : "")
                                color: parent.isSelected ? Theme.primaryText : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popout.selected = parent.modelData
                            }
                        }
                    }
                }

                KeymapView {
                    keymap: keymapVar.value
                    layerName: popout.selected
                    unit: root.keyUnit
                    gap: root.keyGap
                }
            }
        }
    }

    popoutWidth: keymapWidth + Theme.spacingL * 2
    popoutHeight: keymapHeight + 200
}
