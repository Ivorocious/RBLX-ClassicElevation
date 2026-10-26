import hashlib
import json
import math
from collections import Counter
from pathlib import Path

ROOT = Path.cwd()
HERE = Path(__file__).resolve().parent
AUTHORED = ROOT / 'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/authored-geometry.json'
NATIVE = ROOT / 'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/dg02-native-iron-face-investigation.json'

def sub(a, b): return tuple(a[k] - b[k] for k in range(3))
def add(a, b): return tuple(a[k] + b[k] for k in range(3))
def mul(a, n): return tuple(a[k] * n for k in range(3))
def dot(a, b): return sum(a[k] * b[k] for k in range(3))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def length(a): return math.sqrt(dot(a, a))

def nearest(point, a, b, c):
    ab, ac, ap = sub(b, a), sub(c, a), sub(point, a)
    d1, d2 = dot(ab, ap), dot(ac, ap)
    if d1 <= 0 and d2 <= 0: return a
    bp = sub(point, b); d3, d4 = dot(ab, bp), dot(ac, bp)
    if d3 >= 0 and d4 <= d3: return b
    vc = d1*d4 - d3*d2
    if vc <= 0 and d1 >= 0 and d3 <= 0: return add(a, mul(ab, d1/(d1-d3)))
    cp = sub(point, c); d5, d6 = dot(ab, cp), dot(ac, cp)
    if d6 >= 0 and d5 <= d6: return c
    vb = d5*d2 - d1*d6
    if vb <= 0 and d2 >= 0 and d6 <= 0: return add(a, mul(ac, d2/(d2-d6)))
    va = d3*d6 - d5*d4
    if va <= 0 and d4-d3 >= 0 and d5-d6 >= 0:
        return add(b, mul(sub(c, b), (d4-d3)/((d4-d3)+(d5-d6))))
    den = 1/(va+vb+vc)
    return add(a, add(mul(ab, vb*den), mul(ac, vc*den)))

part = next(row for row in json.loads(AUTHORED.read_text())['parts'] if row['name'] == 'MC_DG_WallHoist__Iron')
native = json.loads(NATIVE.read_text())
vertices = part['vertices']
authored_triangles = part['triangles']
native_triangles = native['native']['triangles']

def stats(triangles):
    edges = Counter(tuple(sorted((row[k], row[(k+1)%3]))) for row in triangles for k in range(3))
    boundary = [list(pair) for pair, count in edges.items() if count == 1]
    return {'triangles': len(triangles), 'area': sum(length(cross(sub(vertices[b], vertices[a]), sub(vertices[c], vertices[a])))/2 for a,b,c in triangles),
            'boundaryEdges': boundary, 'nonmanifoldEdges': [list(pair) for pair, count in edges.items() if count != 2],
            'boundaryEdgePositions': [[vertices[a], vertices[b]] for a,b in boundary]}

def surface_difference(source, target):
    target_faces = [[vertices[k] for k in row] for row in target]
    samples = []
    for index, row in enumerate(source):
        points = [vertices[k] for k in row]
        maximum = 0; worst = None
        for weights in ((1/3,1/3,1/3), (.6,.2,.2), (.2,.6,.2), (.2,.2,.6)):
            point = tuple(sum(weights[i]*points[i][k] for i in range(3)) for k in range(3))
            distance = min(length(sub(point, nearest(point, *face))) for face in target_faces)
            if distance > maximum: maximum, worst = distance, point
        if maximum > 0.0001: samples.append({'triangle': index, 'indices': row, 'maxSampleDistance': maximum, 'point': worst})
    return {'sampleScope': 'Four interior points per source triangle, not exhaustive surface equality',
            'differingTriangles': len(samples), 'maxSampleDistance': max((row['maxSampleDistance'] for row in samples), default=0),
            'largestDifferences': sorted(samples, key=lambda row: row['maxSampleDistance'], reverse=True)[:12]}

report = {'inputHashes': {str(path.relative_to(ROOT)).replace('\\','/'): hashlib.sha256(path.read_bytes()).hexdigest() for path in (AUTHORED,NATIVE)},
          'nativeVertexMaxError': native['native']['maxVertexError'],
          'authored': stats(authored_triangles), 'native': stats(native_triangles),
          'authoredToNativeSurfaceSamples': surface_difference(authored_triangles,native_triangles),
          'nativeToAuthoredSurfaceSamples': surface_difference(native_triangles,authored_triangles),
          'boundary': 'Uses native faces mapped by root to authored vertex indices. Native vertex positions agree within 9.611e-7. Surface samples use those authored coordinates; no Studio or payload mutation.'}
(HERE / 'dg02-native-iron-surface-investigation.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf8')
print(json.dumps({key: {k:v for k,v in row.items() if k not in ('boundaryEdges','nonmanifoldEdges','boundaryEdgePositions','largestDifferences')} for key,row in report.items() if key in ('authored','native','authoredToNativeSurfaceSamples','nativeToAuthoredSurfaceSamples')}))
print('native boundary edges:',len(report['native']['boundaryEdges']))
