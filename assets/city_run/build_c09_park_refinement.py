"""Add restrained park edges and a courtyard-facing building frontage."""
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
scene.name = 'CityRun_C09_ParkRefinement'
owner, box, beam, sphere, cylinder, geo = (api[k] for k in ('owner', 'box', 'beam', 'sphere', 'cylinder', 'geo'))

for index, (x, z) in enumerate([(-216, -95), (-137, -93), (-214, 47), (-134, 45)]):
    owner(f'ParkDetail_TreeBed{index + 1}', 'Park')
    cylinder('Soil', (x, .29, z), 5.4, .1, 12)
    for segment in range(12):
        a, b = segment * math.tau / 12, (segment + 1) * math.tau / 12
        beam('Terracotta', (x + 5.6 * math.cos(a), .45, z + 5.6 * math.sin(a)),
             (x + 5.6 * math.cos(b), .45, z + 5.6 * math.sin(b)), .25, 4)

for index, (x, z, ground) in enumerate([(-214, -38, .24), (-135, -38, .24),
                                       (-215, -7, .24), (-134, -7, .24),
                                       (-207, 69, -.5), (-183, 69, -.5)]):
    owner(f'ParkDetail_Planter{index + 1}', 'Frontage' if index >= 4 else 'Park')
    box('Terracotta', (x, ground + .8, z), (7, 1.6, 2.6))
    box('Soil', (x, ground + 1.62, z), (6.4, .12, 2))
    for j, dx in enumerate((-2, 0, 2)):
        sphere('Leaf' if j % 2 else 'LeafLight', (x + dx, ground + 2.1, z), 1.5, 8, 4, (1, .65, .6))
        sphere('Coral' if j % 2 else 'Yellow', (x + dx, ground + 3, z), .4, 6, 3)

for index, (x, z) in enumerate([(-232, -48), (-117, -48), (-232, 14), (-117, 14)]):
    owner(f'ParkDetail_Lamp{index + 1}', 'Park')
    cylinder('Iron', (x, .2, z), .65, .35, 8)
    beam('Iron', (x, .2, z), (x, 8, z), .17, 6)
    box('Iron', (x, 8.35, z), (1.55, 2.1, 1.55))
    box('Light', (x, 8.4, z), (1.6, 1.3, 1.6))
    box('Iron', (x, 9.5, z), (2, .25, 2))

for bay, x in enumerate((-216, -197, -177, -157)):
    for row, y in enumerate((6.7, 16.8)):
        owner(f'ParkFront_Window{bay + 1}_{row + 1}', 'Frontage')
        if bay == 1 and row == 0:
            box('Cream', (x, 5.1, 71.7), (7.1, 10.2, .5))
            box('Iron', (x, 5.1, 71.35), (5.9, 9.3, .2))
            box('Glass', (x, 6.4, 71.18), (4.8, 5.4, .15))
            box('Cream', (x, 5.1, 71.05), (.18, 9.3, .1))
        else:
            box('Cream', (x, y, 71.7), (7.5, 7.5, .5))
            box('Glass', (x, y, 71.35), (6.4, 6.4, .18))
            box('Cream', (x, y, 71.16), (.18, 6.4, .12))
            box('Cream', (x, y, 71.15), (6.4, .18, .12))
            box('Cream', (x, y - 4, 71.2), (8.1, .55, 1.4))
    owner(f'ParkFront_Awning{bay + 1}', 'Frontage')
    x0 = x - 5
    for stripe in range(8):
        geo('Teal' if stripe % 2 == 0 else 'Cream',
            [(x0 + stripe * 1.25, 11.3, 71.2), (x0 + (stripe + 1) * 1.25, 11.3, 71.2),
             (x0 + (stripe + 1) * 1.25, 10.6, 68.1), (x0 + stripe * 1.25, 10.6, 68.1)],
            [(0, 1, 2, 3), (3, 2, 1, 0)])
    box('Teal', (x, 10.4, 68.1), (10, .45, .1))

for name, position in [('Origin', (0, 0, 0)), ('Right', (10, 0, 0)),
                       ('Up', (0, 10, 0)), ('Forward', (0, 0, -10))]:
    owner('Marker' + name, 'Calibration')
    box('Iron', position, (.1, .1, .1))

meshes, objects = {}, []
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
bpy.ops.export_scene.fbx(filepath=str(OUT / 'CityRun_C09_park_refinement.fbx'), use_selection=True,
                        object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
                        bake_space_transform=False, add_leaf_bones=False)
data = {'meshes': meshes, 'components': api['components'], 'colors': api['COLORS']}
(OUT / 'manifest_C09_park_refinement.json').write_text(json.dumps(data, indent=2))


def luau(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + json.dumps(k) + ']=' + luau(v) for k, v in value.items()) + '}'
    if isinstance(value, (list, tuple)):
        return '{' + ','.join(luau(v) for v in value) + '}'
    return json.dumps(value)


(OUT.parents[1] / 'src/ServerStorage/CourseBuilders/CityRun/C09ParkRefinementManifest.luau').write_text('--!strict\nreturn ' + luau(data) + '\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'CityRun_C09_park_refinement.blend'))
print(json.dumps({'meshes': len(meshes), 'triangles': sum(m['triangles'] for m in meshes.values())}))
