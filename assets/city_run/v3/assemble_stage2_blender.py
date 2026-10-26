from pathlib import Path
import bpy,json,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_Stage1.blend'))
plan=json.loads((ROOT/'stage2-layout.json').read_text()); manifest=json.loads((ROOT/'stage1-manifest.json').read_text()); records={a['id']:a for a in manifest['assets']}
source={a:bpy.data.objects[a] for a in records}
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
collections={}
for group in ['Architecture','Roofs','Props','Course reference - not exported']:
 c=bpy.data.collections.new(group);bpy.context.scene.collection.children.link(c);collections[group]=c
for i,p in enumerate(plan['placements']):
 o=source[p['asset']].copy();o.data=source[p['asset']].data
 o.name=f'{i+1:03d}_{p["label"] or p["asset"]}'
 d=records[p['asset']]['dimensionsRobloxXYZ'];s=p['size']
 o.scale=(s[0]/d[0],s[2]/d[2],s[1]/d[1]);x,y,z=p['pos'];o.location=(x-3500,-z,y);o.rotation_euler=(0,0,math.radians(p['yaw']))
 o['V3AssetId']=p['asset'];o['LayoutIndex']=i+1;o['OriginalRobloxPosition']=p['pos'];o['Build']=plan['build']
 collections[p['category']].objects.link(o)
# Grey wire boxes are preserved-course placement references, never replacement gameplay geometry.
refs=json.loads((ROOT.parents[2]/'docs/artifacts/city-run/v3/stage2/course-colliders.json').read_text())
for i,(name,x,y,z,sx,sy,sz) in enumerate(refs):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(x-3500,-z,y));o=bpy.context.object;o.name=f'REFERENCE_{i:03d}_{name}';o.dimensions=(sx,sz,sy);o.display_type='WIRE';o.hide_render=True
 for c in list(o.users_collection):c.objects.unlink(o)
 collections['Course reference - not exported'].objects.link(o)
 o['NotForExport']=True
bpy.context.scene.name=plan['build'];bpy.context.scene['RobloxOrigin']=[3500,0,0];bpy.context.scene['Scope']='Editable V3 scenery assembly; gameplay remains in Roblox source'
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityRun_V3_Stage2.blend'))
print(json.dumps({'build':plan['build'],'sceneryInstances':len(plan['placements']),'linkedMeshDatablocks':len(set(o.data.name for c in list(collections.values())[:3] for o in c.objects)),'courseReferences':len(refs)}))
