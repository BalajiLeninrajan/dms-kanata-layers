import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "kanataLayers"

    ToggleSetting {
        settingKey: "autoOverlay"
        label: "Show overlay when holding a layer"
        description: "Off means the overlay only appears through the toggle IPC command. Right-clicking the bar pill flips this."
        defaultValue: true
    }

    StringSetting {
        settingKey: "configPath"
        label: "Kanata config"
        description: "The .kbd file kanata runs. The keymap is drawn from its defsrc and deflayer blocks."
        placeholder: "~/.config/kanata/kanata.kbd"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "address"
        label: "Kanata TCP address"
        description: "Whatever you pass to kanata's --port, as PORT or HOST:PORT."
        placeholder: "127.0.0.1:5829"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "overlayLayers"
        label: "Overlay layers"
        description: "Comma-separated layers that pop up the keymap overlay. Empty means every layer except the first."
        placeholder: "util, nav"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "showDelay"
        label: "Overlay delay (ms)"
        description: "How long a layer has to stay active before the overlay appears, so quick holds don't flash it."
        placeholder: "250"
        defaultValue: ""
    }
}
