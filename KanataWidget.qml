import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "kbd.js" as Kbd

// Bar pill that opens a popout of every layer in your kanata config.
PluginComponent {
    id: root

    layerNamespacePlugin: "kanata-layers"

    readonly property string configPath: {
        const path = pluginData.configPath || "~/.config/kanata/kanata.kbd";
        return path.startsWith("~/") ? Quickshell.env("HOME") + path.slice(1) : path;
    }
    property var keymap: null

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.keymap = Kbd.parse(text());
            } catch (e) {
                console.warn("kanataLayers: could not parse", root.configPath + ":", e.message);
                root.keymap = null;
            }
        }
        onLoadFailed: err => {
            console.warn("kanataLayers: could not read", root.configPath, err);
            root.keymap = null;
        }
    }

    readonly property real keyUnit: 42
    readonly property real keyGap: 4
    readonly property real keymapWidth: {
        if (!keymap)
            return 400;
        let widest = 0;
        for (const row of keymap.rows) {
            let w = 0;
            for (const k of row)
                w += keyUnit * k.units + keyGap * k.units;
            widest = Math.max(widest, w);
        }
        return widest;
    }
    readonly property real keymapHeight: keymap ? keymap.rows.length * (keyUnit + keyGap) : 200

    horizontalBarPill: Component {
        DankIcon {
            name: "keyboard"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "keyboard"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            property string selected: root.keymap ? root.keymap.layerNames[0] : ""

            headerText: "Kanata layers"
            detailsText: root.keymap ? "" : "Could not read " + root.configPath + ". Check the path in the plugin settings."
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: root.keymap !== null

                Row {
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.keymap ? root.keymap.layerNames : []

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
                                text: modelData
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
                    keymap: root.keymap
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
