import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    property string title: ""
    property string valueText: ""
    property string iconName: "lan"
    property color valueColor: Theme.surfaceText
    property color iconColor: Theme.primary
    property string copyValue: ""
    property bool highlighted: false

    signal copyRequested(string text)

    width: parent ? parent.width : 0
    height: row.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh
    border.width: highlighted ? 1 : 0
    border.color: Theme.withAlpha(valueColor, 0.4)

    Row {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingM
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM * 2 + Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        DankIcon {
            name: root.iconName
            size: Theme.iconSize
            color: root.iconColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            spacing: Theme.spacingXXS
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.title
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: root.valueText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: root.valueColor
            }
        }
    }

    DankIcon {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        name: "content_copy"
        size: Theme.iconSize - 6
        color: copyArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
        visible: root.copyValue !== ""

        MouseArea {
            id: copyArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyRequested(root.copyValue)
        }
    }
}
