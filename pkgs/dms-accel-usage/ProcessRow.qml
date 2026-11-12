import QtQuick
import qs.Common
import qs.Widgets

// One process in the popout: name on the left, memory and busy on the right.
Item {
    id: row

    property string name
    property string memory
    property string busy

    width: parent ? parent.width : 0
    height: Theme.fontSizeSmall + Theme.spacingS

    StyledText {
        text: row.name
        elide: Text.ElideRight
        width: row.width - rightText.width - Theme.spacingM
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        id: rightText
        text: row.memory + (row.busy !== "" ? "   " + row.busy : "")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
