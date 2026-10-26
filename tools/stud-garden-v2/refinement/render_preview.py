"""Render exported course geometry in an isolated Blender process, never in Studio."""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

parser=argparse.ArgumentParser()
parser.add_argument('geometry',type=Path)
parser.add_argument('output',type=Path)
parser.add_argument('--views',type=Path)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
args.geometry=args.geometry.resolve();args.output=args.output.resolve()
if args.views: args.views=args.views.resolve()
root=Path(__file__).resolve().parents[3]
data=json.loads(args.geometry.read_text())
args.output.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
conversion=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
origin=Vector(data['attributes']['CourseOrigin']['value'])
materials={}
def linear(x): return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
def material(color,alpha=1):
    key=tuple(round(x,4) for x in color)+(round(alpha,3),)
    if key not in materials:
        m=bpy.data.materials.new('Paint_'+str(len(materials)))
        m.diffuse_color=(*color,alpha);m.use_nodes=True
        p=m.node_tree.nodes.get('Principled BSDF')
        p.inputs['Base Color'].default_value=(*(linear(x) for x in color),1)
        p.inputs['Roughness'].default_value=.66
        p.inputs['Alpha'].default_value=alpha
        materials[key]=m
    return materials[key]

sources={}
for asset_file in [root/f'assets/stud_garden_v2/phase1/SGV2_{version}.blend' for version in ('M01','M02')]+[root/'docs/artifacts/stud-garden-v2/phase3/f04/SGV2_Phase3_F04.blend',root/'docs/artifacts/stud-garden-v2/refinement-20261005/r01/SGV2_Botanical_R01.blend']:
    with bpy.data.libraries.load(str(asset_file),link=False) as (a,b):
        b.objects=[name for name in a.objects if '__' in name]
    for obj in b.objects:
        if obj is None or obj.type!='MESH': continue
        points=[obj.matrix_world@v.co for v in obj.data.vertices]
        # FBX Y-up mesh coordinates; CFrame supplies each native part's rotation.
        points=[Vector((v.x,v.z,-v.y)) for v in points]
        low=Vector(tuple(min(v[i] for v in points) for i in range(3)))
        high=Vector(tuple(max(v[i] for v in points) for i in range(3)))
        center=(low+high)/2;size=high-low
        normalized=[tuple((v[i]-center[i])/max(size[i],1e-6)*(1 if i==1 else -1) for i in range(3)) for v in points]
        sources[obj.name.split('.')[0]]=(normalized,[tuple(p.vertices) for p in obj.data.polygons])

box=[(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,-.5),(.5,.5,-.5),(-.5,.5,.5),(.5,.5,.5)]
faces=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
wedge=box[:4]+box[6:]
wedge_faces=[(0,1,3,2),(2,3,5,4),(0,4,5,1),(0,2,4),(1,5,3)]
def shape(p):
    if p['class']=='MeshPart' and p['name'] in sources: return sources[p['name']]
    if p['class']=='WedgePart': return wedge,wedge_faces
    if p['shape']=='Cylinder':
        verts=[(x,math.cos(i*math.tau/24)*.5,math.sin(i*math.tau/24)*.5) for x in (-.5,.5) for i in range(24)]
        polys=[tuple(range(23,-1,-1)),tuple(range(24,48))]+[(i,(i+1)%24,(i+1)%24+24,i+24) for i in range(24)]
        return verts,polys
    if p['shape']=='Ball':
        verts=[(.5*math.sin(j*math.pi/10)*math.cos(i*math.tau/20),.5*math.cos(j*math.pi/10),.5*math.sin(j*math.pi/10)*math.sin(i*math.tau/20)) for j in range(11) for i in range(20)]
        polys=[(j*20+i,j*20+(i+1)%20,(j+1)*20+(i+1)%20,(j+1)*20+i) for j in range(10) for i in range(20)]
        return verts,polys
    return box,faces

font_path=Path('C:/Windows/Fonts/arialbd.ttf')
font=bpy.data.fonts.load(str(font_path)) if font_path.exists() else None
missing=[]
labels={}
for label in data['labels']:
    if 'partPath' in label:labels.setdefault(label['partPath'],[]).append(label)
for i,p in enumerate(data['parts']):
    if p['transparency']>=.99: continue
    cf=p['cf'];rot=Matrix((cf[3:6],cf[6:9],cf[9:12]));pos=Vector(cf[:3])-origin
    verts,polys=shape(p)
    if p['class']=='MeshPart' and p['name'] not in sources: missing.append(p['path'])
    size=[min(p['size'])]*3 if p['shape']=='Ball' else ([p['size'][0],min(p['size'][1:]),min(p['size'][1:])] if p['shape']=='Cylinder' else p['size'])
    points=[conversion@(rot@Vector(tuple(v[k]*size[k] for k in range(3)))+pos) for v in verts]
    mesh=bpy.data.meshes.new(p['name']);mesh.from_pydata(points,[],polys);mesh.update()
    obj=bpy.data.objects.new(p['path'],mesh);scene.collection.objects.link(obj)
    obj.data.materials.append(material(p['color'],1-p['transparency']))
    for j,label in enumerate(labels.get(p['path'],[])):
        curve=bpy.data.curves.new('Label','FONT');curve.body=label['text'];curve.align_x='CENTER';curve.align_y='CENTER'
        if font: curve.font=font
        curve.size=1;curve.space_line=1.12
        text=bpy.data.objects.new(p['path']+'_text_'+str(j),curve);scene.collection.objects.link(text)
        scene.view_layers.update()
        factor=min(p['size'][0]*.89/max(text.dimensions.x,.01),p['size'][1]*.82/max(text.dimensions.y,.01))
        text.scale=(factor,factor,factor)
        back=label['face']=='Back'
        # Front text faces native -Z. Back text reverses X to remain readable.
        face=Matrix(((1 if back else -1,0,0),(0,1,0),(0,0,1 if back else -1)))
        rotation=conversion@rot@face
        text.rotation_euler=rotation.to_euler()
        text.location=conversion@(pos+rot@Vector((0,0,(1 if back else -1)*(p['size'][2]/2+.035))))
        curve.materials.append(material(label['color']))

assert not missing, f'Missing source geometry: {missing}'
mesh_metrics=[{'path':p['path'],'name':p['name'],'triangles':sum(len(face)-2 for face in sources[p['name']][1])} for p in data['parts'] if p['class']=='MeshPart' and p['transparency']<.99]
(args.output.parent/'mesh-source-metrics.json').write_text(json.dumps({'visibleMeshPartInstances':len(mesh_metrics),'sourceTriangleInstances':sum(p['triangles'] for p in mesh_metrics),'rows':mesh_metrics,'limits':'Measured from original local Blender mesh topology instantiated as in the archive. Native primitive triangles, GPU batching, memory and device performance excluded.'},indent=2))
scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='Standard'
world=bpy.data.worlds.new('Daylight');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.75,.85,1,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.8;scene.world=world
light_data=bpy.data.lights.new('Sun','SUN');light_data.energy=2.2;light_data.angle=math.radians(14)
light=bpy.data.objects.new('Sun',light_data);scene.collection.objects.link(light);light.rotation_euler=(.5,-.4,-.5)
camera_data=bpy.data.cameras.new('EvidenceCamera');camera=bpy.data.objects.new('EvidenceCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
views=json.loads(args.views.read_text()) if args.views else [
 {'name':'overview','eye':[-300,330,360],'target':[0,0,0],'ortho':510},
 {'name':'start','eye':[-182,16,144],'target':[-128,17,144]},
 {'name':'tools','eye':[-70,30,157],'target':[-61,7,106]},
 {'name':'crop-layout','eye':[-205,150,-5],'target':[-117,4,-102],'ortho':175},
 {'name':'grove','eye':[147,40,-166],'target':[86,6,-102]},
 {'name':'vine','eye':[187,54,-15],'target':[92,14,33]},
 {'name':'festival','eye':[128,68,222],'target':[66,7,127]}
]
bpy.ops.wm.save_as_mainfile(filepath=str(args.output.parent/(data['attributes']['CandidateId']+'_Offline.blend')))
for view in views:
    camera.location=conversion@Vector(view['eye'])
    target=conversion@Vector(view['target'])
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.type='ORTHO' if 'ortho' in view else 'PERSP'
    if 'ortho' in view: camera_data.ortho_scale=view['ortho']
    camera_data.lens=view.get('lens',34)
    scene.render.filepath=str(args.output/(view['name']+'.png'))
    bpy.ops.render.render(write_still=True)
    print('CLOSING_VIEW '+view['name'],flush=True)
(args.output/'render-manifest.json').write_text(json.dumps({'candidate':data['attributes']['CandidateId'],'offline':True,'views':views,'missingMeshes':missing,'limits':'Blender reconstruction from exported transforms and original local mesh sources. Native lighting, GUI text layout, collision and physics are not reproduced. Curved Roblox primitives are polygonal approximations.'},indent=2))
print(json.dumps({'rendered':len(views),'missingMeshes':len(missing)}))
