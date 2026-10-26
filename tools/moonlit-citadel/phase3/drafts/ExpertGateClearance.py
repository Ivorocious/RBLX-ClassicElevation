"""Report gate clearance from the existing typed layout export without changing it."""

import hashlib
import itertools
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
LAYOUT_PATH = ROOT / "docs/artifacts/moonlit-citadel/phase3/INTEGRATED_LAYOUT.json"
REPORT_PATH = ROOT / "docs/artifacts/moonlit-citadel/phase3/drafts/EXPERT_GATE_CLEARANCE.json"


def vector(value):
    assert value["_t"] == "v"
    return value["value"]


def frame(item):
    if "frame" in item:
        value = item["frame"]
        assert value["_t"] == "c"
        return value["value"]
    return vector(item["position"]) + [1, 0, 0, 0, 1, 0, 0, 0, 1]


def to_world(pose, point):
    return [
        pose[row] + sum(pose[3 + row * 3 + col] * point[col] for col in range(3))
        for row in range(3)
    ]


def to_local(pose, point):
    difference = [point[i] - pose[i] for i in range(3)]
    return [
        sum(pose[3 + row * 3 + col] * difference[row] for row in range(3))
        for col in range(3)
    ]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


layout = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
floors = {
    f"Obstacles/{item['group']}/{item['name']}/Contact": item
    for item in layout["Surfaces"]
}
gates = [
    item for item in layout["RouteHazards"]
    if item["kind"] == "WeaveGate" and item["difficulty"] == "Expert"
]
assert {item["name"] for item in gates} == {
    "ExpertWrapGate", "ExpertPostLiftGate", "ExpertPostLiftMirrorGate"
}
records = []
for gate in gates:
    floor = floors[gate["surfacePath"]]
    floor_pose, gate_pose = frame(floor), frame(gate)
    width, _, depth = vector(gate["size"])
    side = gate["side"]
    choices = []
    for opening in (gate["openingWidth"], 5.5, 6):
        contact_width = width - opening + 0.8
        contact_center = side * (opening + 0.8) / 2
        red_inner = side * (opening - width / 2)
        center = -side * (width - opening) / 2
        goals = []
        route_name = "EEEMirror" if "Mirror" in gate["name"] else "EEE"
        for index, node in enumerate(layout["Routes"][route_name], 1):
            if node["path"] != gate["surfacePath"] or "offset" not in node:
                continue
            offset = vector(node["offset"])
            point = to_world(floor_pose, offset)
            local = to_local(gate_pose, point)
            goals.append({
                "routeIndex": index,
                "kind": node["kind"],
                "family": node.get("obstacleFamily"),
                "floorLocal": offset,
                "gateLocal": local,
                "onOpenSide": side * (local[0] - red_inner) < 0,
                "redSideCenterClearance": -side * (local[0] - red_inner),
                "openEdgeCenterClearance": width / 2 + side * local[0],
                "gatePlaneDistance": abs(local[2]),
            })
        choices.append({
            "opening": opening,
            "redSize": [contact_width, 13, depth],
            "redCenterGateX": contact_center,
            "innerRedBoundaryGateX": red_inner,
            "openingCenterGateX": center,
            "goals": goals,
        })
    records.append({"name": gate["name"], "supportPath": gate["surfacePath"],
                    "width": width, "side": side, "choices": choices})

arch_transfers = [item for item in layout["Transfers"] if item["group"] == "ExpertPhase3"]
report = {
    "evidence": "Static typed-export arithmetic; no native body-motion or success proof",
    "layoutSha256": sha(LAYOUT_PATH),
    "productionHashes": {
        name: sha(ROOT / "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse" / name)
        for name in ("SupportingObstacles.luau", "RouteHazardLayout.luau",
                     "RouteHazards.luau", "ExpertRoutes.luau", "Runtime.luau")
    },
    "routeHazardCount": len(layout["RouteHazards"]),
    "fourStudArchRises": sum(abs(item["riseStuds"] - 4) < 0.001 for item in arch_transfers),
    "gates": records,
}
assert report["routeHazardCount"] == 21 and report["fourStudArchRises"] == 6
WITNESS_PATH = ROOT / "docs/artifacts/moonlit-citadel/phase3/MC_P3_gate_contact_witness02.json"
if WITNESS_PATH.exists():
    witness = json.loads(WITNESS_PATH.read_text(encoding="utf-8"))
    contacts = json.loads(witness.get("ContactsJSON", "[]"))
    captured = []
    for contact in contacts:
        corners = [
            to_world(contact["partCF"], [contact["partSize"][i] * signs[i] / 2 for i in range(3)])
            for signs in itertools.product((-1, 1), repeat=3)
        ]
        gate_local = [to_local(contact["gateCF"], corner) for corner in corners]
        minimum = [min(corner[i] for corner in gate_local) for i in range(3)]
        maximum = [max(corner[i] for corner in gate_local) for i in range(3)]
        root = to_local(contact["gateCF"], contact["rootCF"][:3])
        # The captured RedContact frame, rather than the floor-top frame, is the origin here.
        current_clearance = minimum[0] - contact["gateSize"][0] / 2
        captured.append({
            "part": contact["part"],
            "at": contact["at"],
            "nativeIntersection": contact["nativeIntersection"],
            "rootPosition": contact["rootCF"][:3],
            "rootInRedPartFrame": root,
            "rootVelocity": contact["rootVelocity"],
            "bodyMinInRedPartFrame": minimum,
            "bodyMaxInRedPartFrame": maximum,
            "currentInnerFaceProjectionClearance": current_clearance,
            "opening6SamePoseInnerFaceProjectionClearance": current_clearance + 1,
            "rootDeviationFromPrescribedWorldX": contact["rootCF"][0] - 3877,
        })
    report["nativeWitness"] = {
        "sha256": sha(WITNESS_PATH),
        "bindingLimit": "Raw witness has no candidate/source packet fields; retain the correlated native run receipt",
        "contacts": captured,
    }
REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"report": str(REPORT_PATH), "gates": len(gates),
                  "hazards": report["routeHazardCount"], "rises": report["fourStudArchRises"]}))
