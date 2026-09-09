import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "netStatus"

    StyledText {
        width: parent.width
        text: "Network Status Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Shows one address at a time in the bar. Right-click the widget to cycle between Local, VPN, and (if enabled) Tailscale."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "pollIntervalSec"
        label: "Refresh Interval"
        description: "How often to check interfaces for IP changes"
        defaultValue: 5
        minimum: 2
        maximum: 60
        unit: "sec"
    }

    ToggleSetting {
        settingKey: "compactMode"
        label: "Compact Mode"
        description: "Show only the status icon in the bar, hide the IP text"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showTailscale"
        label: "Include Tailscale"
        description: "Add your Tailscale IP to the right-click rotation (uses DMS's built-in Tailscale status, no extra process)"
        defaultValue: false
    }

    StringSetting {
        settingKey: "vpnPrefixes"
        label: "VPN Interface Prefixes"
        description: "Comma-separated interface name prefixes treated as VPN tunnels (e.g. tun0, wg0)"
        placeholder: "tun,wg,ppp,tap"
        defaultValue: "tun,wg,ppp,tap"
    }

    StringSetting {
        settingKey: "excludePrefixes"
        label: "Excluded Interface Prefixes"
        description: "Comma-separated interface name prefixes to ignore (docker/virtual bridges, etc.)"
        placeholder: "docker,veth,br-,virbr"
        defaultValue: "docker,veth,br-,virbr"
    }

    StyledText {
        width: parent.width
        text: "💡 Left-click opens a popout with all addresses and copy-to-clipboard buttons. Right-click cycles what's shown in the bar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
