import QtQuick

Text {
    color: Theme.t3
    font.pixelSize: Theme.fsEyebrow
    font.letterSpacing: Theme.arena ? 1.6 : 0.08 * Theme.fsEyebrow
    font.capitalization: Theme.capsMode
    font.family: Theme.arena ? Theme.fontMono : Theme.fontUi
}
