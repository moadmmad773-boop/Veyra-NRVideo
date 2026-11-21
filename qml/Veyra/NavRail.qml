// M$M! build: the page menu as a rail down the left edge, always there (the design's top
// dock only dropped down when the pointer touched the top). Logo, the five pages with
// their names, the window buttons at the foot; the empty part moves the window.
// The cinema page and fullscreen keep the dropping dock: the picture takes the window.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: rail
    objectName: "nav-rail"
    required property string currentPage
    property bool maximized: false
    signal requestPage(string page)
    signal requestMinimize()
    signal requestMaximize()
    signal requestClose()
    signal requestMove()

    width: 84
    radius: Theme.rCard
    color: Theme.card
    border.width: 1
    border.color: Theme.stroke

    readonly property var items: [
        { id: "home", icon: "home", label: qsTr("首页") },
        { id: "min",  icon: "tv", label: qsTr("极简") },
        { id: "pro",  icon: "sliders", label: qsTr("专业模式") },
        { id: "exp",  icon: "upload", label: qsTr("导出") },
        { id: "set",  icon: "settings", label: qsTr("设置") }
    ]

    // The empty part of the rail is a title bar: drag to move, double-click to maximise.
    DragHandler { target: null; onActiveChanged: if (active) rail.requestMove() }
    TapHandler { onDoubleTapped: rail.requestMaximize() }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 12
        spacing: 6

        // The logo: back to the start page.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 60
            implicitHeight: 44
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: logoHover.hovered ? Theme.ink(0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.d(150) } }
            }
            Image {
                anchors.centerIn: parent
                source: Theme.logoImage
                sourceSize.width: 52
                fillMode: Image.PreserveAspectFit
            }
            HoverHandler { id: logoHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: rail.requestPage("home") }
        }
        Rectangle { Layout.alignment: Qt.AlignHCenter; implicitWidth: 36; implicitHeight: 1; color: Theme.stroke2 }

        Repeater {
            model: rail.items
            delegate: Item {
                id: entry
                required property var modelData
                readonly property bool on: rail.currentPage === modelData.id
                objectName: "rail-" + modelData.id
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 68
                implicitHeight: 58
                scale: entryTap.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: Theme.d(300); easing.bezierCurve: Theme.spring } }
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: entryHover.hovered && !entry.on ? Theme.ink(0.06) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                }
                // The page shown: the accent (its gradient) behind a white icon and name.
                VAccentFill {
                    anchors.fill: parent
                    radius: 16
                    opacity: entry.on ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.d(200) } }
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    VIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: entry.modelData.icon
                        size: 20
                        strokeWidth: 1.8
                        color: entry.on ? Theme.accentInk : Theme.t2
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: entry.modelData.label
                        color: entry.on ? Theme.accentInk : Theme.t2
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: entry.on ? Font.DemiBold : Font.Normal
                    }
                }
                HoverHandler { id: entryHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: entryTap; gesturePolicy: TapHandler.WithinBounds; onTapped: rail.requestPage(entry.modelData.id) }
            }
        }

        Item { Layout.fillHeight: true }

        // Window buttons, one above the other.
        Repeater {
            model: [
                { id: "min", icon: "minus", tip: qsTr("最小化") },
                { id: "max", icon: "max", tip: rail.maximized ? qsTr("还原") : qsTr("最大化") },
                { id: "close", icon: "x", tip: qsTr("关闭") }
            ]
            delegate: Item {
                id: wbtn
                required property var modelData
                objectName: "rail-window-" + modelData.id
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 40
                implicitHeight: 30
                Rectangle {
                    anchors.fill: parent
                    radius: 15
                    color: !whover.hovered ? "transparent"
                         : wbtn.modelData.id === "close" ? Qt.rgba(0.9, 0.2, 0.22, 0.14) : Theme.ink(0.07)
                    Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                }
                VIcon {
                    anchors.centerIn: parent
                    name: wbtn.modelData.icon
                    size: 14
                    color: whover.hovered && wbtn.modelData.id === "close" ? Theme.err : Theme.t2
                }
                HoverHandler { id: whover; cursorShape: Qt.PointingHandCursor }
                ToolTip.visible: whover.hovered
                ToolTip.text: wbtn.modelData.tip
                ToolTip.delay: 500
                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: wbtn.modelData.id === "min" ? rail.requestMinimize()
                            : wbtn.modelData.id === "max" ? rail.requestMaximize() : rail.requestClose()
                }
            }
        }
    }
}
