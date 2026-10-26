"""Independently map planar-union Blender-local replacements to current native seats."""
import hashlib
import itertools
import json
import sys
from pathlib import Path
import numpy as np
from scipy.spatial import cKDTree

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
kit_name=sys.argv[1]if len(sys.argv)>1 else 'proposal01'
tag=''if kit_name=='proposal01'else 'kit02-'
KIT=OWN.parent/'mesh-cleanup'/kit_name
proof=json.loads((KIT/'cleanup-proof.json').read_text(encoding='utf8'))
local=np.load(KIT/'cleanup-local-geometry.npz')
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json').read_text(encoding='utf8'))['editable']['records']
meta=json.loads((OWN/'current56-objects.json').read_text(encoding='utf8'))
npz=np.load(OWN/'current56-triangles.npz');oldtri,oldowners,oldfaces=npz['triangles'],npz['owners'],npz['faces']
ORIGIN=np.array((4000,300,2600))
out=OWN/('cleaned-'+tag+'base139');out.mkdir(exist_ok=True)
lookup={}
for mesh in proof['meshes']:
    for matched in mesh['allGuardedMatchingInstances']:
        path=matched['path']
        assert path not in lookup,path;lookup[path]=mesh


def prop(row,key):
    v=row['props'].get(key,row['props'].get(key.lower()))
    return v.get('value')if isinstance(v,dict)else v


variants={}
def normalized(values,permutation,signs):
    points=values[:,:,permutation]*np.array(signs)
    lo,hi=points.min(axis=(0,1)),points.max(axis=(0,1))
    return (points-(lo+hi)/2)/(hi-lo)


triangles=[];owners=[];faces=[];checks=[];seen=set()
for obj in meta['objects']:
    path=obj['nativePath'];index=obj['index'];sel=oldowners==index;points=oldtri[sel];fs=oldfaces[sel]
    if path in lookup:
        mesh=lookup[path];name=mesh['objectName'];record=native[path]
        assert all(prop(record,k)is False for k in('CanCollide','CanQuery','CanTouch')),path
        assert prop(record,'Anchored')is True
        assert prop(record,'MeshId')in mesh['sourceMeshIds']
        cf=np.array(prop(record,'CFrame'));size=np.array(prop(record,'Size'));r=cf[3:].reshape(3,3)
        sourceold=local[name+'__originalTrianglesBlenderLocal'];sourcenew=local[name+'__trianglesBlenderLocal']
        if name not in variants:
            actual=(points+ORIGIN-cf[:3])@r/size
            tree=cKDTree(actual.reshape(-1,3));candidates=[]
            for permutation in itertools.permutations(range(3)):
                for signs in itertools.product((-1,1),repeat=3):
                    if np.linalg.det(np.eye(3)[list(permutation),:]*np.array(signs)[:,None])<0:continue
                    q=normalized(sourceold,permutation,signs)
                    error=float(tree.query(q.reshape(-1,3))[0].max())
                    face_error=float('inf')
                    if error<.001:
                        _,near=cKDTree(q.mean(axis=1)).query(actual.mean(axis=1),k=min(8,len(q)))
                        possibilities=q[near]
                        distances=np.linalg.norm(actual[:,None,:,None,:]-possibilities[:,:,None,:,:],axis=-1)
                        face_error=float(distances.min(axis=3).max(axis=2).min(axis=1).max())
                    candidates.append((face_error,error,permutation,signs))
            candidates.sort(key=lambda row:row[:2])
            variants[name]=candidates[0][2:]
            print(json.dumps({'axisMaterial':name,'bestNormalizedError':candidates[0][1],'bestTriangleError':candidates[0][0],'permutation':candidates[0][2],'signs':candidates[0][3]}),flush=True)
        permutation,signs=variants[name]
        old=sourceold[:,:,permutation]*np.array(signs);new=sourcenew[:,:,permutation]*np.array(signs)
        lo,hi=old.min(axis=(0,1)),old.max(axis=(0,1));centre=(lo+hi)/2;span=hi-lo
        assert np.max(abs(new.min(axis=(0,1))-lo))<1e-6 and np.max(abs(new.max(axis=(0,1))-hi))<1e-6
        oldworld=((old-centre)/span*size)@r.T+cf[:3]-ORIGIN
        oldpoints=points.reshape(-1,3);mappedpoints=oldworld.reshape(-1,3)
        maximum=float(max(cKDTree(oldpoints).query(mappedpoints)[0].max(),cKDTree(mappedpoints).query(oldpoints)[0].max()))
        assert len(points)==len(oldworld)and maximum<.0005,(path,len(points),len(oldworld),maximum)
        # Map each original triangle by its three vertices; equal bounds alone would not prove the chosen axes.
        tree=cKDTree(oldworld.mean(axis=1));ds,nearest=tree.query(points.mean(axis=1))
        face_errors=[]
        for tri,ni in zip(points,nearest):face_errors.append(float(cKDTree(oldworld[ni]).query(tri)[0].max()))
        assert max(face_errors)<.0005,(path,max(face_errors))
        points=((new-centre)/span*size)@r.T+cf[:3]-ORIGIN
        fs=local[name+'__polygonIndices']
        assert len(fs)==len(points)and fs.max()<mesh['replacementPolygons']
        checks.append({'path':path,'mesh':name,'oldTriangles':len(oldworld),'newTriangles':len(points),'maximumOriginalVertexError':maximum,
          'maximumOriginalTriangleVertexError':max(face_errors),'localNativeBoundsCentre':centre.tolist(),'localNativeBoundsSpan':span.tolist(),
          'verifiedBlenderAxisPermutation':list(permutation),'verifiedBlenderAxisSigns':list(signs),
          'polygonIndicesUsed':True,'sourceFacesNotUsedAsPolygonIds':True,'nativeMeshId':prop(record,'MeshId'),'flagsGuarded':True})
        seen.add(path)
        obj['triangles']=len(points);obj['cleanedSurfaceUnionMesh']=name
        obj['bounds']=[points.min(axis=(0,1)).tolist(),points.max(axis=(0,1)).tolist()]
    triangles.append(points);owners.append(np.full(len(points),index,np.int32));faces.append(fs)
assert seen==set(lookup),(len(seen),len(lookup),set(lookup)-seen)
triangles=np.concatenate(triangles);owners=np.concatenate(owners);faces=np.concatenate(faces)
meta.update(surfaceUnionMeshes=7,surfaceUnionInstances=len(checks),triangles=len(triangles),substitution='Exact canonical axis conversion verified against every original triangle at every substituted native pose; actual replacement polygon IDs.')
np.savez_compressed(out/'current56-triangles.npz',triangles=triangles,owners=owners,faces=faces)
(out/'current56-objects.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf8')
report={'pass':True,'surfaceEquivalentInputKitSHA256':hashlib.sha256((KIT/'cleanup-local-geometry.npz').read_bytes()).hexdigest(),
 'sevenMeshes':7,'instances':len(checks),'objects':len(meta['objects']),'beforeTriangles':len(oldtri),'afterTriangles':len(triangles),
 'originalAxisAndTriangleBindingsPass':True,'actualReplacementPolygonIdsUsed':True,'checks':checks}
(out/'CLEANED_AXIS_BINDING.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
final=OWN/('final-'+tag+'cleaned139');final.mkdir(exist_ok=True)
(final/'operations.json').write_bytes((OWN/'FINAL_POSE136.json').read_bytes())
print(json.dumps({k:v for k,v in report.items()if k!='checks'},indent=2))
