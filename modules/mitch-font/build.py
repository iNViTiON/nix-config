"""Build "Gaegu Mitch": Gaegu plus the letters and scripts it lacks.

  - ä ö ü õ and Ä Ö Ü Õ, made from Gaegu's own letters with its period (two dots) or tilde above them
  - hiragana, katakana, kanji and common Japanese punctuation, taken from Yomogi (also a hand-drawn font) and
    scaled to match the size of Gaegu's Hangul

Usage: build.py GAEGU.ttf YOMOGI.ttf OUT.ttf
"""
import sys

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.misc.transform import Transform
from fontTools.ttLib import TTFont

gaegu_path, yomogi_path, out_path = sys.argv[1:4]
font = TTFont(gaegu_path)
jp = TTFont(yomogi_path)

glyf = font["glyf"]
hmtx = font["hmtx"]
cmap = font.getBestCmap()
gset = font.getGlyphSet()
jset = jp.getGlyphSet()
jcmap = jp.getBestCmap()
order = list(font.getGlyphOrder())
unicode_tables = [t for t in font["cmap"].tables if t.isUnicode()]


def add_glyph(name, glyph, advance, codepoint):
    glyph.recalcBounds(glyf)
    glyf.glyphs[name] = glyph
    order.append(name)
    hmtx.metrics[name] = (advance, getattr(glyph, "xMin", 0))
    for table in unicode_tables:
        table.cmap[codepoint] = name


def bounds(name):
    pen = BoundsPen(gset)
    gset[name].draw(pen)
    return pen.bounds


def build_accented(codepoint, base_cp, mark):
    base = cmap[base_cp]
    adv = hmtx.metrics[base][0]
    x0, y0, x1, y1 = bounds(base)
    cx = (x0 + x1) / 2
    pen = TTGlyphPen(gset)
    gset[base].draw(pen)
    if mark == "diaeresis":
        dot = cmap[ord(".")]
        d0, e0, d1, e1 = bounds(dot)
        s = 0.62
        gap = 38
        for dx in (-0.2, 0.2):
            tx = cx + dx * (x1 - x0 + 120) - s * (d0 + d1) / 2
            ty = y1 + gap - s * e0
            gset[dot].draw(TransformPen(pen, Transform(s, 0, 0, s, tx, ty)))
    else:  # tilde
        tilde = cmap[ord("~")]
        t0, u0, t1, u1 = bounds(tilde)
        s = 0.42
        gap = 34
        tx = cx - s * (t0 + t1) / 2
        ty = y1 + gap - s * u0
        gset[tilde].draw(TransformPen(pen, Transform(s, 0, 0, s, tx, ty)))
    add_glyph("uni%04X" % codepoint, pen.glyph(), adv, codepoint)


for cp, base, mark in [
    (0xE4, "a", "diaeresis"), (0xF6, "o", "diaeresis"), (0xFC, "u", "diaeresis"), (0xF5, "o", "tilde"),
    (0xC4, "A", "diaeresis"), (0xD6, "O", "diaeresis"), (0xDC, "U", "diaeresis"), (0xD5, "O", "tilde"),
]:
    build_accented(cp, ord(base), mark)

# Japanese: scaled so kana match the size of Gaegu's Hangul (advance 820 against Yomogi's 1000)
SCALE = 0.82
ranges = [
    (0x3041, 0x3096), (0x309B, 0x309F),            # hiragana
    (0x30A1, 0x30FF),                              # katakana, middle dot, prolonged sound mark
    (0x4E00, 0x9FFF),                              # kanji (Yomogi has the 6,684 in JIS levels 1 and 2)
    (0x3001, 0x3003), (0x3005, 0x3005), (0x300C, 0x300F), (0x301C, 0x301C), (0x30FB, 0x30FB),
    (0xFF01, 0xFF01), (0xFF1F, 0xFF1F),            # full-width ! and ?
]
for lo, hi in ranges:
    for cp in range(lo, hi + 1):
        if cp in cmap or cp not in jcmap:
            continue
        src = jcmap[cp]
        pen = TTGlyphPen(jset)
        jset[src].draw(TransformPen(pen, Transform(SCALE, 0, 0, SCALE, 0, 0)))
        add_glyph("uni%04X" % cp, pen.glyph(), round(jp["hmtx"].metrics[src][0] * SCALE), cp)

font.setGlyphOrder(order)
glyf.glyphOrder = order
# tables that list every glyph would no longer match
for table in ("hdmx", "LTSH", "VDMX", "DSIG"):
    if table in font:
        del font[table]

# a new name, since this is a modified font
names = {1: "Gaegu Mitch", 3: "GaeguMitch-Regular", 4: "Gaegu Mitch Regular", 6: "GaeguMitch-Regular"}
for record in font["name"].names:
    if record.nameID in names:
        record.string = names[record.nameID]
font.save(out_path)
print("glyphs:", len(order))
