import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id: sw
    property bool checked: false
    signal toggled(bool checked)
    width: Theme.switchWidth
    height: Theme.switchHeight
    // M$M! arena: a HUD toggle - a sharp box with a square knob and ON / OFF printed in
    // it; on, the box fills with the accent. The other palettes keep the pill.
    readonly property bool hud: Theme.arena
    radius: hud ? 2 : 99
    color: hud ? (checked ? Theme.accent : "transparent")
               : checked ? Theme.accent : Theme.ink(0.14)
    border.width: hud ? 1 : 0
    border.color: checked ? Theme.accent : (hover.hovered ? Theme.accent : Theme.stroke2)
    Behavior on color { ColorAnimation { duration: Theme.d(250) } }
    // The dusk palette's sunset accent: the on track is the gradient, faded in
    // and out with the colour.
    VAccentFill {
        anchors.fill: parent
        radius: parent.radius
        visible: Theme.accentGradient && opacity > 0
        opacity: sw.checked ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(250) } }
    }

    Text {
        visible: sw.hud
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? 6 : parent.width - width - 5
        text: sw.checked ? "ON" : "OFF"
        color: sw.checked ? Theme.accentInk : Theme.t3
        font.family: Theme.fontMono
        font.pixelSize: 9
        font.bold: true
    }

    Rectangle {
        id: knob
        width: sw.hud ? 12 : (tap.pressed ? 18 : Theme.switchKnob)
        height: sw.hud ? 12 : Theme.switchKnob
        radius: sw.hud ? 1 : height / 2
        color: sw.hud ? (sw.checked ? Theme.accentInk : Theme.t3)
                      : sw.checked ? Theme.accentInk : "#FFFFFF"
        border.width: Theme.light && !sw.checked ? 1 : 0
        border.color: Theme.knobRing
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? (parent.width - width - (sw.hud ? 4 : 3)) : (sw.hud ? 4 : 3)
        Behavior on x { NumberAnimation { duration: Theme.d(sw.hud ? 220 : 500); easing.bezierCurve: sw.hud ? Theme.easeOut : Theme.spring } }
        Behavior on width { NumberAnimation { duration: Theme.d(200) } }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    // Controlled: owners bind checked to their model and write the new value back in
    // onToggled. Assigning checked here destroyed that binding, so a value changed
    // elsewhere (a preset, another page) no longer moved the switch (GitHub #29).
    TapHandler { id: tap; gesturePolicy: TapHandler.WithinBounds; onTapped: sw.toggled(!sw.checked) }
}
