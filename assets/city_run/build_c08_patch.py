"""Build an editable overlay while preserving the installed owner's C07 edits."""
import json
import sys
import types
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
details = (OUT / 'city_details.py').read_text()
details = details.replace("owner('MarketLife','Market')", "owner('MarketArch','Market',(-170,0,196))")
details = details.replace("        if y:box('Brick',(x,y/2,z),(13,y,11))", "        owner(f'MarketStall_{x}_{z}','Market',(x,y,z))\n        if y:box('Brick',(x,y/2,z),(13,y,11))")
details = details.replace("    for x,z in [(-191,261),(-148,264),(-191,220),(-149,220),(-210,185),(-135,185)]:tree(x,0,z,6)",
    "    for i,(x,z) in enumerate([(-183,263),(-157,267),(-183,221),(-156,217),(-206,181),(-132,181)]):\n        owner(f'MarketTree_{i+1:02}','Market',(x,0,z))\n        tree(x,0,z,3.4)")
details = details.replace("    for x,z in [(-185,244),(-154,244),(-188,202),(-152,202),(-200,140)]:lamp(x,0,z)",
    "    for i,(x,z) in enumerate([(-185,244),(-154,244),(-188,202),(-152,202),(-200,140)]):\n        owner(f'MarketLamp_{i+1:02}','Market',(x,0,z))\n        lamp(x,0,z)")
details = details.replace("    for z in (235,216):", "    for z in (235,216):\n        owner(f'MarketBunting_{z}','Market',(-170,0,z))")
module = types.ModuleType('city_details')
exec(compile(details, str(OUT / 'city_details.py'), 'exec'), module.__dict__)
sys.modules['city_details'] = module
source = (OUT / 'build_city.py').read_text().split('objects=[];meshinfo={}')[0]
source = source.replace('owner("Route_"+s["section"]+f"_{i//5:03}",s["section"],s["p"])',
                        'owner("EditableSurface_"+s["name"],s["section"],s["p"])')
api = {'__file__': str(OUT / 'build_city.py')}
exec(compile(source, str(OUT / 'build_city.py'), 'exec'), api)
for name,x,z,w,d,h,color in [
    ('MarketBackdrop_A',-205,308,27,22,48,'Terracotta'),
    ('MarketBackdrop_B',-174,310,30,24,57,'Plaster'),
    ('MarketBackdrop_C',-139,309,29,22,43,'Brick'),
    ('MarketBackdrop_D',-251,248,27,31,62,'Plaster'),
    ('MarketBackdrop_E',-112,294,22,25,54,'Terracotta'),
]:
    api['building'](name,x,z,w,d,h,color,detail=True)

prefixes = ('EditableSurface_', 'Siding_', 'MarketArch', 'MarketStall_', 'MarketTree_',
            'MarketLamp_', 'MarketBunting_', 'MarketBackdrop_', 'Marker')
scene = api['scene']
scene.name = 'CityRun_C08_EditableOverlay'
objects, meshinfo = [], {}
for (comp,mat),chunks in api['groups'].items():
    if not comp.startswith(prefixes):
        continue
    for i,(vs,fs) in enumerate(chunks):
        name = f'{comp}__{mat}__{i:02}'
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vs, [], fs)
        mesh.materials.append(api['MATS'][mat])
        mesh.update()
        mesh.calc_loop_triangles()
        assert len(mesh.loop_triangles) < 20000, name
        obj = bpy.data.objects.new(name, mesh)
        scene.collection.objects.link(obj)
        objects.append(obj)
        meshinfo[name] = {'material': mat, 'component': comp, 'triangles': len(mesh.loop_triangles)}
for obj in scene.objects:
    obj.select_set(False)
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_C08_patch.fbx'), use_selection=True,
    object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
    bake_space_transform=False, add_leaf_bones=False)
data = {'revision':'C08', 'baseRevision':'C07', 'origin':[3500,0,0], 'meshes':meshinfo,
    'colors':api['COLORS'], 'components':{k:v for k,v in api['components'].items() if k.startswith(prefixes)},
    'surfaces':api['layout'].SURFACES}
(OUT/'manifest_C08_patch.json').write_text(json.dumps(data,indent=2))
def luau(v):
    if isinstance(v,dict): return '{'+','.join('['+json.dumps(k)+']='+luau(x) for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)): return '{'+','.join(luau(x) for x in v)+'}'
    if isinstance(v,str): return json.dumps(v)
    return str(v).lower()
(OUT.parents[1]/'src/ServerStorage/CourseBuilders/CityRun/C08Manifest.luau').write_text('--!strict\nreturn '+luau(data)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_C08_patch.blend'))
print(json.dumps({'meshes':len(objects),'triangles':sum(v['triangles'] for v in meshinfo.values())}))
