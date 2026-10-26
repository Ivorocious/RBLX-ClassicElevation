"""Write the C13-only live geometry correlation artifacts."""

from __future__ import annotations

import json
from pathlib import Path

from city_run_live_geometry_correlator import _dedup_groups


ROOT = Path(__file__).resolve().parents[1] / "docs" / "artifacts" / "city-run" / "c18"


def _is_c13_terminal_path(path: str) -> bool:
    return "C13TERMINAL" in path.upper()


def main() -> None:
    audit = json.loads((ROOT / "live_geometry_mapping.json").read_text(encoding="utf-8"))
    live_records = [record for record in audit["records"] if _is_c13_terminal_path(record["live_path"])]
    matched = [record for record in live_records if record.get("match_type") == "exact_name_and_dimensions"]
    groups = _dedup_groups(matched)
    safe = [group for group in groups if group.get("safe_review_candidate")]
    (ROOT / "c13_live_dedup_candidates.json").write_text(json.dumps(groups, indent=2), encoding="utf-8")

    lines = [
        "# C13 Terminal Geometry Focus",
        "",
        f"Current live inventory rows: `{len(live_records)}`; exact Blender name+dimension matches: `{len(matched)}`; unique MeshIds: `{len({record['mesh_id'] for record in live_records})}`.",
        "",
        f"Exact full-hash groups spanning multiple MeshIds: `{len(groups)}`; safe review subset: `{len(safe)}` groups, `{sum(group['count'] for group in safe)}` instances, `{sum(group['unique_mesh_ids'] - 1 for group in safe)}` potential non-canonical MeshIds.",
        "",
        "Every safe-subset member is non-colliding/non-touching, has the same TextureID within its hash group, and is outside protected route-path gates. Full hashes include topology/winding, material slots, UVs, and normals from the Blender audit. This is review evidence only; no MeshId, Size, CFrame, appearance, or Studio property was changed.",
        "",
        "## Largest exact groups",
        "",
    ]
    lines.extend(
        f"- `{group['unique_mesh_ids']} MeshIds / {group['count']} instances`, hash `{group['normalized_geometry_hash'][:16]}`, canonical `{group['canonical_live_path']}`"
        for group in safe[:80]
    )
    (ROOT / "c13_geometry_focus.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        f"C13 rows={len(live_records)} matched={len(matched)} groups={len(groups)} "
        f"safe={len(safe)} potential_remaps={sum(group['unique_mesh_ids'] - 1 for group in safe)}"
    )


if __name__ == "__main__":
    main()

