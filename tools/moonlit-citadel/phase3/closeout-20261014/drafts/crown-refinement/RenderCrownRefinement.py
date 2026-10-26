"""Evaluate one contained crown apron revision in an isolated, exact Source50 Blender assembly."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "default.project.json").exists())
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/blender/source50_01/MC_P3_CLOSEOUT_SOURCE50.blend"
PLAN = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json"
AXIS = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
INVERSE = AXIS.inverted()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frame(row):
    return Matrix(((row[3], row[4], row[5], row[0]), (row[6], row[7], row[8], row[1]),
                   (row[9], row[10], row[11], row[2]), (0, 0, 0, 1)))


def scaled_frame(unit):
    return AXIS @ frame(unit["localCF"]) @ Matrix.Diagonal((*unit["scale"], 1))


def candidate(original):
    units = json.loads(json.dumps(original))
    for unit in units:
        if unit["name"] == "CrownBaseUnifiedShell":
            unit["localCF"][1] -= 12
        elif unit["name"] == "CrownSouthJoinedScreen":
            unit["localCF"][1] -= 3
    def mass(name, point, scale):
        units.append({"name": name, "district": "CrownArrival", "asset": "MC_AR_MasonryMass", "library": "ER01",
                      "localCF": [*point, 1, 0, 0, 0, 1, 0, 0, 0, 1], "scale": list(scale), "materialRole": "StoneStructure"})
    mass("CrownRaisedFloorCarrier", (-8, 125, -30), (1.4, (148.6-125)/24, 2.08))
    for index, x in enumerate((-26, -14, -2, 10), 1):
        mass(f"CrownSouthScreenFoot{index}", (x, 136.5, -10), (.052, (146.6-136.5)/24, .18))
    for index, z in enumerate((-46, -33, -20, -7), 1):
        mass(f"CrownWestScreenFoot{index}", (-31, 136.5, z), (.0936, (149.6-136.5)/24, .1))
    mass("CrownEmblemLowerPier", (-8, 136.5, -9.1), (.36, (149.6-136.5)/24, .16))
    return units


def geometry_digest(objects):
    h = hashlib.sha256()
    for obj in sorted(objects, key=lambda o: o.name):
        h.update(obj.name.encode())
        h.update(str(tuple(value for row in obj.matrix_world for value in row)).encode())
        if obj.type == "MESH":
            h.update(str([tuple(v.co) for v in obj.data.vertices]).encode())
            h.update(str([tuple(p.vertices) for p in obj.data.polygons]).encode())
    return h.hexdigest()


def ray_report(scene, name, pos, targets):
    graph = bpy.context.evaluated_depsgraph_get()
    result = []
    origin = AXIS @ Vector(pos)
    for target in targets:
        end = AXIS @ Vector(target)
        delta = end - origin
        hit, point, normal, index, obj, matrix = scene.ray_cast(graph, origin, delta.normalized(), distance=delta.length)
        row = {"view": name, "cameraCourseLocal": pos, "targetCourseLocal": target, "hit": hit}
        if hit:
            mesh = obj.evaluated_get(graph).data
            polygon = mesh.polygons[index]
            row.update({"object": obj.name, "unit": obj.get("Source50Unit"), "asset": obj.get("AssetKey"),
                        "protectedPart": obj.get("FrozenNativePart"), "polygon": index,
                        "pointCourseLocal": tuple(INVERSE @ point), "distance": (point-origin).length,
                        "polygonCourseLocal": [tuple(INVERSE @ (matrix @ mesh.vertices[i].co)) for i in polygon.vertices]})
        result.append(row)
    return result


def render(scene, collection, out, name, pos, aim, profile):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.location = AXIS @ Vector(pos)
    obj.rotation_euler = (AXIS @ Vector(aim)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.sensor_fit, data.type, data.clip_start, data.clip_end = "VERTICAL", "PERSP", .05, 3000
    data.angle_y = math.radians(70)
    obj["CourseLocalPosition"], obj["CourseLocalTarget"] = pos, aim
    scene.camera = obj
    sun = bpy.data.lights["Inspection_Sun"]
    background = scene.world.node_tree.nodes["Background"]
    if profile == "night":
        background.inputs["Color"].default_value = (.14, .20, .32, 1)
        background.inputs["Strength"].default_value = .55
        sun.energy, sun.color = .8, (.60, .72, 1)
    else:
        background.inputs["Color"].default_value = (.48, .56, .67, 1)
        background.inputs["Strength"].default_value = .7
        sun.energy, sun.color = 2, (1, .94, .86)
    path = out / (name + ".png")
    assert not path.exists()
    scene.render.filepath = str(path)
    print("RENDER_START " + name, flush=True)
    bpy.ops.render.render(write_still=True)
    print("RENDER_DONE " + name, flush=True)
    return {"name": name, "file": path.name, "sha256": sha(path), "bytes": path.stat().st_size,
            "positionCourseLocal": pos, "targetCourseLocal": aim, "verticalFOV": 70, "profile": profile}


def main():
    assert bpy.app.background, "Preserve live Blender and Studio."
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="render01")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    assert args.output.replace("_", "").isalnum()
    out = HERE / args.output
    assert not out.exists(), "Preserve earlier evidence."
    out.mkdir()
    source_sha, plan_sha = sha(SOURCE), sha(PLAN)
    original = json.loads(PLAN.read_text())["units"]
    units = candidate(original)
    before = {u["name"]: u for u in original}
    updates = [u for u in units if u["name"] in before and u != before[u["name"]]]
    additions = [u for u in units if u["name"] not in before]
    assert len(updates) == 2 and len(additions) == 10
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    if hasattr(bpy.context.preferences.filepaths, "use_save_preview"):
        bpy.context.preferences.filepaths.use_save_preview = False
    scene = bpy.context.scene
    scene.cycles.samples = 12
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1600, 900, 100
    world_collection = bpy.data.collections["Final_233_World_Units"]
    protected = list(bpy.data.collections["Unchanged_Source49_Visible_Course"].all_objects)
    protected_before = geometry_digest(protected)
    camera_collection = bpy.data.collections["Review_Cameras"]
    centre_pos, centre_aim = (-8, 155.5, -30), (172, 124, 4)
    southeast_pos, southeast_aim = (6, 155.5, -18), (38, 85, 106)
    targets = [(38, 85, 106), (72, 90, 84), (8, 85, 118), (-40, 65, 74), (130, 98, 140), (6, 50, 110)]
    views = [render(scene, camera_collection, out, "baseline50-southeast-standing-night", southeast_pos, southeast_aim, "night")]
    rays = {"baseline50": ray_report(scene, "southeastStanding", southeast_pos, targets)}
    old_world_count = len(world_collection.all_objects)
    by_unit = {}
    for obj in list(world_collection.all_objects):
        by_unit.setdefault(obj.get("Source50Unit"), []).append(obj)
    for unit in updates:
        transform = scaled_frame(unit) @ scaled_frame(before[unit["name"]]).inverted()
        for obj in by_unit[unit["name"]]:
            obj.matrix_world = transform @ obj.matrix_world
            obj["RobloxLocalCF"] = unit["localCF"]
    templates = by_unit["CrownEmblemStoneMount"]
    assert len(templates) == 3 and all(o.get("AssetKey") == "MC_AR_MasonryMass" for o in templates)
    template_frame = scaled_frame(before["CrownEmblemStoneMount"])
    for unit in additions:
        transform = scaled_frame(unit) @ template_frame.inverted()
        for template in templates:
            obj = template.copy()
            obj.name = unit["name"] + "__" + template.name.split("__", 1)[1]
            world_collection.objects.link(obj)
            obj.matrix_world = transform @ template.matrix_world
            obj["Source50Unit"], obj["RobloxLocalCF"], obj["AuthorScale"] = unit["name"], unit["localCF"], unit["scale"]
            obj["ProposalDecorationOnly"] = True
    bpy.context.view_layer.update()
    assert len(world_collection.all_objects) == old_world_count + 30
    assert geometry_digest(protected) == protected_before
    rays["candidate"] = ray_report(scene, "southeastStanding", southeast_pos, targets)
    rays["candidateCentre"] = ray_report(scene, "centre", centre_pos, [(172, 124, 4), (38, 85, 106), (130, 98, 140)])
    views.extend([
        render(scene, camera_collection, out, "candidate-southeast-standing-night", southeast_pos, southeast_aim, "night"),
        render(scene, camera_collection, out, "candidate-southeast-standing-day", southeast_pos, southeast_aim, "day"),
        render(scene, camera_collection, out, "candidate-finish-centre-night", centre_pos, centre_aim, "night"),
    ])
    path = out / "MC_CROWN_REFINEMENT_CANDIDATE.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    assert sha(SOURCE) == source_sha and sha(PLAN) == plan_sha
    assert geometry_digest(protected) == protected_before
    (HERE / "candidate-unit-plan.json").write_text(json.dumps(units, indent=2) + "\n")
    report = {"sourceBlend": str(SOURCE.relative_to(ROOT)), "sourceBlendSHA256": source_sha,
              "sourcePlanSHA256": plan_sha, "sourcePreserved": True, "protectedGeometryDigestBefore": protected_before,
              "protectedGeometryDigestAfter": geometry_digest(protected), "protectedGeometryMoved": False,
              "candidate": "Crown shell down12; south screen down3; corrected underfloor carrier/screen feet",
              "updates": updates, "additions": additions, "unitsBefore": len(original), "unitsAfter": len(units),
              "resourceDelta": {"units": 10, "meshParts": 30, "triangles": 1320},
              "views": views, "rays": rays, "blend": {"file": path.name, "bytes": path.stat().st_size, "sha256": sha(path)},
              "boundary": "Actual Source50 Blender mesh assembly with approximate lighting; unretouched composition comparison. This is not native Roblox render or gameplay evidence.",
              "studioTouched": False, "liveBlenderTouched": False, "newAssetOrUpload": False, "scriptSHA256": sha(Path(__file__))}
    (out / "refinement-report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("CROWN_REFINEMENT_DONE " + json.dumps({"views": len(views), "updates": len(updates), "additions": len(additions), "protectedGeometryMoved": False}), flush=True)


if __name__ == "__main__":
    main()
