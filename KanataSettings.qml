import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "kanataLayers"

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
}
