import QtQuick 2.2
import QtQuick.Controls

TextField {
    placeholderTextColor: config.color
    palette.text: config.color
    font.pointSize: config.fontSize
    font.family: config.font
    width: parent.width
    background: Rectangle {
        // Isla translucida a juego con Waybar/hyprlock
        color: "#8c282828"
        radius: 10
        width: parent.width
        height: width / 9
        border.width: 1
        border.color: parent.focus ? "#4dffffff" : "#14ffffff"
        anchors.fill: parent
    }
}
