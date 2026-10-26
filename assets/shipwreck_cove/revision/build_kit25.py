"""Small editable supplement: curved sea cave, naval gun, dock framing and lamps."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parent
# Reuse the existing palette and simple mesh authoring helpers, not the old assembly.
exec((ROOT/'build_revision.py').read_text().split('# Hull axis is local Y.')[0])
BUILD='SC_KIT_25'

def cv(x,y,z): return (x,-z,y)

# A continuous irregular passage bends gradually; independent wall/roof bays are editable.
stations=[(108,-21,17,32),(117,-6,18,36),(125,10,18,41),(126,27,19,38),
          (117,42,20,42),(101,53,21,39),(83,58,20,35),(65,58,19,34),(44,58,18,31)]
for first,last,label in [(0,3,'CaveMouth25'),(3,5,'CaveVault25'),(5,8,'CaveSurge25')]:
    g=Geo()
    profiles=[]
    for i in range(first,last+1):
        x,z,r,h=stations[i];r+=6;h+=4;a=stations[max(0,i-1)];b=stations[min(len(stations)-1,i+1)]
        dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz);nx,nz=-dz/length,dx/length
        ring=[]
        for j,(side,y) in enumerate([(-1,-5),(-1.02,12),(-.84,h*.72),(-.42,h*.94),(.12,h),(.68,h*.84),(1.02,15),(1,-5)]):
            bias=math.sin(i*2.7+j*1.9)*.9
            ring.append(cv(x+nx*(side*r+bias),y,z+nz*(side*r+bias)))
        profiles.append(ring)
    for k,(a,b) in enumerate(zip(profiles,profiles[1:])):
        for j in range(7):
            # The last chamber faces the inlet through one broad natural breach.
            if label=='CaveSurge25' and k==1 and j in (0,1):continue
            q=[a[j],a[j+1],b[j+1],b[j]]
            outer=[]
            for v in q:
                x,negz,y=v;cx,cz,_,_=stations[first+k]
                direction=Vector((x-cx,negz+cz,0));direction.normalize()
                outer.append((x+direction.x*3.5,negz+direction.y*3.5,y+(3 if j in (2,3,4) else 0)))
            g.mesh(q+outer,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7)],
                   [STONE_SHADE if j in (0,5,6) else STONE,STONE,STONE,STONE_SHADE])
    asset(label,g,'cave','Course-local curved shell, open ends; clear center corridor and high irregular roof.',estimated_placements=1)

g=Geo()
g.box((.7,0,.9),(5.6,3.3,1),DARK)
for y in (-1.45,1.45):g.box((.5,y,1.7),(4.8,.55,1.5),WOOD)
# Revolved twelve-sided barrel, visibly open bore, muzzle at X-5/Z3.1.
for rings,col in [([(-5.1,1.14),(-4.6,1.14),(-4.2,.91),(-1.2,1.2),(1.4,1.05),(1.9,.45)],IRON),
                  ([(-5.13,1.17),(-4.74,1.17)],GOLD),([(-1.2,1.25),(-.8,1.25)],IRON_L),
                  ([(-5.15,1.14),(-5.15,.72),(-3.5,.72)],INK)]:
    g.rings(rings,12,col,'x',(0,0,3.1),False)
g.rings([(1.85,.46),(2.2,.3)],8,IRON,'x',(0,0,3.1))
g.rings([(-2.05,.33),(2.05,.33)],8,IRON,'y',(0,0,2.7))
for x in (-1.3,1.8):
    for y in (-2,2):
        g.rings([(-.35,.88),(.35,.88)],10,DARK,'y',(x,y,.9))
        g.rings([(-.36,.89),(-.36,.69)],10,IRON_L,'y',(x,y,.9),False)
g.beam((1.3,0,3.8),(1.6,0,4.45),.18,.18,ROPE)
asset('NavalCannon25',g,'cannon','Local -X muzzle, center Z3.1; simple separate barrel carriage and wheels.',estimated_placements=4)

g=Geo()
g.beam((-5,0,1),(5,0,9),.65,.7,DARK);g.beam((5,0,1),(-5,0,9),.65,.7,WOOD)
g.box((0,0,9),(12,1,1),DARK)
asset('DockBrace25',g,'dock','Top at Z9.5; scale height to meet deck underside.',estimated_placements=18)

g=Geo();g.box((0,0,.2),(1.4,1.4,.4),IRON)
g.box((0,0,1.2),(.8,.8,1.7),GOLD)
for x in (-.6,.6):
    for y in (-.6,.6):g.beam((x,y,.2),(x,y,2.2),.15,.15,IRON)
g.box((0,0,2.2),(1.4,1.4,.25),IRON);g.rings([(2.3,.7),(2.8,.1)],4,IRON)
asset('Lantern25',g,'lamp','Bottom pivot, opaque amber center; one bounded warm light only on selected placements.',estimated_placements=6)

g=Geo()
for i in range(5):
    x=i*.8-1.6;z=-i*.7
    g.beam((x,0,z+.5),(x+.5,.1,z-1),.18,.18,LEAF)
    g.mesh([(x,0,z),(x-1.2,.1,z-.6),(x-.4,.15,z-1.4),(x+.5,.1,z-.4)],[(0,1,2),(0,2,3)],LEAF_L if i%2 else LEAF)
asset('HangingVine25',g,'vegetation','Root at origin, short five-leaf trail below root.',estimated_placements=9)

for i,row in enumerate(rows):
    objects[row['id']].location=((i%4)*230,(i//4)*230,0)
    row['centerBlender']=[(row['boundsBlender']['min'][k]+row['boundsBlender']['max'][k])/2 for k in range(3)]
bpy.context.view_layer.update()
for ob in objects.values():ob.select_set(True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ShipwreckCove_Kit25.blend'))
bpy.ops.export_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit25.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,use_mesh_modifiers=True,bake_anim=False)
manifest=dict(build=BUILD,assets=rows,libraryTriangles=sum(r['triangles'] for r in rows),assetCeiling=1500,kitCeiling=5000,materialCount=1,atlas='palette.png')
assert manifest['libraryTriangles']<=5000
(ROOT/'manifest25.json').write_text(json.dumps(manifest,indent=2))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'ShipwreckCove_Kit25.fbx'))
counts={}
for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
        m=ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh();m.calc_loop_triangles();counts[ob.name]=len(m.loop_triangles)
assert sum(counts.values())==manifest['libraryTriangles']
(ROOT/'export-verification25.json').write_text(json.dumps(dict(triangles=sum(counts.values()),assets=counts,modifiersApplied=True),indent=2))
print(json.dumps(manifest | {'assets':counts}))
