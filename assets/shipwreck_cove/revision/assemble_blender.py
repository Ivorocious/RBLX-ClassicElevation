"""Assemble editable linked kit meshes; no new geometry or asset upload required."""
import bpy,json,math
from mathutils import Matrix, Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parent
data=json.loads((ROOT/'layout.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(ROOT.parent/'phase1/ShipwreckCove_Kit04.blend'),link=False) as (src,dst):
    dst.meshes=[n for n in src.meshes]
meshes={m.name:m for m in dst.meshes}
with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Revision13.blend'),link=False) as (src,dst):
    dst.meshes=[n for n in src.meshes]
meshes.update({m.name:m for m in dst.meshes})
with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Kit25.blend'),link=False) as (src,dst):
    dst.meshes=[n for n in src.meshes]
meshes.update({m.name:m for m in dst.meshes})
if data['build'] in ['SC_CAVE_26','SC_MAP_27','SC_MAP_28','SC_MAP_29','SC_MAP_30']:
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Kit26.blend'),link=False) as (src,dst):
        dst.meshes=[n for n in src.meshes]
    meshes.update({m.name:m for m in dst.meshes})
if data['build'] in ['SC_MAP_27','SC_MAP_28','SC_MAP_29','SC_MAP_30']:
    with bpy.data.libraries.load(str(ROOT/'KitHorizon27.blend'),link=False) as (src,dst):
        dst.meshes=[n for n in src.meshes]
    meshes.update({m.name:m for m in dst.meshes})
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Kit27.blend'),link=False) as (src,dst):
        dst.meshes=[n for n in src.meshes]
    meshes.update({m.name:m for m in dst.meshes})
if data['build'] in ['SC_MAP_28','SC_MAP_29','SC_MAP_30']:
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Kit28.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Wave28B.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})
if data['build'] in ['SC_MAP_29','SC_MAP_30']:
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Palm29.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})

if data['build']=='SC_MAP_30':
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_Water30.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_CliffLedges30b.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})

if data['build']=='SC_MAP_31':
    with bpy.data.libraries.load(str(ROOT/'ShipwreckCove_HullClear31.blend'),link=False) as (src,dst):
        dst.meshes=list(src.meshes)
    meshes.update({m.name:m for m in dst.meshes})

def rotation(p):
    return (Matrix.Rotation(math.radians(p['yaw']), 4, 'Z')
            @ Matrix.Rotation(math.radians(p.get('pitch',0)), 4, 'X')
            @ Matrix.Rotation(-math.radians(p.get('roll',0)), 4, 'Y'))

groups={}
for p in data['placements']:
    if p['section'] not in groups:
        c=bpy.data.collections.new(p['section']);bpy.context.scene.collection.children.link(c);groups[p['section']]=c
    name=p['asset']; mesh=next((m for n,m in meshes.items()if n==name or n.startswith(name+'.')),None)
    if mesh is None:mesh=next(m for n,m in meshes.items()if name in n)
    ob=bpy.data.objects.new(p['name'],mesh);groups[p['section']].objects.link(ob)
    x,y,z=p['p'];ob.location=(x,-z,y);ob.rotation_euler=rotation(p).to_euler()
    sx,sy,sz=p['scale'];ob.scale=(sx,sz,sy)
    ob['Asset']=name
    if p['name']=='SurgeFoam':ob.hide_render=True
    color = p.get('tint') if name == 'SC_R_Horizon28' or p.get('ocean') else ([166,159,142] if name == 'SC_R_Stalactite28' else None)
    if data['build'] == 'SC_MAP_31' and p['name'].startswith('DistantPeak'):
        color = [151,185,193]
    if data['build'] == 'SC_MAP_31' and p['name'] in ('CaveMouth26','CaveVault26','CaveSurge26','R_HullBow_179','R_HullMid_180','R_HullStern_181'):
        for slot in ob.material_slots:
            material=slot.material.copy()
            material.diffuse_color=tuple(material.diffuse_color[i]*(p['tint'][i]/255)**2.2 for i in range(3))+(1,)
            slot.link='OBJECT';slot.material=material
    if color:
        material_name = 'Stone28_' + '_'.join(map(str,color))
        material = bpy.data.materials.get(material_name) or bpy.data.materials.new(material_name)
        material.diffuse_color = tuple((v/255)**2.2 for v in color) + (1,)
        for slot in ob.material_slots:
            slot.link = 'OBJECT';slot.material = material
from mathutils import Vector
brace_collection=bpy.data.collections.new('Wreck supports28');bpy.context.scene.collection.children.link(brace_collection)
wood=bpy.data.materials.new('Support timber28');wood.diffuse_color=(.122,.052,.024,1)
for row in data.get('braces',[]):
    a=Vector((row['a'][0],-row['a'][2],row['a'][1]));b=Vector((row['b'][0],-row['b'][2],row['b'][1]))
    bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)/2)
    ob=bpy.context.object;ob.name=row['name'];ob.scale=(.72,.72,(b-a).length)
    ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();ob.data.materials.append(wood)
    for c in list(ob.users_collection):c.objects.unlink(ob)
    brace_collection.objects.link(ob)
coll=bpy.data.collections.new('Collision guides - hidden render');bpy.context.scene.collection.children.link(coll)
for p in data['surfaces']:
    rot=rotation(p)
    center=Vector((p['p'][0],-p['p'][2],p['p'][1])) + rot.to_3x3() @ Vector((0,0,-p['size'][1]/2))
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    ob=bpy.context.object;ob.name='COL_'+p['name'];ob.scale=(p['size'][0],p['size'][2],p['size'][1]);ob.rotation_euler=rot.to_euler();ob.hide_render=True;ob.display_type='WIRE'
    for c in list(ob.users_collection):c.objects.unlink(ob)
    coll.objects.link(ob)
bpy.context.scene['Build']=data['build'];bpy.context.scene['PlacedVisualTriangles']=data['resource']['visualTriangles']
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('ShipwreckCove_'+data['build']+'.blend')))
print(data['resource'])
total=0;counts={}
deps=bpy.context.evaluated_depsgraph_get()
for collection in groups.values():
    for ob in collection.objects:
        evaluated=ob.evaluated_get(deps);m=evaluated.to_mesh();m.calc_loop_triangles()
        total+=len(m.loop_triangles);counts[ob.name]=len(m.loop_triangles);evaluated.to_mesh_clear()
(ROOT/'placed-counts.json').write_text(json.dumps(dict(build=data['build'],visuals=len(counts),triangles=total,counts=counts),indent=2))
assert total==data['resource']['visualTriangles']
