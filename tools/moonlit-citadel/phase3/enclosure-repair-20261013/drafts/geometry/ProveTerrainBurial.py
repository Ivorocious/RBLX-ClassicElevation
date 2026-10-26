"""Prove cap polygons buried using actual drafted terrain top triangles, not heights alone."""
import argparse
import collections
import hashlib
import json
import math
from pathlib import Path

from AuditCaps import area,clip,orient

HERE = Path(__file__).resolve().parent
LANDSCAPE = HERE.parent/"landscape"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit",type=Path,default=HERE/"combined-cap-audit.json")
    parser.add_argument("--terrain",type=Path,default=LANDSCAPE/"terrain-metadata.json")
    parser.add_argument("--landscape-plan",type=Path,default=LANDSCAPE/"landscape-plan.json")
    args = parser.parse_args()
    input_bytes = {p:p.read_bytes() for p in [args.audit,args.terrain,args.landscape_plan]}
    metadata = json.loads(input_bytes[args.terrain].decode("utf-8"))
    plan = json.loads(input_bytes[args.landscape_plan].decode("utf-8"))
    for row in plan:
        if row["asset"] in metadata and "occupied" in metadata[row["asset"]]:
            assert row["localCF"] == [0,0,0,1,0,0,0,1,0,0,0,1] and row["scale"] == [1,1,1]
    triangles,grid = [],collections.defaultdict(set)
    for asset,data in metadata.items():
        for row in data.get("occupied",[]):
            if "top" not in row:
                continue
            points = row["top"]
            polygon = [[p[0],p[2]] for p in points]
            low = [min(p[i] for p in polygon) for i in range(2)]
            high = [max(p[i] for p in polygon) for i in range(2)]
            index = len(triangles)
            triangles.append({"asset":asset,"p":points,"polygon":polygon,"bottom":data["bottomY"]})
            for x in range(math.floor(low[0]/16),math.floor(high[0]/16)+1):
                for z in range(math.floor(low[1]/16),math.floor(high[1]/16)+1):
                    grid[x,z].add(index)
    audit = json.loads(input_bytes[args.audit].decode("utf-8"))
    results = []
    for conflict in audit["conflicts"]:
        if conflict["classification"] != "external_coplanar_candidate":
            continue
        polygon = conflict["overlap_polygon_xz"]
        low = [min(p[i] for p in polygon) for i in range(2)]
        high = [max(p[i] for p in polygon) for i in range(2)]
        candidates = set()
        for x in range(math.floor(low[0]/16),math.floor(high[0]/16)+1):
            for z in range(math.floor(low[1]/16),math.floor(high[1]/16)+1):
                candidates |= grid[x,z]
        covered,min_margin = 0,float("inf")
        min_bottom_margin = float("inf")
        for index in candidates:
            triangle = triangles[index]
            overlap = clip(polygon,triangle["polygon"])
            footprint = area(overlap)
            if footprint <= 1e-9:
                continue
            covered += footprint
            p,q,r = triangle["p"]
            denominator = orient([p[0],p[2]],[q[0],q[2]],[r[0],r[2]])
            heights = []
            for point in overlap:
                a = orient(point,[q[0],q[2]],[r[0],r[2]])/denominator
                b = orient([p[0],p[2]],point,[r[0],r[2]])/denominator
                c = 1-a-b
                heights.append(a*p[1]+b*q[1]+c*r[1])
            min_margin = min(min_margin,min(heights)-conflict["plane_y"])
            min_bottom_margin = min(min_bottom_margin,conflict["plane_y"]-triangle["bottom"])
        expected = area(polygon)
        coverage_error = abs(covered-expected)
        proven = (covered > 1e-9 and math.isfinite(min_margin) and math.isfinite(min_bottom_margin)
                  and coverage_error <= max(1e-9,expected*1e-7) and min_margin > 1e-4 and min_bottom_margin > 1e-4)
        results.append({"a":conflict["a"],"b":conflict["b"],"plane_y":conflict["plane_y"],
                        "proven_buried":proven,"projected_area":expected,"terrain_covered_area":covered,
                        "coverage_error":coverage_error,"minimum_top_margin":None if math.isinf(min_margin) else min_margin,
                        "minimum_bottom_margin":None if math.isinf(min_bottom_margin) else min_bottom_margin})
    grouped = collections.defaultdict(lambda:{"pairs":0,"proven":0,"minimum_top_margin":float("inf")})
    for row in results:
        key = tuple(sorted((row["a"].rsplit("/face",1)[0],row["b"].rsplit("/face",1)[0])))
        grouped[key]["pairs"] += 1
        grouped[key]["proven"] += row["proven_buried"]
        if row["minimum_top_margin"] is not None:
            grouped[key]["minimum_top_margin"] = min(grouped[key]["minimum_top_margin"],row["minimum_top_margin"])
    groups = [{"a":key[0],"b":key[1],**value,"fully_proven":value["pairs"] == value["proven"]}
              for key,value in sorted(grouped.items())]
    result = {"evidence":"Exact authored terrain triangles/linear height over each clipped overlap polygon; native import parity pending",
              "inputs":{str(p):hashlib.sha256(data).hexdigest() for p,data in input_bytes.items()},
              "candidate_pairs":len(results),"proven_buried_pairs":sum(r["proven_buried"] for r in results),
              "unproven_pairs":sum(not r["proven_buried"] for r in results),"groups":groups,"pairs":results}
    assert all(p.read_bytes() == data for p,data in input_bytes.items()), "Input changed during proof; rerun on the frozen stage."
    (HERE/"terrain-burial-proof.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:result[k] for k in ["candidate_pairs","proven_buried_pairs","unproven_pairs"]}))


if __name__ == "__main__":
    main()
