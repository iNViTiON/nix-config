.pragma library
// Keyframe tables ported from the Plymouth theme (mitch.script), so the login scene moves exactly like the boot splash.
// Phase u is 0..1 over one hop. Height is 0..1 of the jump, squash is (sy - 1) in units of the sprite's q.
var HOP = [
  [0.00, 0.00,  0.00, 0], [0.10, 0.00, -0.30, 0], [0.20, 0.00,  0.25, 0], [0.30, 0.00,  0.00, 2],
  [0.42, 0.00, -1.60, 1], [0.48, 0.35,  1.10, 1], [0.60, 1.00,  0.30, 2], [0.72, 0.20,  0.45, 2],
  [0.76, 0.00, -1.90, 1], [0.83, 0.00,  0.80, 0], [0.90, 0.00, -0.40, 0], [1.00, 0.00,  0.00, 0]
];
var JIG = [[0.00, 0.0], [0.25, -1.0], [0.50, 0.0], [0.75, 1.0], [1.00, 0.0]];
var X   = [[0.00, 0], [0.21, 0], [0.38, 1], [0.71, 1], [0.88, 0], [1.00, 0]];

function ease(u, kind) {
    if (kind === 1) return 1 - (1 - u) * (1 - u);   // out: fast then slow (rise)
    if (kind === 2) return u * u;                   // in: slow then fast (fall)
    return u * u * (3 - 2 * u);                     // smooth
}
function seg(t, u) {
    var i = 0;
    while (i < t.length - 2 && u >= t[i + 1][0]) i++;
    return i;
}
function hopAt(u) {
    var i = seg(HOP, u), a = HOP[i], b = HOP[i + 1];
    var f = ease((u - a[0]) / (b[0] - a[0]), a[3]);
    return { y: a[1] + (b[1] - a[1]) * f, s: a[2] + (b[2] - a[2]) * f };
}
function jigAt(u) {
    var i = seg(JIG, u), a = JIG[i], b = JIG[i + 1];
    var f = ease((u - a[0]) / (b[0] - a[0]), 0);
    return a[1] + (b[1] - a[1]) * f;
}
function xAt(u) {
    var i = seg(X, u), a = X[i], b = X[i + 1];
    var f = ease((u - a[0]) / (b[0] - a[0]), 0);
    return a[1] + (b[1] - a[1]) * f;
}
