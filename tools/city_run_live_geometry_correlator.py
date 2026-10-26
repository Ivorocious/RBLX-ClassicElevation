"""Correlate Blender geometry evidence with the live City Run mesh inventory.

This is a read-only post-processing step. It does not query or modify Studio.
It only accepts a live path when a Blender object name is an exact suffix of
that path and its translation-normalized source dimensions agree with the
recorded live Size (axis order is ignored). Deduplication candidates require
an exact full geometry hash, matching texture IDs, and no collision/touch flags.
"""

from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DIMENSION_TOLERANCE = 0.025


def _load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _dimension_signature(values: list[float] | tuple[float, ...]) -> tuple[float, ...]:
    return tuple(sorted(round(float(value), 4) for value in values))


def _dimension_error(left: list[float], right: list[float]) -> float:
    if len(left) != len(right):
        return float("inf")
    return max(abs(a - b) for a, b in zip(_dimension_signature(left), _dimension_signature(right)))


def _source_revision_matches(path: str, revision: int) -> bool:
    matches = re.findall(r"(?:^|[._])C(\d{1,2})(?:[^\d]|$)", path, re.IGNORECASE)
    return bool(matches) and int(matches[-1]) == revision


def _source_preference(path: str, record: dict[str, Any]) -> tuple[int, int, str]:
    """Prefer a revision named in the live path, then stable reviewed/terminal snapshots."""
    revision = int(record.get("source_revision", 0))
    revision_rank = 0 if _source_revision_matches(path, revision) else 1
    source_name = str(record.get("source", "")).lower()
    variant_rank = 0
    for index, marker in enumerate(("reviewed", "terminal", "depot", "precision", "posts", "cars", "gameplay", "refinement", "patch")):
        if marker in source_name:
            variant_rank = index
            break
    return revision_rank, variant_rank, source_name


def _is_protected_path(path: str) -> bool:
    upper = path.upper()
    return any(token in upper for token in (
        "OBSTACLES",
        "CHECKPOINT",
        "FALLZONE",
        "OWNEREDITS",
        "STARTPEN",
        "ROUTEMARKERS",
        "KILLSTRIP",
        "TRAINENTRY",
        "WALKINGSURFACES",
    ))


def _canonical_score(record: dict[str, Any]) -> tuple[int, int, int, str]:
    path = str(record["live_path"])
    upper = path.upper()
    protected = 1 if _is_protected_path(path) else 0
    course = 0 if "COURSE_CITYRUN" in upper else 1
    manual = 1 if "OWNEREDITS" in upper else 0
    return protected, manual, course, path


def _suffix_index(audit_records: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for record in audit_records:
        if record.get("status") != "ok":
            continue
        name = str(record.get("object_name", ""))
        if not name:
            continue
        for width in (24, 32, 48):
            index[name[-width:]].append(record)
    return index


def _find_audit_matches(
    live_path: str,
    live_size: list[float],
    suffix_index: dict[str, list[dict[str, Any]]],
) -> tuple[list[dict[str, Any]], str]:
    # Object names can contain dots (including Blender's .001 suffix), so a
    # simple split('.') would lose the real leaf. Match the complete known
    # Blender name as a path suffix instead.
    candidates: dict[tuple[str, str], dict[str, Any]] = {}
    for width in (24, 32, 48):
        for record in suffix_index.get(live_path[-width:], []):
            object_name = str(record.get("object_name", ""))
            if live_path == object_name or live_path.endswith("." + object_name):
                candidates[(str(record.get("source")), object_name)] = record
    if not candidates:
        return [], "none"
    dimension_matches = [
        record
        for record in candidates.values()
        if _dimension_error(live_size, list(record.get("dimensions", []))) <= DIMENSION_TOLERANCE
    ]
    if dimension_matches:
        return dimension_matches, "exact_name_and_dimensions"
    return list(candidates.values()), "exact_name_only_dimension_mismatch"


def _make_live_record(item: list[Any], matches: list[dict[str, Any]], match_type: str) -> dict[str, Any]:
    path, mesh_id, size, texture_id, can_collide, can_touch, can_query, cast_shadow = item
    selected = sorted(matches, key=lambda record: _source_preference(str(path), record))[0] if matches else None
    record: dict[str, Any] = {
        "live_path": str(path),
        "mesh_id": str(mesh_id),
        "size": [float(value) for value in size],
        "texture_id": str(texture_id),
        "can_collide": bool(can_collide),
        "can_touch": bool(can_touch),
        "can_query": bool(can_query),
        "cast_shadow": bool(cast_shadow),
        "match_type": match_type,
        "protected_path": _is_protected_path(str(path)),
    }
    if selected is None:
        return record
    record.update({
        "source": selected.get("source"),
        "source_revision": selected.get("source_revision"),
        "source_variant": selected.get("source_variant"),
        "blender_object_name": selected.get("object_name"),
        "blender_object_path": selected.get("object_path"),
        "mesh_data_name": selected.get("mesh_data_name"),
        "normalized_geometry_hash": selected.get("normalized_geometry_hash"),
        "normalized_shape_hash": selected.get("normalized_shape_hash"),
        "rigid_distance_hash": selected.get("rigid_distance_hash"),
        "blender_dimensions": selected.get("dimensions"),
        "dimension_error": _dimension_error(list(size), list(selected.get("dimensions", []))),
        "native_box_candidate": bool(selected.get("native_box_candidate")),
        "native_box_dimensions": selected.get("native_box_dimensions"),
        "all_source_matches": [
            {
                "source": match.get("source"),
                "object_name": match.get("object_name"),
                "normalized_geometry_hash": match.get("normalized_geometry_hash"),
                "dimensions": match.get("dimensions"),
            }
            for match in sorted(matches, key=lambda record: _source_preference(str(path), record))
        ],
    })
    return record


def _dedup_groups(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        digest = record.get("normalized_geometry_hash")
        if record.get("match_type") != "exact_name_and_dimensions" or not digest:
            continue
        grouped[str(digest)].append(record)

    candidates = []
    for digest, members in grouped.items():
        mesh_ids = sorted({member["mesh_id"] for member in members})
        texture_ids = sorted({member["texture_id"] for member in members})
        all_visual_only = all(not member["can_collide"] and not member["can_touch"] for member in members)
        same_texture = len(texture_ids) == 1
        if len(mesh_ids) < 2:
            continue
        canonical = sorted(members, key=_canonical_score)[0]
        candidates.append({
            "normalized_geometry_hash": digest,
            "count": len(members),
            "unique_mesh_ids": len(mesh_ids),
            "mesh_ids": mesh_ids,
            "texture_ids": texture_ids,
            "same_texture_id": same_texture,
            "all_visual_only": all_visual_only,
            "safe_review_candidate": bool(same_texture and all_visual_only and not any(member["protected_path"] for member in members)),
            "canonical_live_path": canonical["live_path"],
            "canonical_mesh_id": canonical["mesh_id"],
            "members": [
                {
                    "live_path": member["live_path"],
                    "mesh_id": member["mesh_id"],
                    "size": member["size"],
                    "texture_id": member["texture_id"],
                    "can_collide": member["can_collide"],
                    "can_touch": member["can_touch"],
                    "can_query": member["can_query"],
                    "cast_shadow": member["cast_shadow"],
                    "protected_path": member["protected_path"],
                    "source": member.get("source"),
                    "blender_object_name": member.get("blender_object_name"),
                }
                for member in sorted(members, key=lambda item: item["live_path"])
            ],
        })
    return sorted(candidates, key=lambda group: (-int(group["safe_review_candidate"]), -group["unique_mesh_ids"], -group["count"], group["canonical_live_path"]))


def _write_csv(path: Path, records: list[dict[str, Any]]) -> None:
    fields = [
        "live_path", "mesh_id", "size", "texture_id", "can_collide", "can_touch", "can_query", "cast_shadow",
        "match_type", "protected_path", "source", "source_revision", "source_variant", "blender_object_name",
        "blender_object_path", "mesh_data_name", "normalized_geometry_hash", "normalized_shape_hash",
        "rigid_distance_hash", "blender_dimensions", "dimension_error", "native_box_candidate", "native_box_dimensions",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        for record in records:
            row = dict(record)
            for field in ("size", "blender_dimensions", "native_box_dimensions"):
                if field in row:
                    row[field] = json.dumps(row[field], separators=(",", ":"))
            writer.writerow(row)


def _write_report(path: Path, audit: dict[str, Any]) -> None:
    records = audit["records"]
    groups = audit["dedup_candidates"]
    matched = [record for record in records if record.get("match_type") == "exact_name_and_dimensions"]
    safe = [group for group in groups if group["safe_review_candidate"]]
    all_hash_groups = len({record.get("normalized_geometry_hash") for record in matched if record.get("normalized_geometry_hash")})
    unique_live_mesh_ids = len({record.get("mesh_id") for record in records if record.get("mesh_id")})
    unique_matched_mesh_ids = len({record.get("mesh_id") for record in matched if record.get("mesh_id")})
    potential_remaps = sum(group["unique_mesh_ids"] - 1 for group in safe)
    lines = [
        "# C18 Live Mesh Geometry Correlation",
        "",
        f"Generated `{audit['generated_at_utc']}` from `original-mesh-inventory.json` and the Blender geometry audit. No Studio or source asset was changed.",
        "",
        "## Evidence boundary",
        "",
        f"The live inventory contains `{audit['inventory_count']}` records and `{unique_live_mesh_ids}` unique MeshIds. `{len(matched)}` records matched a Blender object by complete path suffix and dimension agreement within `{DIMENSION_TOLERANCE}` studs. The mapping uses full translation-normalized geometry hashes containing topology/winding, materials, UVs, and normals; names alone are not used as equivalence evidence.",
        "",
        f"The matched set contains `{unique_matched_mesh_ids}` MeshIds across `{all_hash_groups}` distinct full geometry hashes. Only groups with at least two MeshIds are listed as dedup review candidates. A candidate is marked safe for review only when all members are non-colliding/non-touching, share the same TextureID, and contain no protected route path. This is evidence for a future implementation pass, not an instruction to remap assets.",
        "",
        "## Match coverage",
        "",
        "| Match class | Records |",
        "|---|---:|",
    ]
    for match_type, count in sorted(Counter(record.get("match_type") for record in records).items()):
        lines.append(f"| `{match_type}` | {count} |")
    lines.extend([
        "",
        "## Safe review candidates",
        "",
        f"There are `{len(safe)}` groups with `{potential_remaps}` potential non-canonical MeshIds among `{sum(group['count'] for group in safe)}` instances. Keep each instance’s current Size, CFrame, appearance, CanQuery, and CastShadow values unchanged if a future pass reuses a canonical MeshId.",
        "",
    ])
    if safe:
        for group in safe[:200]:
            lines.append(
                f"- `{group['unique_mesh_ids']} MeshIds / {group['count']} instances`, hash `{group['normalized_geometry_hash'][:16]}`; canonical `{group['canonical_live_path']}`; members: "
                + ", ".join(member["live_path"] for member in group["members"][:8])
                + (" ..." if len(group["members"]) > 8 else "")
            )
    else:
        lines.append("- No group met all safe-review conditions.")

    lines.extend([
        "",
        "## Review-required exact groups",
        "",
        "These groups have exact geometry evidence and multiple MeshIds but fail at least one safety gate, such as a protected path, collision/touch state, or differing TextureID:",
        "",
    ])
    review_required = [group for group in groups if not group["safe_review_candidate"]]
    for group in review_required[:200]:
        lines.append(
            f"- `{group['unique_mesh_ids']} MeshIds / {group['count']} instances`, hash `{group['normalized_geometry_hash'][:16]}`, canonical `{group['canonical_live_path']}`, all_visual_only={group['all_visual_only']}, same_texture_id={group['same_texture_id']}"
        )
    if not review_required:
        lines.append("- None beyond the safe-review candidates.")

    lines.extend([
        "",
        "## Correlation files",
        "",
        "- `live_geometry_mapping.json` contains every inventory record, selected Blender source match, exact hash, dimension delta, flags, and alternate source matches.",
        "- `live_geometry_mapping.csv` is the filterable row form.",
        "- `live_dedup_candidates.json` contains grouped canonical-path candidates.",
        "",
        "Before any remap, verify the live MeshId asset itself, preserve per-instance Size/CFrame/appearance and flags, and recheck all six route views, two fall views, traversal, falling, and mobile/20-player performance. No candidate here authorizes a Studio edit.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    audit_path = Path(__file__).resolve().parents[1] / "docs" / "artifacts" / "city-run" / "c18" / "c18_geometry_audit.json"
    inventory_path = Path(__file__).resolve().parents[1] / "docs" / "artifacts" / "city-run" / "c18" / "original-mesh-inventory.json"
    output_root = audit_path.parent
    audit = _load(audit_path)
    inventory = _load(inventory_path)
    audit_records = list(audit.get("objects", []))
    suffix_index = _suffix_index(audit_records)

    records = []
    for item in inventory:
        if not isinstance(item, list) or len(item) != 8:
            continue
        path = str(item[0])
        matches, match_type = _find_audit_matches(path, list(item[2]), suffix_index)
        records.append(_make_live_record(item, matches, match_type))

    candidates = _dedup_groups(records)
    result = {
        "schema": "city_run_live_geometry_mapping.v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "inventory_path": str(inventory_path),
        "geometry_audit_path": str(audit_path),
        "inventory_count": len(inventory),
        "records": records,
        "dedup_candidates": candidates,
        "parameters": {
            "dimension_tolerance_studs": DIMENSION_TOLERANCE,
            "requires_exact_object_name_suffix": True,
            "requires_dimension_agreement": True,
            "safe_review_requires_noncolliding_nontouching": True,
            "safe_review_requires_same_texture_id": True,
            "safe_review_excludes_protected_paths": True,
        },
    }
    mapping_json = output_root / "live_geometry_mapping.json"
    mapping_csv = output_root / "live_geometry_mapping.csv"
    candidates_json = output_root / "live_dedup_candidates.json"
    report_path = output_root / "live_geometry_correlation.md"
    mapping_json.write_text(json.dumps(result, indent=2), encoding="utf-8")
    _write_csv(mapping_csv, records)
    candidates_json.write_text(json.dumps(candidates, indent=2), encoding="utf-8")
    _write_report(report_path, result)
    print(f"Wrote {mapping_json}")
    print(f"Wrote {mapping_csv}")
    print(f"Wrote {candidates_json}")
    print(f"Wrote {report_path}")
    print(f"Inventory records: {len(inventory)}")
    print(f"Exact name+dimension matches: {sum(record.get('match_type') == 'exact_name_and_dimensions' for record in records)}")
    print(f"Safe review groups: {sum(group.get('safe_review_candidate') for group in candidates)}")


if __name__ == "__main__":
    main()
