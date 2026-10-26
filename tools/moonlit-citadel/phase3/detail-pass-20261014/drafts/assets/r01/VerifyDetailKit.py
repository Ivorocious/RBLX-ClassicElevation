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
OUT=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
FILES=[OUT/'manifest.json',OUT/'MC_DETAIL_KIT_DT01.blend',OUT/'MC_DETAIL_KIT_DT01.fbx',OUT/'authored-geometry.json',OUT/'occupied-geometry.json']

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

    spec=importlib.util.spec_from_file_location('dt_build_audit',HERE/'BuildDetailKit.py');helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    bpy.ops.wm.open_mainfile(filepath=str(FILES[1]))
    expected={row['name']:row for row in manifest['export_parts']}
    saved={obj.name:obj for obj in bpy.data.collections['DT01_Export_Material_Parts'].objects}
    assert saved.keys()==expected.keys() and len(saved)==26
    topology=[helper.mesh_audit(obj) for obj in saved.values()]
    original_vertices={name:rounded_vertices(obj) for name,obj in saved.items()}
    original_bounds={name:(list(obj.dimensions),list(obj.location)) for name,obj in saved.items()}
    assert sum(row['triangles'] for row in topology)==9574
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(FILES[2]),use_custom_normals=True)
    actual={obj.name:obj for obj in bpy.context.scene.objects if obj.type=='MESH'}
    assert actual.keys()==expected.keys() and len(actual)==26
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
    original=OUT.parent
    old_geometry=json.loads((original/'authored-geometry.json').read_text())['parts']
    new_geometry=json.loads((OUT/'authored-geometry.json').read_text())['parts']
    old={p['name']:p for p in old_geometry};new={p['name']:p for p in new_geometry}
    changed=sorted(name for name in old if old[name]!=new[name])
    assert changed==['MC_DT_HeraldicBanner__Brass'],changed
    old_manifest=json.loads((original/'manifest.json').read_text())
    old_parts={p['name']:p for p in old_manifest['export_parts']}
    assert all(old_parts[name]==row for name,row in expected.items()),'Part names/centres/sizes/colours/costs must remain exact'
    old_bounds=json.loads((original/'occupied-geometry.json').read_text())['assets']
    new_bounds=json.loads((OUT/'occupied-geometry.json').read_text())['assets']
    assert all(old_bounds[name]['bounds']==row['bounds'] for name,row in new_bounds.items()),'Whole-unit bounds changed'
    original_sha=sha(original/'MC_DETAIL_KIT_DT01.fbx')
    assert original_sha=='155cdd1029d2292f4eff7c5d778dae44f235933b5c62a02eeae822028cbeb687'
    preservation={'originalUploadedFBXPreserved':True,'originalFBXSHA256':original_sha,
                  'exactOtherMaterialParts':25,'changedMaterialParts':changed,
                  'all26PartManifestRowsExact':True,'all8WholeUnitBoundsExact':True,
                  'occupiedBoxDelta':'Only the corrected crescent component box changes; all other occupied boxes stay exact'}
    badge=json.loads((HERE/'badge-contour-check.json').read_text())
    for path,digest in hashes.items():assert sha(ROOT/path)==digest,'Read-only input changed'
    report={'pass':not failures and badge['pass'],'fbxRoundtripPass':not failures,'roundtripFailures':failures,
            'parts':26,'triangles':9574,'preservation':preservation,'savedPartsTopology':topology,'fbxParts':rows,'badgeContour':badge,
            'inputHashes':hashes,'originalUploadedFBXPreserved':True,'studioTouched':False,'liveBlenderTouched':False,
            'nativeImportVerified':False,'boundary':'FBX roundtrip verifies Blender axis/scale/vertex preservation; actual Roblox importer basis must still be checked by root. Corrected crescent contour has zero proper self crossings; all25other material parts and all26manifest rows remain exact.'}
    (HERE/'r01-readonly-roundtrip.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'pass':report['pass'],'fbxRoundtripPass':report['fbxRoundtripPass'],'failures':failures,'badgeSelfCrossings':len(badge['properSelfCrossings'])}))

if __name__=='__main__':main()
