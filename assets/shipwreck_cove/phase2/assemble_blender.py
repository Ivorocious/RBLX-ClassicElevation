"""Assemble editable linked kit meshes; no new geometry or asset upload required."""
import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parent
data=json.loads((ROOT/'layout.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(ROOT.parent/'phase1/ShipwreckCove_Kit04.blend'),link=False) as (src,dst):
    dst.meshes=[n for n in src.meshes]
meshes={m.name:m for m in dst.meshes}
groups={}
for p in data['placements']:
    if p['section'] not in groups:
        c=bpy.data.collections.new(p['section']);bpy.context.scene.collection.children.link(c);groups[p['section']]=c
    name=p['asset']; mesh=next((m for n,m in meshes.items()if n==name or n.startswith(name+'.')),None)
    if mesh is None:mesh=next(m for n,m in meshes.items()if name in n)
    ob=bpy.data.objects.new(p['name'],mesh);groups[p['section']].objects.link(ob)
    x,y,z=p['p'];ob.location=(x,-z,y);ob.rotation_euler.z=math.radians(p['yaw'])
    ob.rotation_euler.x=math.radians(p.get('pitch',0))
    sx,sy,sz=p['scale'];ob.scale=(sx,sz,sy)
    ob['Asset']=name
coll=bpy.data.collections.new('Collision guides - hidden render');bpy.context.scene.collection.children.link(coll)
for p in data['surfaces']:
    bpy.ops.mesh.primitive_cube_add(size=1,location=(p['p'][0],-p['p'][2],p['p'][1]-p['size'][1]/2))
    ob=bpy.context.object;ob.name='COL_'+p['name'];ob.scale=(p['size'][0],p['size'][2],p['size'][1]);ob.rotation_euler.z=math.radians(p['yaw']);ob.rotation_euler.y=-math.radians(p.get('roll',0));ob.hide_render=True;ob.display_type='WIRE'
    for c in list(ob.users_collection):c.objects.unlink(ob)
    coll.objects.link(ob)
bpy.context.scene['Build']=data['build'];bpy.context.scene['PlacedVisualTriangles']=data['resource']['visualTriangles']
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('ShipwreckCove_'+data['build']+'.blend')))
print(data['resource'])
