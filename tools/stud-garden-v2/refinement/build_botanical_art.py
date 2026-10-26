"""Rebuild garden scenery from authored pieces while preserving route-surface meshes."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/stud-garden-v2'))
from phase3_shapes import GardenShapes, PALETTE

parser = argparse.ArgumentParser()
parser.add_argument('--version', default='R01')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
OUT = ROOT / 'docs/artifacts/stud-garden-v2/refinement-20261005' / args.version.lower()
OUT.mkdir(parents=True, exist_ok=True)
source = json.loads((ROOT / 'docs/artifacts/stud-garden-v2/phase3/f03/placement-pieces.json').read_text())
old_manifest = json.loads((ROOT / 'docs/artifacts/stud-garden-v2/phase3/f03/manifest.json').read_text())
baseline = json.loads((ROOT / 'docs/artifacts/stud-garden-v2/refinement-20261005/owner-baseline-geometry.json').read_text())

g = GardenShapes()
removed_groups = sorted({p['group'] for p in source if p['kind'] == 'low foliage' or p['group'].startswith('Flower_')})
preserved_kinds = {'surface studs', 'ground studs', 'root skin', 'handle studs'}
g.pieces = [p for p in source if p['kind'] not in preserved_kinds and p['group'] not in removed_groups]
retained_piece_count = len(g.pieces)
new_groups = []
colliders = []


def group(name, kind, position):
    g.group, g.kind = name, kind
    new_groups.append({'name': name, 'kind': kind, 'position': position})


def rod(a, b, radius, color, collider=False, top_radius=None, sides=10):
    a, b = np.array(a, dtype=float), np.array(b, dtype=float)
    direction = (b-a) / np.linalg.norm(b-a)
    aa, bb = a-direction*.12, b+direction*.12
    g.rod(tuple(aa), tuple(bb), radius, color, top_radius, sides)
    if collider:
        colliders.append({'group': g.group, 'shape': 'Cylinder', 'a': aa.tolist(), 'b': bb.tolist(), 'radius': min(radius, top_radius or radius)})


def thick_leaf(base, length, width, yaw, pitch, color, studs=True):
    """A closed pointed leaf with attached relief, in a tilted local frame."""
    x, y, z = base
    forward = np.array((math.cos(yaw)*math.cos(pitch), math.sin(pitch), math.sin(yaw)*math.cos(pitch)))
    right = np.array((-math.sin(yaw), 0, math.cos(yaw)))
    up = np.cross(right, forward)
    base = np.array(base)
    outline = [(0, 0), (.25, -.48), (.67, -.42), (1, 0), (.67, .42), (.25, .48)]
    top = [base+forward*(a*length)+right*(b*width)+up*.22 for a, b in outline]
    bottom = [p-up*.65 for p in top]
    ridge = base+forward*length*.45+up*.92
    vertices = [tuple(p) for p in top+bottom]+[tuple(ridge)]
    faces = [(i,(i+1)%6,12) for i in range(6)]+[(11,10,9,8,7,6)]+[(i,i+6,(i+1)%6+6,(i+1)%6) for i in range(6)]
    g.emit(color, vertices, faces)
    rod(base+forward*.3+up*.8, base+forward*length*.87+up*.58, .19, 'light_leaf', sides=8)
    if studs:
        for fraction in (.24, .50, .74):
            pos = base+forward*length*fraction+up*.82
            g.cylinder(tuple(pos), min(width*.09,1.15), .42, color, 8, detail='stud', normal=tuple(up))


def rosette(name, x, z, diameter, height, colors=('deep_leaf','leaf','lime')):
    group(name, 'curated rosette', [x,-2.8,z])
    g.cylinder((x,-2.55,z), diameter*.22, .7, 'soil', 10)
    for i in range(7):
        yaw = i*math.tau/7+.25
        thick_leaf((x,-1.8,z), diameter*(.47 if i%2 else .53), diameter*.22, yaw, math.atan2(height,diameter*.53), colors[i%3])
    rod((x,-2.8,z),(x,height*.67,z),diameter*.055,colors[0],top_radius=diameter*.02)


def large_shrub(name, x, z, width, theme='green'):
    group(name, 'curated shrub', [x,-2.8,z])
    palette = ('deep_leaf','leaf','lime') if theme=='green' else ('teal_dark','teal','teal_light')
    for i,(dx,dz,w,h) in enumerate(((-.2,-.08,.72,5.2),(.2,.13,.66,6.5),(-.03,.07,.50,8.3))):
        center=(x+dx*width,-2.8+h/2,z+dz*width)
        g.box(center,(width*w,h,width*w*.82),palette[i],angle=(i-1)*.09)
        g.studs((center[0],-2.8+h,center[2]),width*w-.8,width*w*.82-.8,palette[i],pitch=5.2,radius=1.0,angle=(i-1)*.09)


def cup(base, radius, color, inner, tilt=0, yaw=0):
    base=np.array(base,dtype=float)
    first_piece=len(g.pieces)
    for i in range(6):
        a,b=i*math.tau/6,(i+1)*math.tau/6
        p=[base+np.array((math.cos(a)*radius*.22,-.2,math.sin(a)*radius*.22)),
           base+np.array((math.cos(b)*radius*.22,-.2,math.sin(b)*radius*.22)),
           base+np.array((math.cos(b)*radius,3.8,math.sin(b)*radius)),
           base+np.array((math.cos(a)*radius,3.8,math.sin(a)*radius))]
        vertices=[tuple(v) for v in p]+[tuple(v-np.array((0,.65,0))) for v in p]
        g.emit(color if i%2 else inner,vertices,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
        rod(p[3],p[2],.45,color,sides=8)
        midpoint=(p[2]+p[3])/2+np.array((0,.6,0))
        g.cylinder(tuple(midpoint),1.0,.5,inner,8,detail='stud')
    g.cylinder(tuple(base+np.array((0,1,0))),radius*.25,3,'flower_gold',12,top_radius=radius*.19)
    for i in range(5):
        a=i*math.tau/5
        p=base+np.array((math.cos(a)*2.4,2.3,math.sin(a)*2.4))
        q=base+np.array((math.cos(a)*3.1,8+(i%2)*1.2,math.sin(a)*3.1))
        rod(p,q,.20,'cream',sides=8)
        g.cylinder(tuple(q),.7,1.2,'flower_gold',8)
    if tilt:
        up=np.array((math.sin(tilt)*math.cos(yaw),math.cos(tilt),math.sin(tilt)*math.sin(yaw)))
        right=np.array((-math.sin(yaw),0,math.cos(yaw)))
        back=np.cross(right,up)
        rotation=np.column_stack((right,up,back))
        for piece in g.pieces[first_piece:]:
            piece['vertices']=[tuple(base+rotation@(np.array(v)-base)) for v in piece['vertices']]


# Larger groups sit at deliberate perimeter corners, with breaks between them.
shrubs=[(-172,160,15),(-167,115,17),(-172,38,16),(-174,-8,16),(-172,-95,17),(-158,-164,17),
        (-119,-176,16),(-63,-176,17),(-11,-176,16),(38,-178,17),(107,-174,18),(171,-143,17),
        (176,-98,17),(175,-43,18),(176,27,17),(176,82,17),(174,137,17),(152,178,18),
        (116,180,16),(70,178,16),(20,180,17),(-29,180,17),(-80,179,17),(-132,178,16)]
for i,(x,z,w) in enumerate(shrubs):
    large_shrub(f'CuratedShrub_{i+1:02d}',x,z,w,'candy' if x>-15 and z<-50 else 'green')

# The owner-marked crop interior gets one asymmetrical botanical display.
group('BotanicalDisplayBed','display bed',[-127,-2.8,0])
bed=[(-163,-22),(-151,-32),(-110,-31),(-94,-19),(-93,18),(-106,29),(-146,30),(-164,18)]
vertices=[(x,y,z) for y in (-3.3,-2.55) for x,z in bed]
g.emit('soil',vertices,[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)])
for i,(x,z) in enumerate(bed):
    x2,z2=bed[(i+1)%8]
    rod((x,-2.3,z),(x2,-2.3,z2),.46,'timber_light',sides=8)
rosette('DisplayRosette',-139,4,29,19)
rosette('DisplaySmallRosette',-103,9,18,13)
group('GoldenOrchidDisplay','hero flower',[-119,-2.8,-10])
stem=[(-119,-2.8,-10),(-121,14,-10),(-118,30,-9),(-120,45,-9)]
for a,b in zip(stem,stem[1:]):rod(a,b,1.6,'deep_leaf',True,1.35)
cup((-120,45,-9),13.5,'flower_cream','flower_gold',math.radians(62),.78)
side=[(-120,18,-10),(-131,27,-15),(-134,34,-17)]
for a,b in zip(side,side[1:]):rod(a,b,1.05,'leaf',True,.85)
cup((-134,34,-17),8.6,'flower_gold','cream',math.radians(52),1.25)
for y,yaw in ((12,.2),(23,2.8),(34,4.7)):
    thick_leaf((-120,y,-10),15,10,yaw,.35,'leaf')
group('DisplayBambooFan','hero bamboo',[-151,-2.8,-20])
for i,(dx,dz,h) in enumerate(((-3,-2,34),(2,-1,39),(0,4,30))):
    x,z=-151+dx,-20+dz
    rod((x,-2.8,z),(x,h,z),1.8,'lime',True)
    for y in range(4,int(h),7):g.cylinder((x,y,z),1.94,.46,'light_leaf',10)
    for yaw in (i*2+.3,i*2+2.7):thick_leaf((x,h-8,z),10,5,yaw,.3,'leaf')
    g.cylinder((x,h+.3,z),1.15,.52,'light_leaf',10,detail='stud')

# Two restrained foreground accents replace dozens of isolated little flowers.
for i,(x,z,h,col) in enumerate(((-148,23,13,'flower_pink'),(-108,21,16,'flower_cream'),(-158,-12,12,'flower_gold'))):
    group(f'DisplayFlower_{i+1}','display flower',[x,-2.8,z])
    g.flower(x,z,h,2.4,col)

# Maintain the existing footprint near the route; expansion begins above racers.
group('GrandStuddedBeanstalk','hero beanstalk',[108,-2.8,43])
bean=np.array((108.,-2.8,43.))
stem_points=[]
for strand in range(3):
    points=[]
    for i in range(29):
        t=i/28
        angle=t*math.tau*1.16+strand*math.tau/3
        radius=6+3*math.sin(t*math.pi)
        p=bean+np.array((math.sin(angle)*radius,145*t,math.cos(angle)*radius))
        points.append(p)
    for i,(a,b) in enumerate(zip(points,points[1:])):
        t=(i+.5)/28
        rad=5.3-1.7*t
        rod(a,b,rad,('leaf','deep_leaf','lime')[strand],True,sides=12)
        outward=np.array((a[0]-bean[0],0,a[2]-bean[2]));outward/=np.linalg.norm(outward)
        for angle in (-.6,.6):
            normal=np.array((outward[0]*math.cos(angle)-outward[2]*math.sin(angle),0,outward[0]*math.sin(angle)+outward[2]*math.cos(angle)))
            pos=(a+b)/2+normal*(rad+.16)
            g.cylinder(tuple(pos),1.2-.35*t,.50,('leaf','deep_leaf','lime')[strand],8,detail='stud',normal=tuple(normal))
    stem_points.extend(points)

g.cylinder(tuple(bean+np.array((0,142,0))),8.6,9.5,'leaf',12,top_radius=5.2)
for i in range(5):
    yaw=i*math.tau/5+.3
    radial=np.array((math.cos(yaw),0,math.sin(yaw)))
    target=bean+radial*6+np.array((0,139+(i%2)*3,0))
    anchor=min(stem_points,key=lambda p:np.linalg.norm(p-target))
    petiole=bean+radial*10+np.array((0,143+(i%2)*3,0))
    rod(anchor,petiole,1.7,'deep_leaf',top_radius=1.05)
    thick_leaf(tuple(petiole),29+(i%2)*3,23,yaw,.13+(i%3)*.06,('leaf','lime','deep_leaf')[i%3])
rod(bean+np.array((0,142,0)),bean+np.array((1,154,1)),2.1,'lime',top_radius=.6)
thick_leaf(tuple(bean+np.array((1,150,1))),9,6,.6,1.15,'lime')

for i in range(5):
    a=i*math.tau/5+.4
    end=bean+np.array((math.cos(a)*25,-1.15,math.sin(a)*25))
    middle=bean+np.array((math.cos(a)*12,-.55,math.sin(a)*12))
    start=bean+np.array((math.cos(a)*3,1,math.sin(a)*3))
    rod(start,middle,2.0,'deep_leaf',True,1.6)
    rod(middle,end,1.6,'deep_leaf',True,.55)

for i in range(12):
    yaw=math.radians(-120+i*137.5)
    radial=np.array((math.cos(yaw),0,math.sin(yaw)))
    height=42+i*7.2
    target=bean+radial*6+np.array((0,height,0))
    anchor=min(stem_points,key=lambda p:np.linalg.norm(p-target))
    tip=bean+radial*16+np.array((0,height+3,0))
    rod(anchor,tip,1.35,'deep_leaf',top_radius=.9)
    thick_leaf(tuple(tip),39 if i<7 else 31,27 if i<7 else 22,yaw,.15 if i%2 else -.08,('leaf','lime','deep_leaf')[i%3])
    if i in (2,5,8):
        pod=tip+radial*7-np.array((0,3,0))
        rod(tip,pod,.5,'deep_leaf')
        rod(pod,pod-np.array((0,16,0)),2.6,'leaf',top_radius=1.8)
        for j in range(4):
            p=pod+radial*2-np.array((0,2.8+j*3.1,0))
            g.cylinder(tuple(p),1.5,2,'lime',10,normal=tuple(radial))

for i in range(3):
    target=bean+np.array((7,57+i*21,-4))
    start=min(stem_points,key=lambda p:np.linalg.norm(p-target))
    center=bean+np.array((15,60+i*21,-6-i*3))
    points=[start,center+np.array((7,0,0))]
    for j in range(1,11):
        a=j*.47
        radius=7*(1-j*.062)
        points.append(center+np.array((math.cos(a)*radius,math.sin(a)*radius,0)))
    for a,b in zip(points,points[1:]):rod(a,b,.55,'lime',sides=8)

# Every replaced batch is identified by the old source manifest, not by color guesses.
replace_meshes=[m['name'] for m in old_manifest['meshes'] if not (m['color'].startswith('surface_') or m['color'] in ('grass','root_skin'))]
existing_meshes={p['name'] for p in baseline['parts'] if p['path'].startswith('Phase3Art.')}
replace_meshes=[name for name in replace_meshes if name in existing_meshes]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.unit_settings.system='NONE'
collection=bpy.data.collections.new('BotanicalRefinement')
scene.collection.children.link(collection)
materials={}
objects=[]
records=[]


def emit_batch(color,tile,index,pieces):
    vertices=[];faces=[]
    for piece in pieces:
        offset=len(vertices)
        vertices.extend((x,-z,y) for x,y,z in piece['vertices'])
        faces.extend(tuple(i+offset for i in face) for face in piece['faces'])
    name=f'{args.version}__{color}__{index:03d}'
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    boundary=sum(e.is_boundary for e in bm.edges)
    bm.to_mesh(mesh);bm.free()
    assert boundary==0,(name,boundary)
    assert len(mesh.polygons)<9500,(name,len(mesh.polygons))
    obj=bpy.data.objects.new(name,mesh);collection.objects.link(obj)
    if color not in materials:
        rgb=tuple(int(PALETTE[color][j:j+2],16)/255 for j in (1,3,5))
        mat=bpy.data.materials.new(color);mat.diffuse_color=(*rgb,1)
        materials[color]=mat
    obj.data.materials.append(materials[color]);objects.append(obj)
    bounds=[[min(v[k] for p in pieces for v in p['vertices']) for k in range(3)],[max(v[k] for p in pieces for v in p['vertices']) for k in range(3)]]
    records.append({'name':name,'color':color,'hex':PALETTE[color],'triangles':len(mesh.polygons),'vertices':len(mesh.vertices),'boundaryEdges':boundary,'exportBoundsRoblox':bounds,'tile':tile,'sourceGroups':sorted({p['group'] for p in pieces})})


batches=defaultdict(list)
for piece in g.pieces:
    center=np.mean(piece['vertices'],axis=0)
    tile=(int(math.floor(center[0]/128)),int(math.floor(center[2]/128)))
    batches[(piece['color'],tile)].append(piece)
indices=Counter()
for (color,tile),pieces in sorted(batches.items()):
    chunk=[];cost=0
    for piece in pieces:
        count=sum(len(face)-2 for face in piece['faces'])
        if cost+count>8800 and chunk:
            emit_batch(color,tile,indices[color],chunk);indices[color]+=1
            chunk=[];cost=0
        chunk.append(piece);cost+=count
    if chunk:emit_batch(color,tile,indices[color],chunk);indices[color]+=1

for name,point in {'CalO':(0,0,0),'CalX':(24,0,0),'CalY':(0,24,0),'CalZ':(0,0,24)}.items():
    bpy.ops.mesh.primitive_cube_add(size=2,location=(point[0],-point[2],point[1]))
    obj=bpy.context.object;obj.name=name;objects.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
fbx=OUT/f'SGV2_Botanical_{args.version}.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False,bake_anim=False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'SGV2_Botanical_{args.version}.blend'))
manifest={'version':args.version,'ownerBaseline':'4b2f6d3d','target':[1563,257,-1053],'replaceMeshes':replace_meshes,'removeCollisionGroups':removed_groups,'removedSmallBushes':500,'removedGenericFlowers':67,'retainedSourcePieces':retained_piece_count,'curatedShrubs':24,'newGroups':new_groups,'meshes':records,'meshCount':len(records),'sourceTriangles':sum(r['triangles'] for r in records),'colliders':colliders,'fbx':fbx.name,'fbxSha256':hashlib.sha256(fbx.read_bytes()).hexdigest(),'limits':'Source triangle count excludes preserved meshes and native primitives; not a measured FPS result.'}
(OUT/'botanical-manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'botanical-pieces.json').write_text(json.dumps(g.pieces,separators=(',',':'),default=lambda value: value.item() if hasattr(value,'item') else list(value)))
print(json.dumps({k:manifest[k] for k in ('version','meshCount','sourceTriangles','removedSmallBushes','removedGenericFlowers','curatedShrubs','fbxSha256')}),flush=True)
