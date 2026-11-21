// M$M! arena: the HUD corner brackets - an L at each corner of a panel, drawn over its
// edge. Fill the panel with it (anchors.fill: parent); nothing shows in other palettes.
import QtQuick

Item {
    id: corners
    property color color: Theme.accent
    property int size: Theme.cornerSize
    property real thickness: 1.5
    // Draw them a little outside the panel's border (0) or on it.
    property real inset: 0
    visible: Theme.arena
    // The brackets are decoration: they never take the pointer.
    enabled: false

    Repeater {
        model: [
            { h: 0, v: 0 }, { h: 1, v: 0 }, { h: 0, v: 1 }, { h: 1, v: 1 }
        ]
        delegate: Item {
            required property var modelData
            x: modelData.h === 0 ? corners.inset : corners.width - corners.size - corners.inset
            y: modelData.v === 0 ? corners.inset : corners.height - corners.size - corners.inset
            width: corners.size
            height: corners.size
            Rectangle {
                x: 0
                y: modelData.v === 0 ? 0 : parent.height - corners.thickness
                width: parent.width
                height: corners.thickness
                color: corners.color
            }
            Rectangle {
                x: modelData.h === 0 ? 0 : parent.width - corners.thickness
                y: 0
                width: corners.thickness
                height: parent.height
                color: corners.color
            }
        }
    }
}
