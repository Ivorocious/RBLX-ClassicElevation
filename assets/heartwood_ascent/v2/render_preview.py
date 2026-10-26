"""Inspect closed forms and render the corrective kit before Roblox upload."""
import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
scene=bpy.context.scene
audit=[]
for o in list(bpy.data.objects):
    if o.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(o.data)
    audit.append({'name':o.name,'boundaryEdges':sum(e.is_boundary for e in bm.edges),
                  'nonmanifoldEdges':sum(not e.is_manifold for e in bm.edges),
                  'finite':all(math.isfinite(c) for v in bm.verts for c in v.co),
                  'minFaceArea':min(f.calc_area() for f in bm.faces)})
    bm.free()
assert all(x['boundaryEdges']==0 and x['nonmanifoldEdges']==0 and x['finite'] and x['minFaceArea']>1e-8 for x in audit)
(ROOT/'geometry-checks.json').write_text(json.dumps(audit,indent=2)+'\n')
scene.render.engine='CYCLES';scene.cycles.samples=12
scene.render.resolution_percentage=100
if not scene.world:scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.color=(.32,.38,.42)
scene.view_settings.view_transform='AgX'
sun_data=bpy.data.lights.new('PreviewSun','SUN');sun_data.energy=3;sun_data.angle=.20
sun=bpy.data.objects.new('PreviewSun',sun_data);scene.collection.objects.link(sun);sun.rotation_euler=(.6,-.5,-.7)
cd=bpy.data.cameras.new('PreviewCamera');cam=bpy.data.objects.new('PreviewCamera',cd);scene.collection.objects.link(cam);scene.camera=cam
def camera(position,target,scale):
    cam.location=position;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=scale
def render(name,x,y):
    scene.render.resolution_x=x;scene.render.resolution_y=y;scene.render.filepath=str(ROOT/('preview-'+name+'.png'));bpy.ops.render.render(write_still=True)
templates=[o for o in bpy.data.objects if o.type=='MESH']
for o in templates:o.hide_render=True
for o in templates:
    if o.name.startswith(('HA_Hollow','HA_Buttress','HA_Bough')):o.hide_render=False
placements=[(87,271,-49,85,42,80),(155,309,-46,105,48,92),(193,325,-32,98,45,98),
(-77,316,50,88,43,80),(-137,347,55,102,49,94),(-188,359,27,95,46,88),
(64,391,-20,96,49,90),(124,425,-8,110,55,98),(-49,434,35,106,50,95),
(-92,463,28,108,50,103),(0,468,-5,126,48,116),
(99,58,-10,34,14,30),(100,69,32,30,14,30),(76,73,84,32,14,30),
(-66,115,124,32,14,28),(-111,123,116,35,15,33),(-125,128,70,35,15,31),(-136,161,12,39,17,34)]
clones=[]
for i,(x,y,z,w,h,d) in enumerate(placements):
    src=bpy.data.objects['HA_FoliageMassA' if i%2==0 else 'HA_FoliageMassB'];o=src.copy();o.data=src.data;scene.collection.objects.link(o)
    o.hide_render=False;source_size=src.dimensions.copy();o.scale=(w/source_size.x,d/source_size.y,h/source_size.z);o.location=(x,-z,y);clones.append(o)
sanct=bpy.data.objects['HA_Sanctuary'];sanct.hide_render=False;sanct.location=(-106,-28,162)
camera((-550,-740,310),(0,0,207),630);render('tree',1200,1400)
for o in templates+clones:o.hide_render=True
names=['HA_ShelfWide','HA_ShelfTip','HA_RootSpan','HA_HeartwoodSocket','HA_FoliageMassA','HA_HangingMass']
for i,name in enumerate(names):
    o=bpy.data.objects[name];o.hide_render=False;o.location=((i%3-1)*45,(i//3)*40,0)
camera((70,-120,110),(0,12,0),150);render('kit',1300,900)
for o in templates:o.hide_render=True
for i,name in enumerate(['HA_BloomBroad','HA_BloomSmall','HA_Sanctuary']):
    o=bpy.data.objects[name];o.hide_render=False;o.location=((i-1)*48,0,0)
camera((0,-105,75),(0,0,0),154);render('flowers',1400,850)
print(json.dumps({'closedMeshes':len(audit),'previews':['tree','kit','flowers']}),flush=True)
