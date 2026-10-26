"""Read-only DT01 saved mesh and FBX roundtrip verification."""
import hashlib
import importlib.util
import json
from pathlib import Path

import bpy
import bmesh

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
OUT=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01'
FILES=[OUT/'manifest.json',OUT/'MC_DETAIL_KIT_DT01.blend',OUT/'MC_DETAIL_KIT_DT01.fbx',OUT/'authored-geometry.json',OUT/'occupied-geometry.json']

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def rounded_vertices(obj):
    return sorted(set(tuple(round(value,5) for value in obj.matrix_world@vertex.co) for vertex in obj.data.vertices))

def main():
    assert bpy.app.background
    hashes={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in FILES}
    manifest=json.loads(FILES[0].read_text())
    assert hashes[str(FILES[2].relative_to(ROOT)).replace('\\','/')]=='155cdd1029d2292f4eff7c5d778dae44f235933b5c62a02eeae822028cbeb687'
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
             'worldVertexSetMatchesAuthored5Decimals':points==original_vertices[name],
             'closedTopology':helper.mesh_audit(obj)}
        low=[min(p[k] for p in points) for k in range(3)];high=[max(p[k] for p in points) for k in range(3)]
        size=[high[k]-low[k] for k in range(3)];centre=[(high[k]+low[k])/2 for k in range(3)]
        row['sizeMaxError']=max(abs(size[k]-part['size'][k]) for k in range(3))
        row['centerMaxError']=max(abs(centre[k]-part['center'][k]) for k in range(3))
        row['pass']=row['worldVertexSetMatchesAuthored5Decimals'] and triangles==part['triangles'] and row['sizeMaxError']<.0001 and row['centerMaxError']<.0001
        if not row['pass']:failures.append(name)
        rows.append(row)
    badge=json.loads((HERE/'badge-contour-check.json').read_text())
    for path,digest in hashes.items():assert sha(ROOT/path)==digest,'Read-only input changed'
    report={'pass':not failures and badge['pass'],'fbxRoundtripPass':not failures,'roundtripFailures':failures,
            'parts':26,'triangles':9574,'savedPartsTopology':topology,'fbxParts':rows,'badgeContour':badge,
            'inputHashes':hashes,'uploadedFBXPreserved':True,'studioTouched':False,'liveBlenderTouched':False,
            'nativeImportVerified':False,'boundary':'FBX roundtrip verifies Blender axis/scale/vertex preservation; actual Roblox importer basis must still be checked by root. Closed/manifold topology does not override the two self-crossing crescent contour findings.'}
    (HERE/'dt01-readonly-roundtrip.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'pass':report['pass'],'fbxRoundtripPass':report['fbxRoundtripPass'],'failures':failures,'badgeSelfCrossings':len(badge['properSelfCrossings'])}))

if __name__=='__main__':main()
