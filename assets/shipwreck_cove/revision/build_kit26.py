"""Continuous limestone cave: editable shell bays with shared, sealed profiles."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parent
exec((ROOT/'build_revision.py').read_text().split('# Hull axis is local Y.')[0])
BUILD='SC_CAVE_KIT_26'
def cv(x,y,z):return (x,-z,y)
stations=[(108,-24,19,31),(114,-14,21,36),(119,-3,23,40),(125,9,24,43),
          (126,22,24,45),(124,34,24,42),(117,45,24,44),(105,53,23,41),
          (92,58,22,38),(79,58,21,37),(66,58,21,37),(53,58,20,34),(39,58,17,28)]
profiles=[]
for i,(x,z,r,h) in enumerate(stations):
    a=stations[max(0,i-1)];b=stations[min(len(stations)-1,i+1)]
    dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz);nx,nz=-dz/length,dx/length
    inner=[];outer=[]
    for j in range(11):
        angle=math.pi*j/10
        side=-math.cos(angle);up=math.sin(angle)
        noise=math.sin(i*1.93+j*2.17)
        iy=-5+(h+5)*up+noise*1.2*up
        ix=side*(r+noise*1.1)
        # A thick asymmetric hill follows the tunnel rather than a thin roof panel.
        ox=side*(r+9+5*math.sin(i*1.27+j*.91)**2)
        oy=-6+(h+16+6*math.sin(i*.82+j*1.31)**2)*up
        inner.append(cv(x+nx*ix,iy,z+nz*ix))
        outer.append(cv(x+nx*ox,oy,z+nz*ox))
    profiles.append((inner,outer))

for first,last,name in [(0,4,'CaveMouth26'),(4,8,'CaveVault26'),(8,12,'CaveSurge26')]:
    g=Geo();vs=[];fs=[];colors=[]
    for inner,outer in profiles[first:last+1]:vs.extend(inner+outer)
    for k in range(last-first):
        for j in range(10):
            for layer in range(2):
                a=k*22+layer*11+j;b=a+1;c=b+22;d=a+22
                # Alternating diagonals retain irregular geological facets without modifiers.
                faces=[(a,b,c),(a,c,d)] if (j+k)%2 else [(a,b,d),(b,c,d)]
                if layer==0:faces=[tuple(reversed(f)) for f in faces]
                fs.extend(faces)
                col=STONE if layer else (STONE_SHADE if j<2 or j>8 else STONE)
                colors.extend([col,col])
        for j in [0,10]:
            a=k*22+j;fs.append((a,a+22,a+33,a+11));colors.append(STONE_SHADE)
    for k in [0,last-first]:
        for j in range(10):
            a=k*22+j;fs.append((a,a+1,a+12,a+11));colors.append(STONE)
    g.mesh(vs,fs,colors)
    asset(name,g,'cave','Sealed thick rock shell; course-local coordinates. Shared end profiles; do not scale bays independently.',estimated_placements=1)

# Flat usable crown with an irregular taper; rocks extend down to the submerged bed.
g=Geo();n=9;vs=[]
for k,(height,rad) in enumerate([(0,4.4),(7,4),(14,3.9),(16,3.25)]):
    for j in range(n):
        a=2*math.pi*j/n;rr=rad*(1+.11*math.sin(j*7.2+k))
        vs.append((rr*math.cos(a),rr*math.sin(a)*.9,height))
fs=[tuple(reversed(range(n))),tuple(3*n+i for i in range(n))]
fs.extend((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j) for k in range(3) for j in range(n))
g.mesh(vs,fs,[STONE_SHADE,CREAM]+[STONE if k%3 else STONE_SHADE for k in range(27)])
asset('CrumbleStone26',g,'cave','Flat irregular crown at Z16. Collider inscribed inside crown; bottom at water bed.',estimated_placements=16)

for i,row in enumerate(rows):
    objects[row['id']].location=(i*240,0,0)
    row['centerBlender']=[(row['boundsBlender']['min'][k]+row['boundsBlender']['max'][k])/2 for k in range(3)]
bpy.context.view_layer.update()
for ob in objects.values():ob.select_set(True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_Kit26.blend'))
bpy.ops.export_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit26.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
manifest=dict(build=BUILD,assets=rows,libraryTriangles=sum(r['triangles'] for r in rows),assetCeiling=1500,kitCeiling=5000,materialCount=1,atlas='palette.png')
assert manifest['libraryTriangles']<=5000
(ROOT/'manifest26.json').write_text(json.dumps(manifest,indent=2))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit26.fbx'))
counts={}
for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
        m=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh();m.calc_loop_triangles();counts[ob.name]=len(m.loop_triangles)
assert sum(counts.values())==manifest['libraryTriangles']
(ROOT/'export-verification26.json').write_text(json.dumps(dict(triangles=sum(counts.values()),assets=counts,modifiersApplied=True),indent=2))
print(json.dumps(manifest | {'assets':counts}))
