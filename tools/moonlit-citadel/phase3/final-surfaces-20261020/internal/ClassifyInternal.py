"""Classify fresh overlap witnesses with finite supported-eye first-surface rays."""
from pathlib import Path
from collections import Counter
import json
import sys
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
if len(sys.argv) > 1:
    HERE = HERE / sys.argv[1]
ORIGIN = np.array((4000, 300, 2600))


def prop(record, key):
    v = record["props"].get(key, record["props"].get(key.lower()))
    return v.get("value") if isinstance(v, dict) else v


meta = json.loads((HERE / "surface-objects56.json").read_text(encoding="utf8"))
candidate = json.loads((HERE / "internal-candidates56.json").read_text(encoding="utf8"))
arrays = np.load(HERE / "surface-triangles56.npz")
triangles, owners, faces = arrays["triangles"], arrays["owners"], arrays["faces"]
objects = meta["objects"]
native = json.loads((ROOT / "docs/artifacts/moonlit-citadel/phase3/repair-20261019/final/native-snapshot55.json").read_text(encoding="utf8"))["editable"]["records"]
eyes = []
for path, record in native.items():
    if record["class"] != "Part" or not isinstance(record["attrs"], dict) or not record["attrs"].get("MCWalkable"):
        continue
    cf, size = np.array(prop(record, "CFrame")), np.array(prop(record, "Size"))
    rotation = cf[3:].reshape(3, 3)
    if rotation[1, 1] < .98:
        continue
    for x, z in ((0, 0), (-1, -1), (-1, 1), (1, -1), (1, 1)):
        p = cf[:3] - ORIGIN + rotation @ np.array((x * max(0, size[0]/2-2), size[1]/2+5.5, z * max(0, size[2]/2-2)))
        eyes.append({"path": path, "point": p})
eyes.extend({"path": "AcceptedCrownStanding", "point": np.array(p)} for p in ((6,155.5,-18), (-8,155.5,-30)))
object_indices = [np.flatnonzero(owners == i) for i in range(len(objects))]
object_low = np.array([triangles[idx].min(axis=(0, 1)) for idx in object_indices])
object_high = np.array([triangles[idx].max(axis=(0, 1)) for idx in object_indices])
v0 = triangles[:, 0]
edge1, edge2 = triangles[:, 1] - v0, triangles[:, 2] - v0
ray_count = 0


def cast(origin, endpoint):
    global ray_count
    ray_count += 1
    delta = endpoint - origin
    length = np.linalg.norm(delta)
    direction = delta / length
    inv = np.divide(1, direction, out=np.full(3, np.inf), where=abs(direction) > 1e-12)
    t1, t2 = (object_low-origin)*inv, (object_high-origin)*inv
    near, far = np.minimum(t1,t2).max(axis=1), np.maximum(t1,t2).min(axis=1)
    choices = np.flatnonzero((far >= np.maximum(near, .001)) & (near < length+.05))
    if not len(choices):
        return None
    idx = np.concatenate([object_indices[i] for i in choices])
    h = np.cross(np.tile(direction,(len(idx),1)), edge2[idx])
    determinant = np.einsum('ij,ij->i', edge1[idx], h)
    good = determinant > 1e-8
    if not np.any(good):
        return None
    idx, h, determinant = idx[good], h[good], determinant[good]
    inverse = 1/determinant
    s = origin-v0[idx]
    u = inverse*np.einsum('ij,ij->i',s,h)
    q = np.cross(s,edge1[idx])
    v = inverse*(q@direction)
    distance = inverse*np.einsum('ij,ij->i',edge2[idx],q)
    good = (u>=-1e-8)&(v>=-1e-8)&(u+v<=1+1e-8)&(distance>.001)&(distance<length+.05)
    if not np.any(good):
        return None
    idx, distance = idx[good], distance[good]
    minimum = distance.min()
    return minimum, list(set(int(o)for o in owners[idx[abs(distance-minimum)<.001]]))


output = []
selected_pairs = candidate["pairs"]
if len(sys.argv)>2:
    if sys.argv[2]=='@changed':
        changed=set(meta['changedIndices'])
        selected_pairs=[p for p in selected_pairs if not p['samePart'] and (p['a']in changed or p['b']in changed)]
    else:
        selected_pairs=[p for p in selected_pairs if any(sys.argv[2] in path for path in p['paths'])]
for n, pair in enumerate(selected_pairs):
    found = []
    pair_owners = {pair["a"], pair["b"]}
    for witness in pair["witnesses"]:
        point, normal = np.array(witness["point"]), np.array(witness["normal"])
        choices = sorted((e for e in eyes if normal@(e["point"]-point)>.05 and .5<np.linalg.norm(e["point"]-point)<300),
                         key=lambda e: np.linalg.norm(e["point"]-point))[:32]
        for eye in choices:
            result = cast(eye["point"],point)
            if result is None:
                continue
            distance, hit_owners = result
            length = float(np.linalg.norm(point-eye["point"]))
            if pair_owners.intersection(hit_owners) and abs(distance-length)<.05:
                found.append({"eye": eye["point"].tolist(), "support": eye["path"], "point": point.tolist(),
                              "normal": normal.tolist(), "distance":length, "firstDistance":float(distance),
                              "firstPaths":[objects[o]["path"] for o in hit_owners], "faceWitness":witness})
                break
        if len(found)>=3:
            break
    row = {**pair, "visibleWitnesses":found, "finiteVisible":bool(found)}
    output.append(row)
    if n%25==0:
        print(json.dumps({"pairsDone":n+1,"of":len(candidate['pairs']),"rays":ray_count,"visible":sum(x['finiteVisible']for x in output)}),flush=True)
report = {"scope":"Fresh within-asset face intersections, with finite supported-eye front-facing first-surface rays; no native motion guarantee",
          "objects":len(objects),"triangles":len(triangles),"maximumGap":candidate["maximumGap"],"routeEyes":len(eyes),
          "rays":ray_count,"pairs":output,"candidatePairs":len(output),
          "visiblePairs":sum(x["finiteVisible"]for x in output),
          "visibleDifferentAppearance":sum(x["finiteVisible"]and x["differentAppearance"]for x in output),
          "visibleSelfPairs":sum(x["finiteVisible"]and x["samePart"]for x in output),
          "pathFilter":sys.argv[2] if len(sys.argv)>2 else None,
          "live56ParityPending":True,"studioTouched":False,"liveBlenderTouched":False}
(HERE/"internal-visible56.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
print("COMPLETE "+json.dumps({k:v for k,v in report.items()if k!='pairs'}),flush=True)
