import QtQuick
import QtQuick.Controls

// Login screen: the same scene as the Mitch boot splash (Mitch whisking, Mälu hopping, friends around),
// on true black. The crafting bar over Mitch's head fills while logging in.
Rectangle {
    id: root
    color: "#000000"
    width: 1600
    height: 1000

    readonly property color cream: "#f3ead8"
    readonly property color matcha: "#9dc183"
    readonly property color soft: "#a79f90"
    readonly property color warn: "#e8a598"
    readonly property real bk: 1.8

    // Gaegu, the handwriting font shared with the lock screen (it looks smaller than the default, so sizes are larger)
    FontLoader { id: gaegu; source: "assets/GaeguMitch.ttf" }
    readonly property string face: gaegu.status === FontLoader.Ready ? gaegu.name : "sans-serif"

    // seconds since start; drives every animation (same maths as the Plymouth theme)
    property real time: 0
    NumberAnimation on time { from: 0; to: 100000; duration: 100000000; loops: Animation.Infinite }
    property real fade: Math.min(1, time / 0.7)

    // ---- login state ----
    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    property string userName: userNames.length > userIndex ? userNames[userIndex] : userModel.lastUser
    property var userNames: []
    property var sessionNames: []
    property bool busy: false
    property string message: ""
    property bool messageIsError: false

    Repeater {
        model: userModel
        delegate: Item {
            required property string name
            required property int index
            Component.onCompleted: { var a = root.userNames.slice(); a[index] = name; root.userNames = a }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            required property string name
            required property int index
            Component.onCompleted: { var a = root.sessionNames.slice(); a[index] = name; root.sessionNames = a }
        }
    }

    function login() {
        if (busy) return
        busy = true
        message = ""
        barAnim.to = 0.85
        barAnim.duration = 3500
        barAnim.restart()
        sddm.login(userName, pw.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            barAnim.stop()
            barAnim.to = 1
            barAnim.duration = 250
            barAnim.restart()
        }
        function onLoginFailed() {
            busy = false
            barAnim.stop()
            barAnim.to = 0
            barAnim.duration = 350
            barAnim.restart()
            pw.text = ""
            messageIsError = true
            message = "that didn't work, try again"
            shake.restart()
            pw.forceActiveFocus()
        }
        function onInformationMessage(msg) {
            messageIsError = false
            message = msg
        }
    }

    // ---- scene: 1600x1000 stage scaled to fit ----
    Item {
        id: stage
        width: 1600
        height: 1000
        anchors.centerIn: parent
        scale: Math.min(root.width / width, root.height / height)
        opacity: root.fade

        // floating accents
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
                readonly property real wave: Math.sin(2 * Math.PI * (root.time / modelData.p + modelData.ph))
                source: "assets/" + modelData.src + ".png"
                x: modelData.x / root.bk
                y: modelData.y / root.bk + (modelData.fl ? 14 * wave : 0)
                width: sourceSize.width / root.bk
                height: sourceSize.height / root.bk
                opacity: modelData.tw ? 0.25 + 0.75 * (0.5 + 0.5 * wave) : 1
                smooth: true
                mipmap: true
            }
        }

        // friends and Mälu; list order is the draw order (back row first)
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
                time: root.time
            }
        }

        // Mitch, whisking
        Item {
            id: mitch
            readonly property real bob: 5 * (0.5 - 0.5 * Math.cos(2 * Math.PI * root.time / 0.55))
            Image {
                source: "assets/mitch.png"
                x: 1314 / root.bk
                y: 666 / root.bk - mitch.bob
                width: 624 / root.bk
                height: 777 / root.bk
                smooth: true
                mipmap: true
            }
            Image {
                readonly property real sp: (root.time / 0.55) % 1
                source: "assets/swish" + (Math.floor(sp * 3) % 3) + ".png"
                x: 1403 / root.bk
                y: 1314 / root.bk - mitch.bob
                width: 189 / root.bk
                height: 162 / root.bk
                opacity: Math.sin(Math.PI * sp)
                smooth: true
            }
        }

        // crafting bar over Mitch's head
        Rectangle {
            id: bar
            property real progress: 0
            // hidden until a login starts, fades out again after a failed attempt
            opacity: root.busy ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            x: 740
            y: 322
            width: 230
            height: 26
            radius: height / 2
            color: "transparent"
            border.color: root.cream
            border.width: 3
            Rectangle {
                x: 6
                y: 6
                height: parent.height - 12
                width: Math.max(0, (parent.width - 12) * bar.progress)
                radius: height / 2
                color: root.matcha
                visible: width > 0
            }
        }
        NumberAnimation { id: barAnim; target: bar; property: "progress"; to: 0; duration: 300; easing.type: Easing.OutCubic }

        // ---- login form ----
        Column {
            id: form
            x: 800 - width / 2
            y: 828
            width: 420
            spacing: 8

            SequentialAnimation {
                id: shake
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 - 14; duration: 60 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 + 14; duration: 90 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2 - 8;  duration: 80 }
                NumberAnimation { target: form; property: "x"; to: 800 - form.width / 2;      duration: 60 }
            }

            Text {
                id: who
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: (root.userNames.length > 1 ? "‹  " : "") + root.userName + (root.userNames.length > 1 ? "  ›" : "")
                color: root.cream
                font.family: root.face
                font.pixelSize: 30
                font.letterSpacing: 1
                MouseArea {
                    anchors.fill: parent
                    enabled: root.userNames.length > 1 && !root.busy
                    onClicked: root.userIndex = (root.userIndex + 1) % root.userNames.length
                }
            }

            TextField {
                id: pw
                width: parent.width
                height: 54
                echoMode: TextInput.Password
                placeholderText: "password"
                placeholderTextColor: root.soft
                // the typed characters are drawn as circles below: Gaegu has no bullet glyph, and the fallback
                // font's bullet sits off the middle of the box
                color: "transparent"
                font.family: root.face
                font.pixelSize: 30
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                enabled: !root.busy
                focus: true
                selectByMouse: true
                background: Rectangle {
                    radius: height / 2
                    color: "transparent"
                    border.width: 3
                    border.color: pw.activeFocus ? root.matcha : root.cream
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 9
                    Repeater {
                        model: Math.min(pw.text.length, 24)
                        Rectangle { width: 13; height: 13; radius: 6.5; color: root.cream }
                    }
                }
                // Enter with an empty field must still go through: fingerprint login uses it
                onAccepted: root.login()
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                height: 20
                font.family: root.face
                font.pixelSize: 22
                color: root.messageIsError ? root.warn : root.soft
                text: keyboard.capsLock ? "caps lock is on" : root.message
                elide: Text.ElideRight
            }

            Text {
                id: sess
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.family: root.face
                font.pixelSize: 22
                color: root.soft
                text: root.sessionNames.length > 0 ? root.sessionNames[root.sessionIndex] + (root.sessionNames.length > 1 ? "  ⇅" : "") : ""
                MouseArea {
                    anchors.fill: parent
                    enabled: root.sessionNames.length > 1 && !root.busy
                    onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessionNames.length
                }
            }
        }

        // power buttons, bottom right
        Row {
            x: 1600 - width - 40
            y: 940
            spacing: 22
            Repeater {
                model: [
                    { label: "sleep",    ok: sddm.canSuspend,  act: function () { sddm.suspend() } },
                    { label: "restart",  ok: sddm.canReboot,   act: function () { sddm.reboot() } },
                    { label: "shut down", ok: sddm.canPowerOff, act: function () { sddm.powerOff() } }
                ]
                delegate: Text {
                    required property var modelData
                    visible: modelData.ok
                    text: modelData.label
                    color: ma.containsMouse ? root.cream : root.soft
                    font.family: root.face
                    font.pixelSize: 22
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: modelData.act()
                    }
                }
            }
        }
    }

    // anywhere on the screen puts the cursor back in the password field
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: pw.forceActiveFocus()
    }
    Keys.onPressed: function (e) { if (!pw.activeFocus) pw.forceActiveFocus() }
}
