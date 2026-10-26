"""Three low-cost coastal silhouettes for the Shipwreck Cove horizon."""
from pathlib import Path
import json
import math

ROOT = Path(__file__).resolve().parent
exec((ROOT / 'build_revision.py').read_text().split('# Hull axis is local Y.')[0])
BUILD = 'SC_HORIZON_KIT_27'

# Blender X is Roblox X, Blender Z is Roblox Y. The eight irregular crown
# stations leave low saddles between separated pale limestone peaks.
variants = [
    ('HorizonTeeth27', 132, 46, [5, 24, 76, 19, 15, 88, 42, 7]),
    ('HorizonSaddle27', 148, 45, [6, 54, 22, 9, 18, 63, 80, 5]),
    ('HorizonBroken27', 116, 47, [4, 38, 85, 43, 11, 50, 67, 6]),
]

for variant_index, (name, width, depth, heights) in enumerate(variants):
    g = Geo()
    verts = []
    station_x = [-width/2, -.37*width, -.21*width, -.065*width,
                 .09*width, .24*width, .39*width, width/2]
    for i, (x, h) in enumerate(zip(station_x, heights)):
        bend = (math.sin(i*2.1+variant_index*1.7)*2.2 if i not in (0, 7) else 0)
        verts.extend([
            (x, -depth/2, 0),
            (x+bend*.4, -depth*.38, h*.48),
            (x+bend, -depth*.11, h),
            (x-bend*.3, depth*.16, h*(.79+.04*math.sin(i+variant_index))),
            (x-bend*.5, depth*.40, h*.42),
            (x, depth/2, 0),
        ])
    faces = []
    colors = []
    for i in range(7):
        for band in range(6):
            a=i*6+band
            b=i*6+(band+1)%6
            c=(i+1)*6+(band+1)%6
            d=(i+1)*6+band
            faces.append((a,b,c,d))
            if band == 2:
                # Moss occupies a few upper facets, leaving most pale stone.
                color = LEAF_L if (i+2*variant_index)%4 == 1 else CREAM
            elif band == 1:
                color = CREAM if i%3 else STONE
            elif band in (0,4):
                color = STONE_SHADE if i%3 else STONE
            elif band == 3:
                color = STONE if i%2 else LEAF
            else:
                color = STONE_SHADE
            colors.append(color)
    faces.extend([tuple(reversed(range(6))), tuple(42+i for i in range(6))])
    colors.extend([STONE_SHADE, STONE])
    g.mesh(verts, faces, colors)
    asset(name, g, 'coastal_ridge',
          'Irregular distant limestone silhouette; pale upper faces and restrained moss. Visual only.',
          estimated_placements=6)

for i, row in enumerate(rows):
    objects[row['id']].location = (i*200, 0, 0)
    row['centerBlender'] = [(row['boundsBlender']['min'][k]+row['boundsBlender']['max'][k])/2
                            for k in range(3)]
bpy.context.view_layer.update()
for ob in objects.values():
    ob.select_set(True)

blend = ROOT / 'KitHorizon27.blend'
fbx = ROOT / 'KitHorizon27.fbx'
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={'MESH'},
                         apply_unit_scale=True, axis_forward='-Z', axis_up='Y',
                         path_mode='COPY', embed_textures=True,
                         use_mesh_modifiers=True, bake_anim=False)

assert len(rows) == 3
assert all(80 <= row['triangles'] <= 100 for row in rows)
assert sum(row['triangles']*row['estimatedPlacements'] for row in rows) <= 1800
manifest = dict(build=BUILD, assets=rows,
                libraryTriangles=sum(row['triangles'] for row in rows),
                placedTrianglesAt18=sum(row['triangles']*row['estimatedPlacements'] for row in rows),
                assetCeiling=1500, kitCeiling=5000, materialCount=1,
                atlas='palette.png')
(ROOT / 'manifestHorizon27.json').write_text(json.dumps(manifest, indent=2))

# Candidate screen composition only. Integration can adjust positions after
# player-height review; these placements do not modify the live layout.
asset_order = [0,1,2,1,2,0,2,0,1,0,1,2,1,2,0,2,0,1]
back_sectors = {2,5,8,11,14,17}
proposal = []
for i, variant in enumerate(asset_order):
    back = i in back_sectors
    angle = math.radians(i*20 + (5 if back else -2+(i%3)*2))
    radius = (425+(i%3)*10) if back else (350+(i%4)*9)
    proposal.append(dict(name=f'HorizonRidge27_{i}',
                         asset=rows[variant]['id'],
                         p=[round(radius*math.cos(angle),2), -8,
                            round(radius*math.sin(angle),2)],
                         scale=[round(.91+(i%4)*.055,3),
                                round(.85+(i%5)*.055,3),
                                round(.86+(i%3)*.10,3)],
                         yaw=round(90-math.degrees(angle),2),
                         section=f'DistantIslandRidge27_{i}',
                         row='back' if back else 'front'))
(ROOT / 'horizon27-placement-proposal.json').write_text(json.dumps(dict(
    build=BUILD, status='proposal_only', origin='course_local',
    notes='Twelve near silhouettes and six offset back silhouettes; review from player height before integration.',
    placements=proposal), indent=2))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(fbx))
counts = {}
for ob in bpy.context.scene.objects:
    if ob.type == 'MESH':
        mesh = ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        mesh.calc_loop_triangles()
        counts[ob.name] = len(mesh.loop_triangles)
assert sum(counts.values()) == manifest['libraryTriangles'], counts
(ROOT / 'export-verification-horizon27.json').write_text(json.dumps(
    dict(build=BUILD, triangles=sum(counts.values()), assets=counts,
         modifiersApplied=True, fbxReimportPassed=True), indent=2))
print(json.dumps(dict(libraryTriangles=manifest['libraryTriangles'],
                      placedTrianglesAt18=manifest['placedTrianglesAt18'],
                      reimported=counts)))
