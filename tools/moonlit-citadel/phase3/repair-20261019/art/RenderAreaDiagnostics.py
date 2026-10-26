import hashlib
import json
import math
from pathlib import Path
import bpy
from mathutils import Matrix,Vector

ROOT=next(path for path in Path(__file__).resolve().parents if (path/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
before=sha(SOURCE)
assert bpy.app.background
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
scene=bpy.context.scene;scene.cycles.samples=8
scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1440,800,100
scene.render.image_settings.file_format='PNG'
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.48,.56,.67,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
sun=bpy.data.lights.get('Inspection_Sun')
if sun:sun.energy,sun.color=2,(1,.94,.86)
collection=bpy.data.collections.new('Oct19_Offline_Diagnostic_Cameras')
scene.collection.children.link(collection)
out=HERE/'inspection54';records=[]
for name,eye,target,fov in (
    ('gallery-matching-area54',[18,66,28],[18,66,73],70),
    ('crown-matching-area54',[32,169,90],[-8,151,-30],50),
):
    data=bpy.data.cameras.new(name);obj=bpy.data.objects.new(name,data);collection.objects.link(obj)
    obj.location=AXIS@Vector(eye);obj.rotation_euler=(AXIS@Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.sensor_fit='VERTICAL';data.angle_y=math.radians(fov);data.clip_end=3000;scene.camera=obj
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
    records.append({'file':name+'.png','eye':eye,'target':target,'FOV':fov,'boundary':'Estimated matching area, not exact native photograph pose'})
(out/'area-view-records.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf8')
assert sha(SOURCE)==before
