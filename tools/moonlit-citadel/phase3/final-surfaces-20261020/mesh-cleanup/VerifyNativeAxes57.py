"""Read-only axis proof against actual native original and imported triangles."""
from pathlib import Path
import itertools
import json
import hashlib
import numpy as np

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
IMPORTED=ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/native-import57.json'
OUT=HERE/'proposal01'
proposal=json.loads((OUT/'cleanup-proof.json').read_text())
local=np.load(OUT/'cleanup-local-geometry.npz')
native=json.loads(IMPORTED.read_text())
current=json.loads((HERE.parent/'internal/surface-objects56.json').read_text())['objects']
old_arrays=np.load(HERE.parent/'internal/surface-triangles56.npz')
ORIGIN=np.array((4000,300,2600))


def match(a,b):
    centers_a=a.mean(axis=1);centers_b=b.mean(axis=1)
    indices=np.argmin(np.sum((centers_a[:,None]-centers_b[None])**2,axis=2),axis=1)
    center_error=np.linalg.norm(centers_a-centers_b[indices],axis=1).max()
    return float(center_error),indices


def signed_axes(source,native):
    choices=[]
    for perm in itertools.permutations(range(3)):
        for signs in itertools.product((-1,1),repeat=3):
            matrix=np.eye(3)[list(perm)]*np.array(signs)[:,None]
            transformed=source@matrix.T
            error,indices=match(transformed,native)
            choices.append((error,matrix,indices))
    choices.sort(key=lambda x:x[0])
    choice_rank=0
    for choice_rank,(error,matrix,indices) in enumerate(choices):
        transformed=source@matrix.T
        surface_error=max(oriented_surface_error(transformed,native),oriented_surface_error(native,transformed))
        if surface_error<1e-3:
            break
    else:
        raise AssertionError(('No signed axis matrix fits the oriented surface',len(source),surface_error))
    mapped=source@matrix.T
    target=native[indices]
    cyclic=[np.max(np.linalg.norm(mapped-np.roll(target,k,axis=1),axis=2),axis=1)for k in range(3)]
    pertriangle=np.min(cyclic,axis=0)
    # Test orientation explicitly; reversing the winding is not an allowed match.
    a=np.cross(mapped[:,1]-mapped[:,0],mapped[:,2]-mapped[:,0])
    b=np.cross(target[:,1]-target[:,0],target[:,2]-target[:,0])
    normal_dot=np.sum(a*b,axis=1)/(np.linalg.norm(a,axis=1)*np.linalg.norm(b,axis=1))
    return {'axisMatrix':matrix.tolist(),'determinant':float(np.linalg.det(matrix)),
            'selectedCentroidRanking':choice_rank,'axisSelectionOrientedSurfaceErrorNormalized':surface_error,
            'maximumNearestCentroidErrorNormalized':error,'centroidPairCyclicVertexErrorDiagnosticNormalized':float(pertriangle.max()),
            'centroidPairNormalDotDiagnostic':float(normal_dot.min()),'uniqueCentroidPairedNativeTriangles':len(set(indices.tolist())),
            'sourceTriangles':len(source),'nativeTriangles':len(native),'secondBestCentroidErrorNormalized':choices[1][0]}


def oriented_surface_error(source,target):
    ta=target[:,0];te=target[:,1]-ta;tf=target[:,2]-ta
    tn=np.cross(te,tf);tn/=np.linalg.norm(tn,axis=1)[:,None]
    sn=np.cross(source[:,1]-source[:,0],source[:,2]-source[:,0]);sn/=np.linalg.norm(sn,axis=1)[:,None]
    max_error=0.;max_plane_normal_error=0.
    for i,triangle in enumerate(source):
        choices=np.flatnonzero(tn@sn[i]>1-1e-5)
        if not len(choices):
            return float('inf')
        a=ta[choices];e=te[choices];f=tf[choices];n=tn[choices]
        samples=np.concatenate((triangle,triangle.mean(axis=0)[None],(triangle+np.roll(triangle,1,axis=0))*.5))
        ee=np.sum(e*e,axis=1);ff=np.sum(f*f,axis=1);ef=np.sum(e*f,axis=1);den=ee*ff-ef*ef
        for p in samples:
            delta=p-a;de=np.sum(delta*e,axis=1);df=np.sum(delta*f,axis=1)
            u=(de*ff-df*ef)/den;v=(df*ee-de*ef)/den
            plane=abs(np.sum(delta*n,axis=1))
            inside=(u>=-1e-7)&(v>=-1e-7)&(u+v<=1+1e-7)
            distance=np.where(inside,plane,np.inf)
            for aa,bb in ((a,a+e),(a,a+f),(a+e,a+f)):
                ab=bb-aa;t=np.clip(np.sum((p-aa)*ab,axis=1)/np.sum(ab*ab,axis=1),0,1)
                distance=np.minimum(distance,np.linalg.norm(p-aa-t[:,None]*ab,axis=1))
            max_error=max(max_error,float(distance.min()))
    return max_error


results=[]
for row in proposal['meshes']:
    key=row['objectName'];imported=next(r for r in native['meshes']if r['name']==key)
    nvertices=np.array(imported['verticesMicro'],dtype=float)/1e6
    ntri=nvertices[np.array(imported['faces'],dtype=int)-1]
    new=np.array(local[key+'__trianglesBlenderLocal'])
    old=np.array(local[key+'__originalTrianglesBlenderLocal'])
    extent=np.ptp(old.reshape(-1,3),axis=0)
    old_source=old/extent;new_source=new/extent
    raw_new_normalized=ntri/np.array(imported['meshSize'])
    new_proof=signed_axes(new_source,raw_new_normalized)
    old_object=next(r for r in current if r['meshId']in row['sourceMeshIds'])
    idx=np.flatnonzero(old_arrays['owners']==old_object['index'])
    triangles=old_arrays['triangles'][idx]
    frame=np.array(old_object['cframe']);rotation=frame[3:].reshape(3,3)
    native_old=((triangles+ORIGIN-frame[:3])@rotation)/np.array(old_object['size'])
    old_proof=signed_axes(old_source,native_old)
    om=np.array(old_proof['axisMatrix']);nm=np.array(new_proof['axisMatrix'])
    correction=om@nm.T
    new_matrix=np.array(new_proof['axisMatrix']);old_matrix=np.array(old_proof['axisMatrix'])
    new_surface=max(oriented_surface_error(new_source@new_matrix.T,raw_new_normalized),oriented_surface_error(raw_new_normalized,new_source@new_matrix.T))
    old_surface=max(oriented_surface_error(old_source@old_matrix.T,native_old),oriented_surface_error(native_old,old_source@old_matrix.T))
    direct_surface=max(oriented_surface_error(raw_new_normalized,native_old),oriented_surface_error(native_old,raw_new_normalized))
    old_size=np.array(old_object['size']);new_size=np.array(imported['meshSize'])
    envelope_size=np.max(np.array([instance['size']for instance in row['allGuardedMatchingInstances']]),axis=0)
    old_surface_studs=max(oriented_surface_error((old_source@old_matrix.T)*old_size,native_old*old_size),oriented_surface_error(native_old*old_size,(old_source@old_matrix.T)*old_size))
    new_surface_studs=max(oriented_surface_error((new_source@new_matrix.T)*new_size,ntri),oriented_surface_error(ntri,(new_source@new_matrix.T)*new_size))
    direct_surface_studs=max(oriented_surface_error(raw_new_normalized*envelope_size,native_old*envelope_size),oriented_surface_error(native_old*envelope_size,raw_new_normalized*envelope_size))
    assert new_surface_studs<.0005,(key,new_surface,new_surface_studs)
    assert old_surface_studs<.0005,(key,old_surface,old_surface_studs)
    results.append({'name':key,'newMeshId':imported['meshId'],'oldMeshIds':row['sourceMeshIds'],
                    'newNativeMeshProof':new_proof,'oldInstalledMeshProof':old_proof,
                    'requiredNativeMeshGeometryRotation':correction.tolist(),
                    'newBidirectionalOrientedSurfaceErrorNormalized':new_surface,'oldBidirectionalOrientedSurfaceErrorNormalized':old_surface,
                    'directOldNewBidirectionalOrientedSurfaceErrorNormalized':direct_surface,
                    'oldBidirectionalOrientedSurfaceErrorStudsConservative':old_surface_studs,
                    'newBidirectionalOrientedSurfaceErrorStudsConservative':new_surface_studs,
                    'directOldNewMaximumExistingSizeSurfaceErrorStudsConservative':direct_surface_studs,
                    'maximumExistingPerAxisSizeEnvelope':envelope_size.tolist(),
                    'nativeImportedMinimumStoredNormalDot':imported['minNormalDot'],'nativeImportedInvalidUVs':imported['invalidUVs'],
                    'orientedSurfaceCheck':'Every source triangle vertex, centroid and edge midpoint in both directions; target face normals require dot >0.99999. Nearest-centroid triangle identity is diagnostic only because native import changes convex polygon diagonals.',
                    'directApplyMeshPreservingOldCFrameAndSizeCorrect':bool(direct_surface_studs<.0005),
                    'note':'MeshPart.ApplyMesh does not copy CFrame; template CFrame rotation cannot repair a different local geometry axis mapping.'})
    print(key+' old='+str(old_proof['axisMatrix'])+' new='+str(new_proof['axisMatrix'])+' direct='+str(results[-1]['directApplyMeshPreservingOldCFrameAndSizeCorrect']),flush=True)
output={'scope':'Actual imported EditableMesh face data vs saved Blender replacement triangles, plus actual old installed Source56 geometry; exhaustive48 signed axis permutations',
        'nativeAssetId':native['assetId'],'nativeImportReceiptSHA256':hashlib.sha256(IMPORTED.read_bytes()).hexdigest(),
        'meshes':results,'studioTouched':False,'uploaded':False}
(OUT/'native-axes-proof57.json').write_text(json.dumps(output,indent=2)+'\n')
print('NATIVE_AXES_COMPLETE',flush=True)
