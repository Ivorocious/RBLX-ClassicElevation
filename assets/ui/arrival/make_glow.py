"""Soft round glow for the arrival sky: white, brightest in the middle, fully transparent well before
the image edges so stretched copies never show a seam. Run: python make_glow.py"""
import math
from PIL import Image
S = 256
img = Image.new("RGBA", (S, S), (255, 255, 255, 0))
px = img.load()
edge = math.exp(-(2.4 ** 2))
for y in range(S):
    for x in range(S):
        r = math.hypot((x + 0.5) / S * 2 - 1, (y + 0.5) / S * 2 - 1)
        a = 0 if r >= 1 else (math.exp(-(r * 2.4) ** 2) - edge) / (1 - edge)
        px[x, y] = (255, 255, 255, int(round(255 * max(0, a))))
img.save("soft-glow.png")
print("ok", img.getpixel((0, 0)), img.getpixel((S // 2, S // 2)), img.getpixel((S // 2, 2)))
