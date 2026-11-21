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

    width: hud ? 76 : 84
    // M$M! arena: a flush HUD strip down the window's left edge - near-black, a cyan
    // hairline on its right, the page shown marked by an accent bar and tint.
    readonly property bool hud: Theme.arena
    radius: hud ? 0 : Theme.rCard
    topLeftRadius: hud ? Theme.rWindow : Theme.rCard
    bottomLeftRadius: hud ? Theme.rWindow : Theme.rCard
    // Frost: deep blue (navy to the accent's blue) with white icons; the other looks: a card.
    readonly property bool deep: Theme.frost
    readonly property color fg: deep ? Qt.rgba(1, 1, 1, 0.78) : Theme.t2
    color: hud ? "#070B12" : Theme.card
    gradient: deep ? railFill : undefined
    Gradient {
        id: railFill
        GradientStop { position: 0; color: "#0C2350" }
        GradientStop { position: 1; color: "#1A56C4" }
    }
    border.width: deep || hud ? 0 : 1
    border.color: Theme.stroke
    Rectangle {
        visible: rail.hud
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.stroke2
    }

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
        anchors.topMargin: rail.hud ? 12 : 14
        anchors.bottomMargin: 12
        spacing: rail.hud ? 2 : 6

        // The logo: back to the start page.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 60
            implicitHeight: 44
            Rectangle {
                anchors.fill: parent
                radius: rail.hud ? 2 : 14
                color: logoHover.hovered ? (rail.deep ? Qt.rgba(1, 1, 1, 0.12) : Theme.ink(0.06)) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.d(150) } }
            }
            Image {
                anchors.centerIn: parent
                // On the deep rail a white wordmark.
                source: rail.deep ? "logo-white.png" : Theme.logoImage
                sourceSize.width: rail.hud ? 56 : 52
                fillMode: Image.PreserveAspectFit
            }
            HoverHandler { id: logoHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: rail.requestPage("home") }
        }
        Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: rail.hud ? 8 : 0; implicitWidth: rail.hud ? 44 : 36; implicitHeight: 1; color: rail.deep ? Qt.rgba(1, 1, 1, 0.18) : Theme.stroke2 }

        Repeater {
            model: rail.items
            delegate: Item {
                id: entry
                required property var modelData
                readonly property bool on: rail.currentPage === modelData.id
                objectName: "rail-" + modelData.id
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: rail.hud ? rail.width - 1 : 68
                implicitHeight: rail.hud ? 60 : 58
                scale: entryTap.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: Theme.d(300); easing.bezierCurve: Theme.spring } }
                Rectangle {
                    anchors.fill: parent
                    radius: rail.hud ? 0 : 16
                    color: entry.on && rail.deep ? "#FFFFFF"
                         : entry.on && rail.hud ? Theme.accentSoft
                         : entryHover.hovered && !entry.on ? (rail.deep ? Qt.rgba(1, 1, 1, 0.12) : Theme.ink(0.05)) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                }
                // Arena: the accent bar on the page shown.
                Rectangle {
                    visible: rail.hud && entry.on
                    x: 0; y: 6
                    width: 3
                    height: parent.height - 12
                    color: Theme.accent
                }
                // The page shown: the accent (its gradient) behind a white icon and name.
                VAccentFill {
                    anchors.fill: parent
                    radius: 16
                    opacity: entry.on && !rail.deep && !rail.hud ? 1 : 0
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
                        color: entry.on ? (rail.deep || rail.hud ? Theme.accent : Theme.accentInk)
                                        : rail.hud && entryHover.hovered ? Theme.t1 : rail.fg
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: entry.modelData.label
                        color: entry.on ? (rail.deep ? "#0C2350" : rail.hud ? Theme.accent : Theme.accentInk)
                             : rail.hud && entryHover.hovered ? Theme.t1 : rail.fg
                        font.family: Theme.fontUi
                        font.pixelSize: rail.hud ? 10 : 11
                        font.weight: entry.on ? Font.DemiBold : Font.Normal
                        font.capitalization: Theme.capsMode
                        font.letterSpacing: Theme.spacing(0.8)
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
                implicitWidth: rail.hud ? 36 : 40
                implicitHeight: rail.hud ? 26 : 30
                Rectangle {
                    anchors.fill: parent
                    radius: rail.hud ? 2 : 15
                    border.width: rail.hud ? 1 : 0
                    border.color: whover.hovered ? (wbtn.modelData.id === "close" ? Theme.err : Theme.accent) : Theme.stroke
                    color: !whover.hovered ? "transparent"
                         : wbtn.modelData.id === "close" ? Qt.rgba(0.9, 0.2, 0.22, rail.deep || rail.hud ? 0.85 : 0.14)
                         : rail.deep ? Qt.rgba(1, 1, 1, 0.14) : Theme.ink(0.07)
                    Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                }
                VIcon {
                    anchors.centerIn: parent
                    name: wbtn.modelData.icon
                    size: 14
                    color: whover.hovered && wbtn.modelData.id === "close" ? (rail.deep || rail.hud ? "#FFFFFF" : Theme.err)
                         : rail.hud && whover.hovered ? Theme.accent : rail.fg
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
