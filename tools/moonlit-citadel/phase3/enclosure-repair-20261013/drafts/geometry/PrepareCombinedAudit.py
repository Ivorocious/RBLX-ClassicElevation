"""Read the fortress proposal; write combined cap inputs only in this owned folder."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
FORTRESS = HERE.parent / "fortress"
REPLACED_KEEP = {"GrandKeepSouthWall", "GrandKeepWestWall", "GrandKeepNorthWall", "GrandKeepEastWall", "GrandRearApseFoundation"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", type=Path, default=FORTRESS / "placement-plan.json")
    parser.add_argument("--keep-swap", action="store_true")
    parser.add_argument("--crown-swap", action="store_true")
    args = parser.parse_args()
    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    if isinstance(plan, dict):
        plan = plan["plan"]
    crown_inputs = json.loads((HERE/"crown-inputs.json").read_text(encoding="utf-8"))
    replaced_crown = set(crown_inputs["retired_names"])
    placements = [{"id": row["district"]+"/"+row["name"], "asset": row["asset"],
                   "cf": row["frame"], "scaleRoblox": row["scale"]}
                  for row in plan if not (args.keep_swap and row["name"] in REPLACED_KEEP)
                  and not (args.crown_swap and row["name"] in replaced_crown)]
    if args.keep_swap and not any(p["asset"] == "MC_ER_MainKeepShell" for p in placements):
        source = json.loads((FORTRESS / "source48-plan.json").read_text(encoding="utf-8"))
        finish = source["finish"]
        placements.append({"id": "GrandKeep/MainKeepShell", "asset": "MC_ER_MainKeepShell",
                           "cf": [finish[0],-38,finish[2],1,0,0,0,1,0,0,0,1], "scaleRoblox": [1,1,1]})
    if args.crown_swap and not any(p["asset"] == "MC_ER_CrownBaseShell" for p in placements):
        placements.append({"id":"KeepRoof/CrownBaseShell","asset":"MC_ER_CrownBaseShell",
                           "cf":[0,0,0,1,0,0,0,1,0,0,0,1],"scaleRoblox":[1,1,1]})
    authored = json.loads((HERE / "authored-vertices.json").read_text(encoding="utf-8"))
    path = FORTRESS / "FortressRecipes.py"
    spec = importlib.util.spec_from_file_location("fortress_cap_geometry", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for name, mesh in module.build_recipes().items():
        parts = []
        for material in sorted(set(mesh.materials)):
            faces = [f for f, m in zip(mesh.faces, mesh.materials) if m == material]
            used = sorted({i for f in faces for i in f})
            lookup = {old: new for new, old in enumerate(used)}
            parts.append({"name": name+"__"+material, "material": material,
                          "vertices": [mesh.vertices[i] for i in used],
                          "faces": [[lookup[i] for i in f] for f in faces]})
        authored["assets"].append({"asset": name, "parts": parts})
    digest = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in [args.plan, path]}
    (HERE / "combined-authored.json").write_text(json.dumps(authored)+"\n", encoding="utf-8")
    (HERE / "combined-placements.json").write_text(json.dumps({"coordinate_space": "course-local", "placements": placements,
                                                              "input_hashes": digest, "keep_swap": args.keep_swap,
                                                              "crown_swap": args.crown_swap}, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"placements": len(placements), "mesh_assets": len(authored["assets"]), "keep_swap": args.keep_swap,
                      "note": "Proposal read only; nonfamily retained assets omitted explicitly by cap audit."}))


if __name__ == "__main__":
    main()
