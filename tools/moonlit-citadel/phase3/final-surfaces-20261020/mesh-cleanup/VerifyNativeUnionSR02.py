"""Measure actual imported oriented surface coverage in both directions."""
from pathlib import Path
import ast
import hashlib
import json
import numpy as np

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
OUT=HERE/'proposal02'
SOURCE=ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/native-import-sr02-57.json'
native=json.loads(SOURCE.read_text())
saved=np.load(OUT/'cleanup-local-geometry.npz')
proof=json.loads((OUT/'native-axes-proof-sr02-57.json').read_text())

# Load only pure clipping helpers; do not import Blender or execute the builder.
names={'cross2','area','half','intersection','subtract','box','touching'}
tree=ast.parse((HERE/'BuildPlanarCleanup.py').read_text())
definitions=[node for node in tree.body if isinstance(node,ast.FunctionDef)and node.name in names]
namespace={'np':np,'EPS':1e-10,'AREA_EPS':1e-10}
exec(compile(ast.Module(body=definitions,type_ignores=[]),'<pure planar clipping>','exec'),namespace)
subtract,area=namespace['subtract'],namespace['area']


def coverage(source,target):
    normals=np.cross(target[:,1]-target[:,0],target[:,2]-target[:,0])
    normals/=np.linalg.norm(normals,axis=1)[:,None]
    maximum=total=0.;tested=0
    for triangle in source:
        n=np.cross(triangle[1]-triangle[0],triangle[2]-triangle[0]);n/=np.linalg.norm(n)
        choices=np.flatnonzero((normals@n>1-1e-6)&(np.max(abs((target-triangle[0])@n),axis=1)<.00003))
        axis=np.eye(3)[int(np.argmin(abs(n)))];u=np.cross(axis,n);u/=np.linalg.norm(u);v=np.cross(n,u)
        subject=[np.array((point@u,point@v))for point in triangle]
        pieces=[subject]
        low=np.min(subject,axis=0);high=np.max(subject,axis=0)
        for j in choices:
            clipper=[np.array((point@u,point@v))for point in target[j]]
            if np.any(np.minimum(high,np.max(clipper,axis=0))-np.maximum(low,np.min(clipper,axis=0))<=1e-9):
                continue
            tested+=1
            pieces=[fragment for piece in pieces for fragment in subtract(piece,clipper)]
            if not pieces:
                break
        missing=sum(area(piece)for piece in pieces)
        total+=missing;maximum=max(maximum,missing)
    return {'maximumUncoveredTriangleArea':maximum,'totalUncoveredArea':total,'sourceTriangles':len(source),'triangleClips':tested}


rows=[]
for mesh in native['meshes']:
    key=mesh['name'];row=next(r for r in proof['meshes']if r['name']==key)
    before=saved[key+'__originalTrianglesBlenderLocal']
    extent=np.ptp(before.reshape(-1,3),axis=0)
    matrix=np.array(row['newNativeMeshProof']['axisMatrix'])
    expected=(saved[key+'__trianglesBlenderLocal']/extent)@matrix.T*np.array(mesh['meshSize'])
    vertices=np.array(mesh['verticesMicro'],dtype=float)/1e6
    actual=vertices[np.array(mesh['faces'],dtype=int)-1]
    forward=coverage(expected,actual);reverse=coverage(actual,expected)
    # Native float coordinates may shift a planar edge by several millionths of a stud.
    assert max(forward['maximumUncoveredTriangleArea'],reverse['maximumUncoveredTriangleArea'])<.001,(key,forward,reverse)
    rows.append({'name':key,'meshId':mesh['meshId'],'savedToNative':forward,'nativeToSaved':reverse})
    print(key+' uncovered='+str(max(forward['maximumUncoveredTriangleArea'],reverse['maximumUncoveredTriangleArea'])),flush=True)
result={'scope':'Analytic triangle subtraction on every oriented plane of actual native SR02 vs saved cleanup mesh in both directions; normal dot>0.999999, plane distance<0.00003studs. Tiny edge differences measured rather than assumed zero.',
        'nativeAssetId':'99796608028640','nativeReceiptSHA256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'meshes':rows,'allMaximumUncoveredTriangleAreasBelowSquareStuds':.001,'studioTouched':False,'uploaded':False}
(OUT/'native-union-proof-sr02-57.json').write_text(json.dumps(result,indent=2)+'\n')
print('ALL_ACTUAL_NATIVE_ORIENTED_UNIONS_PASS',flush=True)
