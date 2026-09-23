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
}
