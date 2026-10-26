"""Build a recoverable R305 art overlay, with a bounded first-area export."""
import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from phase3_shapes import GardenShapes, PALETTE
from phase3_root_skins import add_root_skins
from audit_offline import vertices as native_vertices
from audit_phase2_geometry import hull, inset, cross

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'docs/artifacts/stud-garden-v2'
parser=argparse.ArgumentParser()
parser.add_argument('--candidate',default='S01')
parser.add_argument('--full',action='store_true')
parser.add_argument('--no-render',action='store_true')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
OUT=BASE/'phase3'/args.candidate.lower()
OUT.mkdir(parents=True,exist_ok=True)
source_snapshots={name:(Path(__file__).parent/name).read_bytes() for name in
                  ('build_phase3_art.py','phase3_shapes.py','phase3_root_skins.py')}
REGION=(-188,188,-190,190) if args.full else (-188,-27,19,190)
OFFSET=(0,0,0)
DATA_PATH=BASE/'phase2/round3/offline-r305/geometry.json'
data=json.loads(DATA_PATH.read_text())
blend=BASE/'phase3-showcase-20261004/refinement-20261005/four-views/StudGarden-BigPlants-Studs-Reference.blend'
bpy.ops.wm.open_mainfile(filepath=str(blend))
scene=bpy.context.scene
for obj in list(scene.objects):
    if obj.name.startswith(('Concept_','Refined_')):
        bpy.data.objects.remove(obj,do_unlink=True)
for obj in scene.objects:
    if obj.type=='MESH':
        for mod in list(obj.modifiers): obj.modifiers.remove(mod)

ORIGIN=np.array((9200,80,3500))
obstacles=[]
body_zones=[]
surface_parts=[]
launch_boxes=[]
for part in data['parts']:
    if part['transparency']>=.99: continue
    cf=np.array(part['cf']); pos=cf[:3]-ORIGIN; rotation=cf[3:].reshape(3,3)
    half=np.abs(rotation)@(np.array(part['size'])/2)
    lo,hi=pos-half,pos+half
    if part['path']!='Decoration.LowGardenGround':
        obstacles.append((lo,hi,part['path']))
    if part['collide'] and part['role'] in ('Walk','Refuge') and hi[1]>2.4:
        body_zones.append((lo+np.array((-2.2,0,-2.2)),hi+np.array((2.2,12.5,2.2))))
    if part['collide'] and hi[1]>2.4 and part['path']!='Decoration.LowGardenGround':
        launch_boxes.append((lo,hi,part['path']))
    if part['name']=='GrassCap' or part['name'].startswith('DeckPlank_') or part['name'] in ('Lid','CrateLid'):
        if rotation[1,1]>.999 and min(part['size'][0],part['size'][2])>1.7:
            surface_parts.append((part,pos,rotation))
for path in data['paths']:
    pts=path['points']; margin=2.3 if path['kind']=='ExpertBranch' else 4.0
    for a,b in zip(pts,pts[1:]):
        lo=np.minimum(a,b)-np.array((margin,0,margin))
        hi=np.maximum(a,b)+np.array((margin,12.5,margin))
        body_zones.append((lo,hi))
zone_lo=np.array([r[0] for r in body_zones]);zone_hi=np.array([r[1] for r in body_zones])
obs_lo=np.array([r[0] for r in obstacles]);obs_hi=np.array([r[1] for r in obstacles])
launch_lo=np.array([r[0] for r in launch_boxes]);launch_hi=np.array([r[1] for r in launch_boxes])
JUMP_VELOCITY=math.sqrt(2*196.2*7.2)
route_parts={p['path'] for p in data['parts'] if p['collide'] and p['role'] in ('Walk','Refuge')
             and not any(name in p['path'] for name in ('PlantedContext','LowerVineLandmark','CandyBlossom','RaccoonBank'))}
reachable=np.array([row[2] in route_parts for row in launch_boxes])
seed_count=int(reachable.sum())
dx=np.maximum(np.maximum(launch_lo[None,:,0]-launch_hi[:,None,0],launch_lo[:,None,0]-launch_hi[None,:,0]),0)
dz=np.maximum(np.maximum(launch_lo[None,:,2]-launch_hi[:,None,2],launch_lo[:,None,2]-launch_hi[None,:,2]),0)
rise=launch_hi[None,:,1]-launch_hi[:,None,1]
range_bound=16*(JUMP_VELOCITY+np.sqrt(np.maximum(0,JUMP_VELOCITY**2-2*196.2*rise)))/196.2
links=(rise<=7.2)&(range_bound+2-np.sqrt(dx*dx+dz*dz)>=0)
for _ in range(len(launch_boxes)):
    expanded=reachable|np.any(links[reachable],axis=0)
    if np.array_equal(expanded,reachable):break
    reachable=expanded
launch_boxes=[row for row,keep in zip(launch_boxes,reachable) if keep]
launch_lo=launch_lo[reachable];launch_hi=launch_hi[reachable]
del links,dx,dz,rise,range_bound
g=GardenShapes()
rejected=[]
accepted=[]


def inside(x,z,margin=0):
    return REGION[0]+margin<=x<=REGION[1]-margin and REGION[2]+margin<=z<=REGION[3]-margin


def overlap(lo,hi,lows,highs,pad=0):
    return np.where(np.all(hi+pad>lows,axis=1)&np.all(lo-pad<highs,axis=1))[0]


def reachable_art(pieces):
    for p in pieces:
        if p['detail']=='stud':continue
        vertices=np.array(p['vertices']);center=vertices.mean(axis=0)
        if vertices[:,1].max()<=2.4:continue
        for face in p['faces']:
            points=vertices[list(face)]
            normal=np.cross(points[1]-points[0],points[2]-points[0])
            norm=np.linalg.norm(normal)
            if norm<1e-8:continue
            normal/=norm
            if normal@(points.mean(axis=0)-center)<0:normal=-normal
            if normal[1]<.5:continue
            lo,hi=points.min(axis=0),points.max(axis=0)
            if hi[1]<=2.4:continue
            rise=lo[1]-launch_hi[:,1]
            dx=np.maximum(np.maximum(launch_lo[:,0]-hi[0],lo[0]-launch_hi[:,0]),0)
            dz=np.maximum(np.maximum(launch_lo[:,2]-hi[2],lo[2]-launch_hi[:,2]),0)
            distance=np.sqrt(dx*dx+dz*dz)
            reach=16*(JUMP_VELOCITY+np.sqrt(np.maximum(0,JUMP_VELOCITY**2-2*196.2*rise)))/196.2
            hits=np.where((rise<=7.2)&(reach+2-distance>=0))[0]
            if len(hits):return launch_boxes[int(hits[0])][2]
    return None


def place(name,kind,x,z,build):
    if not inside(x,z): return False
    start=len(g.pieces); old_counts=g.counts.copy()
    g.group=name;g.kind=kind
    build()
    pieces=g.pieces[start:]
    why=None
    for p in pieces:
        v=np.array(p['vertices']);lo,hi=v.min(axis=0),v.max(axis=0)
        if len(overlap(lo,hi,zone_lo,zone_hi)):
            why='route body/jump envelope';break
        hits=overlap(lo,hi,obs_lo,obs_hi,.08)
        if len(hits):
            why='existing visible geometry';break
    if why is None:
        source=reachable_art(pieces)
        if source:why='reachable scenery support from '+source
    if why:
        del g.pieces[start:];g.counts=old_counts
        rejected.append({'name':name,'reason':why,'x':x,'z':z})
        return False
    vertices=np.array([v for p in pieces for v in p['vertices']])
    accepted.append({'name':name,'kind':kind,'x':x,'z':z,
                     'bounds':[vertices.min(axis=0).tolist(),vertices.max(axis=0).tolist()]})
    return True


trees=[(-174,172),(-174,99),(-171,22),(-174,-64),(-170,-169),(-114,178),(-45,179),
       (41,179),(161,171),(173,104),(173,23),(173,-63),(164,-170),(77,-174),(3,-174),
       (-64,-174),(-99,110),(-97,-50),(-9,-23),(2,55),(102,-37)]
for i,(x,z) in enumerate(trees):
    candy=x>-20 and z<-45
    place(f'Tree_{i+1:02d}','tree',x,z,lambda x=x,z=z,i=i,candy=candy:g.tree(x,z,43+i%3*2,candy,candy and i%2==0))

sunflowers=[(-172,146),(-174,61),(-173,-23),(-171,-103),(-107,-173),(-43,-174),
            (160,-170),(173,-88),(171,-8),(172,77),(156,176),(89,174),(-25,177),
            (-69,175),(-29,147),(-99,103),(-96,-41),(4,39),(132,70)]
for i,(x,z) in enumerate(sunflowers):
    for dx,dz in ((0,0),(0,-10),(-10,0),(10,0),(0,10),(-14,-8),(14,8)):
        px,pz=x+dx,z+dz
        if any(math.hypot(px-p['x'],pz-p['z'])<32 for p in accepted if p['kind']=='tree'):continue
        if place(f'Sunflower_{i+1:02d}','flower',px,pz,lambda px=px,pz=pz,i=i:g.sunflower(px,pz,34+i%3*3,1.6+i%2*.12,-.5+(i%3)*.22)):break

bamboos=[(-172,122),(-175,3),(-172,-84),(-111,-169),(-106,-33),(-63,83),
         (172,118),(172,-116),(120,174),(-92,174)]
for i,(x,z) in enumerate(bamboos):
    for dx,dz in ((0,0),(0,-12),(0,12),(-10,0),(10,0)):
        px,pz=x+dx,z+dz
        if place(f'Bamboo_{i+1:02d}','bamboo',px,pz,lambda px=px,pz=pz,i=i:g.bamboo(px,pz,40+i%3*4)):break

reserved=[(p['x'],p['z'],6 if p['kind']!='bamboo' else 8) for p in accepted]
for iz,z in enumerate(range(-179,185,11)):
    for ix,x in enumerate(range(-180,183,11)):
        px,pz=x+g.rng.uniform(-2.5,2.5),z+g.rng.uniform(-2.5,2.5)
        if not inside(px,pz,4):continue
        if any(math.hypot(px-rx,pz-rz)<r+4 for rx,rz,r in reserved):continue
        if g.rng.random()>.93:continue
        theme='candy' if px>-15 and pz<-50 else 'green'
        width=g.rng.uniform(7.3,10.4)
        tall=(ix+2*iz)%4==0
        top=g.rng.uniform(5.2,8.3) if tall else 1.7
        if place(f'Underplant_{ix:02d}_{iz:02d}','low foliage',px,pz,
                 lambda px=px,pz=pz,width=width,theme=theme,top=top:g.bush(px,pz,width,top,theme)) or (tall and
                 place(f'Underplant_{ix:02d}_{iz:02d}','low foliage',px,pz,
                 lambda px=px,pz=pz,width=width,theme=theme:g.bush(px,pz,width,1.7,theme))):
            if g.rng.random()<.48:
                fx,fz=px+g.rng.uniform(-2,2),pz+g.rng.uniform(-2,2)
                col=['flower_pink','flower_cream','flower_gold'][(ix+iz)%3]
                height,size=g.rng.uniform(9.5,14),g.rng.uniform(1.2,1.8)
                for lift in (0,6,12,18):
                    if place(f'Flower_{ix:02d}_{iz:02d}','flower',fx,fz,
                        lambda fx=fx,fz=fz,col=col,height=height,size=size,lift=lift:g.flower(fx,fz,height+lift,size,col)):break

for i,(x,z) in enumerate([(61,-26),(111,-28),(154,-22),(137,42),(108,96),(62,65),(88,111)]):
    placed=False
    for height in (14,24,30,36):
        for dx,dz in ((0,0),(-8,0),(8,0),(0,-8),(0,8)):
            px,pz=x+dx,z+dz
            if place(f'Clover_{i:02d}','clover',px,pz,lambda px=px,pz=pz,height=height:g.clover(px,pz,height,.95)):
                placed=True;break
        if placed:break

for i,(x,z,size) in enumerate([(-175,157,1.15),(-40,181,1.3),(23,178,1.15),(103,181,1.25),
        (160,179,1.3),(177,148,1.1),(13,114,1),(63,135,1.2),(145,84,1.15)]):
    place(f'HarvestPumpkin_{i:02d}','produce',x,z,lambda x=x,z=z,size=size:g.pumpkin(x,z,size))

# Boundary sections are grouped by panel, with one deliberate opening at the start.
for axis in ('x','z'):
    for side in (-1,1):
        for t in range(-180,181,12):
            x,z=(side*184,t) if axis=='x' else (t,side*187)
            if not inside(x,z):continue
            if axis=='x' and side==-1 and 122<t<168:continue
            def fence_panel(drop=0):
                g.stud_box((x,.65-drop,z),(1.7,6.9,1.7),'timber',pitch=2,radius=.55)
                if t==180:return
                center=(x,1.2-drop,z+6) if axis=='x' else (x+6,1.2-drop,z)
                size=(.85,1.1,10.5) if axis=='x' else (10.5,1.1,.85)
                g.box(center,size,'timber_light');g.box((center[0],-1.2-drop,center[2]),size,'timber_light')
            if not place(f'Fence_{axis}_{side}_{t}','fence',x,z,fence_panel):
                place(f'Fence_{axis}_{side}_{t}','fence',x,z,lambda:fence_panel(2.1))

stud_surfaces=[]
for part,pos,rot in surface_parts:
    if not inside(pos[0],pos[2]):continue
    color='surface_'+'_'.join(str(round(c*255)) for c in part['color'])
    PALETTE[color]='#'+''.join(f'{round(c*255):02X}' for c in part['color'])
    g.group='Studs_'+part['path'];g.kind='surface studs'
    yaw=math.atan2(rot[2,0],rot[0,0])
    top=pos[1]+part['size'][1]/2
    def clear_paint(stud_pos):
        lo=np.array((stud_pos[0]-.82,top+.015,stud_pos[2]-.82))
        hi=np.array((stud_pos[0]+.82,top+.36,stud_pos[2]+.82))
        return not len(overlap(lo,hi,obs_lo,obs_hi))
    g.studs((pos[0],pos[1]+part['size'][1]/2,pos[2]),part['size'][0]-.45,
            part['size'][2]-.45,color,3.3,.74,.28,yaw,clear_paint)
    stud_surfaces.append(part['path'])

for model in data['models']:
    if model.get('family') not in ('BroadPlayableLeaf','ExpertLeaf','FacetedRootBridge'):continue
    parts=[p for p in data['parts'] if p['path'].startswith(model['path']+'.')
           and p['role']=='Walk' and (p['name'].startswith('BladeFacet') or p['name'].startswith('RootCrownFacet'))]
    if not parts:continue
    points=np.concatenate([native_vertices(p) for p in parts]);lo=points.min(axis=0);hi=points.max(axis=0)
    center=(lo+hi)/2
    if not inside(center[0],center[2]):continue
    if hi[1]-lo[1]>1.1:continue
    outline=inset(hull(points[:,[0,2]]),.85)
    if len(outline)<3:continue
    source_color=parts[0]['color'];color='surface_'+'_'.join(str(round(c*255)) for c in source_color)
    PALETTE[color]='#'+''.join(f'{round(c*255):02X}' for c in source_color)
    g.group='Studs_'+model['path'];g.kind='surface studs'
    def on_crown(pos):
        if not all(cross(a,b,(pos[0],pos[2]))>=0 for a,b in zip(outline,outline[1:]+outline[:1])):return False
        return not len(overlap(np.array((pos[0]-.7,hi[1]+.015,pos[2]-.7)),
                               np.array((pos[0]+.7,hi[1]+.3,pos[2]+.7)),obs_lo,obs_hi))
    g.studs((center[0],hi[1],center[2]),hi[0]-lo[0],hi[2]-lo[2],color,3.3,.65,.26,predicate=on_crown)
    stud_surfaces.extend(p['path'] for p in parts)

for part in data['parts']:
    if part['name'] not in ('RoundedWoodShaft','GripCrossbar'):continue
    cf=np.array(part['cf']);pos=cf[:3]-ORIGIN;rot=cf[3:].reshape(3,3)
    if not inside(pos[0],pos[2]) or abs(rot[1,0])>.01:continue
    color='surface_'+'_'.join(str(round(c*255)) for c in part['color'])
    PALETTE[color]='#'+''.join(f'{round(c*255):02X}' for c in part['color'])
    g.group='Studs_'+part['path'];g.kind='handle studs'
    length,radius=part['size'][0],min(part['size'][1:])/2
    for along in np.arange(-length/2+1.5,length/2-1,3.1):
        p=pos+rot[:,0]*along+np.array((0,radius+.10,0))
        g.cylinder(tuple(p),.48,.24,color,10,detail='stud')

# Only uncovered ground receives literal studs; large hidden grids are omitted.
g.group='GroundStuds';g.kind='ground studs'
plant_bounds=[p['bounds'] for p in accepted]
for x in np.arange(REGION[0]+2,REGION[1]-1,5.0):
    for z in np.arange(REGION[2]+2,REGION[3]-1,5.0):
        if any(lo[0]-1<x<hi[0]+1 and lo[2]-1<z<hi[2]+1 for lo,hi in plant_bounds):continue
        lo=np.array((x-.85,-2.8,z-.85));hi=np.array((x+.85,-2.46,z+.85))
        foot_hits=(obs_lo[:,0]<hi[0])&(obs_hi[:,0]>lo[0])&(obs_lo[:,2]<hi[2])&(obs_hi[:,2]>lo[2])
        if np.any(foot_hits):continue
        g.cylinder((float(x),-2.63,float(z)),.82,.34,'grass',12,detail='stud')
        g.counts['raised_studs']+=1

root_skins=add_root_skins(g,data,ORIGIN,scene,PALETTE) if args.full else []
g.prune_buried_studs()

collection=bpy.data.collections.new('SGV2_Phase3_'+args.candidate)
scene.collection.children.link(collection)
material_cache={}
export_objects=[]
mesh_records=[]


def material(color):
    if color not in material_cache:
        rgb=tuple(int(PALETTE[color][i:i+2],16)/255 for i in (1,3,5))
        m=bpy.data.materials.new('P3_'+color);m.use_nodes=True
        shader=m.node_tree.nodes['Principled BSDF']
        shader.inputs['Base Color'].default_value=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb)+(1,)
        shader.inputs['Roughness'].default_value=.48
        material_cache[color]=m
    return material_cache[color]


def emit_batch(color,detail,index,pieces,tile):
    vertices=[];faces=[]
    for p in pieces:
        offset=len(vertices)
        vertices.extend((x,-z,y) for x,y,z in p['vertices'])
        faces.extend(tuple(v+offset for v in f) for f in p['faces'])
    name=f'{args.candidate}__{color}__{detail}__{index:03d}'
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    if detail=='solid':
        bmesh.ops.bevel(bm,geom=list(bm.edges),offset=.38,segments=1,affect='EDGES',clamp_overlap=True)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    boundaries=sum(e.is_boundary for e in bm.edges)
    bm.to_mesh(mesh);bm.free()
    assert boundaries==0,(name,boundaries)
    obj=bpy.data.objects.new(name,mesh);collection.objects.link(obj)
    obj.data.materials.append(material(color));export_objects.append(obj)
    mesh_vertices=[(v.co.x,v.co.z,-v.co.y) for v in mesh.vertices]
    mesh_records.append({'name':name,'color':color,'hex':PALETTE[color],
        'triangles':len(mesh.polygons),'vertices':len(mesh.vertices),'boundaryEdges':boundaries,
        'tile':tile,
        'exportBoundsRoblox':[[min(v[k] for v in mesh_vertices) for k in range(3)],
                              [max(v[k] for v in mesh_vertices) for k in range(3)]],
        'boundsRoblox':[list(min(v[k] for p in pieces for v in p['vertices']) for k in range(3)),
                         list(max(v[k] for p in pieces for v in p['vertices']) for k in range(3))],
        'sourceGroups':sorted(set(p['group'] for p in pieces))})


# Bound each batch before bevel. Solid boxes grow under bevel, so use a smaller budget.
batches=defaultdict(list)
for p in g.pieces:
    vertices=np.array(p['vertices']);center=vertices.mean(axis=0)
    tile=(int(math.floor(center[0]/128)),int(math.floor(center[2]/128)))
    batches[(p['color'],p['detail'],tile)].append(p)
indices=defaultdict(int)
for (color,detail,tile),pieces in sorted(batches.items()):
    chunk=[];cost=0;limit=7200 if detail=='stud' else 1700
    for p in pieces:
        triangles=sum(len(f)-2 for f in p['faces'])
        if cost+triangles>limit and chunk:
            key=(color,detail);emit_batch(color,detail,indices[key],chunk,tile);indices[key]+=1
            chunk=[];cost=0
        chunk.append(p);cost+=triangles
    if chunk:
        key=(color,detail);emit_batch(color,detail,indices[key],chunk,tile);indices[key]+=1

# Finish solid edges first, then share batches with same-color relief in the same region.
compatible=defaultdict(list)
for record,obj in zip(mesh_records,export_objects):
    compatible[(record['hex'],tuple(record['tile']))].append((record,obj))
finished_records=[];finished_objects=[];finish_indices=defaultdict(int)
for (hex_color,tile),entries in sorted(compatible.items()):
    chunks=[];chunk=[];cost=0
    for entry in entries:
        if cost+entry[0]['triangles']>9000 and chunk:
            chunks.append(chunk);chunk=[];cost=0
        chunk.append(entry);cost+=entry[0]['triangles']
    if chunk:chunks.append(chunk)
    color=next(key for key,value in PALETTE.items() if value==hex_color)
    for chunk in chunks:
        vertices=[];faces=[];source_groups=set()
        for record,obj in chunk:
            offset=len(vertices)
            vertices.extend(tuple(v.co) for v in obj.data.vertices)
            faces.extend(tuple(i+offset for i in p.vertices) for p in obj.data.polygons)
            source_groups.update(record['sourceGroups'])
        index=finish_indices[color];finish_indices[color]+=1
        name=f'{args.candidate}__{color}__batch__{index:03d}'
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
        obj=bpy.data.objects.new(name,mesh);collection.objects.link(obj);obj.data.materials.append(material(color))
        points=[(v[0],v[2],-v[1]) for v in vertices]
        bounds=[[min(v[k] for v in points) for k in range(3)],[max(v[k] for v in points) for k in range(3)]]
        finished_records.append({'name':name,'color':color,'hex':hex_color,'triangles':len(faces),
             'vertices':len(vertices),'boundaryEdges':0,'tile':tile,'exportBoundsRoblox':bounds,
             'boundsRoblox':bounds,'sourceGroups':sorted(source_groups)})
        finished_objects.append(obj)
for obj in export_objects:bpy.data.objects.remove(obj,do_unlink=True)
export_objects=finished_objects;mesh_records=finished_records

assert max(r['triangles'] for r in mesh_records)<10000,'Mesh must be split further for import'
manifest={'candidate':'SGV2_Phase3_'+args.candidate,'sourceCourse':'SGV2_R305',
          'geometrySourceSha256':hashlib.sha256(DATA_PATH.read_bytes()).hexdigest(),
          'regionRobloxXZ':REGION,'offsetRoblox':OFFSET,'counts':dict(g.counts),
          'meshCount':len(mesh_records),'triangles':sum(r['triangles'] for r in mesh_records),
          'maxMeshTriangles':max(r['triangles'] for r in mesh_records),'meshes':mesh_records,
          'acceptedGroups':accepted,'rejectedGroups':rejected,'studdedSourceParts':sorted(set(stud_surfaces)),
          'rootSkins':root_skins,
          'sceneryReachScreen':{'initialRouteParts':seed_count,'conservativeReachableLaunchParts':len(launch_boxes),
             'partialContactAllowance':2,'movement':{'speed':16,'jumpHeight':7.2,'gravity':196.2},
             'limits':'Static bounding-box reach closure; no motion, run-up, steering or collision response. New upward-facing solid art is kept outside direct reach from this closure.'},
          'palette':PALETTE,'calibrationRoblox':{'CalO':[0,0,0],'CalX':[24,0,0],'CalY':[0,24,0],'CalZ':[0,0,24]},
          'limits':['Art overlay only; original course geometry remains R305.','Placement uses conservative visible/body bounds, not gameplay or camera motion.','Literal studs are shallow decorative relief, not new landing support.','Import and final collision representation require native verification.']}
(OUT/'placement-pieces.json').write_text(json.dumps(g.pieces,separators=(',',':')),encoding='utf-8')
(OUT/'source').mkdir(exist_ok=True)
for name,content in source_snapshots.items():(OUT/'source'/name).write_bytes(content)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

for name,point in manifest['calibrationRoblox'].items():
    bpy.ops.mesh.primitive_cube_add(size=2,location=(point[0],-point[2],point[1]))
    obj=bpy.context.object;obj.name=name;obj.hide_render=True;export_objects.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in export_objects:obj.select_set(True)
bpy.context.view_layer.objects.active=export_objects[0]
fbx=OUT/f'SGV2_Phase3_{args.candidate}.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'MESH'},
    apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=False,bake_anim=False)
manifest.update(fbxBytes=fbx.stat().st_size,fbxSha256=hashlib.sha256(fbx.read_bytes()).hexdigest())
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/f'SGV2_Phase3_{args.candidate}.blend'))
scene.cycles.samples=16;scene.render.threads=8
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.camera.data.type='PERSP';scene.camera.data.lens=27;scene.camera.data.clip_end=3000
views=[('01-seed-overview',(-244,155,233),(-112,8,106),220),
       ('02-start-height',(-165,13.5,144),(-105,11,144),None),
       ('03-tools-height',(-74,16,148),(-48,10,96),None),
       ('04-seed-reverse',(-48,14,83),(-127,13,132),None)]
if args.full:
    views=[('01-whole-southwest',(-320,350,360),(0,8,0),565),
           ('02-whole-northeast',(340,350,-355),(0,8,0),565),
           ('03-seed-forward',(-165,13.5,144),(-105,11,144),None),
           ('04-seed-reverse',(-48,14,83),(-127,13,132),None),
           ('05-crop-forward',(-58,12,31),(-57,12,-52),None),
           ('06-crop-reverse',(-154,15,-126),(-125,14,-62),None),
           ('07-grove-forward',(-18,14,-144),(56,14,-135),None),
           ('08-grove-reverse',(79,15,-53),(74,14,-106),None),
           ('09-grove-root-detail',(162,16,-113),(124,8,-106),None),
           ('10-vine-forward',(75,15,-56),(114,16,-22),None),
           ('11-vine-reverse',(32,17,22),(105,19,41),None),
           ('12-festival-forward',(35,15,79),(91,14,112),None),
           ('13-festival-reverse',(-11,14,159),(54,17,141),None),
           ('14-harvest-destination',(-69,32,207),(10,10,150),None),
           ('15-grove-overview',(106,100,-218),(82,6,-107),180)]
if not args.no_render:
    (OUT/'views').mkdir(exist_ok=True)
    for name,eye,target,ortho in views:
        camera=scene.camera;camera.data.type='ORTHO' if ortho else 'PERSP'
        if ortho:camera.data.ortho_scale=ortho
        camera.location=Vector((eye[0],-eye[2],eye[1]))
        t=Vector((target[0],-target[2],target[1]))
        camera.rotation_euler=(t-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(OUT/'views'/f'{name}.png')
        bpy.ops.render.render(write_still=True)
        print('PHASE3_VIEW '+name,flush=True)
print(json.dumps({'candidate':args.candidate,'counts':dict(g.counts),'meshes':len(mesh_records),
                  'triangles':manifest['triangles'],'fbxBytes':manifest['fbxBytes']}),flush=True)
