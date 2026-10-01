import QtQuick
import QtQuick.Effects
import Quickshell.Io
import QtQuick.Controls

// What each screen shows while locked: the desktop wallpaper, dimmed and blurred, with the same scene as the boot
// splash and the login screen, a clock and date in Gaegu, a password field, media controls and a count of the
// notifications that arrived while locked.
FocusScope {
    id: view

    property var auth
    property bool secure: false
    property real time: 0
    property date now: new Date()
    property string wallpaper: ""
    property string screenName: ""
    property var player: null
    property var newNotifications: []
    property bool showTime: true
    property bool showDate: true
    property bool showMedia: true
    property int notificationMode: 1       // 0 off, 1 count, 2 app names, 3 full content
    property string clockStyle: "horizontal"
    property string clockFormat: ""        // "24h", "12h" or "" for the locale default
    property bool showSeconds: false
    property bool showPower: true
    property bool showProfile: true
    property bool showSystemIcons: true
    property bool showWeather: true
    property string statusText: ""
    property string weatherText: ""
    property string profileImage: ""
    property string userName: ""
    signal powerRequested(string kind)
    property string dateFormat: ""         // Qt format string; empty uses the handwritten default

    // Day and month names follow the locale that controls date formats (LC_TIME, like your Estonian formats), not
    // the interface language, which Qt would use by default.
    property string localeName: ""
    readonly property var timeLocale: localeName !== "" ? Qt.locale(localeName) : Qt.locale()
    readonly property bool use12h: clockFormat === "12h" || (clockFormat !== "24h" && /[aA]/.test(timeLocale.timeFormat(Locale.ShortFormat)))
    readonly property bool vertical: clockStyle === "vertical"
    readonly property string timeText: now.toLocaleString(timeLocale, (use12h ? "h:mm" : "HH:mm") + (showSeconds ? ":ss" : "") + (use12h ? " AP" : ""))
    readonly property string dateText: dateFormat !== "" ? now.toLocaleString(timeLocale, dateFormat) : now.toLocaleString(timeLocale, "dddd d MMMM").toLowerCase()
    readonly property string notificationText: {
        const list = newNotifications;
        if (notificationMode === 0 || list.length === 0)
            return "";
        const count = list.length === 1 ? "1 new notification" : list.length + " new notifications";
        if (notificationMode === 1)
            return count;
        if (notificationMode === 2) {
            const apps = [];
            for (let i = 0; i < list.length; i++)
                if (list[i].appName && apps.indexOf(list[i].appName) < 0)
                    apps.push(list[i].appName);
            return apps.length > 0 ? count + "\n" + apps.slice(0, 4).join(", ") : count;
        }
        const lines = [count];
        for (let j = Math.max(0, list.length - 3); j < list.length; j++)
            lines.push((list[j].appName || "") + ": " + (list[j].summary || ""));
        return lines.join("\n");
    }

    readonly property color cream: "#f3ead8"
    readonly property color matcha: "#9dc183"
    readonly property color soft: "#b3aa9a"
    readonly property color warn: "#e8a598"
    readonly property real bk: 1.8
    readonly property real fade: Math.min(1, time / 0.7)

    // Typing goes straight to the password buffer. The compositor gives keyboard focus to one surface only, and
    // every surface shows the same buffer.
    focus: true
    Keys.onPressed: event => {
        if (!auth)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            auth.submit();
        } else if (event.key === Qt.Key_Backspace) {
            auth.buffer = auth.buffer.slice(0, -1);
        } else if (event.key === Qt.Key_Escape) {
            auth.buffer = "";
        } else if (event.text.length > 0 && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            auth.buffer += event.text;
        } else {
            return;
        }
        event.accepted = true;
    }
    // keyboard focus only arrives once the compositor confirms the lock, so ask again then
    onSecureChanged: if (secure) forceActiveFocus()
    Component.onCompleted: {
        forceActiveFocus();
        if (wallpaper !== "")
            lumaProc.running = true;
    }

    FontLoader { id: gaegu; source: "assets/GaeguMitch.ttf" }
    readonly property string face: gaegu.status === FontLoader.Ready ? gaegu.name : "sans-serif"

    // ---- wallpaper. Only bright pictures are dimmed (the cream line art needs a darker ground); a dark wallpaper
    // is shown as it is ----
    property real luma: 0.3
    Process {
        id: lumaProc
        command: ["mitch-lock-info", "luma", view.wallpaper]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text);
                if (!isNaN(v))
                    view.luma = v;
            }
        }
    }
    onWallpaperChanged: if (wallpaper !== "") lumaProc.running = true
    Rectangle { anchors.fill: parent; color: "#000000" }
    Image {
        id: wall
        anchors.fill: parent
        source: view.wallpaper !== "" ? "file://" + view.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 0.4
        blurMax: 40
        opacity: view.fade
    }
    // dim by brightness: nothing for a dark wallpaper, up to half for a bright one
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: Math.max(0, Math.min(0.5, (view.luma - 0.25))) * view.fade
    }

    // ---- scene on a 1600x1000 stage ----
    Item {
        id: stage
        width: 1600
        height: 1000
        anchors.centerIn: parent
        scale: Math.min(view.width / width, view.height / height)
        opacity: view.fade

        Repeater {
            model: [
                { src: "a_star", x: 1800, y: 450, p: 2.2, ph: 0,   tw: true,  fl: false },
                { src: "a_yarc", x: 684,  y: 594, p: 3.0, ph: 0.6, tw: true,  fl: false },
                { src: "a_arc",  x: 2016, y: 612, p: 4.0, ph: 0,   tw: false, fl: true  },
                { src: "a_bdash", x: 108, y: 846, p: 2.6, ph: 1.0, tw: true,  fl: false },
                { src: "a_pdash", x: 2610, y: 1440, p: 3.4, ph: 0.4, tw: false, fl: true }
            ]
            delegate: Image {
                required property var modelData
                readonly property real wave: Math.sin(2 * Math.PI * (view.time / modelData.p + modelData.ph))
                source: "assets/" + modelData.src + ".png"
                x: modelData.x / view.bk
                y: modelData.y / view.bk + (modelData.fl ? 14 * wave : 0)
                width: sourceSize.width / view.bk
                height: sourceSize.height / view.bk
                opacity: modelData.tw ? 0.25 + 0.75 * (0.5 + 0.5 * wave) : 1
                smooth: true
                mipmap: true
            }
        }

        Repeater {
            model: [
                { name: "pear", cx: 522, ground: 1247, lw: 324, lh: 329, cw: 350, ch: 397, ox: 26, h: 40, q: 0.08, d: 3.4, dl: -0.7, x: -50, jig: false, malu: false },
                { name: "bean", cx: 2313, ground: 1118, lw: 378, lh: 232, cw: 408, ch: 232, ox: 30, h: 60, q: 0.08, d: 3.8, dl: -1.6, x: 60, jig: false, malu: false },
                { name: "round", cx: 2682, ground: 1259, lw: 252, lh: 256, cw: 272, ch: 256, ox: 20, h: 70, q: 0.1, d: 3.2, dl: -0.3, x: -70, jig: false, malu: false },
                { name: "bean2", cx: 2259, ground: 1454, lw: 378, lh: 297, cw: 408, ch: 297, ox: 30, h: 60, q: 0.09, d: 3.4, dl: -2, x: 60, jig: false, malu: false },
                { name: "flat", cx: 306, ground: 1399, lw: 468, lh: 157, cw: 505, ch: 221, ox: 37, h: 0, q: 0, d: 2.8, dl: 0, x: 0, jig: true, malu: false },
                { name: "malu", cx: 1026, ground: 1428, lw: 468, lh: 317, cw: 468, ch: 317, ox: 0, h: 130, q: 0.15, d: 2.6, dl: 0, x: 0, jig: false, malu: true }
            ]
            delegate: Friend {
                required property var modelData
                d: modelData
                time: view.time
            }
        }

        Item {
            id: mitch
            readonly property real bob: 5 * (0.5 - 0.5 * Math.cos(2 * Math.PI * view.time / 0.55))
            Image {
                source: "assets/mitch.png"
                x: 1314 / view.bk
                y: 666 / view.bk - mitch.bob
                width: 624 / view.bk
                height: 777 / view.bk
                smooth: true
                mipmap: true
            }
            Image {
                readonly property real sp: (view.time / 0.55) % 1
                source: "assets/swish" + (Math.floor(sp * 3) % 3) + ".png"
                x: 1403 / view.bk
                y: 1314 / view.bk - mitch.bob
                width: 189 / view.bk
                height: 162 / view.bk
                opacity: Math.sin(Math.PI * sp)
                smooth: true
            }
        }

        // crafting bar: only while a password is being checked
        Rectangle {
            id: bar
            property real progress: 0
            opacity: view.auth && view.auth.busy ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            x: 740
            y: 322
            width: 230
            height: 26
            radius: height / 2
            color: "transparent"
            border.color: view.cream
            border.width: 3
            Rectangle {
                x: 6
                y: 6
                height: parent.height - 12
                width: Math.max(0, (parent.width - 12) * bar.progress)
                radius: height / 2
                color: view.matcha
                visible: width > 0
            }
        }
        NumberAnimation { id: barAnim; target: bar; property: "progress"; to: 0.9; duration: 1800; easing.type: Easing.OutCubic }
        Connections {
            target: view.auth
            function onBusyChanged() {
                if (view.auth.busy) {
                    bar.progress = 0;
                    barAnim.restart();
                } else {
                    barAnim.stop();
                    bar.progress = 0;
                }
            }
        }

        // ---- clock and date: top centre, or stacked at the top left in DMS's "vertical" style ----
        Column {
            x: view.vertical ? 60 : 800 - width / 2
            y: view.vertical ? 30 : 40
            width: view.vertical ? 420 : 900
            visible: view.showTime || view.showDate
            Text {
                visible: view.showTime
                width: parent.width
                horizontalAlignment: view.vertical ? Text.AlignLeft : Text.AlignHCenter
                text: view.vertical ? view.timeText.replace(/[: ]+/g, "\n") : view.timeText
                color: view.cream
                font.family: view.face
                font.pixelSize: view.vertical ? 140 : 190
                lineHeight: 0.85
            }
            Text {
                visible: view.showDate
                width: parent.width
                horizontalAlignment: view.vertical ? Text.AlignLeft : Text.AlignHCenter
                text: view.dateText
                color: view.soft
                font.family: view.face
                font.pixelSize: 40
                wrapMode: Text.WordWrap
            }
            Text {
                visible: view.showWeather && view.weatherText !== ""
                width: parent.width
                horizontalAlignment: view.vertical ? Text.AlignLeft : Text.AlignHCenter
                text: view.weatherText
                color: view.soft
                font.family: view.face
                font.pixelSize: 34
            }
        }

        // ---- status line, top right: network, bluetooth, volume, battery ----
        Text {
            x: 1600 - width - 50
            y: 40
            visible: view.showSystemIcons && view.statusText !== ""
            text: view.statusText
            horizontalAlignment: Text.AlignRight
            color: view.soft
            font.family: view.face
            font.pixelSize: 26
        }

        // ---- profile picture, left of the password field ----
        Item {
            id: avatar
            x: 800 - 210 - 18 - 54
            y: 850
            width: 54
            height: 54
            visible: view.showProfile
            Image {
                id: avatarImage
                anchors.fill: parent
                source: view.profileImage !== "" ? "file://" + view.profileImage : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 256
                sourceSize.height: 256
                smooth: true
                mipmap: true
                visible: false
            }
            // The circle mask is rendered at 4x size and smoothed, so the picture's edge is anti-aliased
            Rectangle {
                id: avatarMask
                anchors.fill: parent
                radius: width / 2
                antialiasing: true
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(width * 4, height * 4)
            }
            MultiEffect {
                anchors.fill: parent
                source: avatarImage
                visible: avatarImage.status === Image.Ready
                maskEnabled: true
                maskSource: avatarMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            // thin ring in the same style as the password pill; it also hides any edge roughness
            Rectangle {
                anchors.fill: parent
                visible: avatarImage.status === Image.Ready
                radius: width / 2
                antialiasing: true
                color: "transparent"
                border.width: 3
                border.color: view.cream
            }
            Rectangle {
                anchors.fill: parent
                visible: avatarImage.status !== Image.Ready
                radius: width / 2
                color: "transparent"
                border.width: 3
                border.color: view.cream
                Text {
                    anchors.centerIn: parent
                    text: view.userName.length > 0 ? view.userName[0].toLowerCase() : ""
                    color: view.cream
                    font.family: view.face
                    font.pixelSize: 30
                }
            }
        }

        // ---- password ----
        Column {
            id: form
            x: 800 - width / 2
            y: 850
            width: 420
            spacing: 8

            SequentialAnimation {
                id: shake
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 - 14; duration: 60 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 + 14; duration: 90 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 - 8;  duration: 80 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2;      duration: 60 }
            }
            Connections { target: view.auth; function onFailed() { shake.restart() } }

            Rectangle {
                width: parent.width
                height: 54
                radius: height / 2
                color: "transparent"
                border.width: 3
                border.color: view.auth && view.auth.busy ? view.matcha : view.cream

                Text {
                    anchors.centerIn: parent
                    visible: !view.auth || view.auth.buffer.length === 0
                    text: "password"
                    color: view.soft
                    font.family: view.face
                    font.pixelSize: 26
                }
                // typed characters as circles: Gaegu has no bullet glyph and the fallback one sits off the middle
                Row {
                    anchors.centerIn: parent
                    spacing: 9
                    visible: view.auth && view.auth.buffer.length > 0
                    Repeater {
                        model: view.auth ? Math.min(view.auth.buffer.length, 24) : 0
                        Rectangle { width: 13; height: 13; radius: 6.5; color: view.cream }
                    }
                }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                height: 24
                font.family: view.face
                font.pixelSize: 22
                color: view.auth && view.auth.isError ? view.warn : view.soft
                text: view.auth ? view.auth.message : ""
                elide: Text.ElideRight
            }
        }

        // ---- media, bottom left ----
        Column {
            x: 50
            y: 850
            width: 480
            spacing: 4
            visible: view.showMedia && view.player !== null
            Text {
                width: parent.width
                text: view.player ? (view.player.trackTitle || "") : ""
                color: view.cream
                font.family: view.face
                font.pixelSize: 28
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: view.player ? (view.player.trackArtist || "") : ""
                color: view.soft
                font.family: view.face
                font.pixelSize: 22
                elide: Text.ElideRight
            }
            Row {
                spacing: 22
                Repeater {
                    model: [
                        { label: "prev", act: function (p) { p.previous() } },
                        { label: view.player && view.player.isPlaying ? "pause" : "play", act: function (p) { p.togglePlaying() } },
                        { label: "next", act: function (p) { p.next() } }
                    ]
                    delegate: Text {
                        required property var modelData
                        text: modelData.label
                        color: ma.containsMouse ? view.cream : view.soft
                        font.family: view.face
                        font.pixelSize: 26
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            onClicked: if (view.player) modelData.act(view.player)
                        }
                    }
                }
            }
        }

        // ---- power actions, bottom right. A first click arms the button, a second one within 4 seconds does it ----
        Row {
            x: 1600 - width - 50
            y: 950
            spacing: 26
            visible: view.showPower
            Repeater {
                model: [
                    { kind: "suspend",   label: "sleep" },
                    { kind: "hibernate", label: "hibernate" },
                    { kind: "reboot",    label: "restart" },
                    { kind: "poweroff",  label: "shut down" }
                ]
                delegate: Text {
                    id: btn
                    required property var modelData
                    property bool armed: false
                    text: armed ? "sure?" : modelData.label
                    color: armed ? view.warn : (ma.containsMouse ? view.cream : view.soft)
                    font.family: view.face
                    font.pixelSize: 26
                    Timer { id: disarm; interval: 4000; onTriggered: btn.armed = false }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: {
                            if (btn.armed) {
                                btn.armed = false;
                                view.powerRequested(btn.modelData.kind);
                            } else {
                                btn.armed = true;
                                disarm.restart();
                            }
                        }
                    }
                }
            }
        }

        // ---- new notifications, bottom right (what is shown follows DMS's notification setting) ----
        Text {
            x: 1600 - width - 50
            y: 940 - height
            visible: view.notificationText !== ""
            text: view.notificationText
            horizontalAlignment: Text.AlignRight
            color: view.soft
            font.family: view.face
            font.pixelSize: 24
        }
    }
}
