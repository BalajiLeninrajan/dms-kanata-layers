import QtQuick
import qs.Common
import qs.Widgets

// Draws one layer of a keymap parsed by kbd.js, laid out on the defsrc rows.
Column {
    id: root

    property var keymap: null
    property string layerName: ""
    property real unit: 42
    property real gap: 4

    readonly property var layerData: keymap && keymap.layers[layerName] ? keymap.layers[layerName] : null

    spacing: gap

    Repeater {
        model: root.keymap ? root.keymap.rows : []

        Row {
            required property var modelData
            spacing: root.gap

            Repeater {
                model: modelData

                Rectangle {
                    id: keyCap

                    required property var modelData
                    readonly property var key: root.layerData ? root.layerData.keys[modelData.index] : null
                    readonly property bool active: !!key && !key.transparent

                    width: root.unit * modelData.units + root.gap * (modelData.units - 1)
                    height: root.unit
                    radius: Theme.cornerRadius / 2
                    color: !active ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.5) : key.layer ? Theme.secondaryContainer : Theme.surfaceContainerHighest
                    border.width: active ? 1 : 0
                    border.color: Theme.outlineMedium

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 4
                        spacing: 0

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: keyCap.active ? keyCap.key.label : (keyCap.key ? keyCap.key.src : "")
                            color: keyCap.active ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceVariantText, 0.45)
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: keyCap.active ? Font.Medium : Font.Normal
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 8
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            visible: keyCap.active && keyCap.key.hold !== ""
                            horizontalAlignment: Text.AlignHCenter
                            text: keyCap.key ? keyCap.key.hold : ""
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall - 2
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 7
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingS
        visible: root.layerData && root.layerData.combos.length > 0

        Repeater {
            model: root.layerData ? root.layerData.combos : []

            StyledRect {
                required property var modelData
                width: comboText.implicitWidth + Theme.spacingM * 2
                height: comboText.implicitHeight + Theme.spacingXS * 2
                radius: height / 2
                color: Theme.surfaceContainerHigh

                StyledText {
                    id: comboText
                    anchors.centerIn: parent
                    text: modelData.keys + "  →  " + modelData.label
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }
}
