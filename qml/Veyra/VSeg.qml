import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
Rectangle {
    id: seg
    property var options: []      // [{ id, label }]
    property string current: ""
    signal picked(string id)

    // M$M! arena: no tray and no sliding indicator - each option is its own sharp box,
    // the chosen one outlined and lettered in the accent.
    readonly property bool hud: Theme.arena
    implicitWidth: segRow.implicitWidth + (hud ? 0 : 6)
    implicitHeight: hud ? 28 : 30
    radius: Theme.rCtl
    color: hud ? "transparent" : Theme.ink(0.05)
    border.width: hud ? 0 : 1
    border.color: Theme.stroke

    readonly property int currentIndex: {
        for (var i = 0; i < options.length; ++i)
            if (options[i].id === current) return i
        return -1
    }
    // itemAt() is not a notifying call; reading count re-runs this once the Repeater
    // has built its buttons (otherwise it stays null from the first evaluation).
    readonly property Item currentItem: (segRepeater.count > 0 && currentIndex >= 0) ? segRepeater.itemAt(currentIndex) : null

    // Read by the motion probe (G0.5): where the indicator is, and where it is going.
    readonly property real indicatorX: indicator.x
    readonly property real targetX: currentItem ? segRow.x + currentItem.x : 3

    // .seg-ind: one indicator slides under the chosen button (transform and width,
    // .5s --spring), instead of each button lighting its own background.
    Rectangle {
        id: indicator
        visible: seg.currentItem !== null && !seg.hud
        x: seg.currentItem ? segRow.x + seg.currentItem.x : 3
        y: 3
        width: seg.currentItem ? seg.currentItem.width : 0
        height: 24
        // M$M! frost: the chosen option is a pill in the accent, its label white.
        radius: Theme.light ? 12 : 7
        color: Theme.light ? "transparent" : Theme.card3
        VAccentFill {
            anchors.fill: parent
            radius: parent.radius
            visible: Theme.light
        }
        Behavior on x { NumberAnimation { duration: Theme.d(500); easing.bezierCurve: Theme.spring } }
        Behavior on width { NumberAnimation { duration: Theme.d(500); easing.bezierCurve: Theme.spring } }
        // box-shadow 0 1px 0 rgba(255,255,255,.06) inset: the lit top edge.
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 4; anchors.rightMargin: 4
            height: 1
            color: Theme.ink(0.06)
        }
    }

    // box-shadow 0 4px 10px rgba(0,0,0,.35): card3 alone is the same grey as the seg
    // background, so the shadow is what makes the indicator visible (G1.5).
    MultiEffect {
        source: indicator
        anchors.fill: indicator
        visible: indicator.visible
        shadowEnabled: true
        shadowColor: Theme.light ? Qt.rgba(0.11, 0.45, 0.95, 0.30) : Qt.rgba(0, 0, 0, 0.35)
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
        blurMax: 16
        shadowBlur: 0.625
    }

    RowLayout {
        id: segRow
        anchors.centerIn: parent
        spacing: seg.hud ? 4 : 0
        Repeater {
            id: segRepeater
            model: seg.options
            delegate: Item {
                required property var modelData
                enabled: modelData.disabled !== true
                opacity: enabled ? 1 : 0.4
                readonly property bool chosen: seg.current === modelData.id
                implicitWidth: segContent.implicitWidth + (seg.hud ? 18 : 20)
                implicitHeight: seg.hud ? 28 : 24
                Rectangle {
                    visible: seg.hud
                    anchors.fill: parent
                    radius: 2
                    color: parent.chosen ? Theme.accentSoft : (optHover.hovered ? Theme.ink(0.05) : "transparent")
                    border.width: 1
                    border.color: parent.chosen ? Theme.accent : optHover.hovered ? Theme.stroke2 : Theme.stroke
                    Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                }
                // { id, label, icon? }: the design's 列表 / 节点 toggle carries icons.
                Row {
                    id: segContent
                    anchors.centerIn: parent
                    spacing: 6
                    VIcon {
                        visible: (modelData.icon || "").length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        name: modelData.icon || ""
                        size: 13
                        color: segLabel.color
                    }
                    Text {
                        id: segLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: seg.current === modelData.id ? (seg.hud ? Theme.accent : Theme.light ? Theme.accentInk : Theme.t1) : Theme.t2
                        Behavior on color { ColorAnimation { duration: Theme.d(200) } }
                        font.family: Theme.fontUi
                        font.pixelSize: seg.hud ? 12 : Theme.fsBody
                        font.weight: Font.Medium
                        font.capitalization: Theme.capsMode
                        font.letterSpacing: Theme.spacing(0.8)
                    }
                }
                HoverHandler { id: optHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { enabled: parent.enabled; gesturePolicy: TapHandler.WithinBounds; onTapped: seg.picked(modelData.id) }
            }
        }
    }
}
