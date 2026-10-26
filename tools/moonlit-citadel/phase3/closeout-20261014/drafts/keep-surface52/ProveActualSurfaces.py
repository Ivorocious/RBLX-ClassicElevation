"""Prove material face competition and correction on the exported actual assembled keep vertices."""
import hashlib
import itertools
import json
from pathlib import Path
import sys

import numpy as np
from scipy.spatial import ConvexHull

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
sys.path.insert(0,str(ROOT / "tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry"))
from AuditCaps import area, clip, components


def triangles(parts):
    result=[]
    for part in parts:
        vertices=np.array(part["vertices"])
        for index,face in enumerate(part["faces"]):
            for i in range(1,len(face)-1):
                p=vertices[[face[0],face[i],face[i+1]]]
                normal=np.cross(p[1]-p[0],p[2]-p[0]); length=np.linalg.norm(normal)
                assert length>1e-9
                normal/=length
                result.append({"material":part["material"],"face":index,"p":p,"normal":normal,
                               "low":np.min(p,axis=0),"high":np.max(p,axis=0)})
    return result


def convex_components(parts):
    result=[]
    for part in parts:
        for group in components(part):
            points=np.array([part["vertices"][i] for i in sorted(group)])
            hull=ConvexHull(points)
            faces=[f for f in part["faces"] if f[0] in group]
            valid=all(np.any(np.all(np.abs(np.array([part["vertices"][i] for i in face]) @ hull.equations[:,:3].T+hull.equations[:,3])<2e-5,axis=0)) for face in faces)
            if valid:
                result.append({"material":part["material"],"planes":hull.equations,"low":np.min(points,axis=0),"high":np.max(points,axis=0)})
    return result


def buried(polygon,normal,solids):
    sample=np.array(polygon)+normal*.001
    for solid in solids:
        if np.any(np.min(sample,axis=0)<=solid["low"]-1e-7) or np.any(np.max(sample,axis=0)>=solid["high"]+1e-7):
            continue
        distances=sample @ solid["planes"][:,:3].T+solid["planes"][:,3]
        if np.all(distances < -1e-7):
            return {"material":solid["material"],"wholePolygonMargin":float(-np.max(distances))}
    return None


def audit(parts):
    faces=triangles(parts); solids=convex_components(parts); pairs=[]
    for a,b in itertools.combinations(faces,2):
        if a["material"]==b["material"] or np.dot(a["normal"],b["normal"]) < 1-1e-6:
            continue
        if np.max(np.abs((b["p"]-a["p"][0]) @ a["normal"])) > .001:
            continue
        drop=int(np.argmax(np.abs(a["normal"])))
        keep=[i for i in range(3) if i!=drop]
        if np.any(np.minimum(a["high"][keep],b["high"][keep])-np.maximum(a["low"][keep],b["low"][keep])<1e-7):
            continue
        polygon2d=clip(a["p"][:,keep].tolist(),b["p"][:,keep].tolist())
        overlap=area(polygon2d)
        if overlap<1e-7:
            continue
        plane=np.dot(a["normal"],a["p"][0]); polygon=[]
        for p in polygon2d:
            vertex=[0,0,0]
            for axis,value in zip(keep,p): vertex[axis]=value
            vertex[drop]=(plane-sum(a["normal"][i]*vertex[i] for i in keep))/a["normal"][drop]
            polygon.append(vertex)
        proofs=[buried(polygon,face["normal"],solids) for face in (a,b)]
        pairs.append({"a":a["material"]+"/face"+str(a["face"]),"b":b["material"]+"/face"+str(b["face"]),
                      "dominantAxis":"XYZ"[drop],"normal":a["normal"].tolist(),"planeValue":float(a["p"][0][drop]),
                      "planeDelta":float(np.max(np.abs((b["p"]-a["p"][0]) @ a["normal"]))),
                      "areaStudsSquared":overlap/abs(a["normal"][drop]),"polygonCourseLocal":polygon,
                      "aTriangleCourseLocal":a["p"].tolist(),"bTriangleCourseLocal":b["p"].tolist(),
                      "buried":all(proofs),"burialProofs":proofs})
    unburied=[p for p in pairs if not p["buried"]]
    return {"pairs":pairs,"notWhollyBuried":unburied,"sameFacingPairs":len(pairs),"notWhollyBuriedPairs":len(unburied),
            "notWhollyBuriedCandidateAxisAreas":{axis:sum(p["areaStudsSquared"] for p in unburied if p["dominantAxis"]==axis) for axis in "XYZ"},
            "actualConvexComponents":len(solids)}


def scaled(parts,centre,rotation,factor):
    result=json.loads(json.dumps(parts))
    transform=rotation @ np.diag([1,1,factor]) @ rotation.T
    for part in result:
        if part["material"]=="StoneLight":
            part["vertices"]=((np.array(part["vertices"])-centre) @ transform.T+centre).tolist()
    return result


def main():
    source=HERE / "actual-assembled-keep.json"
    data=json.loads(source.read_text())
    light=next(p for p in data["actualParts"] if p["material"]=="StoneLight")
    matrix=np.array(light["blenderMatrix"]).reshape((4,4))
    centre=np.array([matrix[0,3],matrix[2,3],-matrix[1,3]])
    native=data["nativeStoneLightPart"]
    rotation=np.array(native["cf"][3:]).reshape((3,3))
    cases={}
    for name,factor in [("source51",1),("depth1_02",1.02),("depth1_04",1.04)]:
        cases[name]=audit(scaled(data["actualParts"],centre,rotation,factor))
    report={"sourceSHA256":hashlib.sha256(source.read_bytes()).hexdigest(),"nativeAxisBindings":data["nativeAxisBindings"],
            "cases":cases,"toleranceStuds":.001,"burialOutwardProbe":.001,
            "boundary":"Actual assembled Blender polygons with exact native part rotation. A not-wholly-buried candidate area includes the entire overlap polygon, even when part of it is buried; it is not measured visible cap area. This proves material face competition, not every renderer change."}
    (HERE / "face-overlap-proof.json").write_text(json.dumps(report,indent=2)+"\n")
    for name,result in cases.items():
        print(json.dumps({"case":name,"sameFacingPairs":result["sameFacingPairs"],"notWhollyBuriedPairs":result["notWhollyBuriedPairs"],"notWhollyBuriedCandidateAxisAreas":result["notWhollyBuriedCandidateAxisAreas"]}))


if __name__=="__main__":
    main()
