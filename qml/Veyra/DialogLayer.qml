// Shared dialog presentation; extracted without changing geometry or motion.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: dlg
    required property Item dialogHost
    property string title: ""
    property string sub: ""
    property string glyph: ""
    property int dialogWidth: 640
    readonly property real bodyWidth: Math.max(1, width - 40)
    property var actions: []
    // dialogs.js `foot`: a quiet note at the left of the button row.
    property string foot: ""
    default property alias body: bodyCol.data
    signal actionTriggered(string label)
    readonly property alias bodyViewport: bodyScroll
    readonly property Item primaryAction: {
        for (let i = 0; i < actionButtons.count; ++i) {
            const button = actionButtons.itemAt(i)
            if (button && button.primary) return button
        }
        return null
    }
    property bool instantTransition: false

    // Which dialog key shows this layer.
    property string key: ""
    readonly property bool shown: key.length > 0 && dialogHost.dialog === key
    // M17: .dlg scale .9 -> 1 and translate 0 14px -> 0 over .55s --spring inside the
    // scrim's .2s fade; closing runs the same back while the scrim fades out.
    property real motionS: 0.9
    property real motionDy: 14
    onShownChanged: {
        if (instantTransition) {
            enterAnim.stop()
            exitAnim.stop()
            motionS = 1
            motionDy = 0
            if (shown) dialogHost.motionScale = 1
        } else if (shown) {
            motionS = 0.9
            motionDy = 14
            enterAnim.restart()
        } else {
            exitAnim.restart()
        }
    }
    onMotionSChanged: if (shown) dialogHost.motionScale = motionS
    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: dlg; property: "motionS"; to: 1; duration: Theme.d(550); easing.bezierCurve: Theme.spring }
        NumberAnimation { target: dlg; property: "motionDy"; to: 0; duration: Theme.d(550); easing.bezierCurve: Theme.spring }
    }
    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: dlg; property: "motionS"; to: 0.9; duration: Theme.d(550); easing.bezierCurve: Theme.spring }
        NumberAnimation { target: dlg; property: "motionDy"; to: 14; duration: Theme.d(550); easing.bezierCurve: Theme.spring }
    }
    opacity: shown ? 1 : 0
    visible: opacity > 0
    // A closed dialog leaves the scene. Its live bindings (capture preview, fps text)
    // kept changing while hidden and Qt redrew the window for each change, ~40 times
    // a second during capture; OBS game capture then held the UI instead of the video.
    // Keyed on shown/opacity, never on visible: an item without a parent always
    // reads invisible, so "visible ? host : null" never brought a dialog back.
    parent: (shown || opacity > 0) ? dialogHost : null
    Behavior on opacity {
        enabled: !dlg.instantTransition
        NumberAnimation { duration: Theme.d(200) }
    }
    transform: [
        Scale { origin.x: dlg.width / 2; origin.y: dlg.height / 2; xScale: dlg.motionS; yScale: dlg.motionS },
        Translate { y: dlg.motionDy }
    ]
    // Cut out of the native video window (main.cpp syncVideoCovers). The flag,
    // not the objectName: each dialog below names itself for tests.
    objectName: "videoCover"
    readonly property bool videoCover: true
    property real coverRadius: 16

    // Centred by position, not anchors: the parent is null while closed.
    x: Math.round((dialogHost.width - width) / 2)
    y: Math.round((dialogHost.height - height) / 2)
    width: Math.max(1, Math.min(dialogWidth, dialogHost.width - 24))
    // Never taller than the window: the body scrolls instead of the panel
    // being cut off at the top and bottom of a small window.
    // Header and footer each carry 16px margins top and bottom (64 in all); the
    // old +40 left every body 24px short, so short dialogs hid their last row.
    implicitHeight: Math.min(720, dialogHost.height - 24,
                             header.implicitHeight + bodyScroll.contentHeight + footer.implicitHeight + 64)
    height: implicitHeight
    // Swallow presses on the panel itself so they never reach the scrim
    // below (a passive tap on a control used to close the whole dialog).
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; z: -1 }
    radius: Theme.frost ? 24 : 16
    color: Theme.dialog
    border.width: Theme.frost ? 0 : 1
    border.color: Theme.stroke2

    // M$M! frost: the title sits on a deep blue band across the top.
    Rectangle {
        visible: Theme.frost
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: header.implicitHeight + 32
        topLeftRadius: dlg.radius
        topRightRadius: dlg.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#0C2350" }
            GradientStop { position: 0.6; color: "#1A56C4" }
            GradientStop { position: 1; color: "#36B6FF" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            id: header
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 12
            Rectangle {
                implicitWidth: 34; implicitHeight: 34; radius: Theme.frost ? 17 : 10
                color: Theme.frost ? Qt.rgba(1, 1, 1, 0.18) : Theme.ink(0.06)
                VIcon { anchors.centerIn: parent; name: dlg.glyph; color: Theme.frost ? "#FFFFFF" : Theme.t1 }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    // Fill: without a subtitle this is the column's only child, and
                    // its natural width would cap the column and pull the close
                    // button in beside the title.
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: dlg.title
                    color: Theme.frost ? "#FFFFFF" : Theme.t1
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fsH2
                    font.weight: Font.DemiBold; font.variableAxes: Theme.axesDemiBold
                }
                Text {
                    Layout.fillWidth: true
                    visible: dlg.sub.length > 0
                    text: dlg.sub
                    color: Theme.frost ? Qt.rgba(1, 1, 1, 0.8) : Theme.t3
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
            VButton { visible: !Theme.frost; icon: true; iconName: "x"; ghost: true; onClicked: dialogHost.close() }
            // Frost: a white close button on the band.
            Rectangle {
                visible: Theme.frost
                implicitWidth: 32; implicitHeight: 32; radius: 16
                color: closeHover.hovered ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.14)
                VIcon { anchors.centerIn: parent; name: "x"; size: 14; color: "#FFFFFF" }
                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: dialogHost.close() }
            }
        }

        Flickable {
            id: bodyScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            // Very narrow film windows still need access to fixed-width device
            // address and format controls. Keep the header and actions in view.
            contentWidth: dlg.width < 520 ? Math.max(dlg.bodyWidth, dlg.dialogWidth - 40) : dlg.bodyWidth
            contentHeight: bodyCol.implicitHeight + (contentWidth > dlg.bodyWidth ? 12 : 0)
            flickableDirection: Flickable.AutoFlickIfNeeded
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: VScrollBar { }
            ScrollBar.horizontal: VScrollBar { wide: true }
            ColumnLayout {
                id: bodyCol
                // Keep the groups clear of the overlaid scroll bar.
                width: Math.max(1, bodyScroll.contentWidth - 12)
                spacing: 0
            }
        }

        RowLayout {
            id: footer
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 8
            Text {
                objectName: "dialog-foot"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: dlg.foot.length > 0
                text: dlg.foot
                color: Theme.t3
                font.family: Theme.fontUi
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Item { Layout.fillWidth: true; visible: dlg.foot.length === 0 }
            Repeater {
                id: actionButtons
                model: dlg.actions
                delegate: VButton {
                    required property var modelData
                    Layout.maximumWidth: Math.max(0, (dlg.width - 32 - Math.max(0, actionButtons.count - 1) * footer.spacing)
                        / Math.max(1, actionButtons.count))
                    text: modelData.label
                    iconName: modelData.icon || ""
                    primary: modelData.primary === true
                    onClicked: dlg.actionTriggered(modelData.label)
                }
            }
        }
    }
}
