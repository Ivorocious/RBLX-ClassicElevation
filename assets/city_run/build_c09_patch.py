"""Build semantic editing pieces and a courtyard depth overlay for preserved C08."""
import json
import math
import sys
import textwrap
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
source = (OUT / 'build_city.py').read_text().split('# Market storefronts frame')[0]
api = {'__file__': str(OUT / 'build_city.py')}
exec(compile(source, str(OUT / 'build_city.py'), 'exec'), api)
scene = api['scene']
scene.name = 'CityRun_C09_EditableDepth'
box, beam, geo, text = (api[k] for k in ('box', 'beam', 'geo', 'text'))
component_sources = {}
original_owner = api['owner']


def owner(name, section='Scenery', pivot=(0, 0, 0), source_model=None):
    original_owner(name, section, pivot)
    component_sources[name] = source_model


for cp, location, normal in [(2, (-190, 31, 68), (1, 0)),
                             (4, (-105, 82, -254), (-1, 0)),
                             (8, (223, 86, 74), (0, -1))]:
    base = f'BranchDirections{cp}'
    x, y, z = location
    nx, nz = normal
    scale = 1 if cp == 2 else .72

    def point(u, v, n=0):
        return x + u * nz + n * nx, y + v, z - u * nx + n * nz

    for side, u in enumerate((-4 * scale, 4 * scale)):
        owner(f'{base}_Support{side + 1}', 'Wayfinding', source_model=base)
        beam('Iron', point(u, -11 if cp == 8 else -2), point(u, 10.6), .14)
    for v, color, label in ((9, 'Teal', 'MAIN'), (5.5, 'Yellow', 'EXPERT')):
        owner(f'{base}_Board_{label}', 'Wayfinding', source_model=base)
        box(color, point(0, v), (.45, 2.8 * scale, 11 * scale) if nx else (11 * scale, 2.8 * scale, .45))
        for face in (-1, 1):
            owner(f'{base}_Lettering_{label}_{face}', 'Wayfinding', source_model=base)
            text(label, point(-.7 * scale, v, .3 * face), 1.25 * scale,
                 'Cream' if color == 'Teal' else 'Iron', math.atan2(nx * face, nz * face))
            owner(f'{base}_Arrow_{label}_{face}', 'Wayfinding', source_model=base)
            direction = 1 if cp == 2 or color == 'Yellow' else -1
            u = direction * 4.15 * scale
            arrow = [point(u + direction * .65 * scale, v, .32 * face),
                     point(u - direction * .45 * scale, v + .65 * scale, .32 * face),
                     point(u - direction * .45 * scale, v - .65 * scale, .32 * face)]
            if cp == 2 and color == 'Teal':
                arrow = [point(u, v + .8, .32 * face), point(u - .65, v - .4, .32 * face),
                         point(u + .65, v - .4, .32 * face)]
            geo('Cream' if color == 'Teal' else 'Iron', arrow, [(0, 1, 2), (2, 1, 0)])
    arrows = ({2: [(-157, 29.12, 80, -1, 0), (-150, 29.13, 74, 0, -1)],
               4: [(-92, 82.12, -252, 0, -1), (-84, 82.13, -244, 1, 0)],
               8: [(212, 86.12, 57, 1, 0), (199, 86.13, 57, -1, 0)]})[cp]
    for label, color, (x, y, z, dx, dz) in zip(('MAIN', 'EXPERT'), ('Teal', 'Yellow'), arrows):
        tops = [py + offset for px, py, pz, w, d, offset in api['surface_layers']
                if abs(py - y) < .5 and abs(x - px) <= w / 2 and abs(z - pz) <= d / 2]
        if tops:
            y = max(tops) + .18
        owner(f'{base}_FloorArrow_{label}', 'Wayfinding', source_model=base)
        shape = [(-.6, -2), (.6, -2), (.6, .3), (1.7, .3), (0, 2.5), (-1.7, .3), (-.6, .3)]
        geo(color, [(x + u * dz + v * dx, y, z - u * dx + v * dz) for u, v in shape],
            [tuple(range(7)), tuple(reversed(range(7)))])

for side, x in enumerate((-193, -147)):
    owner(f'MarketArch_Support{side + 1}', 'Market', source_model='MarketArch')
    box('Brick', (x, 12, 196), (3.2, 24, 3.2))
    owner(f'MarketArch_Cap{side + 1}', 'Market', source_model='MarketArch')
    box('Cream', (x, 24, 196), (4.4, 1, 4.4))
owner('MarketArch_Panel', 'Market', source_model='MarketArch')
box('Teal', (-170, 26.47149086, 196), (49, 4, .8))
for face, z, angle in [('Front', 196.5, 0), ('Back', 195.5, math.pi)]:
    owner(f'MarketArch_Lettering{face}', 'Market', source_model='MarketArch')
    text('MARKET STREET', (-170, 26, z), 3, 'Cream', angle)

# Keep the original storefront shapes while assigning useful editing units.
hero = (OUT / 'route_immersion.py').read_text().split('def hero_sets(api):\n', 1)[1]
hero = textwrap.dedent(hero.split("    owner('CourtyardCloseLife'", 1)[0])
hero = hero.replace("owner('MarketCloseFronts','Market')", '')
hero = hero.replace("    box('Cream',(x,11.5,88.3)",
                    "    owner(f'MarketCloseFronts_{label}_Window','Market')\n    box('Cream',(x,11.5,88.3)")
hero = hero.replace("    box(color,(x,20.2,88.8)",
                    "    owner(f'MarketCloseFronts_{label}_Panel','Market')\n    box(color,(x,20.2,88.8)")
hero = hero.replace("    text(label,", "    owner(f'MarketCloseFronts_{label}_Lettering','Market')\n    text(label,")
hero = hero.replace("    box(color,(x,18.6,90.2)",
                    "    owner(f'MarketCloseFronts_{label}_Awning','Market')\n    box(color,(x,18.6,90.2)")
hero = hero.replace("    for dx in (-7.4,7.4):", "    owner(f'MarketCloseFronts_{label}_Piers','Market')\n    for dx in (-7.4,7.4):")
hero = hero.replace("    for dz in (-5,0,5):", "    for dz in (-5,0,5):\n        owner(f'MarketCloseFronts_Street{name}_Window{dz}','Market')")
hero = hero.replace("    box(color,(x+nx*.5,16,z)",
                    "    owner(f'MarketCloseFronts_Street{name}_Panel','Market')\n    box(color,(x+nx*.5,16,z)")
hero = hero.replace("    text(name,", "    owner(f'MarketCloseFronts_Street{name}_Lettering','Market')\n    text(name,")
hero = hero.replace("    for dz in (-6,6):", "    for dz in (-6,6):\n        owner(f'MarketCloseFronts_Street{name}_Planter{dz}','Market')")
hero = hero.replace("    for band in range(10):", "    owner(f'MarketCloseFronts_Street{name}_Awning','Market')\n    for band in range(10):")
import route_immersion
hero_api = dict(api)
hero_api['owner'] = lambda name, section: owner(name, section, source_model='MarketCloseFronts')
exec(compile(hero, 'C09_storefronts', 'exec'), {'api': hero_api, 'math': math, 'foliage': route_immersion.foliage})

cx, cz, width, depth = -153.451171875, 111.28535461425781, 68.97915649414063, 16.74031448364258
for side in (-1, 1):
    for row, y in enumerate((6.5, 17.5, 28.5)):
        for bay, dx in enumerate((-25, -8.3, 8.3, 25)):
            owner(f'OwnerFacade_Window_{side}_{row}_{bay}', 'OwnerFacade')
            z = cz + side * (depth / 2 + .15)
            box('Cream', (cx + dx, y, z), (7.7, 8.2, .35))
            box('Glass', (cx + dx, y, z + side * .23), (6.7, 7.2, .16))
            box('Cream', (cx + dx, y, z + side * .35), (.2, 7.2, .15))
            box('Cream', (cx + dx, y - .7, z + side * .35), (6.7, .2, .15))
            box('Stone', (cx + dx, y - 4.15, z + side * .2), (8.4, .5, .8))
            if row == 1 and bay % 2 == 0:
                for shutter in (-1, 1):
                    box('Teal', (cx + dx + shutter * 4.2, y, z + side * .3), (1.2, 7.4, .25))
    for y in (12.3, 23.3):
        owner(f'OwnerFacade_FloorTrim_{side}_{y}', 'OwnerFacade')
        box('Cream', (cx, y, cz + side * (depth / 2 + .2)), (width, .45, .5))
for side in (-1, 1):
    for row, y in enumerate((7, 18, 28)):
        owner(f'OwnerFacade_EndWindow_{side}_{row}', 'OwnerFacade')
        x = cx + side * (width / 2 + .15)
        box('Cream', (x, y, cz), (.35, 7.5, 7.4))
        box('Glass', (x + side * .23, y, cz), (.15, 6.5, 6.4))
        box('Cream', (x + side * .34, y, cz), (.12, 6.5, .22))
for index, dx in enumerate((-20, 0, 20)):
    owner(f'OwnerFacade_RoofVent_{index}', 'OwnerFacade')
    box('Rail', (cx + dx, 35.6, cz), (2.4, 2.1, 2.4))
    box('Cream', (cx + dx, 36.7, cz), (3.2, .25, 3.2))

# The physical floor stays in place; these ground pieces open only the courtyard view.
for name, x0, x1, z0, z1 in [
    ('West', -465, -284.5, -445, 405), ('East', -59, 535, -445, 405),
    ('North', -284.5, -59, -445, -143), ('South', -284.5, -59, 99, 405),
]:
    owner('GroundRing_' + name, 'Depth')
    box('Stone', ((x0 + x1) / 2, -3, (z0 + z1) / 2), (x1 - x0, 5, z1 - z0))
owner('CourtyardDepth_Floor', 'Depth')
box('Rail', (-171.75, -103, -22), (225.5, 2, 242))
for index, (x, z, w, d, color) in enumerate([
    (-264, 53, 42, 90, 'Terracotta'), (-264, -68, 42, 105, 'Brick'),
    (-81, 14, 44, 65, 'Plaster'), (-82, -89, 45, 73, 'Terracotta'),
    (-180, -158, 74, 30, 'Brick'),
]):
    owner(f'CourtyardDepth_Foundation_{index}', 'Depth')
    box(color, (x, -50, z), (w, 100, d))
    side = 1 if x < -170 else -1
    for row, y in enumerate((-13, -33, -56, -80)):
        owner(f'CourtyardDepth_Bays_{index}_{row}', 'Depth')
        for dz in range(-int(d / 2) + 8, int(d / 2) - 3, 14):
            xx = x + side * (w / 2 + .15)
            box('Cream', (xx, y, z + dz), (.4, 10, 5.5))
            box('Glass', (xx + side * .25, y, z + dz), (.15, 8.6, 4.4))
        box('Cream', (x + side * (w / 2 + .15), y - 7, z), (.5, .65, d))
for z in (5, -55):
    for x in (-242, -196, -150, -104):
        owner(f'CourtyardDepth_Pier_{x}_{z}', 'Depth')
        box('Brick', (x, -50, z), (5, 100, 5))
        for y in (-29, -59, -90):
            box('Stone', (x, y, z), (6.5, 1.6, 6.5))
for index, (x, z, y, w, d) in enumerate([
    (-223, -24, -41, 20, 18), (-173, -98, -65, 27, 18), (-120, -22, -52, 19, 21),
    (-225, -90, -76, 22, 16), (-164, 45, -34, 22, 17),
]):
    owner(f'CourtyardDepth_LowRoof_{index}', 'Depth')
    box('Plaster', (x, (-101 + y) / 2, z), (w, y + 101, d))
    box('Roof', (x, y, z), (w + 1, .5, d + 1))
    box('Cream', (x, y + 1, z - d / 2), (w + 1, 2, .6))

for name, p in [('Origin', (0, 0, 0)), ('Right', (10, 0, 0)), ('Up', (0, 10, 0)), ('Forward', (0, 0, -10))]:
    owner('Marker' + name, 'Calibration', p)
    box('Iron', p, (.1, .1, .1))

objects, meshes = [], {}
frames = json.loads((OUT / 'c09_source_mesh_frames.json').read_text())
for (comp, mat), chunks in api['groups'].items():
    if comp not in component_sources:
        continue
    for index, (vertices, faces) in enumerate(chunks):
        name = f'{comp}__{mat}__{index:02}'
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(api['MATS'][mat])
        mesh.update()
        mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles) < 20000, name
        obj = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(obj)
        objects.append(obj)
        source_model = component_sources[comp]
        source_mesh = f'{source_model}__{mat}__00' if source_model else None
        if source_mesh:
            assert source_mesh in frames, source_mesh
        meshes[name] = {'component': comp, 'material': mat, 'triangles': len(mesh.loop_triangles), 'sourceMesh': source_mesh}
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT / 'CityRun_C09_patch.fbx'), use_selection=True,
                        object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = {'revision': 'C09', 'meshes': meshes, 'colors': api['COLORS'], 'sourceFrames': frames,
        'components': {name: api['components'][name] for name in component_sources}}
(OUT / 'manifest_C09_patch.json').write_text(json.dumps(data, indent=2))


def luau(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + json.dumps(k) + ']=' + luau(v) for k, v in value.items()) + '}'
    if isinstance(value, (list, tuple)):
        return '{' + ','.join(luau(v) for v in value) + '}'
    if isinstance(value, str):
        return json.dumps(value)
    if value is None:
        return 'nil'
    return str(value).lower()


(OUT.parents[1] / 'src/ServerStorage/CourseBuilders/CityRun/C09Manifest.luau').write_text('--!strict\nreturn ' + luau(data) + '\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'CityRun_C09_patch.blend'))
print(json.dumps({'meshes': len(objects), 'components': len(component_sources),
                  'triangles': sum(m['triangles'] for m in meshes.values())}))
