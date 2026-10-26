"""Focused analytic fixtures for cap overlap, burial, normals, and recipe regression."""
import json
from pathlib import Path

from AuditCaps import audit, extract_native, REVIEW, IDENTITY
from VerifyRecipe import load_recipe

HERE = Path(__file__).resolve().parent


def box_asset(a, recipe, name, boxes):
    mesh = a._Mesh()
    for center, size, color in boxes:
        mesh.box(center, size, color)
    return recipe.authored_record(name, mesh)


def main():
    recipe, a, e = load_recipe()
    row = lambda name, x=0: {"id": name, "asset": "Fixture", "cf": [x, 0, 0]+IDENTITY}
    cube = box_asset(a, recipe, "Fixture", [((0, 0, 1), (2, 2, 2), "Stone")])
    conflict = audit({"assets": [cube]}, [row("a"), row("b", .5)], .001)
    assert conflict["classifications"].get("external_coplanar_candidate", 0) > 0
    assert all(c["render_reproduced"] is False for c in conflict["conflicts"])
    # Two boxes sharing a full horizontal face have opposite outward normals.
    touching = box_asset(a, recipe, "Fixture", [((0, 0, 1), (2, 2, 2), "Stone"),
                                                ((0, 0, 3), (2, 2, 2), "StoneLight")])
    opposed = audit({"assets": [touching]}, [row("a")], .001)
    assert set(opposed["classifications"]) == {"opposing_normal_interior_contact"}
    hidden = box_asset(a, recipe, "Fixture", [((0, 0, 1), (2, 2, 2), "Stone"),
                                              ((0, 0, 1), (2, 2, 2), "StoneDark"),
                                              ((0, 0, 1), (4, 4, 4), "StoneLight")])
    buried = audit({"assets": [hidden]}, [row("a")], .001)
    assert set(buried["classifications"]) == {"buried_join"}
    placements = extract_native(REVIEW)
    assert len(placements) == 41
    legacy = recipe.load(recipe.ROOT / "tools/moonlit-citadel/phase3/art-repair-20261013/BlenderArtRepairKit.py", "er_old")
    old, new = [], []
    for name, factory in recipe.FACTORIES.items():
        if not name.startswith("MC_AR_"):
            continue
        old_factory = legacy.foundation if "Foundation" in name else legacy.masonry_mass
        g, _, _ = old_factory(a, e)
        old.append(recipe.authored_record(name, g))
        g, _, _ = factory(a, e)
        new.append(recipe.authored_record(name, g))
    before = audit({"assets": old}, placements, .001)
    after = audit({"assets": new}, placements, .001)

    def same_instance_external(data):
        return [c for c in data["conflicts"] if c["classification"] == "external_coplanar_candidate"
                and c["a"].rsplit("/", 2)[0] == c["b"].rsplit("/", 2)[0]]

    old_pairs, new_pairs = same_instance_external(before), same_instance_external(after)
    old_instances = {c["a"].rsplit("/", 2)[0] for c in old_pairs}
    assert len(old_instances) == 41, len(old_instances)
    assert len(new_pairs) == 0
    g, _, _ = recipe.keep_recipe.main_keep_shell(a, e)
    shell = recipe.authored_record("MC_ER_MainKeepShell", g)
    shell_row = {"id": "KeepShell", "asset": "MC_ER_MainKeepShell", "cf": [0,0,0]+IDENTITY}
    shell_audit = audit({"assets": [shell]}, [shell_row], .001)
    assert not shell_audit["conflicts"], shell_audit["classifications"]
    g,_,_ = recipe.crown_recipe.crown_base_shell(a,e)
    crown = recipe.authored_record("MC_ER_CrownBaseShell",g)
    crown_row = {"id":"CrownShell","asset":"MC_ER_CrownBaseShell","cf":[0,0,0]+IDENTITY}
    crown_audit = audit({"assets":[crown]},[crown_row],.001)
    assert not crown_audit["conflicts"],crown_audit["classifications"]
    boxes = recipe.crown_recipe.inputs()["boxes"]
    probes = [[20,145,-38],[-8,150,-30],[-8,156.5,-30]]
    assert all(not any(all(b["low"][i] <= p[i] <= b["high"][i] for i in range(3)) for b in boxes) for p in probes)
    result = {"fixture_checks": ["same_facing_exposed", "opposing_internal_contact", "buried_join", "render_proof_not_inferred"],
              "reviewed_instances": 41, "old_same_instance_external_triangle_pairs": len(old_pairs),
              "repaired_same_instance_external_triangle_pairs": len(new_pairs),
              "keep_shell_same_instance_cap_conflicts": len(shell_audit["conflicts"]),
              "crown_shell_same_instance_cap_conflicts":len(crown_audit["conflicts"]),
              "crown_void_probes":probes,
              "remaining_cross_instance_candidates": after["classifications"].get("external_coplanar_candidate", 0)}
    (HERE / "audit-test-results.json").write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
