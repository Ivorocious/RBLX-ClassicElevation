"""Read-only clearance and support check for the assembled SC_MAP_15 visuals."""
import bpy
import json
import math
from pathlib import Path

from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parent
layout = json.loads((root / 'layout.json').read_text())
assert layout['build'] == 'SC_MAP_15'
bpy.ops.wm.open_mainfile(filepath=str(root / 'ShipwreckCove_SC_MAP_15.blend'))

names = [p['name'] for p in layout['placements'] if p['asset'] in (
    'SC_R_HullBow', 'SC_R_HullMid', 'SC_R_HullStern',
    'SC_R_CaveChamber', 'SC_R_CaveTideBend', 'SC_R_HeadlandRidge')]
trees = {}
for name in names:
    ob = bpy.data.objects[name]
    verts = [ob.matrix_world @ v.co for v in ob.data.vertices]
    trees[name] = BVHTree.FromPolygons(verts, [tuple(p.vertices) for p in ob.data.polygons])

def bl(v):
    return Vector((v[0], -v[2], v[1]))

def rb(v):
    return [round(v.x, 2), round(v.z, 2), round(-v.y, 2)]

def route_scan(points, assets, threshold=2.0):
    rows = []
    for seg, (a, b) in enumerate(zip(points, points[1:])):
        length = math.hypot(b[0]-a[0], b[2]-a[2])
        steps = max(1, math.ceil(length))
        for step in range(steps+1):
            t = step / steps
            q = [a[i] + (b[i]-a[i])*t for i in range(3)]
            for height, label in ((0.5, 'foot'), (3, 'body'), (6, 'head')):
                p = bl((q[0], q[1]+height, q[2]))
                for name in assets:
                    hit = trees[name].find_nearest(p, threshold)
                    if hit[0] is not None and hit[3] < threshold:
                        rows.append(dict(segment=seg, t=round(t, 3), route=rb(p),
                                         height=label, asset=name, distance=round(hit[3], 2),
                                         meshPoint=rb(hit[0])))
    groups = {}
    for row in rows:
        key = (row['segment'], row['asset'], row['height'])
        group = groups.setdefault(key, dict(segment=row['segment'], asset=row['asset'],
                                            height=row['height'], count=0, nearest=row,
                                            first=row, last=row))
        group['count'] += 1
        group['last'] = row
        if row['distance'] < group['nearest']['distance']:
            group['nearest'] = row
    return dict(hitSamples=len(rows), clusters=list(groups.values()))

hulls = [n for n in names if n.startswith('R_Hull')]
caves = ['CaveApproach', 'TideChamber']
ship = [[-108, 13, -66]] + layout['paths']['S02'] + [[0, 43, -100]]
cave = [[108, 15, -18]] + layout['paths']['S04_Entry'] + layout['paths']['H02']
report = dict(build=layout['build'], assets=names,
              ship=route_scan(ship, hulls), cave=route_scan(cave, caves))

roof = []
for seg, (a, b) in enumerate(zip(cave[1:], cave[2:]), 1):
    dx, dz = b[0]-a[0], b[2]-a[2]
    length = math.hypot(dx, dz)
    steps = max(1, math.ceil(length/2))
    nx, nz = (-dz/length, dx/length) if length else (0, 0)
    for i in range(steps+1):
        t = i/steps
        for offset in (-5, 0, 5):
            x = a[0]+dx*t+nx*offset
            z = a[2]+dz*t+nz*offset
            floor = a[1]+(b[1]-a[1])*t
            p = bl((x, floor+6, z))
            hits = []
            for name in caves:
                hit = trees[name].ray_cast(p, Vector((0, 0, 1)), 100)
                if hit[0] is not None:
                    hits.append((hit[0].z, name))
            nearest = min(hits) if hits else None
            roof.append(dict(segment=seg, route=[round(x, 2), round(floor, 2), round(z, 2)],
                             offset=offset, roof=round(nearest[0], 2) if nearest else None,
                             roofAsset=nearest[1] if nearest else None,
                             headroom=round(nearest[0]-floor, 2) if nearest else None))
covered = [r for r in roof if r['roof'] is not None]
report['caveRoof'] = dict(sampleCount=len(roof), uncovered=[r for r in roof if r['roof'] is None],
                          minimum=min(covered, key=lambda r:r['headroom']) if covered else None,
                          below8=[r for r in covered if r['headroom'] < 8])

ridge = trees['ConnectedHeadland']
supports = []
for i, p in enumerate(layout['paths']['S03']):
    hit = ridge.ray_cast(bl((p[0], p[1]+1, p[2])), Vector((0, 0, -1)), 100)
    ridge_top = hit[0].z if hit[0] is not None else None
    supports.append(dict(node=i, route=p, ridgeTop=round(ridge_top, 2) if ridge_top is not None else None,
                         gap=round(p[1]-ridge_top, 2) if ridge_top is not None else None))
report['ridgeSupport'] = supports

ledge_edges = []
for place in layout['placements']:
    if not place['name'].startswith('S03_') or place['asset'] != 'SC_RockLedge':
        continue
    x, bottom, z = place['p']
    samples = []
    for ox in (-3.5, 0, 3.5):
        for oz in (-3.5, 0, 3.5):
            hit = ridge.ray_cast(bl((x+ox, bottom+4, z+oz)), Vector((0, 0, -1)), 100)
            top = hit[0].z if hit[0] is not None else None
            samples.append(dict(offset=[ox, oz], ridgeTop=round(top, 2) if top is not None else None,
                                gapBelowLedge=round(bottom-top, 2) if top is not None else None))
    ledge_edges.append(dict(name=place['name'], ledgeBottom=bottom, samples=samples))
report['ridgeLedgeFootprint'] = ledge_edges

out = root / 'check15.json'
out.write_text(json.dumps(report, indent=2))
print(json.dumps(dict(ship=report['ship'], cave=report['cave'], caveRoof=dict(
    sampleCount=len(roof), uncoveredCount=len(report['caveRoof']['uncovered']),
    minimum=report['caveRoof']['minimum'], below8Count=len(report['caveRoof']['below8'])),
    ridgeSupport=supports,
    ridgeLedgeSummary=[dict(name=e['name'], supported=sum(s['gapBelowLedge'] is not None and
        s['gapBelowLedge'] <= 0.5 for s in e['samples']), sampled=len(e['samples']),
        worstGap=max((s['gapBelowLedge'] for s in e['samples'] if s['gapBelowLedge'] is not None),
                     default=None)) for e in ledge_edges]), indent=2))
