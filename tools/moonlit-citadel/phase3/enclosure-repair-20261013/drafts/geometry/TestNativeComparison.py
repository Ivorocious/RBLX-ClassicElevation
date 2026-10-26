"""Small independent distance fixtures; no native calls or large distance matrices."""
import collections
import json
import math
from pathlib import Path
import random

from CompareNativeVertices import direction,load_parts,query

HERE = Path(__file__).resolve().parent


def main():
    randomizer = random.Random(20261014)
    reference = [(randomizer.uniform(-200,200),randomizer.uniform(-20,240),randomizer.uniform(-100,100)) for _ in range(300)]
    reference += [(x,0,0) for x in range(-20,21)]
    reference += [reference[0]]*4
    points = [(randomizer.uniform(-250,250),randomizer.uniform(-50,280),randomizer.uniform(-120,120)) for _ in range(60)]
    points += [reference[0],(-20,0,0),(20,0,0),(.5,0,0)]
    answers = query(reference,points,"kd")
    error = 0
    for point,(distance,_) in zip(points,answers):
        expected = math.sqrt(min(sum((point[i]-candidate[i])**2 for i in range(3)) for candidate in reference))
        error = max(error,abs(expected-distance))
        assert abs(expected-distance) <= 1e-12
    counts,duplicates = load_parts({"parts":[{"name":"Fixture","vertices":[[0,0,0],[0,0,0],[0,0,0],[2,0,0]]}]})
    assert not duplicates and len(counts["Fixture"]) == 2 and sum(counts["Fixture"].values()) == 4
    points = collections.Counter({(.0012,0,0):3,(0,0,0):2})
    result = direction(counts["Fixture"],points,"kd",.001)
    assert result["outlier_unique_count"] == 1 and result["outlier_raw_count"] == 3
    assert result["max_error"] == .0012
    _,duplicates = load_parts({"parts":[{"name":"Repeated","vertices":[[0,0,0]]},{"name":"Repeated","vertices":[[1,0,0]]}]})
    assert duplicates == {"Repeated":2}
    report = {"passed":True,"kd_query_fixtures":64,"reference_points":345,"max_distance_error_vs_small_exact_loop":error,
              "duplicate_positions_tolerated":True,"duplicate_names_reported":True,"outlier_threshold_and_multiplicity_checked":True}
    (HERE/"native-comparator-fixtures.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
