"""Generate the strict C18 live MeshId reuse plan and Luau data module."""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MAPPING_PATH = ROOT / "docs" / "artifacts" / "city-run" / "c18" / "live_geometry_mapping.json"
MODULE_PATH = ROOT / "src" / "ServerStorage" / "CourseBuilders" / "CityRun" / "C18MeshReuseData.luau"
REPORT_PATH = ROOT / "docs" / "artifacts" / "city-run" / "c18" / "mesh_reuse_plan.md"
SIZE_TOLERANCE = 0.025


def _source_hashes(record: dict[str, Any]) -> set[str]:
    hashes = {
        str(record.get("normalized_geometry_hash"))
        for record in record.get("all_source_matches", [])
        if record.get("normalized_geometry_hash")
    }
    if record.get("normalized_geometry_hash"):
        hashes.add(str(record["normalized_geometry_hash"]))
    return hashes


def _is_eligible(record: dict[str, Any], duplicate_paths: set[str]) -> tuple[bool, str]:
    path = record.get("live_path")
    if not path or path in duplicate_paths:
        return False, "duplicate_or_missing_live_path"
    if record.get("match_type") != "exact_name_and_dimensions":
        return False, "not_exact_name_and_dimensions"
    if record.get("can_collide") or record.get("can_touch"):
        return False, "collision_or_touch_enabled"
    if record.get("protected_path"):
        return False, "protected_path"
    if not record.get("mesh_id") or not record.get("normalized_geometry_hash"):
        return False, "missing_mesh_id_or_hash"
    hashes = _source_hashes(record)
    if len(hashes) != 1:
        return False, "ambiguous_source_hash"
    size = record.get("size")
    if not isinstance(size, list) or len(size) != 3:
        return False, "missing_ordered_size"
    return True, "eligible"


def _clusters(records: list[dict[str, Any]]) -> list[list[dict[str, Any]]]:
    """Cluster ordered Size axes without sorting or axis permutation."""
    clusters: list[list[dict[str, Any]]] = []
    representatives: list[tuple[float, float, float]] = []
    for record in sorted(records, key=lambda item: item["live_path"]):
        size = tuple(float(value) for value in record["size"])
        placed = False
        for index, representative in enumerate(representatives):
            if all(abs(size[axis] - representative[axis]) <= SIZE_TOLERANCE for axis in range(3)):
                clusters[index].append(record)
                placed = True
                break
        if not placed:
            representatives.append(size)
            clusters.append([record])
    return clusters


def _build_groups(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_hash_and_texture: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        by_hash_and_texture[(str(record["normalized_geometry_hash"]), str(record.get("texture_id", "")))].append(record)

    groups = []
    for (geometry_hash, _texture_id), hash_records in sorted(by_hash_and_texture.items()):
        for cluster in _clusters(hash_records):
            mesh_counts = Counter(str(record["mesh_id"]) for record in cluster)
            if len(mesh_counts) < 2:
                continue
            canonical_mesh_id = sorted(mesh_counts, key=lambda mesh_id: (-mesh_counts[mesh_id], mesh_id))[0]
            canonical_path = min(
                record["live_path"] for record in cluster if str(record["mesh_id"]) == canonical_mesh_id
            )
            groups.append(
                {
                    "canonicalPath": canonical_path,
                    "canonicalMeshId": canonical_mesh_id,
                    "hash": geometry_hash,
                    "members": [
                        {
                            "path": record["live_path"],
                            "expectedMeshId": str(record["mesh_id"]),
                        }
                        for record in sorted(cluster, key=lambda item: item["live_path"])
                    ],
                    "memberCount": len(cluster),
                    "uniqueMeshIdCount": len(mesh_counts),
                    "meshIdCounts": dict(sorted(mesh_counts.items())),
                }
            )
    return sorted(groups, key=lambda group: (group["canonicalPath"], group["hash"]))


def _luau_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def _render_module(groups: list[dict[str, Any]]) -> str:
    lines = [
        "-- Generated from docs/artifacts/city-run/c18/live_geometry_mapping.json.",
        "-- Apply only with per-instance MeshId, Size, CFrame, and appearance verification.",
        "return {",
    ]
    for group in groups:
        lines.extend([
            "    {",
            f"        canonicalPath = {_luau_string(group['canonicalPath'])},",
            f"        canonicalMeshId = {_luau_string(group['canonicalMeshId'])},",
            f"        hash = {_luau_string(group['hash'])},",
            "        members = {",
        ])
        for member in group["members"]:
            lines.append(
                f"            {{ path = {_luau_string(member['path'])}, expectedMeshId = {_luau_string(member['expectedMeshId'])} }},"
            )
        lines.extend([
            "        },",
            "    },",
        ])
    lines.append("}")
    return "\n".join(lines) + "\n"


def _write_report(
    report_path: Path,
    mapping: dict[str, Any],
    groups: list[dict[str, Any]],
    reasons: Counter[str],
    duplicate_path_count: int,
    duplicate_row_count: int,
) -> None:
    group_savings = sum(group["uniqueMeshIdCount"] - 1 for group in groups)
    canonical_ids = {group["canonicalMeshId"] for group in groups}
    noncanonical_ids = {
        member["expectedMeshId"]
        for group in groups
        for member in group["members"]
        if member["expectedMeshId"] != group["canonicalMeshId"]
    }
    globally_removable = noncanonical_ids - canonical_ids
    lines = [
        "# C18 Mesh Reuse Plan",
        "",
        f"Generated `{datetime.now(timezone.utc).isoformat()}` from `live_geometry_mapping.json`. This is data only; no Studio or runtime instance was changed.",
        "",
        "## Strict gates",
        "",
        f"Eligible records require exact Blender object-name-plus-dimension matching, `CanCollide=false`, `CanTouch=false`, `protected_path=false`, one unambiguous normalized full geometry hash across all source matches, a non-empty MeshId, and a unique live path. Groups use the full geometry hash plus TextureID and compare ordered Size axes independently within `{SIZE_TOLERANCE}` studs; axis permutations are never merged.",
        "",
        f"The mapping contains `{mapping['inventory_count']}` inventory records. `{duplicate_row_count}` rows across `{duplicate_path_count}` duplicate live paths were rejected before grouping.",
        "",
        "## Plan size",
        "",
        f"- Eligible records: `{mapping['eligible_records']}`",
        f"- Reuse groups with multiple MeshIds: `{len(groups)}`",
        f"- Group member instances: `{sum(group['memberCount'] for group in groups)}`",
        f"- Group-level candidate savings: `{group_savings}` non-canonical MeshIds",
        f"- Conservative globally removable MeshIds: `{len(globally_removable)}` (IDs that are never selected as a canonical ID in another group)",
        f"- Luau module: `{MODULE_PATH.relative_to(ROOT)}`",
        "",
        "Group-level savings is an upper bound for a later guarded pass. The runtime must verify the current MeshId, actual asset size, current Size, CFrame, appearance, CanQuery, and CastShadow before changing any member.",
        "",
        "## Rejection counts",
        "",
        "| Reason | Rows |",
        "|---|---:|",
    ]
    for reason, count in sorted(reasons.items()):
        lines.append(f"| `{reason}` | {count} |")
    lines.extend([
        "",
        "## Largest groups",
        "",
    ])
    for group in sorted(groups, key=lambda item: (-item["uniqueMeshIdCount"], -item["memberCount"], item["canonicalPath"]))[:40]:
        lines.append(
            f"- `{group['uniqueMeshIdCount']} MeshIds / {group['memberCount']} instances`, hash `{group['hash'][:16]}`, canonical `{group['canonicalPath']}`"
        )
    lines.extend([
        "",
        "The module contains only `canonicalPath`, `canonicalMeshId`, `hash`, and member `path`/`expectedMeshId` data. It does not replace native boxes or alter any source or Studio content.",
        "",
    ])
    report_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    mapping = json.loads(MAPPING_PATH.read_text(encoding="utf-8"))
    records = list(mapping.get("records", []))
    path_counts = Counter(str(record.get("live_path")) for record in records if record.get("live_path"))
    duplicate_paths = {path for path, count in path_counts.items() if count > 1}
    duplicate_row_count = sum(path_counts[path] for path in duplicate_paths)
    reasons: Counter[str] = Counter()
    eligible = []
    for record in records:
        ok, reason = _is_eligible(record, duplicate_paths)
        if ok:
            eligible.append(record)
        else:
            reasons[reason] += 1
    groups = _build_groups(eligible)
    MODULE_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    MODULE_PATH.write_text(_render_module(groups), encoding="utf-8")
    mapping["eligible_records"] = len(eligible)
    _write_report(REPORT_PATH, mapping, groups, reasons, len(duplicate_paths), duplicate_row_count)
    print(f"Eligible records: {len(eligible)}")
    print(f"Reuse groups: {len(groups)}")
    print(f"Group-level candidate savings: {sum(group['uniqueMeshIdCount'] - 1 for group in groups)}")
    print(f"Module: {MODULE_PATH}")
    print(f"Report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
