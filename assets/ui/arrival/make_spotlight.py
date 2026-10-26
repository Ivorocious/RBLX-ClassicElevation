"""Soft stage spotlight for the arrival screen: a blurred light cone, narrow at the top, wide at the
floor, fading upward, with a brighter core. White so the game can tint it. Run: python make_spotlight.py"""
from PIL import Image, ImageDraw, ImageFilter
W, H = 512, 1024
cone = Image.new("L", (W, H), 0)
d = ImageDraw.Draw(cone)
top, bottom = 40, 168  # half-widths; blur must fade out before the image edges
d.polygon([(W/2-top, 0), (W/2+top, 0), (W/2+bottom, H), (W/2-bottom, H)], fill=255)
cone = cone.filter(ImageFilter.GaussianBlur(28))
core = Image.new("L", (W, H), 0)
dc = ImageDraw.Draw(core)
dc.polygon([(W/2-14, 0), (W/2+14, 0), (W/2+90, H), (W/2-90, H)], fill=255)
core = core.filter(ImageFilter.GaussianBlur(30))
alpha = Image.new("L", (W, H))
pa, pc, po = cone.load(), core.load(), alpha.load()
for y in range(H):
    t = y / (H - 1)
    fade = t ** 1.6          # dark at the top, strongest near the floor
    floor = 1 - min(1, max(0, (t - 0.82) / 0.18)) ** 1.5  # fully transparent at the bottom edge
    for x in range(W):
        side = min(x, W - 1 - x) / 40  # fully transparent at the side edges
        v = (pa[x, y] * 0.55 + pc[x, y] * 0.45) * fade * floor * min(1, side)
        po[x, y] = int(max(0, min(255, v)))
img = Image.new("RGBA", (W, H), (255, 255, 255, 0))
img.putalpha(alpha)
img.save("spotlight-cone.png")
print("ok")
