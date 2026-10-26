"""Build six small, seamless night-sky faces with a quiet ridge silhouette."""
import hashlib
import json
import math
from pathlib import Path
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
OUTPUT = ROOT / 'assets/moonlit_citadel/phase3/rework-20261012/sky03'
SIZE = 512
FACES = ('Bk', 'Dn', 'Ft', 'Lf', 'Rt', 'Up')


def direction(face, u, v):
    return {'Ft': (u, v, -1), 'Bk': (-u, v, 1), 'Rt': (1, v, u),
            'Lf': (-1, v, -u), 'Up': (u, 1, -v), 'Dn': (u, -1, v)}[face]


def project(face, x, y, z):
    if face == 'Ft' and z < 0:
        return x / -z, y / -z
    if face == 'Bk' and z > 0:
        return -x / z, y / z
    if face == 'Rt' and x > 0:
        return z / x, y / x
    if face == 'Lf' and x < 0:
        return -z / -x, y / -x
    if face == 'Up' and y > 0:
        return x / y, -z / y
    if face == 'Dn' and y < 0:
        return x / -y, z / -y
    return None


def main():
    assert not OUTPUT.exists(), 'Preserve the authored skybox files.'
    OUTPUT.mkdir(parents=True)
    rng = random.Random(512107)
    stars = []
    for _ in range(360):
        y, angle = rng.uniform(.16, 1), rng.uniform(0, math.tau)
        r = math.sqrt(1 - y * y)
        stars.append((r * math.sin(angle), y, -r * math.cos(angle), rng.random()))
    rows = []
    for face in FACES:
        image = Image.new('RGB', (SIZE, SIZE))
        pixels = image.load()
        for py in range(SIZE):
            v = 1 - 2 * py / (SIZE - 1)
            for px in range(SIZE):
                u = 2 * px / (SIZE - 1) - 1
                x, y, z = direction(face, u, v)
                length = math.sqrt(x * x + y * y + z * z)
                y /= length
                theta = math.atan2(x, -z)
                horizon = math.exp(-abs(y) * 5)
                color = tuple(round(a + horizon * b) for a, b in ((42, 22), (51, 24), (72, 30)))
                far_ridge = .080 + .036 * math.sin(theta * 5 + .4) + .023 * math.sin(theta * 11 - .6)
                near_ridge = .008 + .022 * math.sin(theta * 7 - .7) + .020 * math.sin(theta * 13 + .1)
                if y < far_ridge:
                    color = (36, 44, 61)
                if y < near_ridge:
                    color = (24, 30, 43)
                pixels[px, py] = color
        draw = ImageDraw.Draw(image)
        for x, y, z, strength in stars:
            uv = project(face, x, y, z)
            if uv is None or max(abs(uv[0]), abs(uv[1])) > 1:
                continue
            px, py = (uv[0] + 1) * (SIZE - 1) / 2, (1 - uv[1]) * (SIZE - 1) / 2
            brightness = round(135 + strength * 86)
            radius = 1 if strength > .86 else .4
            draw.ellipse((px - radius, py - radius, px + radius, py + radius), fill=(brightness - 13, brightness - 4, brightness))
        path = OUTPUT / (face.lower() + '.png')
        image.save(path, optimize=True)
        rows.append({'property': 'Skybox' + face, 'file': path.relative_to(ROOT).as_posix(),
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size})
    manifest = {'name': 'Moonlit Citadel quiet night sky RW03', 'resolution': SIZE,
                'faces': rows, 'engineMoon': True, 'source': 'Seeded original procedural texture',
                'boundary': 'No scene geometry, scripts, gameplay, or publishing changes.'}
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'faces': len(rows), 'bytes': sum(row['bytes'] for row in rows), 'resolution': SIZE}))


if __name__ == '__main__':
    main()
