"""Bidirectional exact nearest-point distances; no native calls or coordinate edits."""
import argparse
import collections
import hashlib
import json
import math
from pathlib import Path
import time

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p/"default.project.json").exists())


class KDTree:
    def __init__(self,points):
        self.low = tuple(min(p[i] for p in points) for i in range(3))
        self.high = tuple(max(p[i] for p in points) for i in range(3))
        self.points,self.children = None,None
        if len(points) <= 16:
            self.points = points
        else:
            axis = max(range(3),key=lambda i:self.high[i]-self.low[i])
            ordered = sorted(points,key=lambda p:p[axis])
            split = len(ordered)//2
            self.children = (KDTree(ordered[:split]),KDTree(ordered[split:]))

    def bound(self,point):
        return sum(max(self.low[i]-point[i],0,point[i]-self.high[i])**2 for i in range(3))

    def nearest(self,point,best=(float("inf"),None)):
        if self.bound(point) > best[0]:
            return best
        if self.points is not None:
            for candidate in self.points:
                distance = sum((point[i]-candidate[i])**2 for i in range(3))
                if distance < best[0]:
                    best = (distance,candidate)
            return best
        children = sorted(self.children,key=lambda child:child.bound(point))
        for child in children:
            best = child.nearest(point,best)
        return best


def load_parts(data):
    result,duplicates = {},collections.Counter()
    for part in data["parts"]:
        name = part["name"]
        if not isinstance(name,str) or not name:
            raise ValueError("Empty/nonstring part name")
        duplicates[name] += 1
        points = []
        for point in part["vertices"]:
            if len(point) != 3 or any(not isinstance(v,(int,float)) or isinstance(v,bool) or not math.isfinite(v) for v in point):
                raise ValueError("Invalid XYZ point in "+name)
            points.append(tuple(float(v) for v in point))
        result[name] = collections.Counter(points)
    return result,{name:count for name,count in duplicates.items() if count > 1}


def query(reference,points,backend):
    if backend == "scipy":
        from scipy.spatial import cKDTree
        distances,indices = cKDTree(reference).query(points,k=1)
        return [(float(distance),reference[int(index)]) for distance,index in zip(distances,indices)]
    tree = KDTree(reference)
    answer = []
    for point in points:
        squared,nearest = tree.nearest(point)
        answer.append((math.sqrt(squared),nearest))
    return answer


def direction(reference,points,backend,tolerance):
    ordered = sorted(points)
    answers = query(sorted(reference),ordered,backend)
    worst = max(range(len(answers)),key=lambda index:answers[index][0])
    outliers = [{"point":point,"nearest":nearest,"error":distance,"raw_multiplicity":points[point]}
                for point,(distance,nearest) in zip(ordered,answers) if distance > tolerance]
    return {"max_error":answers[worst][0],"worst_point":ordered[worst],"nearest_to_worst":answers[worst][1],
            "outlier_unique_count":len(outliers),"outlier_raw_count":sum(p["raw_multiplicity"] for p in outliers),
            "outliers":outliers}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--authored",type=Path,default=ROOT/"assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/authored-vertices.json")
    parser.add_argument("--native",type=Path,default=ROOT/"docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_native_vertices49.json")
    parser.add_argument("--output",type=Path,default=HERE/"native-vertex-comparison49.json")
    parser.add_argument("--tolerance",type=float,default=.001)
    parser.add_argument("--expected-parts",type=int,default=53)
    parser.add_argument("--backend",choices=["auto","scipy","kd"],default="auto")
    args = parser.parse_args()
    assert args.output.resolve().is_relative_to(HERE), "Write only in owned geometry drafts."
    assert math.isfinite(args.tolerance) and args.tolerance > 0
    started = time.perf_counter()
    snapshots = {p:p.read_bytes() for p in [args.authored,args.native]}
    authored,author_duplicates = load_parts(json.loads(snapshots[args.authored].decode("utf-8")))
    native,native_duplicates = load_parts(json.loads(snapshots[args.native].decode("utf-8")))
    backend = args.backend
    if backend == "auto":
        try:
            from scipy.spatial import cKDTree
            backend = "scipy"
        except ImportError:
            backend = "kd"
    missing = sorted(set(authored)-set(native))
    unexpected = sorted(set(native)-set(authored))
    results = []
    for name in sorted(set(authored)&set(native)):
        a,n = authored[name],native[name]
        counts = {"authored_raw":sum(a.values()),"native_raw":sum(n.values()),"authored_unique":len(a),"native_unique":len(n)}
        if not a or not n:
            results.append({"name":name,"passed":False,"empty_pointset":True,"counts":counts})
            continue
        a_to_n = direction(n,a,backend,args.tolerance)
        n_to_a = direction(a,n,backend,args.tolerance)
        maximum = max(a_to_n["max_error"],n_to_a["max_error"])
        results.append({"name":name,"passed":maximum <= args.tolerance,"counts":counts,"max_error":maximum,
                        "authored_to_native":a_to_n,"native_to_authored":n_to_a})
    unchanged = all(p.read_bytes() == data for p,data in snapshots.items())
    count_pass = len(authored) == len(native) == args.expected_parts
    passed = (unchanged and count_pass and not missing and not unexpected and not author_duplicates and not native_duplicates
              and all(part["passed"] for part in results))
    maximum = max((p.get("max_error",0) for p in results),default=0)
    result = {"schema":1,"passed":passed,"method":"Exact bidirectional nearest-pointset Euclidean distance; duplicate normal/UV vertices tolerated",
              "coordinate_space":"Native points already transformed into authored library coordinates by the lead; comparator applies no transform",
              "backend":backend,"tolerance_studs":args.tolerance,"expected_parts":args.expected_parts,
              "authored_parts":len(authored),"native_parts":len(native),"checked_parts":len(results),"max_error":maximum,
              "missing_native_parts":missing,"unexpected_native_parts":unexpected,"duplicate_authored_names":author_duplicates,
              "duplicate_native_names":native_duplicates,"part_counts_pass":count_pass,"inputs_unchanged":unchanged,
              "input_sha256":{str(p):hashlib.sha256(data).hexdigest() for p,data in snapshots.items()},
              "input_bytes":{str(p):len(data) for p,data in snapshots.items()},"elapsed_seconds":time.perf_counter()-started,"parts":results,
              "boundary":"Vertex coordinate parity only; not a final visual review, material/import topology proof or gameplay test"}
    args.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:result[k] for k in ["passed","backend","checked_parts","max_error","missing_native_parts","unexpected_native_parts","inputs_unchanged"]}))
    raise SystemExit(0 if passed else 1)


if __name__ == "__main__":
    main()
