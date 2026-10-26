"""Probe the actual proposed gallery support surfaces without altering the saved scene."""
import hashlib,json
from pathlib import Path
import bpy
from mathutils import Matrix,Vector
from mathutils.bvhtree import BVHTree

HERE=Path(__file__).resolve().parent
OUT=HERE/'proposal03'
SCENE=OUT/'MC_ART_REPAIR55_PROPOSAL.blend'
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
guard=sha(SCENE)
assert bpy.app.background
bpy.ops.wm.open_mainfile(filepath=str(SCENE))
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INV=AXIS.inverted()
plan=json.loads((OUT/'art-plan.json').read_text(encoding='utf8'))
units={r['name']:r for r in plan['units']}
def frame(v):return Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))
def unit(obj):return obj.get('ArtRepairUnit') or obj.get('Detail54Unit') or obj.get('Source50Unit') or obj.get('NativeUnit')
def tree(name):
    vertices=[];faces=[]
    for obj in bpy.data.objects:
        if obj.type!='MESH' or unit(obj)!=name or obj.hide_render:continue
        start=len(vertices);vertices.extend([INV@(obj.matrix_world@v.co) for v in obj.data.vertices])
        obj.data.calc_loop_triangles()
        faces.extend([tuple(start+i for i in t.vertices) for t in obj.data.loop_triangles])
    assert faces,name
    return BVHTree.FromPolygons(vertices,faces,all_triangles=True)
rows=[]
for band in (1,2,3):
    support=f'Gallery{band}EnclosedBody';wall=tree(support)
    for suffix in ('-1','1'):
        name=f'GalleryMoonBanner{band}{suffix}';row=units[name];cf=frame(row['localCF']);scale=Vector(row['scale'])
        for x,y in ((-.22,8.25),(.22,8.25),(-.22,9.9),(.22,9.9),(0,9.08)):
            local=Vector((x*scale.x,y*scale.y,0))
            location=cf@local;front=cf.to_3x3()@Vector((0,0,1))
            origin=location+front*2
            hit,normal,index,distance=wall.ray_cast(origin,-front,3)
            passed=hit is not None and abs(hit.z-59.6)<.002 and normal.dot(front)>.99
            rows.append({'unit':name,'support':support,'point':list(location),'actualWallHit':list(hit) if hit else None,
                         'wallNormal':list(normal) if normal else None,'pass':passed,
                         'backPlateEmbeddedDepth':(hit-(cf@Vector((0,0,-.14*scale.z)))).dot(front) if hit else None})
for name,niche in (('GalleryOneCornice','GalleryOneNorthNiche'),('GalleryThreeCornice','GalleryThreeSouthNiche')):
    cornice=units[name];support=tree(niche)
    point=frame(cornice['localCF'])@Vector((0,.15,.35))
    hit,normal,index,distance=support.ray_cast(point,Vector((0,-1,0)),1)
    passed=hit is not None and normal.y>.5 and distance<.5
    rows.append({'unit':name,'support':niche,'point':list(point),'actualNicheHit':list(hit) if hit else None,'distance':distance,'pass':passed})
assert sha(SCENE)==guard
report={'pass':all(r['pass'] for r in rows),'checks':len(rows),'failures':[r for r in rows if not r['pass']],
        'rows':rows,'sceneSHA256':guard,'planSHA256':sha(OUT/'art-plan.json'),'sceneSavedOrChanged':False,
        'boundary':'Actual authored triangle probes for six bracket backplates and two connected cornice caps; native imported material faces remain root verification.'}
(OUT/'gallery-support-probes.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':report['pass'],'checks':len(rows),'failures':len(report['failures'])}))
assert report['pass'],report['failures']
