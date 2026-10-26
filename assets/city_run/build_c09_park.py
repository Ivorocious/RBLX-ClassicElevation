"""Build the courtyard park at its original ground elevation."""
import json
import math
import sys
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
api = {'__file__': str(OUT / 'build_city.py')}
exec(compile((OUT / 'build_city.py').read_text().split('# Market storefronts frame')[0],
             str(OUT / 'build_city.py'), 'exec'), api)
api['groups'].clear()
api['components'].clear()
scene = api['scene']
scene.name = 'CityRun_C09_CourtyardPark'
owner, box, beam, sphere, geo = (api[k] for k in ('owner', 'box', 'beam', 'sphere', 'geo'))
api['COLORS']['Turf'] = (.29, .46, .19)
mat = bpy.data.materials.new('Turf')
mat.diffuse_color = (*api['COLORS']['Turf'], 1)
api['MATS']['Turf'] = mat

owner('Park_Paths', 'Park')
box('Cream', (-175, -.08, -24.5), (116.7, .2, 179.7))
for index, (x0, x1, z0, z1) in enumerate([
    (-229, -183, -109, -32), (-168, -121, -109, -32),
    (-229, -183, -16, 60), (-168, -121, -16, 60),
]):
    owner(f'Park_Lawn{index + 1}', 'Park')
    cut = 4
    outline = [(x0 + cut, z0), (x1 - cut, z0), (x1, z0 + cut), (x1, z1 - cut),
               (x1 - cut, z1), (x0 + cut, z1), (x0, z1 - cut), (x0, z0 + cut)]
    vertices = [(x, y, z) for y in (.04, .24) for x, z in outline]
    geo('Turf', vertices, [tuple(range(8)), tuple(reversed(range(8, 16)))]
        + [(i + 8, (i + 1) % 8 + 8, (i + 1) % 8, i) for i in range(8)])

for index, (x, z, side) in enumerate([(-231, -83, 1), (-231, 35, 1), (-118, -83, -1), (-118, 35, -1)]):
    owner(f'Park_Bench{index + 1}', 'Park')
    for dz in (-2.5, 2.5):
        box('Iron', (x, .9, z + dz), (1.8, 1.8, .45))
    for dx in (-.6, 0, .6):
        box('WoodLight', (x + dx, 1.9, z), (.5, .3, 7.5))
    for y in (2.6, 3.25):
        box('Wood', (x - side * .9, y, z), (.25, .5, 7.5))
    for dz in (-3, 3):
        beam('Iron', (x - side * .9, .8, z + dz), (x - side * .9, 3.5, z + dz), .12)

for index, (x, z, height) in enumerate([(-216, -95, 11), (-137, -93, 13), (-214, 47, 12), (-134, 45, 10)]):
    owner(f'Park_Tree{index + 1}', 'Park')
    beam('Wood', (x, .24, z), (x, height - 2, z), .55, 7)
    for dx, dz, dy, radius in [(-1.6, 0, -.6, 3.7), (1.7, 1, -.2, 3.9), (0, -1.3, 1.7, 3.6)]:
        sphere('Leaf' if dx < 0 else 'LeafLight', (x + dx, height + dy, z + dz), radius, 9, 5, (1, .8, 1))

for name, position in [('Origin', (0, 0, 0)), ('Right', (10, 0, 0)),
                       ('Up', (0, 10, 0)), ('Forward', (0, 0, -10))]:
    owner('Marker' + name, 'Calibration')
    box('Iron', position, (.1, .1, .1))

objects, meshes = [], {}
for (component, material), chunks in api['groups'].items():
    for index, (vertices, faces) in enumerate(chunks):
        name = f'{component}__{material}__{index:02}'
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(api['MATS'][material])
        mesh.update()
        mesh.calc_loop_triangles()
        obj = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(obj)
        objects.append(obj)
        meshes[name] = {'component': component, 'material': material, 'triangles': len(mesh.loop_triangles)}
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT / 'CityRun_C09_park.fbx'), use_selection=True,
                        object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = {'meshes': meshes, 'components': api['components'], 'colors': api['COLORS']}
(OUT / 'manifest_C09_park.json').write_text(json.dumps(data, indent=2))


def luau(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + json.dumps(k) + ']=' + luau(v) for k, v in value.items()) + '}'
    if isinstance(value, (list, tuple)):
        return '{' + ','.join(luau(v) for v in value) + '}'
    return json.dumps(value)


(OUT.parents[1] / 'src/ServerStorage/CourseBuilders/CityRun/C09ParkManifest.luau').write_text('--!strict\nreturn ' + luau(data) + '\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'CityRun_C09_park.blend'))
print(json.dumps({'meshes': len(meshes), 'triangles': sum(m['triangles'] for m in meshes.values())}))
