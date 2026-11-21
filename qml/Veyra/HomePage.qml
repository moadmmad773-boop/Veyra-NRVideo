// 首页, rebuilt from the design (pages-a.js PAGES.home + pages.css .home).
//
// The design is: a large logo, a two-line greeting, a 4-up grid of source cards
// (164x124 each), a "continue last capture" row, and a row of recent chips.
// The logo in the dock returns here; there is no other home affordance.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

VPage {
    id: root
    signal requestPage(string page)
    signal requestOnboarding()
    readonly property Item onboardingEntry: guideEntry
    readonly property alias sourceViewport: homeScroll
    readonly property bool compact: height < 500
    // M$M! frost: its own start page - a banner, then the sources as wide tiles in three
    // columns (the design's centred logo, greeting and row of small cards are not shown).
    readonly property bool fresh: Theme.frost
    readonly property real freshWidth: Math.min(1060, root.width - 64)
    function captureCard() {
        for (let i = 0; i < sourceCards.count; ++i) {
            const slot = sourceCards.itemAt(i)
            if (slot && slot.modelData.act === "capture") return slot.card
        }
        return null
    }
    // The coffee line under the title: Main opens 设置 → 赞助作者.
    signal requestSponsor()
    // Main.qml keeps the dusk wordmark hidden while the startup intro (DuskIntro.qml) flies a
    // copy of it in, and aims that copy at this item.
    property bool introHold: false
    readonly property Item wordmarkItem: wordmark

    Flickable {
        id: homeScroll
        objectName: "source-card-scroll"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: guideRow.top
        anchors.bottomMargin: 8
        contentWidth: width
        contentHeight: Math.max(height, homeContent.implicitHeight + 24)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: VScrollBar { }
    }

    ColumnLayout {
        id: homeContent
        parent: homeScroll.contentItem
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(root.compact ? 8 : 12, Math.round((homeScroll.height - height) / 2))
        spacing: root.compact ? 8 : 24

        // .home .mark: 128px wide, drop-shadow(0 0 20px rgba(255,255,255,.35)) and the
        // 4.5s "breathe" loop: at 50% the glow is 30px at .55 and the mark scales 1.02.
        // MultiEffect blur is 0..1 of blurMax (32px): 20px = .625, 30px = .94.
        // The layer is padded 40px on every side so the glow has room (a layer on the
        // bare image clips the shadow to the image's own bounds). Negative margins
        // keep the layout the same as a plain 128px image.
        // The M$M! banner: name, what it does, the playlist and address buttons.
        Rectangle {
            id: hero
            objectName: "home-hero"
            visible: root.fresh
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.freshWidth
            implicitHeight: root.compact ? 96 : 196
            radius: 26
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#0C2350" }
                GradientStop { position: 0.55; color: "#1A56C4" }
                GradientStop { position: 1; color: "#36B6FF" }
            }
            // Rings, all inside the banner (its corners are round, a clip would not be).
            Rectangle { x: parent.width - 250; y: 22; width: 150; height: 150; radius: 75; color: "transparent"; border.width: 22; border.color: Qt.rgba(1, 1, 1, 0.08); visible: !root.compact }
            Rectangle { x: parent.width - 120; y: parent.height - 92; width: 70; height: 70; radius: 35; color: Qt.rgba(1, 1, 1, 0.10); visible: !root.compact }
            Rectangle { x: parent.width - 330; y: parent.height - 52; width: 28; height: 28; radius: 14; color: Qt.rgba(1, 1, 1, 0.16); visible: !root.compact }
            VIcon {
                x: parent.width - 200; y: (parent.height - height) / 2
                visible: !root.compact
                name: "sparkles"
                size: 64
                strokeWidth: 1.4
                color: Qt.rgba(1, 1, 1, 0.55)
            }
            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? 22 : 36
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 22 : 300
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.compact ? 2 : 6
                Text {
                    text: "M$M!"
                    color: "#FFFFFF"
                    font.family: Theme.fontUi
                    font.pixelSize: root.compact ? 30 : 56
                    font.weight: Font.Bold
                    font.variableAxes: ({ "wght": 700 })
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("采集 · 画质增强 · 实时翻译")
                    color: Qt.rgba(1, 1, 1, 0.86)
                    font.family: Theme.fontUi
                    font.pixelSize: root.compact ? 13 : 17
                    elide: Text.ElideRight
                }
                Row {
                    visible: !root.compact
                    Layout.topMargin: 10
                    spacing: 10
                    HeroButton { objectName: "home-playlist"; glyph: "list"; text: qsTr("播放列表 · 导入文件夹"); onClicked: veyra.showPlaylist() }
                    HeroButton { objectName: "home-network"; glyph: "cast"; text: qsTr("播放地址…"); onClicked: veyra.openNetworkDialog() }
                }
            }
        }
        Text {
            visible: root.fresh
            Layout.preferredWidth: root.freshWidth
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: root.compact ? 0 : 6
            text: qsTr("选择片源")
            color: Theme.t1
            font.family: Theme.fontUi
            font.pixelSize: root.compact ? 14 : 20
            font.weight: Font.DemiBold; font.variableAxes: Theme.axesDemiBold
        }

        Item {
            id: mark
            visible: !Theme.dusk && !root.fresh
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -40
            Layout.bottomMargin: -40
            implicitWidth: logoImg.implicitWidth + 80
            implicitHeight: logoImg.implicitHeight + 80
            property real breath: 0
            scale: 1 + 0.02 * breath
            // Only while the home page shows: running behind other pages it redrew the whole
            // window every vsync during playback (~300 presents/s on a 320 Hz screen), which
            // cost GPU time and kept OBS game capture on the UI instead of the video.
            SequentialAnimation on breath {
                running: !Theme.reduced && mark.visible
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: Theme.d(2250); easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: Theme.d(2250); easing.type: Easing.InOutSine }
            }
            Image {
                id: logoImg
                anchors.centerIn: parent
                source: Theme.logoImage
                sourceSize.width: root.compact ? 42 : 128
                fillMode: Image.PreserveAspectFit
            }
            // A sibling MultiEffect, not layer.effect: Qt recreates a layer's effect item on
            // a screen DPI change while it walks the parent's children, and the walk then touched
            // the deleted item (crash moving the window to a 200 % monitor, field 2026-10-01).
            MultiEffect {
                source: logoImg
                anchors.fill: logoImg
                shadowEnabled: true
                // The dusk logo carries its own neon glow; the breath adds a pink one to it.
                shadowColor: Theme.frost ? "#4FB2FF" : Theme.sky ? "#7CC6FF" : Theme.dusk ? "#F396CE" : "#FFFFFF"
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 64
                shadowBlur: 0.625 + 0.3125 * mark.breath
                shadowOpacity: (Theme.dusk ? 0.22 : 0.35) + 0.2 * mark.breath
            }
        }

        // 日落: the user's wordmark (tools/qt_probe/make-wordmark-dusk.py) in place of the gamepad
        // and the title, a baked glow breathing behind it (the software scene graph draws no
        // MultiEffect). 0.24 of the page height, 130..210 px, so short windows keep the cards.
        Item {
            id: duskMark
            visible: Theme.dusk
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: wordmark.width
            implicitHeight: wordmark.height
            property real breath: 0
            // Only while it shows, as the gamepad's breath (see above).
            SequentialAnimation on breath {
                running: !Theme.reduced && duskMark.visible && !root.introHold
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: Theme.d(2250); easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: Theme.d(2250); easing.type: Easing.InOutSine }
            }
            Image {
                // wordmark-dusk-glow.png is the wordmark's box grown by 186/1164 of its width.
                readonly property real pad: wordmark.width * 186 / 1164
                x: -pad
                y: -pad
                width: wordmark.width + 2 * pad
                height: wordmark.height + 2 * pad
                source: "wordmark-dusk-glow.png"
                opacity: root.introHold ? 0 : 0.16 + 0.14 * duskMark.breath
            }
            Image {
                id: wordmark
                objectName: "home-wordmark"
                height: Math.round(root.compact ? Math.min(90, root.height * 0.15)
                                               : Math.max(130, Math.min(210, root.height * 0.24)))
                width: Math.round(height * 1164 / 969)
                source: "wordmark-dusk.png"
                sourceSize: Qt.size(width, height)
                opacity: root.introHold ? 0 : 1
            }
        }

        // .hello: .h1 plus a muted line. The line asks for a coffee; the whole of it
        // opens the sponsor section of 设置.
        ColumnLayout {
            id: hello
            visible: !root.fresh
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: !Theme.dusk                    // the dusk wordmark says it
                text: "M$M!"
                color: Theme.t1
                font.family: Theme.fontUi
                font.pixelSize: Theme.fsH1
                font.weight: Font.DemiBold; font.variableAxes: Theme.axesDemiBold
            }
            Item {
                id: sponsorLine
                objectName: "home-sponsor"
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: sponsorRow.implicitWidth
                implicitHeight: sponsorRow.implicitHeight
                Row {
                    id: sponsorRow
                    spacing: 5
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("本软件开源免费，如果对你有帮助，你可以 →")
                        color: sponsorHover.hovered ? Theme.t1 : Theme.t2
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.fsBody
                    }
                    VIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "coffee"
                        size: 14
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("请作者喝杯咖啡")
                        color: Theme.accent
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.Medium
                        font.underline: sponsorHover.hovered
                    }
                }
                HoverHandler { id: sponsorHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        veyra.logUi("ui-sponsor", "home link")
                        root.requestSponsor()
                    }
                }
            }
        }

        VButton {
            visible: !root.fresh
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("播放列表 · 导入文件夹"); iconName: "list"
            onClicked: veyra.showPlaylist()
        }

        // .srcgrid: 164px cards, gap 12. Six cards since PC and Xbox streaming (1044 wide,
        // fits a 1280 window); a narrower window wraps them onto a second row.
        Flow {
            id: srcGrid
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.fresh ? root.freshWidth : Math.min(1044, root.width - 48)
            spacing: root.compact ? 8 : root.fresh ? 14 : 12
            // Fresh: three wide tiles a row, the icon beside the name.
            readonly property bool wide: root.fresh && !root.compact
            readonly property int cardWidth: wide ? Math.floor((Layout.preferredWidth - 2 * spacing) / 3)
                : root.compact
                ? Math.max(1, Math.min(164, Math.floor((Layout.preferredWidth - 5 * spacing) / 6))) : 164
            readonly property int cardHeight: wide ? 96 : root.compact ? 80 : 124
            // Subtitles name what is really there: the device of the last capture
            // session and the saved PS5 host; generic wording when there is none.
            // Only the subtitle follows the live state. The cards themselves are a fixed
            // list: when the whole array was one binding, every Xbox / PC state change
            // (polling after sign-in) destroyed and rebuilt all six cards, and a click
            // landing during the rebuild was lost (field report 2026-10-02).
            function cardSub(act) {
                switch (act) {
                case "file": return qsTr("MP4 · MKV · 图片")
                case "capture": return veyra.hasCaptureSession ? veyra.captureSessionSummary.split(" · ")[0] : qsTr("HDMI 采集设备")
                case "ps5": return veyra.remotePlayHost.length > 0 ? qsTr("已保存主机 ") + veyra.remotePlayHost : qsTr("局域网串流")
                case "moonlight": return veyra.moonlight && veyra.moonlight.state.lastLabel ? veyra.moonlight.state.lastLabel : qsTr("Sunshine 主机")
                case "xbox": return veyra.xbox && veyra.xbox.state.lastLabel ? veyra.xbox.state.lastLabel : qsTr("账号登录 · 实验")
                default: return qsTr("窗口或显示器")
                }
            }
            Repeater {
                id: sourceCards
                // M$M! frost: each source has its own colour (hue) for its icon tile.
                model: [
                    { glyph: "folder", title: qsTr("打开视频"), act: "file", hue: "#3B82F6" },
                    { glyph: "video", title: qsTr("采集卡"), act: "capture", hue: "#0EA5A0" },
                    { glyph: "gamepad", title: qsTr("PS5 串流"), act: "ps5", hue: "#5B5CF0" },
                    { glyph: "cast", title: qsTr("PC 串流"), act: "moonlight", hue: "#F59E0B" },
                    { glyph: "gamepad", title: qsTr("Xbox 串流"), act: "xbox", hue: "#16A34A" },
                    { glyph: "monitor", title: qsTr("屏幕捕获"), act: "screen", hue: "#E0457B" }
                ]
                // The layout owns the slot's position, so the card inside it is free to
                // move its own y for the hover lift (a y set on a layout child is
                // overwritten); the entrance rise goes on the slot.
                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property alias card: srcCard
                    implicitWidth: srcGrid.cardWidth
                    implicitHeight: srcGrid.cardHeight
                    VRise { page: root; target: slot; d: 2 + slot.index }
                  Rectangle {
                    id: srcCard
                    readonly property var modelData: slot.modelData
                    // .srccard: 164x124, radius 14, content pinned top and bottom.
                    width: slot.width
                    height: slot.height
                    radius: srcGrid.wide ? 22 : Theme.rCard
                    color: cardHover.hovered ? Theme.card2 : Theme.card
                    border.width: srcGrid.wide && cardHover.hovered ? 2 : 1
                    border.color: srcGrid.wide && cardHover.hovered ? srcCard.modelData.hue
                                : cardHover.hovered ? Theme.stroke2 : Theme.stroke
                    // .srccard:hover { transform: translateY(-4px) }
                    y: cardHover.hovered ? -4 : 0
                    Behavior on y { NumberAnimation { duration: Theme.d(500); easing.bezierCurve: Theme.spring } }
                    scale: cardTap.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.d(500); easing.bezierCurve: Theme.spring } }

                    // One column (icon over the name) or, wide, two (icon beside it).
                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: root.compact ? 8 : srcGrid.wide ? 18 : 14
                        columns: srcGrid.wide ? 3 : 1
                        columnSpacing: 16
                        rowSpacing: 0
                        Rectangle {
                            Layout.alignment: srcGrid.wide ? Qt.AlignVCenter : Qt.AlignLeft | Qt.AlignTop
                            // .srccard .ico: 34x34, radius 10, translucent plate. Frost: a
                            // 40px tile in the source's colour, its icon white.
                            implicitWidth: srcGrid.wide ? 54 : Theme.light && !root.compact ? 40 : 34
                            implicitHeight: implicitWidth
                            radius: srcGrid.wide ? 17 : Theme.light ? 13 : 10
                            color: Theme.light ? srcCard.modelData.hue : Theme.ink(0.06)
                            // A soft light from the top (fixed stops: a gradient bound to the
                            // card's own colour did not draw on the CI screenshots).
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                visible: Theme.light
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.28) }
                                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                                }
                            }
                            VIcon {
                                anchors.centerIn: parent
                                name: modelData.glyph
                                size: srcGrid.wide ? 24 : Theme.light ? 19 : 16
                                color: Theme.light ? "#FFFFFF" : Theme.t1
                            }
                        }
                        Item { Layout.fillHeight: true; visible: !srcGrid.wide }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                elide: Text.ElideRight
                                id: sourceTitle
                                text: modelData.title
                                color: Theme.t1
                                font.family: Theme.fontUi
                                font.pixelSize: srcGrid.wide ? 17 : Theme.light ? 14 : Theme.fsBody
                                font.weight: Theme.light ? Font.DemiBold : Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                elide: Text.ElideRight
                                id: sourceSubtitle
                                text: srcGrid.cardSub(modelData.act)
                                color: Theme.t3
                                font.family: Theme.fontUi
                                font.pixelSize: srcGrid.wide ? 13 : Theme.fsSmall
                            }
                        }
                        // Wide tiles: an arrow in the source's colour at the right.
                        Rectangle {
                            visible: srcGrid.wide
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 30; implicitHeight: 30; radius: 15
                            color: cardHover.hovered ? srcCard.modelData.hue : Theme.ink(0.05)
                            Behavior on color { ColorAnimation { duration: Theme.d(150) } }
                            VIcon { anchors.centerIn: parent; name: "right"; size: 14; color: cardHover.hovered ? "#FFFFFF" : Theme.t3 }
                        }
                    }
                    // PS5 手柄控制 is switched on for the capture card.
                    VTag {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 12
                        visible: modelData.act === "capture" && veyra.ps5Control.enabled === true
                        text: qsTr("PS5 手柄")
                        kind: "acc"
                    }
                    HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
                    ToolTip.visible: cardHover.hovered && (sourceTitle.truncated || sourceSubtitle.truncated)
                    ToolTip.text: sourceTitle.text + " · " + sourceSubtitle.text
                    TapHandler {
                        id: cardTap
                        onTapped: {
                            veyra.logUi("ui-source", "home card act=" + modelData.act)
                            switch (modelData.act) {
                            case "file": veyra.openFileDialog(); break
                            case "capture": veyra.openCaptureDialog(); break
                            case "ps5": veyra.openPs5Dialog(); break
                            case "moonlight": veyra.openMoonlightDialog(); break
                            case "xbox": veyra.openXboxDialog(); break
                            case "screen": veyra.openScreenCaptureDialog(); break
                            }
                        }
                    }
                  }
                }
            }
        }

        VButton {
            visible: !root.fresh
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("播放地址…")
            iconName: "cast"
            onClicked: veyra.openNetworkDialog()
        }

        // .resume: 692 wide, an accent-tinted gradient plate, shown only when a
        // capture session was actually used before. Nothing invented: the text is
        // the recorded session, and the row is absent when there is none.
        Rectangle {
            id: resume
            objectName: "home-resume"
            Layout.alignment: Qt.AlignHCenter
            // The last source actually used: capture card, PS5 or screen capture.
            readonly property var last: veyra.lastSource
            visible: last.kind !== undefined
            implicitWidth: srcGrid.width
            implicitHeight: 54
            radius: 14
            border.width: 1
            border.color: Theme.stroke
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.accentSoft }
                GradientStop { position: 1.0; color: Theme.ink(0.03) }
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 14
                Rectangle {
                    implicitWidth: 34; implicitHeight: 34; radius: 10
                    color: Theme.accentSoft
                    VIcon {
                        anchors.centerIn: parent
                        name: resume.last.kind === "screen" ? "monitor" : resume.last.kind === "capture" ? "video" : "gamepad"
                        color: Theme.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: qsTr("继续上次")
                        color: Theme.t1
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.DemiBold; font.variableAxes: Theme.axesDemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: resume.last.summary || ""
                        color: Theme.t2
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
                VButton {
                    text: qsTr("开始")
                    iconName: "play"
                    primary: true
                    onClicked: veyra.resumeLastSource()
                }
            }
        }

        // .recent: 692 wide, left-aligned, wrapping; "最近" in --v-t3 then 28px chips
        // with a film/image icon. Present only when there are recent files; a chip
        // whose file is gone is dimmed and does nothing (clicking it cannot open it).
        // Custom: a "清空" action sits at the right edge of this block, so it lines up
        // with 继续上次's "开始" button above it, and it wears the same primary button.
        // Anchored Item rather than a layout: the chips' own width is what a layout
        // would use for its implicit size, and the long file names then widened the
        // whole column and pushed the button out of line.
        // It confirms first, because the list is a convenience the user may still want.
        Item {
            id: recentBlock
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: srcGrid.width
            implicitHeight: recent.height
            Layout.preferredHeight: implicitHeight
            visible: veyra.recentFiles.length > 0
            Flow {
                id: recent
                anchors.left: parent.left
                anchors.right: clearRecent.left
                anchors.rightMargin: 12
                anchors.top: parent.top
                spacing: 8
                Text {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("最近")
                    color: Theme.t3
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }
                Repeater {
                    model: veyra.recentFiles
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool isImage: /\.(png|jpe?g|bmp|webp|tiff?)$/i.test(modelData.path)
                    width: Math.min(recent.width, chipRow.implicitWidth + 22)
                    height: 28
                    radius: 99
                    opacity: modelData.exists ? 1 : 0.45
                    color: chipHover.hovered && modelData.exists ? Theme.ink(0.08) : Theme.ink(0.04)
                    border.width: 1
                    border.color: Theme.stroke
                    RowLayout {
                        id: chipRow
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        spacing: 7
                        VIcon {
                            name: chip.isImage ? "image" : "film"
                            size: 14
                            color: chipText.color
                        }
                        Text {
                            id: chipText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            elide: Text.ElideMiddle
                            text: modelData.label
                            color: chipHover.hovered && modelData.exists ? Theme.t1 : Theme.t2
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }
                    }
                    ToolTip.visible: chipHover.hovered && (!modelData.exists || chipText.truncated)
                    ToolTip.text: modelData.exists ? modelData.label : qsTr("文件已不存在")
                    HoverHandler { id: chipHover; cursorShape: modelData.exists ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    TapHandler { onTapped: if (modelData.exists) veyra.openPath(modelData.path) }
                }
            }
            }
            VButton {
                id: clearRecent
                objectName: "home-clear-recent"
                // Same right inset as the resume card's own row (10), so this button's
                // right edge lands exactly on 开始's.
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                text: qsTr("清空")
                iconName: "trash"
                primary: true
                tip: qsTr("只清空这个列表，不会删除文件。")
                onClicked: clearRecentConfirm.open()
            }
        }
    }

    Row {
        id: guideRow
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 4
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("第一次使用？")
            color: Theme.t2
            font.family: Theme.fontUi
            font.pixelSize: Theme.fsBody
        }
        VButton {
            id: guideEntry
            objectName: "home-onboarding"
            text: qsTr("查看新手引导")
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            Keys.onSpacePressed: clicked()
            border.width: activeFocus ? 2 : 1
            border.color: activeFocus ? Theme.accent : Theme.stroke2
            onClicked: {
                forceActiveFocus()
                root.requestOnboarding()
            }
        }
    }

    // A glass pill on the banner.
    component HeroButton: Rectangle {
        id: hb
        property string glyph: ""
        property string text: ""
        signal clicked()
        implicitWidth: hbRow.implicitWidth + 30
        implicitHeight: 38
        radius: 19
        color: hbHover.hovered ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35)
        Behavior on color { ColorAnimation { duration: Theme.d(150) } }
        scale: hbTap.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: Theme.d(300); easing.bezierCurve: Theme.spring } }
        Row {
            id: hbRow
            anchors.centerIn: parent
            spacing: 8
            VIcon { anchors.verticalCenter: parent.verticalCenter; name: hb.glyph; size: 15; color: "#FFFFFF" }
            Text { anchors.verticalCenter: parent.verticalCenter; text: hb.text; color: "#FFFFFF"; font.family: Theme.fontUi; font.pixelSize: 14; font.weight: Font.Medium }
        }
        HoverHandler { id: hbHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: hbTap; onTapped: hb.clicked() }
    }

    // Fresh: the coffee line at the foot, right (the greeting that carried it is not shown).
    Item {
        visible: root.fresh
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 18
        implicitWidth: footSponsor.implicitWidth
        implicitHeight: footSponsor.implicitHeight
        Row {
            id: footSponsor
            spacing: 5
            VIcon { anchors.verticalCenter: parent.verticalCenter; name: "coffee"; size: 13; color: Theme.accent }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("请作者喝杯咖啡")
                color: footHover.hovered ? Theme.accent : Theme.t3
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.underline: footHover.hovered
            }
        }
        HoverHandler { id: footHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: { veyra.logUi("ui-sponsor", "home foot"); root.requestSponsor() } }
    }

    // [data-in] entrance order from pages-a.js (the source cards rise from their delegate, --d 2-5).
    VRise { target: hero; d: 0 }
    VRise { target: mark; d: 0 }
    VRise { target: hello; d: 1 }
    VRise { target: resume; d: 6 }
    VRise { target: recent; d: 7 }

    // Custom: clearing the home page's recent list. It only drops the history (the
    // files stay on disk), so the question says so, and the accept button repeats
    // the action word from the button that opened it.
    VConfirm {
        id: clearRecentConfirm
        objectName: "home-clear-recent-confirm"
        glyph: "film"
        title: qsTr("清空最近播放记录？")
        text: qsTr("只清空这个列表，不会删除文件。")
        acceptText: qsTr("清空")
        rejectText: qsTr("取消")
        onAccepted: veyra.clearRecentFiles()
    }
}
