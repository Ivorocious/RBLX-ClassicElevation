"""Bake convex rock cells around Classic Ascent's authored walking curves."""
import bpy
import bmesh
import json
import math
import random
from pathlib import Path
from mathutils import Vector

BASE = Path(__file__).resolve().parent
OUT = BASE / "routed_terrain"
OUT.mkdir(exist_ok=True)
runs = json.loads((BASE / "routed_terrain_input.json").read_text())
scene = bpy.data.scenes.new("RoutedTerrain")
bpy.context.window.scene = scene
manifest = {"props": [], "parts": {}}


def cell(col, name, rings, color):
    # Roblox's Y-up positions are converted to Blender's Z-up coordinates.
    vertices = [(p[0], -p[2], p[1]) for ring in rings for p in ring]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1)
    mesh.materials.append(material)
    manifest["parts"][name] = color
    return obj


for run in runs:
    kind = f"RoutedShelf{run['section']:02d}_{run['first']:02d}_{run['last']:02d}"
    col = bpy.data.collections.new(kind)
    scene.collection.children.link(col)
    rng = random.Random(run["section"]*1000 + run["first"]*13)
    points = [Vector((p["x"], p["y"], p["z"])) for p in run["points"]]
    source_points = [list(p) for p in points]
    tangent = []
    for i in range(len(points)):
        delta = points[min(i+1, len(points)-1)]-points[max(0, i-1)]
        delta.y = 0
        tangent.append(delta.normalized())
    points[0] -= tangent[0]*4.3
    points[-1] += tangent[-1]*4.3
    rings = []
    for i, p in enumerate(points):
        side = Vector((-tangent[i].z, 0, tangent[i].x))
        width = rng.uniform(5.4, 7.1) if run["section"] == 3 else rng.uniform(5.0, 6.7)
        outer_left = rng.uniform(27, 39)
        outer_right = rng.uniform(49, 57)
        mountain_foot = -4 if run["section"] == 3 else -14
        def at(x, y):
            return list(p+side*x+Vector((0, y, 0)))
        rings.append({
            "Path": [at(-width, 0), at(width, 0), at(width+1.2, -7), at(-width-1.2, -7)],
            "Left": [at(-outer_left, -rng.uniform(22, 31)), at(-width, -.08),
                     at(-width-1.2, -38), at(-outer_left, -42)],
            "RightInner": [at(width, -.08), at(34, mountain_foot),
                           at(34, -43), at(width+1.2, -38)],
            "RightWall": [at(34, mountain_foot), at(outer_right, rng.uniform(26, 39)),
                          at(outer_right, -43), at(34, -43)],
        })
    parts = []
    cells = []
    all_positions = []
    for i in range(len(points)-1):
        for surface in ("Path", "Left", "RightInner", "RightWall"):
            name = f"{kind}__{surface}{i+1:02d}"
            shade = rng.uniform(-.012, .012)
            base = (.39, .44, .37) if surface == "Path" else (.29, .35, .32)
            cell(col, name, [rings[i][surface], rings[i+1][surface]], [c+shade for c in base])
            parts.append(name)
            cells.append({"name": name, "path": surface == "Path",
                          "first": run["points"][i]["step"], "last": run["points"][i+1]["step"]})
            all_positions.extend(rings[i][surface]+rings[i+1][surface])
    minimum = [min(p[a] for p in all_positions) for a in range(3)]
    maximum = [max(p[a] for p in all_positions) for a in range(3)]
    center = [(lo+hi)/2 for lo, hi in zip(minimum, maximum)]
    size = [hi-lo for lo, hi in zip(minimum, maximum)]
    # Each collection is exported at its own origin; manifest restores its world placement.
    for obj in col.objects:
        for vertex in obj.data.vertices:
            vertex.co -= Vector((center[0], -center[2], minimum[1]))
    manifest["props"].append({"name": kind, "height": size[1], "size": size,
                              "center": center, "parts": parts, "cells": cells,
                              "section": run["section"], "first": run["first"],
                              "last": run["last"], "points": source_points})

objects = [o for col in scene.collection.children for o in col.objects]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"RoutedTerrain.fbx"), use_selection=True,
                        object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                        apply_unit_scale=True, bake_space_transform=False, add_leaf_bones=False)
(OUT/"manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"RoutedTerrain.blend"))
print(json.dumps({"meshes": len(objects), "triangles": sum(len(o.data.polygons)*2 for o in objects)}))
