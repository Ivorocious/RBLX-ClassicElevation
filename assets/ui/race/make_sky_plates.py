"""Builds the slanted Sky Rush plate 9-slice images (SVG) in ./svg.

Roblox UI cannot skew, so each plate is a white rounded parallelogram with a navy edge,
authored at 2x for one reference height; the game tints the white with a UIGradient and
9-slices it so the edge stays 3 px at any size. Run: python make_sky_plates.py, then
node render_svgs.mjs. Slant matches the concept page's skewX(-9deg) at the reference height.
"""
import math, os

HERE = os.path.dirname(os.path.abspath(__file__))
TAN = math.tan(math.radians(9))
SCALE = 2  # authored at 2x; the game uses SliceScale 0.5
EDGE = 3   # navy edge in design pixels

def inset_polygon(w, h, s, d):
    """Parallelogram leaning right ('/'), inset by d: top-left, top-right, bottom-right, bottom-left."""
    k = d / math.cos(math.radians(9))
    def left(y): return s * (1 - y / h) + k
    def right(y): return w - s * (y / h) - k
    return [(left(d), d), (right(d), d), (right(h - d), h - d), (left(h - d), h - d)]

def rounded(points, r):
    # Polygon inset by r, stroked 2r with round joins = rounded shape.
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in points), r

def plate(name, height, radius, width):
    h, w, s, r, e = height * SCALE, width * SCALE, height * TAN * SCALE, radius * SCALE, EDGE * SCALE
    outer, _ = rounded(inset_polygon(w, h, s, r), r)
    inner, _ = rounded(inset_polygon(w, h, s, r + e), r - e)
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" viewBox="0 0 {w:.0f} {h:.0f}">
<polygon points="{outer}" fill="#10215C" stroke="#10215C" stroke-width="{2*r:.2f}" stroke-linejoin="round"/>
<polygon points="{inner}" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="{2*(r-e):.2f}" stroke-linejoin="round"/>
</svg>'''
    open(os.path.join(HERE, "svg", name + ".svg"), "w").write(svg)
    left = math.ceil(s + r + 2 * SCALE)
    top = math.ceil(r + 2 * SCALE)
    print(f"{name}: {w:.0f}x{h:.0f} SliceCenter=Rect({left},{top},{w - left:.0f},{h - top:.0f}) slant={s/SCALE:.1f}")

plate("sky-plate-s", 56, 10, 160)
plate("sky-plate-m", 96, 12, 200)
plate("sky-plate-l", 320, 14, 260)

# Speed stripes: white diagonal bands (9 px every 22 px, like the page's repeating stripes) on a
# transparent tile. Bands lean so they shift one period per tile height, which keeps the tile seamless.
tile = 44 * SCALE
period = tile // 2
band = 9 * SCALE
stripes = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{tile}" height="{tile}" viewBox="0 0 {tile} {tile}">
<g fill="#FFFFFF">'''
for k in range(-2, 3):
    x0 = k * period
    stripes += f'<polygon points="{x0},{tile} {x0 + band},{tile} {x0 + band + period},0 {x0 + period},0"/>'
stripes += "</g></svg>"
open(os.path.join(HERE, "svg", "speed-stripes.svg"), "w").write(stripes)
print("speed-stripes: tile", tile)
