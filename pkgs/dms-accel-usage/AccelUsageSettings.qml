import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "accelUsage"

    StyledText {
        width: parent.width
        text: "GPU and NPU usage"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "labelStyle"
        label: "Labels"
        description: "Text in front of each percentage. Without labels the GPU value comes first."
        options: [
            {
                label: "GPU 12%  NPU 0%",
                value: "full"
            },
            {
                label: "G 12%  N 0%",
                value: "short"
            },
            {
                label: "12% · 0%",
                value: "none"
            }
        ]
        defaultValue: "full"
    }

    ToggleSetting {
        settingKey: "showIcon"
        label: "Show icon"
        description: "The chip icon before the numbers"
        defaultValue: true
    }
}
