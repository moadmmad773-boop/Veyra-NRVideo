import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id: sel
    property string value: ""
    property string displayValue: value
    readonly property bool compactLabel: displayValue !== value
    readonly property var selectedOption: options.find(o => o.label === value) || ({})
    readonly property color valueColor: selectedOption.danger === true ? Theme.err
                                       : selectedOption.gold === true ? Theme.warn : Theme.t1
    property var options: []      // [{ id, label, danger?, gold? }]
    // .pop h6: the design titles a select's menu with the row label (core.js sel()).
    property string title: ""
    signal picked(string id)

    implicitWidth: 150
    implicitHeight: compactLabel ? 30 : Math.max(30, valueLabel.implicitHeight + 8)
    // M$M! arena: a sharp field with a cyan chevron in its own box at the right end.
    readonly property bool hud: Theme.arena
    radius: hud ? 2 : Theme.light ? height / 2 : 9
    color: hud ? (hover.hovered ? Theme.card3 : Theme.card2) : hover.hovered ? Theme.ink(0.09) : Theme.ink(0.05)
    border.width: 1
    border.color: hud ? (hover.hovered ? Theme.accent : Theme.stroke2) : Theme.stroke
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: menu.openAt(sel, "down") }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.light ? 14 : 12
        anchors.rightMargin: sel.hud ? 0 : Theme.light ? 4 : 10
        Text {
            id: valueLabel
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: sel.displayValue
            color: sel.valueColor
            font.family: Theme.fontUi
            font.pixelSize: Theme.fsBody
            font.weight: Font.Medium
            wrapMode: sel.compactLabel ? Text.NoWrap : Text.Wrap
            elide: sel.compactLabel ? Text.ElideRight : Text.ElideNone
        }
        VIcon { visible: !Theme.light && !sel.hud; name: "down"; size: 14; color: Theme.t3 }
        Rectangle {
            visible: sel.hud
            Layout.fillHeight: true
            implicitWidth: 26
            color: "transparent"
            Rectangle { width: 1; height: parent.height; color: Theme.stroke2 }
            VIcon { anchors.centerIn: parent; name: "down"; size: 12; color: Theme.accent }
        }
        Rectangle {
            visible: Theme.light
            implicitWidth: 22; implicitHeight: 22; radius: 11
            color: Theme.accentSoft
            VIcon { anchors.centerIn: parent; name: "down"; size: 12; color: Theme.accent }
        }
    }

    ToolTip.visible: hover.hovered && (sel.compactLabel || valueLabel.truncated)
    ToolTip.delay: 500
    ToolTip.text: sel.value

    VMenu {
        id: menu
        // Default to the enclosing VRow's label, as the design's sel(label, ...) does.
        title: {
            if (sel.title.length > 0) return sel.title
            for (let p = sel.parent; p; p = p.parent)
                if (p instanceof VRow) return p.label
            return ""
        }
        items: sel.options.map(o => ({ label: o.label, checked: o.label === sel.value, disabled: o.disabled === true, danger: o.danger === true, gold: o.gold === true, note: o.note || "" }))
        onPicked: (i, o) => sel.picked(sel.options[i].id)
    }
}
