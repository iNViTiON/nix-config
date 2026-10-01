import QtQuick
import "Anim.js" as Anim

// One hopping or jiggling character. Sprites are baked at 2880x1800 (B px per stage unit); "_f" files are the
// mirrored composite (outline plus its colour shadow), so turning around moves the shadow to the other side too.
Item {
    id: f
    property var d
    property real time: 0
    readonly property real bk: 1.8

    readonly property real u: { var v = ((time - d.dl) / d.d) % 1; return v < 0 ? v + 1 : v }
    readonly property real u2: { var v = ((time - d.dl) / (2 * d.d)) % 1; return v < 0 ? v + 1 : v }
    readonly property var hop: d.jig ? null : Anim.hopAt(u)
    readonly property real sy: d.jig ? 1 + Anim.jigAt(u) * 0.035 : 1 + hop.s * d.q
    readonly property real sx: 1 - 0.65 * (sy - 1)
    readonly property real lift: d.jig ? 0 : hop.y * d.h
    readonly property real dx: d.x !== 0 ? Anim.xAt(u2) * d.x : 0
    // natural sprites face left; the first half of each two-hop cycle faces the travel direction
    readonly property bool faceRight: d.x !== 0 && (u2 < 0.5 ? d.x > 0 : d.x < 0)
    readonly property real centre: (faceRight ? d.ox + d.lw / 2 : d.lw / 2) / bk

    x: d.cx / bk + dx - centre
    y: d.ground / bk - d.lh / bk - lift
    width: d.cw / bk
    height: d.ch / bk

    Image {
        anchors.fill: parent
        source: "assets/" + d.name + (d.malu ? "" : (faceRight ? "_f" : "_n")) + ".png"
        smooth: true
        mipmap: true
        transform: Scale {
            origin.x: f.centre
            origin.y: d.lh / f.bk
            xScale: f.sx
            yScale: f.sy
        }
    }
}
