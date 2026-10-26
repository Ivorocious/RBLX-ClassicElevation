"""Project the preserved selected panorama into six continuous Roblox sky faces."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
ART = ROOT / 'assets/sky/moonlit-citadel-20261021'
SOURCE = ART / 'source-panorama-S04.png'
OUTPUT = ART / 'violet-veil-S04-C01'
SIZE = 512
FACES = ('Bk', 'Dn', 'Ft', 'Lf', 'Rt', 'Up')
SOURCE_HASH = '4027ef3ae74f31cf91c7af2d7109a0fbdf262b290ccf88668ae36fa6a11b961f'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def directions(face, u, v):
    one = np.ones_like(u)
    return np.stack({'Ft': (u, v, -one), 'Bk': (-u, v, one),
                     'Rt': (one, v, u), 'Lf': (-one, v, -u),
                     'Up': (u, one, -v), 'Dn': (u, -one, v)}[face], axis=-1)


def smooth(t):
    return t * t * (3 - 2 * t)


def projection_source():
    assert sha(SOURCE) == SOURCE_HASH, 'Selected art changed.'
    pixels = np.asarray(Image.open(SOURCE).convert('RGB'), dtype=np.float64).copy()
    height, width = pixels.shape[:2]
    assert width == height * 2
    original_seam = float(np.abs(pixels[:, 0] - pixels[:, -1]).max())
    wrap = round(width * .04)
    for x in range(wrap):
        weight = .5 * (1 - smooth(x / (wrap - 1)))
        left, right = pixels[:, x].copy(), pixels[:, width - 1 - x].copy()
        pixels[:, x] = left * (1 - weight) + right * weight
        pixels[:, width - 1 - x] = right * (1 - weight) + left * weight
    cap = round(height * .04)
    for y in range(cap):
        weight = 1 - smooth(y / (cap - 1))
        for row in (y, height - 1 - y):
            pixels[row] = pixels[row] * (1 - weight) + pixels[row].mean(axis=0) * weight
    return pixels, {'wrapFeatherPixelsPerSide': wrap, 'poleCapRows': cap,
                    'originalWrapMaxChannelDifference': original_seam,
                    'normalizedWrapMaxChannelDifference': float(np.abs(pixels[:, 0] - pixels[:, -1]).max())}


def sample(pixels, rays):
    unit = rays / np.linalg.norm(rays, axis=-1, keepdims=True)
    height, width = pixels.shape[:2]
    x = (np.arctan2(unit[..., 0], -unit[..., 2]) / (2 * np.pi) + .5) * (width - 1)
    y = (.5 - np.arcsin(np.clip(unit[..., 1], -1, 1)) / np.pi) * (height - 1)
    x, y = np.clip(x, 0, width - 1), np.clip(y, 0, height - 1)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    x1, y1 = np.minimum(x0 + 1, width - 1), np.minimum(y0 + 1, height - 1)
    a, b = (x - x0)[..., None], (y - y0)[..., None]
    values = ((pixels[y0, x0] * (1 - a) + pixels[y0, x1] * a) * (1 - b)
              + (pixels[y1, x0] * (1 - a) + pixels[y1, x1] * a) * b)
    return np.rint(values).clip(0, 255).astype(np.uint8)


def edge_checks(face_pixels, face_rays):
    pairs = {}
    for face in FACES:
        pixels, rays = face_pixels[face], face_rays[face]
        for side, values, vectors in (
            ('top', pixels[0], rays[0]), ('bottom', pixels[-1], rays[-1]),
            ('left', pixels[:, 0], rays[:, 0]), ('right', pixels[:, -1], rays[:, -1]),
        ):
            ends = (tuple(vectors[0]), tuple(vectors[-1]))
            if ends[0] > ends[1]:
                ends, values = ends[::-1], values[::-1]
            pairs.setdefault(ends, []).append((face + '.' + side, values))
    assert len(pairs) == 12 and all(len(p) == 2 for p in pairs.values())
    results = []
    for a, b in pairs.values():
        difference = np.abs(a[1].astype(int) - b[1].astype(int))
        results.append({'edges': [a[0], b[0]], 'maxChannelDifference': int(difference.max())})
    assert max(x['maxChannelDifference'] for x in results) <= 1
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Reproduce saved faces without rewriting assets or receipts.')
    args = parser.parse_args()
    pixels, normalization = projection_source()
    u, v = np.meshgrid(np.linspace(-1, 1, SIZE), np.linspace(1, -1, SIZE))
    rays = {face: directions(face, u, v) for face in FACES}
    faces = {face: sample(pixels, rays[face]) for face in FACES}
    edges = edge_checks(faces, rays)
    if args.check:
        manifest = json.loads((OUTPUT / 'manifest.json').read_text())
        for row in manifest['faces']:
            path = ROOT / row['file']
            assert sha(path) == row['sha256']
            assert np.array_equal(np.asarray(Image.open(path)), faces[row['property'][6:]])
        print(json.dumps({'reproducedFaces': 6, 'edges': edges, 'normalization': normalization}))
        return
    assert not (OUTPUT / 'manifest.json').exists(), 'Use --check for the completed candidate.'
    OUTPUT.mkdir(parents=True, exist_ok=True)
    normalized = np.rint(pixels).astype(np.uint8)
    normalized_path = OUTPUT / 'projection-source.png'
    if normalized_path.exists():
        assert np.array_equal(np.asarray(Image.open(normalized_path)), normalized)
    else:
        Image.fromarray(normalized).save(normalized_path, optimize=True)
    rows = []
    sheet = Image.new('RGB', (1008, 720), (18, 21, 34))
    draw = ImageDraw.Draw(sheet)
    for index, face in enumerate(FACES):
        path = OUTPUT / (face.lower() + '.png')
        im = Image.fromarray(faces[face])
        if path.exists():
            assert np.array_equal(np.asarray(Image.open(path)), faces[face])
        else:
            im.save(path, optimize=True)
        x, y = (index % 3) * 336 + 8, (index // 3) * 360 + 28
        sheet.paste(im.resize((320, 320), Image.LANCZOS), (x, y))
        draw.text((x, y - 20), 'Skybox' + face, fill=(220, 226, 240))
        rows.append({'property': 'Skybox' + face, 'file': path.relative_to(ROOT).as_posix(),
                     'sha256': sha(path), 'bytes': path.stat().st_size})
    sheet.save(OUTPUT / 'six-face-preview.jpg', quality=94)
    manifest = {'taskId': 'moonlit-citadel-skybox-20261021', 'candidate': 'D/S04-C01 Violet Veil',
                'source': SOURCE.relative_to(ROOT).as_posix(), 'sourceSha256': SOURCE_HASH,
                'sourceResolution': list(Image.open(SOURCE).size), 'resolution': SIZE,
                'faces': rows, 'normalization': normalization, 'edgeChecks': edges,
                'projection': 'Bilinear latitude-longitude sample of unit rays; inclusive shared edge rays.',
                'directions': {'Ft': '(u,v,-1)', 'Bk': '(-u,v,1)', 'Rt': '(1,v,u)',
                               'Lf': '(-1,v,-u)', 'Up': '(u,1,-v)', 'Dn': '(u,-1,v)'},
                'uv': 'u left=-1 right=1; v top=1 bottom=-1; panorama center faces -Z, seam +Z.',
                'engineMoon': True, 'engineStars': 0, 'rotationDegreesPerSecond': .2,
                'boundary': 'Preserved selected source; spherical wrap/pole normalization and projection only.'}
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'candidate': manifest['candidate'], 'faces': len(rows), 'resolution': SIZE,
                      'totalPngBytes': sum(r['bytes'] for r in rows), 'edges': edges}))


if __name__ == '__main__':
    main()
