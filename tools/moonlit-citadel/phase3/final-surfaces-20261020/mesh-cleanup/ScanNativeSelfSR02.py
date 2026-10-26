"""Scan every actual imported native triangle for exact same-facing overlap."""
from pathlib import Path
import hashlib
import json
import numpy as np

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
SOURCE=ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/native-import-sr02-57.json'
OUT=HERE/'proposal02'
native=json.loads(SOURCE.read_text())


def cross(a,b):
    return a[0]*b[1]-a[1]*b[0]


def overlap(a,b):
    result=list(a)
    if cross(b[1]-b[0],b[2]-b[0])<0:
        b=b[::-1]
    for start,end in zip(b,np.roll(b,-1,axis=0)):
        previous=result;result=[]
        if not previous:
            return 0.
        p=previous[-1];pd=cross(end-start,p-start)
        for q in previous:
            qd=cross(end-start,q-start)
            if (qd>=-1e-10)!=(pd>=-1e-10):
                result.append(p+(q-p)*(pd/(pd-qd)))
            if qd>=-1e-10:
                result.append(q)
            p,pd=q,qd
    if len(result)<3:
        return 0.
    return abs(sum(cross(result[i+1]-result[0],result[i+2]-result[0])for i in range(len(result)-2)))*.5


rows=[]
all_geometry={}
for mesh in native['meshes']:
    vertices=np.array(mesh['verticesMicro'],dtype=float)/1e6
    faces=np.array(mesh['faces'],dtype=int)-1
    triangles=vertices[faces]
    normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    lengths=np.linalg.norm(normals,axis=1)
    assert np.all(lengths>1e-9)
    normals/=lengths[:,None]
    centers=triangles.mean(axis=1)
    hits=[];maximum_sliver=0.;tested=0
    for i,triangle in enumerate(triangles):
        normal=normals[i]
        normal_match=normals[i+1:]@normal>1-1e-6
        point_plane=np.max(abs((triangles[i+1:]-triangle[0])@normal),axis=1)<.00003
        axes=[a for a in range(3)if a!=int(np.argmax(abs(normal)))]
        a=triangle[:,axes];others=triangles[i+1:,:,axes]
        bounds=np.all(np.minimum(a.max(axis=0),others.max(axis=1))-np.maximum(a.min(axis=0),others.min(axis=1))>1e-7,axis=1)
        choices=np.flatnonzero(normal_match&point_plane&bounds)+i+1
        for j in choices:
            tested+=1
            area=overlap(a,triangles[j][:,axes])
            if area>1e-5:
                hits.append({'faceA':i+1,'faceB':int(j+1),'projectedOverlapArea':area,
                             'maximumPointPlaneGap':float(np.max(abs((triangles[j]-triangle[0])@normal))),
                             'normalDot':float(normal@normals[j])})
            else:
                maximum_sliver=max(maximum_sliver,area)
    rows.append({'name':mesh['name'],'meshId':mesh['meshId'],'actualNativeTriangleCount':len(triangles),
                 'coplanarTrianglePairsClipped':tested,'exactSameFacingOverlapPairsAbove1e-5':len(hits),
                 'maximumSubthresholdProjectedOverlapArea':maximum_sliver,'hits':hits})
    all_geometry[mesh['name']+'__trianglesNativeLocal']=triangles
    all_geometry[mesh['name']+'__facesNativeOneBased']=np.array(mesh['faces'],dtype=int)
    print(mesh['name']+' actualfaces='+str(len(triangles))+' exactoverlaps='+str(len(hits)),flush=True)
report={'scope':'All actual imported SR02 EditableMesh triangles, all oriented planes; same-facing dot>0.999999, maximum point-plane gap0.00003studs, positive projected area>0.00001squarestuds',
        'nativeAssetId':native.get('assetId','99796608028640'),'sourceSHA256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'meshes':rows,'totalActualNativeTriangles':sum(r['actualNativeTriangleCount']for r in rows),
        'totalExactSameFacingOverlapPairs':sum(r['exactSameFacingOverlapPairsAbove1e-5']for r in rows),
        'studioTouched':False,'uploaded':False}
(OUT/'native-self-overlap-sr02-57.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'native-actual-geometry-sr02-57.npz',**all_geometry)
assert report['totalExactSameFacingOverlapPairs']==0
print('ALL_NATIVE_SELF_PLANES_PASS',flush=True)
