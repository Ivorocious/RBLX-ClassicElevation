"""Screen bidirectional stake/refuge/board connections from actual support vertices."""

import argparse
import json
import math

from audit_phase2_geometry import support, separation, inset


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()
    with open(args.input, encoding="utf-8") as stream:
        data = json.load(stream)
    groups = {g["name"]: g for g in data["groups"]}
    prefix = "Obstacles.G2_CropGarden.PlayableObjects."
    stakes = [groups[prefix+"ExpertStakes.Stake_"+str(i)] for i in range(1, 6)]
    others = [groups["H1_Sprinkler."+n] for n in ("DryWait", "DryExitAndChoice")]
    others += [groups[prefix+n] for n in ("BambooWest", "BambooTurn", "BambooSouth", "BambooReturn", "MergeRefuge")]
    velocity = math.sqrt(2*196.2*7.2)
    def pair(a, b):
        ap, ay = support(a)
        bp, by = support(b)
        gap = separation(inset(ap, .65), inset(bp, .65))["distance"]
        rise = by-ay
        reach = 16*(velocity+math.sqrt(max(0, velocity**2-2*196.2*rise)))/196.2 if rise <= 7.2 else 0
        return {"from": a["name"], "to": b["name"], "footCenterGap": gap,
                "rise": rise, "idealRange": reach, "rangeMargin": reach-gap}
    pairs = [pair(a, b) for stake in stakes for other in others for a, b in ((stake, other), (other, stake))]
    result = {"candidate": data["candidate"], "pairs": pairs,
              "limits": "Actual convex support footprints inset 0.65 studs. Ideal speed16, jump7.2, gravity196.2; no run-up, steering or obstruction simulation. Positive margin is a possible connection, not traversal. Negative margin is only closure within this model."}
    with open(args.output, "w", encoding="utf-8") as stream:
        json.dump(result, stream, indent=2)
    print(json.dumps({"candidate": data["candidate"], "pairs": len(pairs),
                      "dryWaitBestMargin": max(p["rangeMargin"] for p in pairs if "DryWait" in p["from"] or "DryWait" in p["to"]),
                      "possibleConnections": [{**p, "from": p["from"].split(".")[-1], "to": p["to"].split(".")[-1]} for p in pairs if p["rangeMargin"] >= 0]}, indent=2))


if __name__ == "__main__":
    main()
