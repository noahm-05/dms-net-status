import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "net-status"

    Ref {
        service: TailscaleService
    }

    property int pollIntervalSec: pluginData.pollIntervalSec || 30
    property string vpnPrefixes: pluginData.vpnPrefixes || "tun,wg,ppp,tap"
    property string excludePrefixes: pluginData.excludePrefixes || "docker,veth,br-,virbr"
    property bool compactMode: pluginData.compactMode || false
    property bool showTailscale: pluginData.showTailscale || false
    property string selectedType: pluginData.selectedType || "local"

    property string localIp: ""
    property string localIface: ""
    property string vpnIp: ""
    property string vpnIface: ""
    property bool vpnConnected: false
    property bool hasError: false

    readonly property string tailscaleIp: TailscaleService.selfNode?.tailscaleIp || ""
    readonly property bool tailscaleConnected: TailscaleService.available && TailscaleService.connected && root.tailscaleIp !== ""

    readonly property var availableTypes: {
        const types = ["local", "vpn"];
        if (root.showTailscale)
            types.push("tailscale");
        return types;
    }

    readonly property string displayType: root.availableTypes.includes(root.selectedType) ? root.selectedType : "local"

    readonly property var currentDisplay: {
        if (root.displayType === "vpn")
            return {
                icon: "vpn_lock",
                text: root.vpnConnected ? root.vpnIp : I18n.trFor("netStatus", "VPN off"),
                color: root.vpnConnected ? Theme.success : Theme.error
            };
        if (root.displayType === "tailscale")
            return {
                icon: "device_hub",
                text: root.tailscaleConnected ? root.tailscaleIp : I18n.trFor("netStatus", "Tailscale off"),
                color: root.tailscaleConnected ? Theme.success : Theme.error
            };
        return {
            icon: "lan",
            text: root.localIp || "—",
            color: Theme.primary
        };
    }

    function splitList(csv) {
        return csv.split(",").map(s => s.trim()).filter(s => s.length > 0);
    }

    function refreshNetwork() {
        Proc.runCommand("netStatus.ipaddr", ["ip", "-j", "addr", "show"], (stdout, exitCode) => {
            if (exitCode !== 0) {
                if (!root.hasError)
                    ToastService.showError(I18n.trFor("netStatus", "Network Status"), I18n.trFor("netStatus", "Failed to read network interfaces"));
                root.hasError = true;
                return;
            }

            let ifaces = [];
            try {
                ifaces = JSON.parse(stdout);
            } catch (e) {
                if (!root.hasError)
                    ToastService.showError(I18n.trFor("netStatus", "Network Status"), I18n.trFor("netStatus", "Failed to read network interfaces"));
                root.hasError = true;
                return;
            }

            const vpnPrefixList = root.splitList(root.vpnPrefixes);
            const excludeList = root.splitList(root.excludePrefixes);

            let bestLocal = null;
            let bestVpn = null;

            for (const iface of ifaces) {
                const name = iface.ifname || "";
                if (name === "lo")
                    continue;
                if (excludeList.some(p => name.startsWith(p)))
                    continue;

                const ipv4 = (iface.addr_info || []).find(a => a.family === "inet");
                if (!ipv4)
                    continue;

                const isVpn = vpnPrefixList.some(p => name.startsWith(p));
                const isUp = iface.operstate === "UP";

                if (isVpn) {
                    if (!bestVpn || isUp)
                        bestVpn = {
                            name: name,
                            ip: ipv4.local
                        };
                } else if (!bestLocal || isUp) {
                    bestLocal = {
                        name: name,
                        ip: ipv4.local
                    };
                }
            }

            root.hasError = false;
            root.localIp = bestLocal ? bestLocal.ip : "";
            root.localIface = bestLocal ? bestLocal.name : "";
            root.vpnIp = bestVpn ? bestVpn.ip : "";
            root.vpnIface = bestVpn ? bestVpn.name : "";
            root.vpnConnected = bestVpn !== null;
        }, 100, 5000, root);
    }

    function cycleDisplayType() {
        const types = root.availableTypes;
        if (types.length <= 1)
            return;
        const idx = types.indexOf(root.displayType);
        const next = types[(idx + 1) % types.length];
        root.selectedType = next;
        if (root.pluginService)
            root.pluginService.savePluginData(root.pluginId, "selectedType", next);
    }

    function copyToClipboard(text) {
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", text]);
        ToastService.showInfo(I18n.trFor("netStatus", "Copied %1 to clipboard").arg(text));
    }

    pillRightClickAction: () => root.cycleDisplayType()

    Component.onCompleted: refreshNetwork()

    Timer {
        interval: Math.max(1, root.pollIntervalSec) * 1000
        running: true
        repeat: true
        onTriggered: root.refreshNetwork()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.currentDisplay.icon
                size: Theme.iconSize - 6
                color: root.currentDisplay.color
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.currentDisplay.text
                color: root.currentDisplay.color
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.compactMode
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXXS

            DankIcon {
                name: root.currentDisplay.icon
                size: Theme.iconSize - 6
                color: root.currentDisplay.color
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.currentDisplay.text
                color: root.currentDisplay.color
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.compactMode
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: I18n.trFor("netStatus", "Network Status")
            showCloseButton: true

            Component.onCompleted: root.refreshNetwork()

            headerActions: Component {
                DankIcon {
                    name: "refresh"
                    size: Theme.iconSize - 6
                    color: refreshArea.containsMouse ? Theme.primary : Theme.surfaceVariantText

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshNetwork()
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: contentColumn.implicitHeight

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.spacingM

                    NetStatusAddressRow {
                        title: I18n.trFor("netStatus", "Local Machine")
                        valueText: root.localIp ? (root.localIp + "  (" + root.localIface + ")") : I18n.trFor("netStatus", "No address found")
                        iconName: "lan"
                        iconColor: Theme.primary
                        valueColor: Theme.surfaceText
                        copyValue: root.localIp
                        onCopyRequested: text => root.copyToClipboard(text)
                    }

                    NetStatusAddressRow {
                        title: I18n.trFor("netStatus", "VPN Tunnel")
                        valueText: root.vpnConnected ? (root.vpnIp + "  (" + root.vpnIface + ")") : I18n.trFor("netStatus", "Not connected")
                        iconName: "vpn_lock"
                        iconColor: root.vpnConnected ? Theme.success : Theme.error
                        valueColor: root.vpnConnected ? Theme.success : Theme.error
                        copyValue: root.vpnConnected ? root.vpnIp : ""
                        highlighted: true
                        onCopyRequested: text => root.copyToClipboard(text)
                    }

                    NetStatusAddressRow {
                        visible: root.showTailscale
                        title: I18n.trFor("netStatus", "Tailscale")
                        valueText: {
                            if (!TailscaleService.available)
                                return I18n.trFor("netStatus", "Not available");
                            return root.tailscaleConnected ? root.tailscaleIp : I18n.trFor("netStatus", "Not connected");
                        }
                        iconName: "device_hub"
                        iconColor: root.tailscaleConnected ? Theme.success : Theme.error
                        valueColor: root.tailscaleConnected ? Theme.success : Theme.error
                        copyValue: root.tailscaleConnected ? root.tailscaleIp : ""
                        highlighted: true
                        onCopyRequested: text => root.copyToClipboard(text)
                    }
                }
            }
        }
    }

    popoutWidth: 340
    popoutHeight: 280
}
