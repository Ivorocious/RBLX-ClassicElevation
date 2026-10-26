"""Background-only geometry diagnostics; never load or save a live scene."""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import mechanisms


def report(mesh, include_tiny=True):
    mesh.update()
    mesh.calc_loop_triangles()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    remaining = set(bm.faces)
    component_volumes = []
    while remaining:
        seed = remaining.pop()
        component, queue = {seed}, [seed]
        while queue:
            face = queue.pop()
            for edge in face.edges:
                for adjacent in edge.link_faces:
                    if adjacent in remaining:
                        remaining.remove(adjacent)
                        component.add(adjacent)
                        queue.append(adjacent)
        volume = 0
        for face in component:
            origin = face.verts[0].co
            for index in range(1, len(face.verts) - 1):
                volume += origin.dot(face.verts[index].co.cross(face.verts[index + 1].co)) / 6
        component_volumes.append(volume)
    result = {"vertices": len(mesh.vertices), "triangles": len(mesh.loop_triangles),
              "boundary_edges": sum(edge.is_boundary for edge in bm.edges),
              "nonmanifold_edges": sum(not edge.is_manifold for edge in bm.edges),
              "signed_volume": bm.calc_volume(signed=True),
              "component_count": len(component_volumes),
              "nonpositive_components": [volume for volume in component_volumes if volume <= 0],
              "finite": all(math.isfinite(v) for vertex in mesh.vertices for v in vertex.co),
              "bounds": [[min(vertex.co[axis] for vertex in mesh.vertices) for axis in range(3)],
                         [max(vertex.co[axis] for vertex in mesh.vertices) for axis in range(3)]],
              "zero_normal_faces": sum(face.normal.length < 0.5 for face in bm.faces)}
    if include_tiny:
        result["tiny_faces"] = [{"index": polygon.index, "area": polygon.area,
                                  "material": mesh.materials[polygon.material_index].name,
                                  "coordinates": [list(mesh.vertices[index].co) for index in polygon.vertices]}
                                 for polygon in mesh.polygons if polygon.area < 1e-9]
    bm.free()
    return result


collection = bpy.data.collections.new("MC_MechanismDiagnostic")
bpy.context.scene.collection.children.link(collection)
objects = mechanisms.build_library(collection)
rows = {}
for obj in objects:
    graph = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(graph), preserve_all_data_layers=True, depsgraph=graph)
    before = report(mesh)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    after = report(mesh)
    rows[obj.name] = {"before": before, "cleaned": after}
    print(obj.name, "tiny", len(before["tiny_faces"]), "->", len(after["tiny_faces"]),
          "volume", after["signed_volume"], "boundary", after["boundary_edges"],
          "inward_components", after["nonpositive_components"], "bounds", after["bounds"])

path = ROOT / "mechanism-diagnostic.json"
path.write_text(json.dumps(rows, indent=2) + "\n")
print("DIAGNOSTIC", path)
