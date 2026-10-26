"""Seat additive details on actual frozen mesh faces, without changing the source scene."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
SOURCE = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/drafts/keep-surface52/render01/MC_KEEP_SURFACE52_CANDIDATE.blend"
META_BASE = ROOT / "assets/moonlit_citadel/phase3/detail-pass-20261014/dt01"
AXIS = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INVERSE = AXIS.inverted()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_surface(objects):
    vertices, polygons, provenance = [], [], []
    for obj in objects:
        offset = len(vertices)
        vertices.extend(INVERSE @ (obj.matrix_world @ vertex.co) for vertex in obj.data.vertices)
        for face in obj.data.polygons:
            polygons.append([offset + index for index in face.vertices])
            provenance.append((obj.name, face.index))
    return BVHTree.FromPolygons(vertices, polygons), provenance


def ray(surface, origin, direction, distance=600):
    point, normal, index, length = surface[0].ray_cast(origin, direction, distance)
    if point is None:
        return None
    return {"point":list(point), "normal":list(normal), "distance":length,
            "object":surface[1][index][0], "face":surface[1][index][1]}


def get_frame(position, front, up=None):
    up = Vector((0,1,0)) if up is None else up.normalized()
    right = up.cross(front).normalized()
    front = right.cross(up).normalized()
    return Matrix(((right.x,up.x,front.x,position.x),(right.y,up.y,front.y,position.y),
                   (right.z,up.z,front.z,position.z),(0,0,0,1)))


def row(matrix):
    return list(matrix.translation) + [matrix[i][j] for i in range(3) for j in range(3)]


def main():
    assert bpy.app.background
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    seed_report = json.loads((HERE / "seat-seeds.json").read_text())
    metadata_path = (META_BASE / "r01/occupied-geometry.json") if (META_BASE / "r01/occupied-geometry.json").exists() else META_BASE / "occupied-geometry.json"
    metadata = json.loads(metadata_path.read_text())["assets"]
    world = list(bpy.data.collections["Final_233_World_Units"].all_objects)
    assert len(world) == 639
    surfaces, objects_by_unit = {}, {}
    for obj in world:
        unit = str(obj.get("Source50Unit", ""))
        objects_by_unit.setdefault(unit, []).append(obj)
        objects_by_unit.setdefault(str(obj.get("AssetKey", "")), []).append(obj)
    units, failures = [], []
    for seed in seed_report["seeds"]:
        support = seed["supportUnit"]
        objects = objects_by_unit.get(support, [])
        if not objects:
            failures.append({"name":seed["name"],"reason":"No actual support unit","support":support})
            continue
        if support.endswith('CarvedBasin'):
            objects = [obj for obj in objects if obj.name.endswith('__Soil')]
        if support not in surfaces:
            surfaces[support] = build_surface(objects)
        surface = surfaces[support]
        meta = metadata[seed["asset"]]
        scale, front, position = Vector(seed["scale"]), Vector(seed["front"]), Vector(seed["seed"])
        low, high = Vector(meta["bounds"]["low"]), Vector(meta["bounds"]["high"])
        height = (high.y-low.y)*scale.y
        samples, support_ok = [], True
        if seed["kind"] == "wall":
            target = position + Vector((0,height*.5,0))
            hit = ray(surface,target+front*80,-front)
            if hit is None or Vector(hit["normal"]).dot(front) < .8:
                failures.append({"name":seed["name"],"reason":"No outward wall at seed", "hit":hit})
                continue
            inset = -.07 if seed["asset"].endswith("IvyCluster") else .08
            plane = Vector(hit["point"])
            position += front*((plane-position).dot(front)+inset)
            frame = get_frame(position,front)
            for x in (low.x*.80,0,high.x*.80):
                for y in (max(.15,low.y+.25), (low.y+high.y)*.5, high.y-.25):
                    point = frame @ Vector((x*scale.x,y*scale.y,0))
                    sample = ray(surface,point+front*3,-front,8)
                    rooted = bool(sample and abs((Vector(sample["point"])-point).dot(front)) < .5 and Vector(sample["normal"]).dot(front) > .7)
                    samples.append({"probe":list(point),"hit":sample,"rooted":rooted})
                    support_ok = support_ok and rooted
        else:
            frame = get_frame(position,front)
            # The middle fifth of the ground/roof prop is its structural root.
            for x,z in ((0,0),(low.x*.45,low.z*.45),(low.x*.45,high.z*.45),(high.x*.45,low.z*.45),(high.x*.45,high.z*.45)):
                point = frame @ Vector((x*scale.x,0,z*scale.z))
                hit = ray(surface,point+Vector((0,600,0)),Vector((0,-1,0)),1200)
                rooted = bool(hit and hit["normal"][1] > .1)
                samples.append({"probe":list(point),"hit":hit,"rooted":rooted})
                support_ok = support_ok and rooted
            good = [sample["hit"]["point"][1] for sample in samples if sample["rooted"]]
            if not good:
                failures.append({"name":seed["name"],"reason":"No upward supporting face","samples":samples})
                continue
            position.y = min(good)-.12-low.y*scale.y
            frame = get_frame(position,front)
            rise = max(good)-min(good)
            support_ok = support_ok and rise < height*.80
            if support == "MC_EC_WestWoodedCliff":
                centre_hit = samples[0]["hit"]
                up = Vector(centre_hit["normal"])
                position = Vector(centre_hit["point"])-up*.12
                frame = get_frame(position,front,up)
                slope_samples = []
                shifts = []
                for x,z in ((0,0),(low.x*.45,low.z*.45),(low.x*.45,high.z*.45),(high.x*.45,low.z*.45),(high.x*.45,high.z*.45)):
                    point = frame @ Vector((x*scale.x,0,z*scale.z))
                    hit = ray(surface,point+up*4,-up,8)
                    rooted = bool(hit and Vector(hit['normal']).dot(up)>.7)
                    slope_samples.append({"probe":list(point),"hit":hit,"rooted":rooted})
                    if rooted:
                        shifts.append((Vector(hit['point'])-point).dot(up))
                if shifts:
                    position += up*(min(shifts)-.12)
                    frame = get_frame(position,front,up)
                samples = slope_samples
                support_ok = len(shifts)==5 and max(shifts)-min(shifts)<height*.8
        unit = {"name":seed["name"],"district":seed["district"],"asset":seed["asset"],"library":"DT01",
                "localCF":row(frame),"scale":list(scale),"front":list(front),"materialRole":"AdditiveDetail",
                "support":{"unit":support,"kind":seed["kind"],"front":list(front),"samples":samples,"verified":support_ok}}
        units.append(unit)
        if not support_ok:
            failures.append({"name":seed["name"],"reason":"Partial root or excessive surface rise","samples":samples})
    report={"baseSource":52,"units":units,"counts":seed_report["totals"],"combined":seed_report["combined"],
            "sourceBlendSHA256":sha(SOURCE),"metadataPath":str(metadata_path.relative_to(ROOT)),"metadataSHA256":sha(metadata_path),
            "supportVerified":not failures,"failures":failures,"noExistingGeometryChanged":True,"nativeVerified":False}
    (HERE / "detail-placement-plan.json").write_text(json.dumps(report,indent=2)+"\n")
    (HERE / "support-measurements.json").write_text(json.dumps({"units":units,"failures":failures},indent=2)+"\n")
    print("DETAIL_SEATS "+json.dumps({"units":len(units),"failed":len(failures),"failures":[{"name":f["name"],"reason":f["reason"]}for f in failures]}),flush=True)


if __name__ == "__main__":
    main()
