"""Bind saved visible geometry to fresh native poses, then intersect near-coplanar triangles."""
from collections import defaultdict
import hashlib
import itertools
import json
from pathlib import Path
import re

import numpy as np

OWN = Path(__file__).resolve().parent
ROOT = next(p for p in OWN.parents if (p / "default.project.json").exists())
SNAPSHOT = ROOT / "docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json"
meta = json.loads((OWN / "surface-objects54.json").read_text(encoding="utf8"))
native = json.loads(SNAPSHOT.read_text(encoding="utf8"))["editable"]["records"]
arrays = np.load(OWN / "surface-triangles54.npz")
triangles, owners, faces = arrays["triangles"], arrays["owners"], arrays["faces"]
objects = meta["objects"]
ORIGIN = np.array((4000,300,2600))
GAP = .02


def value(record, key):
    result = record["props"].get(key, record["props"].get(key.lower()))
    return result.get("value") if isinstance(result, dict) else result


def path_for(row):
    props = row["props"]
    if "FrozenNativePart" in props:
        path = props["FrozenNativePart"].replace(".", "/")
        assert path in native, (row["name"], path)
        return path
    unit = props.get("Source50Unit", props.get("Detail54Unit"))
    material = re.sub(r"\.\d{3}$", "", row["name"].split("__")[-1])
    candidates = [path for path, record in native.items() if record["class"] == "MeshPart"
                  and unit in path.split("/") and record["attrs"].get("SourceAsset") == props["AssetKey"]
                  and record["attrs"].get("SourceMaterial") == material]
    assert len(candidates) == 1, (row["name"], candidates)
    return candidates[0]


errors, maximum = [], 0
for row in objects:
    path = path_for(row)
    record = native[path]
    row["nativePath"] = path
    row["nativeClass"] = record["class"]
    row["nativeTransparency"] = value(record,"Transparency")
    row["nativeDoubleSided"] = value(record,"DoubleSided")
    row["nativeColor"] = value(record,"Color")
    row["nativeMaterial"] = value(record,"Material")
    cf = np.array(value(record,"CFrame"))
    size = np.array(value(record,"Size"))
    selected = triangles[owners == row["index"]].reshape(-1,3)
    local = (selected + ORIGIN - cf[:3]) @ cf[3:].reshape(3,3)
    low, high = local.min(axis=0), local.max(axis=0)
    error = max(np.max(np.abs((low+high)/2)), np.max(np.abs(high-low-size)))
    row["nativeBoundsError"] = float(error)
    maximum = max(maximum,error)
    if error > .003:
        errors.append({"name":row["name"],"nativePath":path,"error":float(error),"renderBounds":[low.tolist(),high.tolist()],"nativeSize":size.tolist()})
binding={"pass":not errors,"objects":len(objects),"nativeMeshes":sum(r["nativeClass"]=="MeshPart" for r in objects),
         "nativePrimitives":sum(r["nativeClass"]=="Part" for r in objects),"maximumTightLocalBoundsError":maximum,
         "errors":errors,"snapshotSHA256":hashlib.sha256(SNAPSHOT.read_bytes()).hexdigest(),
         "sourceBlendSHA256":meta["sourceBlendSHA256"],"boundary":"Actual saved triangle geometry checked against fresh native CFrame/Size tight local bounds; native face proofs remain the original asset receipts."}
(OWN/"native-pose-binding54.json").write_text(json.dumps(binding,indent=2)+"\n",encoding="utf8")
print("NATIVE_BIND "+json.dumps({k:v for k,v in binding.items() if k!="errors"}),flush=True)
if errors:
    print("ERRORS "+json.dumps(errors[:12]),flush=True)
    raise SystemExit("Resolve geometry binding before surface claims")

normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
lengths=np.linalg.norm(normals,axis=1)
valid=lengths>1e-7
normals[valid]/=lengths[valid,None]
distances=np.einsum("ij,ij->i",normals,triangles[:,0])
groups={}
for index in np.flatnonzero(valid):
    normal=tuple(np.rint(normals[index]*1000).astype(int))
    distance=int(round(distances[index]/.04))
    key=(int(owners[index]),normal,distance)
    groups.setdefault(key,[]).append(int(index))
surfaces=[]
buckets=defaultdict(list)
for (owner,normal,distance),indices in groups.items():
    idx=np.array(indices,dtype=np.int32)
    n=normals[idx].mean(axis=0);n/=np.linalg.norm(n)
    drop=int(np.argmax(np.abs(n)));axes=[a for a in range(3) if a!=drop]
    points=triangles[idx][:,:,axes]
    surface={"owner":owner,"normal":n,"distance":float(distances[idx].mean()),"indices":idx,"axes":axes,
             "low":points.min(axis=(0,1)),"high":points.max(axis=(0,1)),"points":points}
    surfaces.append(surface);buckets[(normal,distance)].append(len(surfaces)-1)


def cross(a,b): return a[0]*b[1]-a[1]*b[0]


def clip(a,b):
    output=[point for point in a]
    if cross(b[1]-b[0],b[2]-b[0])<0:b=b[::-1]
    for k in range(3):
        start,end=b[k],b[(k+1)%3]
        source=output;output=[]
        if not source:break
        prev=source[-1];pdist=cross(end-start,prev-start)
        for point in source:
            dist=cross(end-start,point-start)
            if (dist>=-1e-9)!=(pdist>=-1e-9):
                output.append(prev+(point-prev)*(pdist/(pdist-dist)))
            if dist>=-1e-9:output.append(point)
            prev,pdist=point,dist
    if len(output)<3:return 0,None
    polygon=np.array(output)
    area=abs(sum(cross(polygon[(i+1)%len(polygon)]-polygon[0],polygon[(i+2)%len(polygon)]-polygon[0]) for i in range(len(polygon)-2)))*.5
    return area,polygon.mean(axis=0)


pair_candidates=set()
for (normal,distance),indices in buckets.items():
    other=indices+buckets.get((normal,distance+1),[])
    for first in indices:
        for second in other:
            a,b=surfaces[first],surfaces[second]
            if np.dot(a["normal"],b["normal"])<1-1e-6:continue
            if abs(a["distance"]-b["distance"])>GAP+.001:continue
            if a["axes"]!=b["axes"]:continue
            if np.any(np.minimum(a["high"],b["high"])-np.maximum(a["low"],b["low"])<=1e-6):continue
            pair_candidates.add(tuple(sorted((first,second))))
print("SURFACE_BROADPHASE "+json.dumps({"triangles":len(triangles),"surfaceGroups":len(surfaces),"surfacePairs":len(pair_candidates)}),flush=True)
hits={};triangle_pairs=0
for si,sj in sorted(pair_candidates):
    a,b=surfaces[si],surfaces[sj]
    ap,bp=a["points"],b["points"]
    blo,bhi=bp.min(axis=1),bp.max(axis=1)
    for ai,at in enumerate(ap):
        alo,ahi=at.min(axis=0),at.max(axis=0)
        candidates=np.flatnonzero(np.all(np.minimum(ahi,bhi)-np.maximum(alo,blo)>1e-6,axis=1))
        for bi in candidates:
            i,j=int(a["indices"][ai]),int(b["indices"][bi])
            if i>=j and si==sj:continue
            if owners[i]==owners[j] and faces[i]==faces[j]:continue
            triangle_pairs+=1
            gap=np.abs((triangles[j]-triangles[i,0])@normals[i]).max()
            if gap>GAP:continue
            area,centre=clip(at,bp[bi])
            area/=abs(a["normal"][3-sum(a["axes"])])
            if area<.01:continue
            k=tuple(sorted((int(owners[i]),int(owners[j]))))
            item=hits.setdefault(k,{"a":k[0],"b":k[1],"area":0,"maximumGap":0,"minimumGap":float("inf"),"trianglePairs":0,"witnesses":[]})
            item["area"]+=area;item["maximumGap"]=max(item["maximumGap"],float(gap));item["minimumGap"]=min(item["minimumGap"],float(gap));item["trianglePairs"]+=1
            axes=a["axes"];drop=3-sum(axes)
            point=np.zeros(3);point[axes]=centre
            point[drop]=(np.dot(normals[i],triangles[i,0])-sum(normals[i,axis]*point[axis] for axis in axes))/normals[i,drop]
            item["witnesses"].append({"area":float(area),"gap":float(gap),"point":point.tolist(),"normal":normals[i].tolist(),"faces":[int(faces[i]),int(faces[j])],"triangleIndices":[i,j]})
for item in hits.values():
    item["witnesses"]=sorted(item["witnesses"],key=lambda row:row["area"],reverse=True)[:8]
    item["paths"]=[objects[item["a"]]["nativePath"],objects[item["b"]]["nativePath"]]
result={"scope":"Same-facing near-coplanar actual triangles, positive 2D overlap; visibility classification pending", "maximumGap":GAP,
        "trianglePairsTested":triangle_pairs,"surfacePairs":len(pair_candidates),"pairs":sorted(hits.values(),key=lambda row:row["area"],reverse=True)}
(OWN/"surface-objects54-bound.json").write_text(json.dumps(meta,indent=2)+"\n",encoding="utf8")
(OWN/"coplanar-triangle-candidates.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf8")
print("OVERLAP_CANDIDATES "+json.dumps({"pairs":len(hits),"trianglePairs":triangle_pairs,"top":[{"paths":item["paths"],"area":item["area"],"gap":item["minimumGap"]} for item in result["pairs"][:12]]}),flush=True)
