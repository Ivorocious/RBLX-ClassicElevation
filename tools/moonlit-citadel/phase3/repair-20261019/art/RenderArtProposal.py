"""One bounded layout proposal on an isolated copy of the verified54 scene."""
import hashlib,importlib.util,json,math
from pathlib import Path
import bpy
from mathutils import Matrix,Vector

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
PLAN=HERE/'proposal01/art-plan.json'
FRESH=ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json'
KIT=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01/MC_DETAIL_KIT_DT01.blend'
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)));INV=AXIS.inverted()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def frame(v):return Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))
def transform(row):return AXIS@frame(row['localCF'])@Matrix.Diagonal((*row['scale'],1))@INV
def unit(obj):return obj.get('ArtRepairUnit') or obj.get('Detail54Unit') or obj.get('Source50Unit') or obj.get('NativeUnit')
def digest(objects):
    result=hashlib.sha256()
    for obj in sorted(objects,key=lambda obj:obj.name):
        result.update(obj.name.encode());result.update(repr(tuple(tuple(row) for row in obj.matrix_world)).encode())
        result.update(repr((obj.hide_render,obj.hide_viewport)).encode())
        for vertex in obj.data.vertices:result.update(repr(tuple(vertex.co)).encode())
        for material in obj.data.materials:result.update(material.name.encode())
    return result.hexdigest()
def bounds(obj):
    pts=[INV@(obj.matrix_world@v.co) for v in obj.data.vertices]
    return {'low':[min(p[k] for p in pts) for k in range(3)],'high':[max(p[k] for p in pts) for k in range(3)]}

assert bpy.app.background
OUT=HERE/'proposal01';assert not (OUT/'MC_ART_REPAIR55_PROPOSAL.blend').exists()
guards={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in (SOURCE,PLAN,FRESH,KIT)}
plan=json.loads(PLAN.read_text(encoding='utf8'));fresh=json.loads(FRESH.read_text(encoding='utf8'))
edits={r['before']['name']:r for r in plan['replacements']};retired={r['before']['name'] for r in plan['retired']}
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
details=list(bpy.data.collections['DT54_Corrected_77_Details'].all_objects)
protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
assert (len(world),len(details),len(protected))==(639,242,717)
original=world+details
unchanged=[obj for obj in original if unit(obj) not in edits and unit(obj) not in retired]
unchanged_hash,protected_hash=digest(unchanged),digest(protected)
camera_collection=bpy.data.collections.new('Oct19_Proposal_Cameras');scene.collection.children.link(camera_collection)
def camera(name,eye,target,fov=70):
    data=bpy.data.cameras.new(name);obj=bpy.data.objects.new(name,data);camera_collection.objects.link(obj)
    obj.location=AXIS@Vector(eye);obj.rotation_euler=(AXIS@Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.sensor_fit='VERTICAL';data.angle_y=math.radians(fov);data.clip_end=3000
    return obj
cameras={
    'crown-exterior':camera('CrownExterior',[32,169,90],[-8,151,-30],50),
    'gallery-route':camera('GalleryRoute',[-60,57.5,46],[18,65,78],70),
    'crown-standing':camera('CrownStanding',[6,155.5,-18],[38,85,106],70),
}
native=fresh['camera']['records']['']['props']['CFrame']['value'][:]
origin=fresh['editable']['records']['']['attrs']['Origin']['value']
native[:3]=[native[k]-origin[k] for k in range(3)]
cam=camera('GalleryOwnerPhoto3',[0,0,0],[0,0,1]);cam.matrix_world=AXIS@frame(native)
cameras['gallery-owner']=cam
scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1920,1043,100
scene.render.image_settings.file_format='PNG'
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.48,.56,.67,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
sun=bpy.data.lights.get('Inspection_Sun')
if sun:sun.energy,sun.color=2,(1,.94,.86)
views=[]
def render(stage):
    for name,cam in cameras.items():
        file=f'{stage}-{name}.png';scene.camera=cam;scene.render.filepath=str(OUT/file)
        print('RENDER_START '+file,flush=True);bpy.ops.render.render(write_still=True)
        cf=INV@cam.matrix_world
        views.append({'file':file,'sha256':sha(OUT/file),'stage':stage,'view':name,
                      'cameraPosition':list(cf.translation),'verticalFOV':math.degrees(cam.data.angle_y),
                      'dimensions':[1920,1043],'ownerPhoto3ExactCurrentCamera':name=='gallery-owner',
                      'approximateBlenderLighting':True,'retouched':False})
render('before54')
archive=bpy.data.collections.new('Oct19_Retired54_Art_Recovery');scene.collection.children.link(archive)
def preserve(obj):
    for collection in list(obj.users_collection):collection.objects.unlink(obj)
    archive.objects.link(obj);obj.hide_render=True;obj.hide_viewport=True
newcollection=bpy.data.collections.new('Oct19_Reused_Bracketed_Banners');scene.collection.children.link(newcollection)
names=['MC_DT_HeraldicBanner__'+m for m in ('Iron','Brass','SlateBand')]
with bpy.data.libraries.load(str(KIT),link=False)as(source_data,loaded):loaded.objects=names
templates=dict(zip(names,loaded.objects))
replaced_names=set();active=[]
for obj in original:
    name=unit(obj)
    if name in retired:preserve(obj);continue
    record=edits.get(name)
    if not record:active.append(obj);continue
    before,after=record['before'],record['after']
    if before['asset']!=after['asset']:
        preserve(obj)
        if name in replaced_names:continue
        replaced_names.add(name)
        for source in templates.values():
            clone=source.copy();clone.data=source.data;newcollection.objects.link(clone)
            clone.name='Oct19_'+name+'__'+source.name.split('__')[-1]
            clone.matrix_world=transform(after)@source.matrix_world
            clone.hide_render=False;clone.hide_viewport=False
            clone['ArtRepairUnit']=name;clone['AssetKey']=after['asset'];clone['DecorationOnly']=True
            active.append(clone)
    else:
        obj.matrix_world=transform(after)@transform(before).inverted()@obj.matrix_world
        active.append(obj)
assert len(active)==869,len(active)
assert digest(protected)==protected_hash and digest(unchanged)==unchanged_hash
render('after55-proposal')
partrows=[]
for obj in active:
    name=unit(obj)
    if name not in edits:continue
    row=bounds(obj);lo,hi=row['low'],row['high'];centre=[(lo[k]+hi[k])/2 for k in range(3)]
    partrows.append({'path':name+'/'+obj.name.split('__')[-1],
                     'frame':centre+[1,0,0,0,1,0,0,0,1],
                     'size':[hi[k]-lo[k] for k in range(3)],'bounds':row,
                     'anchored':True,'collide':False,'query':False,'touch':False,'transparency':0})
(OUT/'proposed-actual-part-bounds.json').write_text(json.dumps(partrows,indent=2)+'\n',encoding='utf8')
for path,hashvalue in guards.items():assert sha(ROOT/path)==hashvalue,path
assert digest(protected)==protected_hash and digest(unchanged)==unchanged_hash
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MC_ART_REPAIR55_PROPOSAL.blend'))
report={'pass':True,'candidate':plan['candidate'],'inputHashes':guards,'counts':plan['counts'],
        'replacements':len(edits),'retiredUnits':len(retired),'retiredOrReplacedMaterialPartsPreservedInScene':len(archive.objects),
        'all717ProtectedVisibleObjectsExact':True,'unchangedOtherArtPartsExact':True,'unchangedOtherArtParts':len(unchanged),
        'protectedDigest':protected_hash,'unchangedOtherArtDigest':unchanged_hash,
        'actualChangedPartBounds':len(partrows),'views':views,'savedBlendSHA256':sha(OUT/'MC_ART_REPAIR55_PROPOSAL.blend'),
        'nativeStateMatchedByRoot':True,'productionEdited':False,'studioTouched':False,'liveBlenderTouched':False,
        'boundary':'Offline authored before/after proposal. View geometry is bound to current owner camera for image3, but Blender shading differs from Roblox. Native moving overlap/route/finish checks remain lead work.'}
(OUT/'art-proposal-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':True,'parts':len(active),'changedBounds':len(partrows),'retiredPartsPreserved':len(archive.objects)}))
