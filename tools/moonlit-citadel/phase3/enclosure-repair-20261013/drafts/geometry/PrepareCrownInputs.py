"""Freeze exactly the nine agreed crown scenery solids from the current draft plan."""
import hashlib
import itertools
import json
from pathlib import Path

from VerifyRecipe import load_recipe
from AuditCaps import transform

HERE = Path(__file__).resolve().parent
NAMES = {"RoofDrumWestReturn","RoofDrumSouthReturn","RoofDrumNorthWestReturn","EastApproachLowSill",
         "RoofDrumEastSouthReturn","EastApproachPortalFoot","CrownUnderfloorSeat","SouthScreenSeatedCurb","WestScreenSeatedCurb"}


def main():
    recipe,a,e = load_recipe()
    g,_,_ = recipe.masonry_mass(a,e)
    path = HERE.parent/"fortress/placement-plan.json"
    plan = json.loads(path.read_text(encoding="utf-8"))
    rows = [r for r in plan if r["name"] in NAMES]
    assert {r["name"] for r in rows} == NAMES and len(rows) == 9
    boxes,max_error = [],0
    for source in rows:
        assert source["asset"] == "MC_AR_MasonryMass"
        row = {"cf":source["frame"],"scaleRoblox":source["scale"]}
        assert row["cf"][3:] == [1,0,0,0,1,0,0,0,1], "Crown union expects agreed identity rotations."
        for box in g.boxes:
            low = [box["low"][0],box["low"][2],-box["high"][1]]
            high = [box["high"][0],box["high"][2],-box["low"][1]]
            corners = [transform(row,p) for p in itertools.product(*zip(low,high))]
            original = [[min(p[i] for p in corners) for i in range(3)],[max(p[i] for p in corners) for i in range(3)]]
            snapped = [[round(v,5) for v in bound] for bound in original]
            max_error = max(max_error,max(abs(x-y) for a,b in zip(original,snapped) for x,y in zip(a,b)))
            boxes.append({"source":source["name"],"material":box["material"],"low":snapped[0],"high":snapped[1],
                          "original_low":original[0],"original_high":original[1]})
    result = {"retired_names":sorted(NAMES),"retained_separate":"CrownEmblemStoneMount and both joined screens remain exact",
              "source_plan_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"source_rows":rows,
              "coordinate_space":"course-local Roblox XYZ","snap_studs":.00001,"max_corner_delta":max_error,"boxes":boxes}
    (HERE/"crown-inputs.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"sources":len(rows),"solid_boxes":len(boxes),"max_corner_delta":max_error}))


if __name__ == "__main__":
    main()
