"""SC_MAP_27 economical hanging rock, vegetation and leading-wave kit."""
from pathlib import Path
import math,json
ROOT=Path(__file__).resolve().parent
exec((ROOT/'build_revision.py').read_text().split('# Hull axis is local Y.')[0])
BUILD='SC_KIT_27'
# Roof anchor at zero. Broad broken shoulder narrows into an asymmetric pointed tip.
g=Geo();vs=[];n=7
for level,(y,r,dx,dz) in enumerate([(0,1.35,0,0),(-1.1,1.12,.08,.03),(-3.8,.65,-.2,.1),(-6.4,.22,-.38,.2),(-7,0,-.43,.24)]):
    for j in range(n):
        a=j*2*math.pi/n;rr=r*(1+.12*math.sin(j*2.1+level))
        vs.append((dx+rr*math.cos(a),-(dz+rr*math.sin(a)),y))
fs=[tuple(reversed(range(n)))]
fs.extend((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j)for k in range(4)for j in range(n))
g.mesh(vs,fs,[STONE]+[STONE if j%3 else STONE_SHADE for j in range(len(fs)-1)])
asset('Stalactite27',g,'rock','Ceiling anchor0. Tip -7 RobloxY. Attach broad shoulder inside roof.',mount='ceiling',estimated_placements=25)
g=Geo();g.rings([(-.8,.05),(-.6,.48),(-.1,.76),(.4,.62),(.72,.3),(.8,.03)],8,DARK)
asset('Coconut27',g,'prop','Center pivot. 1.6 stud diameter. Visual falls use predictable server clock.',estimated_placements=15)
# Curved segmented fronds replace pointed grass triangles without alpha textures.
def leaf(g,a,length,width,rise,tipheight,color,origin=(0,0,0),steps=5):
    ox,oy,oz=origin;verts=[]
    for k in range(steps+1):
        t=k/steps;radius=length*t;h=oz+rise*math.sin(math.pi*t)+tipheight*t
        w=width*math.sin(math.pi*t)**.65
        cx=ox+math.cos(a)*radius;cy=oy+math.sin(a)*radius
        verts.extend([(cx-math.sin(a)*w,cy+math.cos(a)*w,h),(cx,cy,h+.12*math.sin(math.pi*t)),(cx+math.sin(a)*w,cy-math.cos(a)*w,h)])
    faces=[]
    for k in range(steps):
        for j in range(2):faces.append((k*3+j,k*3+j+1,(k+1)*3+j+1,(k+1)*3+j))
    g.mesh(verts,faces,[color if i%2 else LEAF for i in range(len(faces))])
g=Geo()
for i in range(8):leaf(g,i*2.399,1.7+(i%3)*.35,.27,1.2,.1,LEAF_L,steps=4)
asset('Grass27',g,'vegetation','Opaque curved sea-grass clump. Base0, max height about1.6.',estimated_placements=26,recalculate_normals=False)
g=Geo();n=8;vs=[]
for k in range(7):
    t=k/6;z=24*t;cx=2.4*t*t;cy=.8*math.sin(t*2)
    r=.7-.24*t
    vs.extend((cx+r*math.cos(j*2*math.pi/n),cy+r*math.sin(j*2*math.pi/n),z)for j in range(n))
fs=[tuple(reversed(range(n)))]
fs.extend((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j)for k in range(6)for j in range(n))
g.mesh(vs,fs,[DARK]+[WOOD if i%3 else TAN for i in range(len(fs)-1)])
for i in range(8):
    leaf(g,i*2.399,8+(i%3)*1.2,1.1,2.7,-3.5,LEAF_L,origin=(2.4,.8*math.sin(2),24),steps=4)
asset('Palm27',g,'vegetation','Root0; crown offset Roblox(2.4,24,-.73). Fronds droop below crown; keeprootgrounded.',estimated_placements=7,recalculate_normals=False)
# Low-poly curling cross-section, opaque water body and segmented pale crest.
g=Geo();profile=[(2,0),(-2,0),(-2,2.3),(-1.6,3.8),(-.7,4.8),(-1.4,5),(-2.1,4.5),(-1.8,5.25),(-.7,5.6),(.5,4.9),(1.4,3),(2,0)]
vs=[];slices=11
for i in range(slices):
    x=-9+18*i/(slices-1);swell=.9+.09*math.sin(i*1.8)+.04*math.cos(i*3.1)
    for z,y in profile:vs.append((x,-z,y*swell))
fs=[];colors=[]
for i in range(slices-1):
    for j in range(len(profile)-1):
        a=i*len(profile)+j;fs.append((a,a+1,a+len(profile)+1,a+len(profile)))
        colors.append(FOAM if j in [4,5,6,7,8] else SEA if j in [2,3,9] else DEEP)
fs.extend([tuple(reversed(range(len(profile)))),tuple((slices-1)*len(profile)+j for j in range(len(profile)))])
colors.extend([SEA,SEA]);g.mesh(vs,fs,colors)
asset('Wave27',g,'water','Width18,depth4,baseY0; curled front points Roblox -Z; +Z trailing pool. No physics collider.',estimated_placements=2)
for i,row in enumerate(rows):
    objects[row['id']].location=(i*60,0,0)
    row['centerBlender']=[(row['boundsBlender']['min'][k]+row['boundsBlender']['max'][k])/2 for k in range(3)]
bpy.context.view_layer.update()
for ob in objects.values():ob.select_set(True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_Kit27.blend'))
bpy.ops.export_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit27.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
manifest=dict(build=BUILD,assets=rows,libraryTriangles=sum(r['triangles']for r in rows),assetCeiling=1500,kitCeiling=5000,materialCount=1,atlas='palette.png')
assert manifest['libraryTriangles']<=5000
(ROOT/'manifest27.json').write_text(json.dumps(manifest,indent=2))
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit27.fbx'))
counts={}
for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
        m=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh();m.calc_loop_triangles();counts[ob.name]=len(m.loop_triangles)
assert sum(counts.values())==manifest['libraryTriangles']
(ROOT/'export-verification27.json').write_text(json.dumps(dict(triangles=sum(counts.values()),assets=counts,modifiersApplied=True),indent=2))
print(json.dumps(dict(triangles=sum(counts.values()),assets=counts)))

