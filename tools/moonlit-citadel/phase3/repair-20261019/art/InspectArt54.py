"""Inspect the frozen map offline; never controls live Blender or Studio."""
import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT=next(path for path in Path(__file__).resolve().parents if (path/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INVERSE=AXIS.inverted()

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def point(value):return list(INVERSE@value)
def row(obj):
    points=[INVERSE@(obj.matrix_world@vertex.co) for vertex in obj.data.vertices]
    low=[min(value[k] for value in points) for k in range(3)]
    high=[max(value[k] for value in points) for k in range(3)]
    attrs={key:obj[key] for key in obj.keys() if isinstance(obj[key],(str,float,int,bool))}
    return {'name':obj.name,'bounds':{'low':low,'high':high},'attrs':attrs,
            'materials':[material.name for material in obj.data.materials],
            'triangles':len(obj.data.loop_triangles)}

assert bpy.app.background
source_hash=sha(SOURCE)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
names=('Final_233_World_Units','Unchanged_Source49_Visible_Course','DT54_Corrected_77_Details')
groups={name:list(bpy.data.collections[name].all_objects) for name in names}
records={name:[row(obj) for obj in values if obj.type=='MESH'] for name,values in groups.items()}
focused=[]
for group,rows in records.items():
    for item in rows:
        low,high=item['bounds']['low'],item['bounds']['high']
        crown=high[0]>-53 and low[0]<35 and high[1]>120 and low[1]<181 and high[2]>-80 and low[2]<15
        gallery=high[0]>-70 and low[0]<108 and high[1]>48 and low[1]<94 and high[2]>-4 and low[2]<91
        if crown or gallery:focused.append(dict(item,group=group,inCrown=crown,inGallery=gallery))
out=HERE/'inspection54'
out.mkdir(exist_ok=True)
report={'historicalBaseline':54,'source':str(SOURCE.relative_to(ROOT)),'sourceSHA256':source_hash,
        'groups':{name:len(rows) for name,rows in records.items()},'focusedParts':focused,
        'boundary':'Historical frozen54 authored scene. Current native identity/deltas require lead confirmation.',
        'studioTouched':False,'liveBlenderTouched':False}
(out/'part-inventory.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
camera_collection=bpy.data.collections.new('Oct19_Offline_Diagnostic_Cameras')
scene.collection.children.link(camera_collection)
scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1440,800,100
scene.render.image_settings.file_format='PNG'
background=scene.world.node_tree.nodes['Background'];background.inputs['Color'].default_value=(.48,.56,.67,1)
background.inputs['Strength'].default_value=.7
sun=bpy.data.lights.get('Inspection_Sun')
if sun:sun.energy,sun.color=2,(1,.94,.86)
views=[]
for name,eye,target,fov in (
    ('crown-front54',[80,172,180],[-8,151,-26],50),
    ('gallery-front54',[-10,67,-12],[0,66,64],50),
):
    data=bpy.data.cameras.new(name);obj=bpy.data.objects.new(name,data);camera_collection.objects.link(obj)
    obj.location=AXIS@Vector(eye);obj.rotation_euler=(AXIS@Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.sensor_fit='VERTICAL';data.angle_y=math.radians(fov);data.clip_end=3000;scene.camera=obj
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
    views.append({'file':name+'.png','eye':eye,'target':target,'verticalFOV':fov,'approximateDaylight':True,'retouched':False})
(out/'views.json').write_text(json.dumps(views,indent=2)+'\n',encoding='utf8')
assert sha(SOURCE)==source_hash
print(json.dumps({'pass':True,'focusedParts':len(focused),'groups':report['groups'],'sourcePreserved':True}))
