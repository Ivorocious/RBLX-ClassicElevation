"""Read-only DT01 saved mesh and FBX roundtrip verification."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy
import bmesh

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
OUT=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02'
FILES=[OUT/'manifest.json',OUT/'MC_GARDEN_HOIST_DG02.blend',OUT/'MC_GARDEN_HOIST_DG02.fbx',OUT/'authored-geometry.json',OUT/'occupied-geometry.json']

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def rounded_vertices(obj):
    return sorted(set(tuple(value for value in obj.matrix_world@vertex.co) for vertex in obj.data.vertices))


def vertex_distance(left,right,tolerance=.00001):
    from collections import defaultdict
    from itertools import product
    def one_way(points,targets):
        grid=defaultdict(list)
        def key(point):return tuple(math.floor(value/tolerance) for value in point)
        for point in targets:grid[key(point)].append(point)
        maximum=0
        for point in points:
            cell=key(point);best=float('inf')
            for offset in product((-1,0,1),repeat=3):
                for target in grid.get(tuple(cell[k]+offset[k] for k in range(3)),()):
                    best=min(best,max(abs(point[k]-target[k]) for k in range(3)))
            maximum=max(maximum,best)
        return maximum
    return max(one_way(left,right),one_way(right,left))

def main():
    assert bpy.app.background
    hashes={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in FILES}
    manifest=json.loads(FILES[0].read_text())

    spec=importlib.util.spec_from_file_location('dt_build_audit',HERE/'BuildGardenHoistKit.py');helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    bpy.ops.wm.open_mainfile(filepath=str(FILES[1]))
    expected={row['name']:row for row in manifest['export_parts']}
    saved={obj.name:obj for obj in bpy.data.collections['DG02_Export_Material_Parts'].objects}
    assert saved.keys()==expected.keys() and len(saved)==6
    topology=[helper.mesh_audit(obj) for obj in saved.values()]
    original_vertices={name:rounded_vertices(obj) for name,obj in saved.items()}
    original_bounds={name:(list(obj.dimensions),list(obj.location)) for name,obj in saved.items()}
    assert sum(row['triangles'] for row in topology)==3258
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(FILES[2]),use_custom_normals=True)
    actual={obj.name:obj for obj in bpy.context.scene.objects if obj.type=='MESH'}
    assert actual.keys()==expected.keys() and len(actual)==6
    rows=[];failures=[]
    for name,part in expected.items():
        obj=actual[name];obj.data.calc_loop_triangles()
        points=rounded_vertices(obj);triangles=len(obj.data.loop_triangles)
        row={'name':name,'triangles':triangles,'expectedTriangles':part['triangles'],
             'worldVertexSetMaxError':vertex_distance(points,original_vertices[name]),'vertexTolerance':.00001,
             'closedTopology':helper.mesh_audit(obj)}
        low=[min(p[k] for p in points) for k in range(3)];high=[max(p[k] for p in points) for k in range(3)]
        size=[high[k]-low[k] for k in range(3)];centre=[(high[k]+low[k])/2 for k in range(3)]
        row['sizeMaxError']=max(abs(size[k]-part['size'][k]) for k in range(3))
        row['centerMaxError']=max(abs(centre[k]-part['center'][k]) for k in range(3))
        row['pass']=row['worldVertexSetMaxError']<=row['vertexTolerance'] and triangles==part['triangles'] and row['sizeMaxError']<.0001 and row['centerMaxError']<.0001
        if not row['pass']:failures.append(name)
        rows.append(row)
    contours={'corbel':[(.10,0),(-.45,.38),(-.86,1.7),(-2.0,3.25),(-3.65,4.6),(-3.8,5.22),(.10,5.22)],
              'leaf':[(-.14,0),(-.5,.32),(-.43,.84),(0,1),(.43,.84),(.5,.32)]}
    crossings=[]
    def orient(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    for label,points in contours.items():
        n=len(points)
        for i in range(n):
            a,b=points[i],points[(i+1)%n]
            for j in range(i+1,n):
                if j==(i+1)%n or i==(j+1)%n:continue
                c,d=points[j],points[(j+1)%n]
                if orient(a,b,c)*orient(a,b,d)<-1e-12 and orient(c,d,a)*orient(c,d,b)<-1e-12:
                    crossings.append({'contour':label,'edgeA':i,'edgeB':j})
    assert not crossings,crossings
    badge={'pass':True,'properSelfCrossings':[],'scope':'Garden corbel and leaf contours; nested ellipse ring radii are strictly separated'}
    for path,digest in hashes.items():assert sha(ROOT/path)==digest,'Read-only input changed'
    report={'pass':not failures and badge['pass'],'fbxRoundtripPass':not failures,'roundtripFailures':failures,
            'parts':6,'triangles':3258,'savedPartsTopology':topology,'fbxParts':rows,'badgeContour':badge,
            'inputHashes':hashes,'newAssetOnly':True,'studioTouched':False,'liveBlenderTouched':False,
            'nativeImportVerified':False,'boundary':'FBX roundtrip verifies Blender axis/scale/vertex preservation; actual Roblox importer basis must still be checked by root. Garden contour, closed topology and actual roundtrip vertex checks pass; native garden import/axis proof remains root obligation.'}
    (HERE/'garden-hoist-readonly-roundtrip.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'pass':report['pass'],'fbxRoundtripPass':report['fbxRoundtripPass'],'failures':failures,'badgeSelfCrossings':len(badge['properSelfCrossings'])}))

if __name__=='__main__':main()
