"""Reuse the frozen garden and the existing winch's supported mechanism only."""
import importlib.util
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(path for path in HERE.parents if (path / 'default.project.json').exists())

def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

garden = load(HERE / 'GardenRecipe.py', 'dg02_garden')
old = load(ROOT / 'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/DetailRecipes.py', 'dg02_old')
PALETTE = {name: old.PALETTE[name] for name in ('Stone', 'Earth', 'Foliage', 'Wood', 'Iron', 'Brass')}

def wall_hoist(a, e):
    source = old.tracked_mesh(a)
    for x in (-3.25, 3.25):
        for side in (-1, 1):
            old.beam(source, a, (x, side * 2.15, .12), (x, side * .42, 5.38), .65, .62)
        old.beam(source, a, (x, -1.63, 1.3), (x, 1.63, 1.3), .42, .55)
        source.box((x, 0, 4.03), (.85, 1.55, .88), 'Wood')
    for y in (-2.12, 2.12):
        source.box((0, y, .21), (7.7, .65, .42), 'Wood')
    drum = a._Mesh()
    drum.profile([(0, 1.28), (.18, 1.28), (.25, 1.04), (3.55, 1.04), (3.62, 1.28), (3.8, 1.28)], sides=12, color='Wood')
    old.move(source, drum, [[0, 0, 1], [0, 1, 0], [-1, 0, 0]], (-1.9, 0, 3.63))
    source.tube([(-4.08, 0, 3.63), (3.78, 0, 3.63)], .19, 'Iron', sides=8)
    for x in (-1.45, -.85, -.25, .35, .95, 1.5):
        circle = [(x, 1.08 * math.cos(math.tau * i / 16), 3.63 + 1.08 * math.sin(math.tau * i / 16)) for i in range(16)]
        source.tube(circle, .075, 'Brass', sides=5, closed=True)
    wheel = [(-4.07, 1.50 * math.cos(math.tau * i / 16), 3.63 + 1.50 * math.sin(math.tau * i / 16)) for i in range(16)]
    source.tube(wheel, .115, 'Iron', sides=6, closed=True)
    for i in range(6):
        angle = math.tau * i / 6
        source.tube([(-4.07, 0, 3.63), (-4.07, 1.49 * math.cos(angle), 3.63 + 1.49 * math.sin(angle))], .07, 'Iron', sides=5)
    source.tube([(-4.07, 1.49, 3.63), (-4.4, 1.49, 3.63)], .12, 'Wood', sides=8)
    result = old.tracked_mesh(a)
    matrix = [[1, 0, 0], [0, 0, -1], [0, 1, 0]]
    old.move(result, source, matrix, (0, .10, 0))
    result.occupied = [{'low': [box['low'][0], .10 - box['high'][2], box['low'][1]],
                        'high': [box['high'][0], .10 - box['low'][2], box['high'][1]]}
                       for box in source.occupied]
    result.tube([(.95, -4.61, 0), (.95, -4.61, -2.8), (.83, -4.55, -3.10)], .07, 'Brass', sides=6)
    return result, ('Wall-mount centre pivot. Intended front +Z; two closed timber mount rails on back Z=-0.10, '
                    'sloped triangulated braces, flanged horizontal drum, six rope coils, forged handwheel and crank. '
                    'Short closed rope hangs downward. Ground crate and loose tools are omitted; no platform, collision, or gameplay mechanism.')

def build_recipes(a, e):
    return garden.build_recipes(a, e) + [('MC_DG_WallHoist', *wall_hoist(a, e))]
