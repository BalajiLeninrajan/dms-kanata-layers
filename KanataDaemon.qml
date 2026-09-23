import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import "kbd.js" as Kbd

// Owns the connection to kanata's TCP server and the parsed config, publishes
// both as plugin global vars for the bar widget, and draws the overlay.
Item {
    id: root

    property var pluginService: null
    property string pluginId: "kanataLayers"

    property var settings: ({})
    readonly property string configPath: expandHome(settings.configPath || "~/.config/kanata/kanata.kbd")
    readonly property string address: settings.address || "127.0.0.1:5829"
    readonly property var overlayLayers: (settings.overlayLayers ?? "").split(",").map(s => s.trim()).filter(s => s)
    readonly property int showDelay: parseInt(settings.showDelay) || 250

    property string currentLayer: ""
    property bool connected: false
    property var keymap: null
    property string pinnedLayer: ""

    // With no layers configured, show every layer except the first (base).
    readonly property bool layerWantsOverlay: {
        if (!keymap || !currentLayer)
            return false;
        if (overlayLayers.length > 0)
            return overlayLayers.indexOf(currentLayer) >= 0;
        return keymap.layerNames.indexOf(currentLayer) > 0;
    }
    readonly property string overlayLayer: pinnedLayer || (layerWantsOverlay ? currentLayer : "")
    property bool overlayShown: false
    // Set on the first keypress while the overlay is up; fades the overlay so
    // it stops covering whatever you're doing with the layer.
    property bool typing: false

    function expandHome(path) {
        return path.startsWith("~/") ? Quickshell.env("HOME") + path.slice(1) : path;
    }

    function loadSettings() {
        if (!pluginService)
            return;
        const keys = ["configPath", "address", "overlayLayers", "showDelay"];
        const next = {};
        for (const k of keys)
            next[k] = pluginService.loadPluginData(pluginId, k, undefined);
        settings = next;
    }

    function publish(name, value) {
        PluginService.setGlobalVar(pluginId, name, value);
    }

    function handleMessage(line) {
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }
        connected = true;
        reconnectTimer.attempt = 0;
        if (msg.LayerChange)
            currentLayer = msg.LayerChange.new;
        else if (msg.CurrentLayerName)
            currentLayer = msg.CurrentLayerName.name;
        else if (msg.ConfigFileReload)
            configFile.reload();
        else if (msg.Error)
            console.warn("kanataLayers: kanata error:", msg.Error.msg);
    }

    function parseConfig(text) {
        try {
            keymap = Kbd.parse(text);
        } catch (e) {
            console.warn("kanataLayers: could not parse", configPath + ":", e.message);
            keymap = null;
        }
    }

    function reconnect() {
        reconnectTimer.attempt = 0;
        conn.running = false;
        reconnectTimer.restart();
    }

    onPluginServiceChanged: loadSettings()
    onCurrentLayerChanged: publish("layer", currentLayer)
    onConnectedChanged: publish("connected", connected)
    onKeymapChanged: publish("keymap", keymap)
    onAddressChanged: reconnect()

    onOverlayShownChanged: {
        if (!overlayShown)
            typing = false;
    }

    onOverlayLayerChanged: {
        if (!overlayLayer) {
            showTimer.stop();
            overlayShown = false;
        } else if (pinnedLayer) {
            overlayShown = true;
        } else if (!overlayShown) {
            showTimer.restart();
        }
    }

    Component.onCompleted: {
        loadSettings();
        publish("address", address);
        conn.running = true;
    }

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedId) {
            if (changedId === root.pluginId)
                root.loadSettings();
        }
    }

    // Quickshell's Socket only speaks Unix sockets and kanata only serves TCP,
    // so bash's /dev/tcp bridges the two. kanata sends the current layer as
    // soon as a client connects.
    Process {
        id: conn

        readonly property var hostPort: {
            const i = root.address.lastIndexOf(":");
            return i < 0 ? ["127.0.0.1", root.address] : [root.address.slice(0, i), root.address.slice(i + 1)];
        }

        command: ["bash", "-c", 'exec 3<>"/dev/tcp/$1/$2" || exit 1; exec cat <&3', "kanata-layers", hostPort[0], hostPort[1]]

        stdout: SplitParser {
            onRead: line => root.handleMessage(line)
        }

        onRunningChanged: {
            if (running)
                return;
            root.connected = false;
            reconnectTimer.restart();
        }
    }

    Timer {
        id: reconnectTimer

        property int attempt: 0

        interval: Math.min(500 * Math.pow(2, attempt), 15000)
        onTriggered: {
            attempt++;
            conn.running = true;
        }
    }

    Timer {
        id: showTimer
        interval: root.showDelay
        onTriggered: root.overlayShown = root.overlayLayer !== ""
    }

    // Kanata swallows the physical keyboard, so keypresses are read off its
    // virtual output device instead. This only runs while the overlay is up,
    // and awk passes on key-down events without the key codes. od prints each
    // 24-byte input_event as 12 u16s: field 9 is the type (1 = EV_KEY) and
    // field 11 the low half of the value (1 = press).
    Process {
        id: keyWatch

        running: root.overlayShown
        command: ["bash", "-c", `
            dev=$(awk '/^N: Name="kanata"/ { f = 1 } f && /^H: / { for (i = 1; i <= NF; i++) if ($i ~ /^event/) { print $i; exit } }' /proc/bus/input/devices)
            [ -n "$dev" ] || exit 1
            # Stopping the Process only signals bash, which would orphan the
            # pipeline and leave od reading the keyboard.
            trap 'pkill -P $$; exit' TERM INT HUP
            stdbuf -oL od -An -v -w24 -tu2 "/dev/input/$dev" | awk '$9 == 1 && $11 == 1 { print "press"; fflush() }' &
            wait
        `]

        stdout: SplitParser {
            onRead: root.typing = true
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseConfig(text())
        onLoadFailed: err => {
            console.warn("kanataLayers: could not read", root.configPath, err);
            root.keymap = null;
        }
    }

    IpcHandler {
        target: "kanataLayers"

        function layer(): string {
            return root.currentLayer;
        }

        // Pins the overlay open on a layer (or the live one when empty), so a
        // compositor bind can peek at any layer without holding it.
        function toggle(name: string): string {
            root.pinnedLayer = root.pinnedLayer ? "" : (name || root.currentLayer);
            return root.pinnedLayer ? "shown " + root.pinnedLayer : "hidden";
        }

        function reload(): string {
            configFile.reload();
            root.reconnect();
            return "reloaded";
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.overlayShown && root.keymap !== null
            color: "transparent"

            WlrLayershell.namespace: "dms:plugins:kanataLayers"
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.bottom: true
            margins.bottom: Theme.spacingL * 4

            implicitWidth: card.width
            implicitHeight: card.height

            // Empty input region: clicks go through to whatever is underneath.
            mask: Region {}

            Rectangle {
                id: card

                width: content.implicitWidth + Theme.spacingL * 2
                height: content.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainer, 1)
                border.width: 1
                border.color: Theme.outlineMedium
                opacity: root.typing ? 0.15 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                    }
                }

                Column {
                    id: content
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    StyledText {
                        text: root.overlayLayer
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                    }

                    KeymapView {
                        keymap: root.keymap
                        layerName: root.overlayLayer
                    }
                }
            }
        }
    }
}
