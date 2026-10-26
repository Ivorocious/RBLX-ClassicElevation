"""Read-only Blender geometry audit for City Run source snapshots.

Run with Blender, for example:

    blender.exe --background --python tools/city_run_geometry_audit.py -- \
        --source-root assets/city_run

The audit opens source .blend files without saving them. Hashes are translation
normalized while preserving scale, orientation, topology, materials, UVs, and
normals. This makes a full hash a conservative geometry reuse signal rather
than an object-name guess.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import bpy
from mathutils import Vector


POSITION_QUANTUM = 1e-5
UV_QUANTUM = 1e-5
NORMAL_QUANTUM = 1e-5
MAX_DISTANCE_SIGNATURE_VERTICES = 256


def _arg(name: str, default: str) -> str:
    """Read a simple ``--name value`` argument after Blender's ``--``."""
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    for index, value in enumerate(args):
        if value == name and index + 1 < len(args):
            return args[index + 1]
    return default


def q(value: float, quantum: float) -> int:
    return int(round(float(value) / quantum))


def qvec(values: Iterable[float], quantum: float) -> tuple[int, ...]:
    return tuple(q(value, quantum) for value in values)


def _json_hash(payload: Any) -> str:
    encoded = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _rotate_to_minimum(entries: list[Any]) -> tuple[Any, ...]:
    if not entries:
        return ()
    rotations = [tuple(entries[index:] + entries[:index]) for index in range(len(entries))]
    return min(rotations)


def _source_info(path: Path) -> tuple[int, str]:
    match = re.match(r"CityRun_C(\d+)(.*)\.blend$", path.name, re.IGNORECASE)
    if not match:
        return (999, path.stem)
    return (int(match.group(1)), match.group(2) or "base")


def discover_sources(source_root: Path) -> list[Path]:
    sources = []
    for path in source_root.glob("CityRun_C*.blend"):
        revision, _ = _source_info(path)
        if 7 <= revision <= 17:
            sources.append(path)
    return sorted(sources, key=lambda path: (_source_info(path), path.name.lower()))


def _collection_path(obj: bpy.types.Object) -> str:
    names = sorted(collection.name for collection in obj.users_collection)
    return "/".join(names)


def _parent_path(obj: bpy.types.Object) -> str:
    names = []
    current = obj
    while current is not None:
        names.append(current.name)
        current = current.parent
    return "/".join(reversed(names))


def _loop_normals(mesh: bpy.types.Mesh) -> list[tuple[float, float, float] | None]:
    """Return split normals when Blender exposes them for this evaluated mesh."""
    try:
        # Blender 4+ exposes calculated split normals as corner_normals.
        corners = mesh.corner_normals
        return [tuple(corners[index].vector) for index in range(len(mesh.loops))]
    except Exception:
        pass
    try:
        return [tuple(loop.normal) for loop in mesh.loops]
    except Exception:
        return [None] * len(mesh.loops)


def _active_uvs(mesh: bpy.types.Mesh) -> tuple[str | None, list[tuple[float, float] | None]]:
    if not mesh.uv_layers:
        return None, [None] * len(mesh.loops)
    layer = mesh.uv_layers.active or mesh.uv_layers[0]
    return layer.name, [tuple(item.uv) for item in layer.data]


def _normalized_geometry(
    eval_obj: bpy.types.Object,
    mesh: bpy.types.Mesh,
) -> dict[str, Any]:
    matrix = eval_obj.matrix_world
    world_vertices = [matrix @ vertex.co for vertex in mesh.vertices]
    if world_vertices:
        minimum = Vector((
            min(vertex.x for vertex in world_vertices),
            min(vertex.y for vertex in world_vertices),
            min(vertex.z for vertex in world_vertices),
        ))
        maximum = Vector((
            max(vertex.x for vertex in world_vertices),
            max(vertex.y for vertex in world_vertices),
            max(vertex.z for vertex in world_vertices),
        ))
        center = (minimum + maximum) * 0.5
        dimensions = maximum - minimum
    else:
        center = Vector((0.0, 0.0, 0.0))
        dimensions = Vector((0.0, 0.0, 0.0))

    normalized_vertices = [qvec((vertex - center), POSITION_QUANTUM) for vertex in world_vertices]
    uv_name, uvs = _active_uvs(mesh)
    loop_normals = _loop_normals(mesh)
    normal_matrix = matrix.to_3x3().inverted().transposed()
    try:
        normal_matrix.normalize()
    except Exception:
        pass

    full_faces = []
    shape_faces = []
    has_loop_normals = any(normal is not None for normal in loop_normals)
    for polygon in mesh.polygons:
        world_polygon_normal = (normal_matrix @ polygon.normal).normalized()
        full_entries = []
        shape_entries = []
        for loop_index, vertex_index in zip(polygon.loop_indices, polygon.vertices):
            point = normalized_vertices[vertex_index]
            uv = uvs[loop_index] if loop_index < len(uvs) and uvs[loop_index] is not None else None
            loop_normal = loop_normals[loop_index] if loop_index < len(loop_normals) else None
            if loop_normal is not None:
                loop_normal = qvec((normal_matrix @ Vector(loop_normal)).normalized(), NORMAL_QUANTUM)
            polygon_normal = qvec(world_polygon_normal, NORMAL_QUANTUM)
            full_entries.append((point, None if uv is None else qvec(uv, UV_QUANTUM), loop_normal, polygon_normal))
            shape_entries.append(point)
        full_faces.append(
            (
                int(polygon.material_index),
                bool(polygon.use_smooth),
                _rotate_to_minimum(full_entries),
            )
        )
        shape_faces.append(_rotate_to_minimum(shape_entries))

    material_names = [material.name if material is not None else None for material in mesh.materials]
    full_payload = {
        "vertices": sorted(normalized_vertices),
        "faces": sorted(full_faces),
        "materials": material_names,
        "uv_layer": uv_name,
        "has_loop_normals": has_loop_normals,
    }
    shape_payload = {
        "vertices": sorted(normalized_vertices),
        "faces": sorted(shape_faces),
    }

    distance_hash = None
    if len(normalized_vertices) <= MAX_DISTANCE_SIGNATURE_VERTICES:
        distances = []
        for first in range(len(world_vertices)):
            for second in range(first + 1, len(world_vertices)):
                delta = world_vertices[first] - world_vertices[second]
                distances.append(q(delta.length_squared, POSITION_QUANTUM * POSITION_QUANTUM))
        distance_hash = _json_hash(
            {
                "vertex_count": len(world_vertices),
                "distances": sorted(distances),
                "face_sizes": sorted(len(polygon.vertices) for polygon in mesh.polygons),
            }
        )

    return {
        "normalized_geometry_hash": _json_hash(full_payload),
        "normalized_shape_hash": _json_hash(shape_payload),
        "rigid_distance_hash": distance_hash,
        "dimensions": [round(float(value), 6) for value in dimensions],
        "bbox_center": [round(float(value), 6) for value in center],
        "vertex_count": len(mesh.vertices),
        "polygon_count": len(mesh.polygons),
        "loop_count": len(mesh.loops),
        "edge_count": len(mesh.edges),
        "material_names": material_names,
        "uv_layer": uv_name,
        "uv_layer_count": len(mesh.uv_layers),
        "has_loop_normals": has_loop_normals,
        "normalized_vertices": normalized_vertices,
        "polygons": [len(polygon.vertices) for polygon in mesh.polygons],
    }


def _native_box_candidate(mesh: bpy.types.Mesh, world_vertices: list[Vector]) -> tuple[bool, str, list[float] | None]:
    """Conservative axis-aligned closed-box test for a native Part candidate."""
    if len(world_vertices) != 8 or len(mesh.polygons) != 6 or len(mesh.edges) != 12:
        return False, "requires exactly 8 vertices, 6 faces, and 12 edges", None
    if any(len(polygon.vertices) != 4 for polygon in mesh.polygons):
        return False, "all six faces must be quads", None

    axes = []
    for axis in range(3):
        values = sorted({q(vertex[axis], POSITION_QUANTUM) for vertex in world_vertices})
        if len(values) != 2:
            return False, "each world axis must contain exactly two coordinate planes", None
        axes.append(values)

    combinations = {
        (x, y, z)
        for x in axes[0]
        for y in axes[1]
        for z in axes[2]
    }
    actual = {qvec(vertex, POSITION_QUANTUM) for vertex in world_vertices}
    if actual != combinations:
        return False, "vertices do not form all eight box corners", None

    for polygon in mesh.polygons:
        points = [qvec(world_vertices[index], POSITION_QUANTUM) for index in polygon.vertices]
        constant_axes = sum(len({point[axis] for point in points}) == 1 for axis in range(3))
        if constant_axes != 1:
            return False, "each face must lie on one box plane", None

    dimensions = [max(axis) - min(axis) for axis in axes]
    return True, "closed axis-aligned cuboid with native Part-compatible topology", [value * POSITION_QUANTUM for value in dimensions]


def audit_object(obj: bpy.types.Object, depsgraph: bpy.types.Depsgraph) -> dict[str, Any]:
    record: dict[str, Any] = {
        "object_name": obj.name,
        "object_path": _parent_path(obj),
        "collection_path": _collection_path(obj),
        "mesh_data_name": obj.data.name if obj.type == "MESH" and obj.data else None,
        "object_type": obj.type,
        "hide_viewport": bool(obj.hide_viewport),
        "hide_render": bool(obj.hide_render),
    }
    if obj.type != "MESH":
        record["status"] = "skipped_non_mesh"
        return record

    evaluated = None
    mesh = None
    try:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        geometry = _normalized_geometry(evaluated, mesh)
        world_vertices = [evaluated.matrix_world @ vertex.co for vertex in mesh.vertices]
        box_like, box_reason, box_dimensions = _native_box_candidate(mesh, world_vertices)
        record.update({key: value for key, value in geometry.items() if key not in {"normalized_vertices", "polygons"}})
        record["native_box_candidate"] = box_like
        record["native_box_reason"] = box_reason
        record["native_box_dimensions"] = box_dimensions
        record["status"] = "ok"
    except Exception as error:
        record["status"] = "error"
        record["error"] = f"{type(error).__name__}: {error}"
    finally:
        if evaluated is not None:
            try:
                evaluated.to_mesh_clear()
            except Exception:
                pass
    return record


def _groups(records: list[dict[str, Any]], key: str) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        value = record.get(key)
        if record.get("status") == "ok" and value:
            grouped[value].append(record)
    result = []
    for digest, members in grouped.items():
        if len(members) < 2:
            continue
        result.append(
            {
                "hash": digest,
                "count": len(members),
                "vertex_count": members[0].get("vertex_count"),
                "polygon_count": members[0].get("polygon_count"),
                "material_names": members[0].get("material_names"),
                "members": [
                    {
                        "source": member.get("source"),
                        "object_name": member.get("object_name"),
                        "object_path": member.get("object_path"),
                        "mesh_data_name": member.get("mesh_data_name"),
                        "dimensions": member.get("dimensions"),
                    }
                    for member in sorted(members, key=lambda item: (item.get("source", ""), item.get("object_path", "")))
                ],
            }
        )
    return sorted(result, key=lambda group: (-group["count"], group["hash"]))


def _write_csv(path: Path, records: list[dict[str, Any]]) -> None:
    fields = [
        "source",
        "source_revision",
        "object_name",
        "object_path",
        "collection_path",
        "mesh_data_name",
        "status",
        "vertex_count",
        "polygon_count",
        "loop_count",
        "edge_count",
        "dimensions",
        "material_names",
        "uv_layer",
        "uv_layer_count",
        "has_loop_normals",
        "normalized_geometry_hash",
        "normalized_shape_hash",
        "rigid_distance_hash",
        "native_box_candidate",
        "native_box_reason",
        "native_box_dimensions",
        "error",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        for record in records:
            row = dict(record)
            for field in ("dimensions", "material_names", "native_box_dimensions"):
                if field in row:
                    row[field] = json.dumps(row[field], separators=(",", ":"))
            writer.writerow(row)


def _group_line(group: dict[str, Any]) -> str:
    names = [f"{member['source']}::{member['object_name']}" for member in group["members"][:8]]
    suffix = " ..." if len(group["members"]) > 8 else ""
    return f"- `{group['count']}x` `{group['hash'][:16]}` ({group['vertex_count']}v/{group['polygon_count']}p): " + ", ".join(names) + suffix


def _write_report(path: Path, audit: dict[str, Any]) -> None:
    source_summary = audit["source_summary"]
    records = audit["objects"]
    c13_records = [record for record in records if record.get("source_revision") == 13 and record.get("status") == "ok"]
    c13_exact = _groups(c13_records, "normalized_geometry_hash")
    c13_shape = _groups(c13_records, "normalized_shape_hash")
    c13_boxes = [record for record in c13_records if record.get("native_box_candidate")]
    exact_groups = audit["exact_reuse_groups"]
    shape_groups = audit["shape_reuse_groups"]
    box_records = audit["native_box_candidates"]

    lines = [
        "# C18 Blender Geometry Audit — reusable mesh evidence",
        "",
        f"Generated `{audit['generated_at_utc']}` with Blender `{audit['blender_version']}`. This audit opened source `.blend` files read-only and did not save, import, export, or modify Studio content.",
        "",
        "## Method",
        "",
        "The full `normalized_geometry_hash` is translation-normalized around each object world-space bounding-box center. Scale and orientation remain significant. The hash includes quantized vertex positions, face winding/topology, material slots, active UV coordinates, smooth flags, and split/face normals when Blender exposes them. A matching full hash is therefore a conservative geometry match; object names alone are never used as evidence.",
        "",
        "`normalized_shape_hash` omits UVs, normals, and materials for shape-only clustering. `rigid_distance_hash` is supplemental for small meshes and is not sufficient by itself for replacement. Native-box candidates use a conservative test: exactly eight vertices, six quad faces, twelve edges, all eight corners, and axis-aligned box planes in world space.",
        "",
        "## Source coverage",
        "",
        f"Scanned `{len(source_summary)}` C07–C17 `.blend` snapshots, `{len(records)}` mesh object records, `{len(exact_groups)}` exact full-hash reuse groups, `{len(shape_groups)}` shape-only reuse groups, and `{len(box_records)}` axis-aligned native-box candidates.",
        "",
        "| Source | Mesh objects | Hash errors | Exact groups within source | Native-box candidates |",
        "|---|---:|---:|---:|---:|",
    ]
    for summary in source_summary:
        lines.append(
            f"| `{summary['source']}` | {summary['mesh_objects']} | {summary['errors']} | {summary['exact_groups']} | {summary['native_box_candidates']} |"
        )

    lines.extend([
        "",
        "## C13 terminal focus",
        "",
        f"`CityRun_C13_terminal.blend` contributed `{len(c13_records)}` successful mesh records, `{len(c13_exact)}` exact full-hash groups, `{len(c13_shape)}` shape-only groups, and `{len(c13_boxes)}` native-box candidates. These counts describe the source file; they do not assert that every current Studio MeshPart came from this snapshot.",
        "",
        "### Exact full-hash groups in C13",
        "",
    ])
    if c13_exact:
        lines.extend(_group_line(group) for group in c13_exact[:40])
    else:
        lines.append("- None; no full-hash duplicate was found within the C13 source snapshot.")

    lines.extend([
        "",
        "### C13 native-box candidates",
        "",
    ])
    if c13_boxes:
        for record in c13_boxes[:100]:
            lines.append(
                f"- `{record['object_name']}` at `{record['object_path']}` — dimensions `{record['native_box_dimensions']}`, materials `{record['material_names']}`"
            )
    else:
        lines.append("- None met the conservative axis-aligned native-box test.")

    lines.extend([
        "",
        "## Cross-snapshot exact reuse",
        "",
        "These groups are the strongest safe candidates for shared source mesh data, subject to placement, material, visibility, collision, and manual-edit checks:",
        "",
    ])
    if exact_groups:
        lines.extend(_group_line(group) for group in exact_groups[:80])
    else:
        lines.append("- No exact full-hash groups occurred across the selected snapshots.")

    lines.extend([
        "",
        "## Native-box review list",
        "",
        "A native-box result is a geometry-only candidate. It does not authorize replacing a MeshPart in Studio: per-face materials, UV appearance, shadows, collision/query state, CFrame, and manual owner edits still require review.",
        "",
    ])
    for record in box_records[:200]:
        lines.append(
            f"- `{record['source']}::{record['object_name']}` — `{record['object_path']}`, dimensions `{record['native_box_dimensions']}`, materials `{record['material_names']}`"
        )
    if not box_records:
        lines.append("- None met the conservative axis-aligned native-box test.")

    lines.extend([
        "",
        "## How to use this evidence",
        "",
        "Use `c18_geometry_audit.json` for complete records and `c18_geometry_audit.csv` for filtering. A full-hash match can support reusing one source mesh or deduplicating identical visual geometry after checking current Studio mapping. A shape-only or distance-only match is a review lead, not an equivalence claim. Keep current manually edited Size, CFrame, appearance, collision, query, touch, route, and checkpoint behavior unchanged until an implementation pass proves the mapping.",
        "",
        "The audit intentionally does not change Studio, cameras, Blender source files, or exported assets.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    script_path = Path(__file__).resolve()
    project_root = script_path.parents[1]
    source_root = Path(_arg("--source-root", str(project_root / "assets" / "city_run"))).resolve()
    output_root = Path(_arg("--output-root", str(project_root / "docs" / "artifacts" / "city-run" / "c18"))).resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    sources = discover_sources(source_root)
    if not sources:
        raise SystemExit(f"No C07-C17 .blend sources found under {source_root}")

    records: list[dict[str, Any]] = []
    source_summary = []
    for source in sources:
        revision, variant = _source_info(source)
        print(f"[geometry-audit] opening {source.name}", flush=True)
        result = bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False)
        if result != {"FINISHED"}:
            raise RuntimeError(f"Blender could not open {source}: {result}")
        depsgraph = bpy.context.evaluated_depsgraph_get()
        source_records = []
        for obj in sorted(bpy.data.objects, key=lambda item: item.name.lower()):
            record = audit_object(obj, depsgraph)
            if record.get("object_type") == "MESH":
                record["source"] = source.name
                record["source_revision"] = revision
                record["source_variant"] = variant
                source_records.append(record)
        records.extend(source_records)
        exact_source_groups = _groups(source_records, "normalized_geometry_hash")
        source_summary.append(
            {
                "source": source.name,
                "source_revision": revision,
                "source_variant": variant,
                "mesh_objects": len(source_records),
                "ok": sum(record.get("status") == "ok" for record in source_records),
                "errors": sum(record.get("status") == "error" for record in source_records),
                "exact_groups": len(exact_source_groups),
                "native_box_candidates": sum(record.get("native_box_candidate") is True for record in source_records),
            }
        )
        print(
            f"[geometry-audit] {source.name}: {len(source_records)} mesh objects, "
            f"{len(exact_source_groups)} exact groups, "
            f"{source_summary[-1]['native_box_candidates']} box candidates",
            flush=True,
        )

    exact_groups = _groups(records, "normalized_geometry_hash")
    shape_groups = _groups(records, "normalized_shape_hash")
    native_boxes = [record for record in records if record.get("status") == "ok" and record.get("native_box_candidate")]
    audit = {
        "schema": "city_run_geometry_audit.v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "blender_version": ".".join(str(part) for part in bpy.app.version),
        "source_root": str(source_root),
        "normalization": {
            "position_quantum": POSITION_QUANTUM,
            "uv_quantum": UV_QUANTUM,
            "normal_quantum": NORMAL_QUANTUM,
            "translation_normalized": True,
            "scale_preserved": True,
            "orientation_preserved": True,
            "full_hash_includes": ["positions", "face_topology_and_winding", "materials", "active_uvs", "smooth_flags", "loop_or_face_normals"],
            "distance_hash_max_vertices": MAX_DISTANCE_SIGNATURE_VERTICES,
        },
        "source_summary": source_summary,
        "objects": records,
        "exact_reuse_groups": exact_groups,
        "shape_reuse_groups": shape_groups,
        "native_box_candidates": native_boxes,
    }
    json_path = output_root / "c18_geometry_audit.json"
    csv_path = output_root / "c18_geometry_audit.csv"
    report_path = output_root / "geometry_audit.md"
    json_path.write_text(json.dumps(audit, indent=2), encoding="utf-8")
    _write_csv(csv_path, records)
    _write_report(report_path, audit)
    print(f"[geometry-audit] wrote {json_path}", flush=True)
    print(f"[geometry-audit] wrote {csv_path}", flush=True)
    print(f"[geometry-audit] wrote {report_path}", flush=True)


if __name__ == "__main__":
    main()
