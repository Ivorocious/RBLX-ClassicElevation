"""Shipwreck Cove map revision 27; run only after manifest27.json is ready."""
from pathlib import Path
import json
import math
import runpy

ROOT = Path(__file__).resolve().parent
manifest = ROOT / 'manifest27.json'
if not manifest.exists():
    raise FileNotFoundError('manifest27.json is required before generating SC_MAP_27')

# layout26 owns the approved sealed shell, cave stone route, and all fixed course
# endpoints. Its generation side effects are intentionally part of this script.
base = runpy.run_path(str(ROOT / 'layout26.py'))
data = base['data']
assets = base['assets']
assets.update({a['id']: a for a in json.loads(manifest.read_text())['assets']})
assets.update({a['id']: a for a in json.loads((ROOT/'manifestHorizon27.json').read_text())['assets']})
required = {f'SC_R_{name}27' for name in ('Stalactite', 'Coconut', 'Palm', 'Grass', 'Wave')}
missing = required - assets.keys()
if missing:
    raise ValueError(f'manifest27.json lacks assets: {sorted(missing)}')

placements = data['placements']
surfaces = data['surfaces']
links = data['links']
original_links = list(links)
hazards = data['hazards']
paths = data['paths']
signs = data['signs']

def mesh(asset, name, p, scale=(1, 1, 1), yaw=0, section='Scenery'):
    row = dict(asset=asset, name=name, p=list(p), scale=list(scale), yaw=yaw, section=section)
    placements.append(row)
    return row

def landing(name, p, size, asset, scale, yaw=0, section='S03'):
    mesh(asset, name, (p[0], p[1]-3 if asset == 'SC_R_SeaRockFlat' else p[1]-1.88, p[2]), scale, yaw, section)
    surfaces.append(dict(name=name, p=list(p), size=list(size), yaw=yaw, section=section))

def replace_chain(section, names, nodes):
    paths[section] = [list(p) for p in nodes]
    links[:] = [edge for edge in links if not any(n in names for n in edge)]
    links.extend([[a, b] for a, b in zip(names, names[1:])])

# Red cargo traverses each whole dock row; a two-stud clearance remains before
# the opposite edge, and the surrounding clusters provide waiting space.
for row in hazards:
    if row['name'].startswith('RedCargo'):
        dock_index = int(row['name'][8])
        row['p'][0] = {1: -110, 3: -111, 4: -108}[dock_index]
        row.update(kind='sweep', axis='X', amplitude=8.0, period=3.8,
                   phase={'RedCargo1_0': 0, 'RedCargo3_3': 1.3,
                          'RedCargo4_0': 2.6}.get(row['name'], 0))

# The existing main decks keep their proven connections. Added uneven deck
# obstacles are offset from center, preserving a readable normal route.
for i, (deck, side) in enumerate([(1, -1), (4, 1), (6, -1), (9, 1)]):
    x, y, z = base['base']['ship'][deck]
    px = x + side*2.7
    pz = z
    if i == 3:
        px, pz = x, z + 3
    asset = 'SC_CargoCrate' if i % 2 else 'SC_CargoBarrel'
    mesh(asset, f'WreckObstacle27_{i}',
         (px, y, pz), (.8, .8, .8), i*31, 'S02')
    width, height = (3.2, 3.2) if asset == 'SC_CargoCrate' else (2.6, 3.52)
    surfaces.append(dict(name=f'WreckObstacle27_{i}', p=[px, y+height, pz],
                         size=[width, height, width], yaw=i*31, section='S02'))
for i, deck in enumerate((2, 7)):
    x, y, z = base['base']['ship'][deck]
    hazards.append(dict(name=f'WreckSweep27_{i}', p=[x, y+1.3, z],
                        size=[3.2, .7, .7], section='S02', kind='sweep',
                        period=4.6, amplitude=3.3, axis='X', phase=i*1.8))

# Ribs climb on a tight dogleg. Each pair is reachable with the configured
# walk speed/jump, but narrow caps and side changes require deliberate landings.
old_ribs = {f'Rib{i:02}' for i in range(10)}
placements[:] = [p for p in placements if p['name'] not in old_ribs
                 and not (p['section'] == 'X01' and p['asset'] == 'SC_DockPost')]
surfaces[:] = [s for s in surfaces if s['name'] not in old_ribs]
ribs = [(-100, 15, -67), (-93, 17, -62), (-85, 19, -65), (-77, 21, -59),
        (-69, 23, -64), (-61, 25, -58), (-53, 27, -63), (-45, 29, -57),
        (-37, 31, -62), (-29, 33, -57), (-21, 35, -63), (-14, 37, -68),
        (-8, 39, -74), (-4, 41, -81), (-4, 42, -88)]
for i, p in enumerate(ribs):
    mesh('SC_PlayableRib', f'Rib{i:02}', (p[0], p[1]-18.6, p[2]-12*.53),
         (.53, 1, .53), -90, 'X01')
    surfaces.append(dict(name=f'Rib{i:02}', p=list(p),
                         size=[1.85, .6, 1.65],
                         yaw=0, section='X01'))
replace_chain('X01', ['R2_Boarding']+[f'Rib{i:02}' for i in range(len(ribs))]+['R3_Stern'], ribs)
paths['X01'] = [data['checkpoints'][2]] + paths['X01'] + [data['checkpoints'][3]]

# Short, uneven crowns sink into the existing headland shelf. The route keeps
# the tested sequence and safe jump spacing while avoiding a row of tall pillars.
cliff_anchors = [(9, 44, -103), (19, 45, -106), (32, 47, -119), (46, 49, -129),
                 (60, 51, -136), (74, 53, -138), (88, 54, -130),
                 (101, 53, -119), (113, 50, -105), (123, 46, -91),
                 (131, 41, -75), (131, 35, -57), (122, 28, -38),
                 (116, 23, -30), (112, 18, -23)]
cliff = [cliff_anchors[0]]
for a, b in zip(cliff_anchors, cliff_anchors[1:]):
    steps = max(1, math.ceil(math.dist(a, b) / 12), math.ceil(max(0,b[1]-a[1]) / 2))
    for step in range(1, steps+1):
        t = step / steps
        cliff.append(tuple(round(a[k] + (b[k]-a[k])*t, 2) for k in range(3)))
staggered = []
for i, p in enumerate(cliff):
    if i in (0, len(cliff)-1):
        staggered.append(p)
        continue
    before, after = cliff[i-1], cliff[i+1]
    dx, dz = after[0]-before[0], after[2]-before[2]
    length = math.hypot(dx, dz)
    side = 1.15*math.sin(i*1.73)
    staggered.append((round(p[0]-dz/length*side, 2),
                      round(p[1]+.28*math.sin(i*1.29), 2),
                      round(p[2]+dx/length*side, 2)))
cliff = staggered
old_cliff = {f'S03_{i:02}' for i in range(11)}
placements[:] = [p for p in placements if p['name'] not in old_cliff]
surfaces[:] = [s for s in surfaces if s['name'] not in old_cliff]
data['crumble'] = list(data['crumble'])
for i, p in enumerate(cliff):
    broad = i in (7, 15, 23)
    width, depth = (9.5, 8.8) if broad else (7.1 + .4*(i % 3), 7.0 + .3*(i % 2))
    yaw = (9, -11, 15, -5, 12, -14)[i % 6]
    name = f'S03_{i:02}'
    skirt = 12.5 + (i%4)*1.15
    mesh('SC_R_CrumbleStone26', name, (p[0], p[1]-skirt, p[2]),
         (width/4.6, skirt/16, depth/4.3), yaw, 'S03')
    surfaces.append(dict(name=name, p=list(p), size=[width, 1, depth],
                         section='S03', yaw=yaw))
    if i%4 == 2:
        radial = math.hypot(p[0], p[2])
        shoulder = mesh('SC_R_SeaRockFlat', f'CliffShoulder27_{i}',
                        (p[0]+p[0]/radial*4.5, p[1]-11.8,
                         p[2]+p[2]/radial*4.5),
                        (.72, 1.8+(i%3)*.12, .68), yaw+31, 'S03')
        shoulder['tint'] = [175, 168, 145]
    if not broad:
        data['crumble'].append(name)
replace_chain('S03', ['R3_Stern']+[f'S03_{i:02}' for i in range(len(cliff))]+['R4_CaveEntry'], cliff)
for row in hazards:
    if row['name'].startswith('CliffSweep') or row['name'].startswith('CliffDanger'):
        old_index = int(row['name'][-1])
        nearest = min(cliff, key=lambda p: math.dist(p, cliff_anchors[old_index+1]))
        row['p'] = [nearest[0], nearest[1]+(.4 if 'Danger' in row['name'] else 1), nearest[2]]

# Expert spar route turns twice and has shorter, narrower landing strips.
old_spars = {f'Spar{i:02}' for i in range(7)}
placements[:] = [p for p in placements if p['name'] not in old_spars
                 and not (p['section'] == 'X02' and p['asset'] == 'SC_DockPost')]
surfaces[:] = [s for s in surfaces if s['name'] not in old_spars]
spar = [(16, 41, -91), (23, 38, -84), (31, 35, -78), (39, 32, -72),
        (47, 29, -66), (55, 26, -60), (63, 23, -54), (71, 21, -47),
        (79, 19, -41), (87, 17, -34), (95, 16, -27)]
for i, p in enumerate(spar):
    yaw = (-24, 21, -26, 17)[i % 4]
    landing(f'Spar{i:02}', p, (5.3, 1.88, 1.8), 'SC_BrokenSpar',
            (.34, 1, .64), yaw, 'X02')
    surfaces[-1]['size'][2] = 1.75
    mesh('SC_DockPost', f'SparSupport27_{i}', (p[0], -6, p[2]),
         (1.0, (p[1]+5)/10, 1.0), yaw, 'X02')
replace_chain('X02', ['R3_Stern']+[f'Spar{i:02}' for i in range(len(spar))]+['R4_CaveEntry'], spar)
paths['X02'] = [data['checkpoints'][3]] + paths['X02'] + [data['checkpoints'][4]]
signs.append(dict(text='SPAR SHORTCUT', sub='Short narrow landings / watch each turn',
                  p=[9, 46, -89], yaw=0))

# Remove every old grass clump and replace it with the new root-authored mesh.
grass = [p for p in placements if p['asset'] == 'SC_R_GrassClump']
placements[:] = [p for p in placements if p['asset'] != 'SC_R_GrassClump']
for i, p in enumerate(grass):
    mesh('SC_R_Grass27', f'Grass27_{i:02}', p['p'], (.9, 1, .9), p['yaw'], p['section'])

# Shore palms are large but their trunks stay outside the 12-stud return lane.
for p in placements:
    if p['name'].startswith('BeachPalm'):
        p['asset'] = 'SC_R_Palm27'
        p['scale'] = [1.05, 1.1, 1.05]
palms = [(16, 3, 88), (-4, 3, 101), (-24, 3, 111),
         (-50, 3, 122), (-74, 3, 133)]
for i, p in enumerate(palms):
    mesh('SC_R_Palm27', f'DropPalm27_{i}', p, (1.25, 1.25, 1.25), i*37, 'S04_Shore')
for p in placements:
    if p['name'] == 'SurgeWave':
        p['asset'] = 'SC_R_Wave27'
        p['yaw'] = 0
        p['p'] = [69, 5, 66]
        p['scale'] = [1, 5/assets['SC_R_Wave27']['dimensionsRobloxXYZ'][1], 1]

# Beyond the cove, low varied silhouettes give depth without a giant wall.
for i, (x, z, s, yaw) in enumerate([
    (-490, -160, 1.7, 31), (485, 155, 2.1, -17),
    (390, -355, 2.3, 115), (-135, 465, 1.8, 50),
]):
    section = f'DistantIsland27_{i}'
    mesh('SC_R_SandIsland', f'OuterSand27_{i}', (x, -6, z), (s*2, 2, s*1.4), yaw, section)
    mesh('SC_R_SeaRockTall' if i % 2 else 'SC_R_SeaRockSpire',
         f'OuterRock27_{i}', (x-10, -5, z+8), (s*1.2, s*.8, s), yaw+31, section)
for i in range(18):
    a=i*2*math.pi/18+.07
    x,z=360*math.cos(a),360*math.sin(a)
    section=f'DistantIslandRidge27_{i}'
    mesh('SC_R_SeaRockTall',f'HorizonRidge27_{i}',(x,-8,z),
         (13+(i%3),5.3+(i%4)*.7,7),-math.degrees(a)+90,section)
    mesh('SC_R_SandIsland',f'HorizonShore27_{i}',(x,-5,z),
         (5,2.1,5),-math.degrees(a)+90,section)
placements[:]=[p for p in placements if not p['section'].startswith('DistantIsland27_')]
placements[:]=[p for p in placements if not p['name'].startswith('HorizonRidge27_')]
placements[:]=[p for p in placements if not p['name'].startswith('HorizonShore27_') and p['asset']!='SC_CavePortal']
for p in json.loads((ROOT/'horizon27-placement-proposal.json').read_text())['placements']:
    placements.append({k:v for k,v in p.items() if k!='row'})
# Tiny clumps cannot contribute to silhouettes at this distance.
placements[:]=[p for p in placements if not
    (p['section'].startswith('DistantIsland') and p['asset']=='SC_R_Grass27')]

# Ceiling-local spikes: roof anchors are roughly 28-40 studs above the
# approved cave floor. The caller validates mesh attachment against the shell.
fixed_spikes = [(106, 29, 4), (136, 34, 22), (105, 34, 36),
                (133, 32, 47), (82, 27, 65), (56, 25, 72)]
for i, p in enumerate(fixed_spikes):
    mesh('SC_R_Stalactite27', f'FixedSpike27_{i}', p, (.75, .8, .75), i*43, 'S04')

falling = []
for i, (x, roof, z, floor) in enumerate([(115, 39, 8, 12), (124, 42, 29, 12),
                                         (117, 40, 48, 10), (75, 36, 58, 5)]):
    falling.append(dict(name=f'FallingSpike27_{i}', kind='stalactite',
                        top=[x, roof, z], bottom=[x, floor+3, z], radius=2.3,
                        period=5.4, warning=1.3, fallTime=.48, hold=.75,
                        phase=i*1.15))
for i, (x, y, z) in enumerate(palms):
    falling.append(dict(name=f'FallingCoconut27_{i}', kind='coconut',
                        top=[x, y+21, z-8], bottom=[x, 9.1, z-8], radius=2.4,
                        period=6.1, warning=1.45, fallTime=.55, hold=.7,
                        phase=i*1.17))
data['falling'] = falling
changed_nodes = old_ribs | old_cliff | old_spars
links[:] = [edge for edge in original_links if not any(n in changed_nodes for n in edge)]
for chain in [
    ['R2_Boarding']+[f'Rib{i:02}' for i in range(len(ribs))]+['R3_Stern'],
    ['R3_Stern']+[f'S03_{i:02}' for i in range(len(cliff))]+['R4_CaveEntry'],
    ['R3_Stern']+[f'Spar{i:02}' for i in range(len(spar))]+['R4_CaveEntry'],
]:
    links.extend([[a,b] for a,b in zip(chain,chain[1:])])
grounding_file=ROOT/'grounding27.json'
if grounding_file.exists():
    grounding=json.loads(grounding_file.read_text())
    for p in placements:
        if p['name'] in grounding['placements']:p['p']=grounding['placements'][p['name']]
    for d in falling:
        if d['name'] in grounding['falling']:d.update(grounding['falling'][d['name']])
data['build'] = 'SC_MAP_27'
for sign in data['signs']:
    if sign['text'] == 'WAIT FOR LOW TIDE':
        sign['p'] = [98, 15.5, 48]
placements[:] = [p for p in placements if p['asset'] != 'SC_DangerStripe']
data['kitBuild'] = json.loads(manifest.read_text())['build']
data['resource'] = dict(visuals=len(placements),
                        visualTriangles=sum(assets[p['asset']]['triangles'] for p in placements),
                        colliders=len(surfaces))
assert data['resource']['visualTriangles'] < 35000, data['resource']
assert len(placements)+len(surfaces)+200 < 1200
assert len({p['asset'] for p in placements} | {'SC_R_Coconut27', 'SC_R_Stalactite27'}) <= 48
assert sum(p['name'].startswith('CaveLamp') for p in placements) <= 6
assert len(data['checkpoints']) == 5 and data['gate'] == [-108, 8, 110]
assert len(falling) == 9

dest = ROOT.parents[2] / 'src/ServerStorage/CourseBuilders/ShipwreckCove'
(ROOT/'layout27.json').write_text(json.dumps(data, indent=2))
(ROOT/'layout.json').write_text(json.dumps(data, indent=2))
(dest/'Layout.luau').write_text('-- Generated by assets/shipwreck_cove/revision/layout27.py\nreturn '+base['lua'](data)+'\n')
(dest/'Kit.luau').write_text('return '+base['lua'](assets)+'\n')
print(json.dumps(data['resource']))

