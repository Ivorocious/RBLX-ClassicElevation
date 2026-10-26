"""Reproject the generated spherical environment into six Roblox cube textures."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
SIZE = 1024


def panorama():
    pixels = np.asarray(Image.open(ROOT / 'panorama-source.png').convert('RGB'), dtype=np.float32).copy()
    height, width, _ = pixels.shape
    # A spherical texture must meet at the longitude seam and collapse at both poles.
    seam = (pixels[:, 0] + pixels[:, -1]) / 2
    band = 48
    for i in range(band):
        weight = i / (band - 1)
        weight = weight * weight * (3 - 2 * weight)
        for column in (i, width - 1 - i):
            pixels[:, column] = seam * (1 - weight) + pixels[:, column] * weight
    pole_band = round(height * 0.18)
    for pole in (0, height - 1):
        mean = pixels[pole].mean(axis=0)
        for i in range(pole_band):
            row = i if pole == 0 else height - 1 - i
            weight = i / (pole_band - 1)
            weight = weight * weight * (3 - 2 * weight)
            pixels[row] = mean * (1 - weight) + pixels[row] * weight
    return pixels


def directions(face, u, v):
    one = np.ones_like(u)
    return {
        'ft': (u, -v, -one),
        'bk': (-u, -v, one),
        'rt': (one, -v, u),
        'lf': (-one, -v, -u),
        'up': (u, one, v),
        'dn': (u, -one, -v),
    }[face]


def sample(pixels, direction):
    x, y, z = direction
    length = np.sqrt(x * x + y * y + z * z)
    height, width, _ = pixels.shape
    longitude = np.arctan2(x, -z)
    latitude = np.arcsin(np.clip(y / length, -1, 1))
    px = ((longitude / (2 * np.pi) + .5) % 1) * (width - 1)
    py = (.5 - latitude / np.pi) * (height - 1)
    x0, y0 = np.floor(px).astype(int), np.floor(py).astype(int)
    x1, y1 = (x0 + 1) % width, np.minimum(y0 + 1, height - 1)
    wx, wy = (px - x0)[..., None], (py - y0)[..., None]
    upper = pixels[y0, x0] * (1 - wx) + pixels[y0, x1] * wx
    lower = pixels[y1, x0] * (1 - wx) + pixels[y1, x1] * wx
    return upper * (1 - wy) + lower * wy


def build():
    pixels = panorama()
    uv = np.linspace(-1, 1, SIZE)
    u, v = np.meshgrid(uv, uv)
    faces = {}
    metadata = {}
    for face in ('ft', 'bk', 'rt', 'lf', 'up', 'dn'):
        projected = sample(pixels, directions(face, u, v))
        data = np.round(projected).clip(0, 255).astype(np.uint8)
        path = ROOT / f'keyboard-archive-{face}.png'
        Image.fromarray(data).save(path)
        faces[face] = data
        metadata[face] = {'file': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

    # These pairings verify continuity across every edge of the folded cube.
    edges = [
        ('ft-right/rt-left', faces['ft'][:, -1], faces['rt'][:, 0]),
        ('rt-right/bk-left', faces['rt'][:, -1], faces['bk'][:, 0]),
        ('bk-right/lf-left', faces['bk'][:, -1], faces['lf'][:, 0]),
        ('lf-right/ft-left', faces['lf'][:, -1], faces['ft'][:, 0]),
        ('ft-top/up-top', faces['ft'][0], faces['up'][0]),
        ('bk-top/up-bottom', faces['bk'][0], faces['up'][-1, ::-1]),
        ('rt-top/up-right', faces['rt'][0], faces['up'][:, -1]),
        ('lf-top/up-left', faces['lf'][0], faces['up'][::-1, 0]),
        ('ft-bottom/dn-bottom', faces['ft'][-1], faces['dn'][-1]),
        ('bk-bottom/dn-top', faces['bk'][-1], faces['dn'][0, ::-1]),
        ('rt-bottom/dn-right', faces['rt'][-1], faces['dn'][::-1, -1]),
        ('lf-bottom/dn-left', faces['lf'][-1], faces['dn'][:, 0]),
    ]
    seam_errors = {name: int(np.abs(a.astype(int) - b.astype(int)).max()) for name, a, b in edges}
    assert max(seam_errors.values()) <= 1, seam_errors
    # Studio uses different face axes; these transforms were checked against rendered joins.
    roblox = {}
    for name, face, transform, filename in (
        ('SkyboxFt', 'bk', None, 'keyboard-archive-bk.png'),
        ('SkyboxBk', 'ft', None, 'keyboard-archive-ft.png'),
        ('SkyboxRt', 'rt', None, 'keyboard-archive-rt.png'),
        ('SkyboxLf', 'lf', None, 'keyboard-archive-lf.png'),
        ('SkyboxUp', 'up', Image.TRANSPOSE, 'keyboard-archive-up-roblox.png'),
        ('SkyboxDn', 'dn', Image.TRANSVERSE, 'keyboard-archive-dn-roblox-final.png'),
    ):
        path = ROOT / filename
        if transform is not None:
            Image.fromarray(faces[face]).transpose(transform).save(path)
        roblox[name] = {'file': filename, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    report = {'size': SIZE, 'source_size': list(Image.open(ROOT / 'panorama-source.png').size),
              'faces': metadata, 'roblox_faces': roblox, 'edge_max_channel_error': seam_errors,
              'note': 'Technical spherical seam/pole normalization and bilinear cube projection; sky art generated with ImageGen.'}
    (ROOT / 'texture-manifest.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'faces': len(faces), 'edge_checks': len(edges), 'max_edge_error': max(seam_errors.values())}))


if __name__ == '__main__':
    build()
