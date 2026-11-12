import QtQuick
import qs.Common
import qs.Widgets

// A popout section header: title on the left, device load and held memory on the right.
Item {
    id: header

    property string title
    property string load
    property string memory

    width: parent ? parent.width : 0
    height: Theme.fontSizeMedium + Theme.spacingS

    StyledText {
        text: header.title
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        text: header.load + (header.memory !== "" ? "  ·  " + header.memory : "")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
