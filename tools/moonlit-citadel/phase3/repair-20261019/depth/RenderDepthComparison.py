"""Render bounded Source54/chasm comparisons without touching the live Blender session."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
SOURCE = ROOT / "tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend"
KIT = HERE / "dp01f/MC_DEPTH_CHASM_DP01.blend"
OUT = HERE / "comparison01"
AXIS = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
HELPER = ROOT / "tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/placements/RenderDetailComposition.py"
spec = importlib.util.spec_from_file_location("depth_composition_helpers", HELPER)
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def camera(collection, name, point, target):
    data = bpy.data.cameras.new("Depth_" + name)
    obj = bpy.data.objects.new("Depth_" + name, data)
    collection.objects.link(obj)
    obj.location = AXIS @ Vector(point)
    obj.rotation_euler = (AXIS @ Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    data.sensor_fit, data.clip_start, data.clip_end = "VERTICAL", .05, 4000
    data.angle_y = math.radians(70)
    obj["CourseLocalEye"], obj["CourseLocalTarget"] = point, target
    return obj


def render(scene, name, cam):
    path = OUT / (name + ".png")
    assert not path.exists()
    scene.camera, scene.render.filepath = cam, str(path)
    print("DEPTH_RENDER_START " + name, flush=True)
    bpy.ops.render.render(write_still=True)
    print("DEPTH_RENDER_DONE " + name, flush=True)
    return {"file": path.name, "sha256": sha(path), "bytes": path.stat().st_size,
            "eye": list(cam["CourseLocalEye"]), "target": list(cam["CourseLocalTarget"]),
            "verticalFOV": 70, "dimensions": [1600, 869], "retouched": False}


def main():
    assert bpy.app.background and not OUT.exists()
    assert sha(SOURCE) == "2f94aa964cf323fa831d4e88e753e54176f942e990bc420395a199f8a53b27e5"
    binding = json.loads((HERE / "fresh54-depth-binding.json").read_text())
    assert binding["pass"]
    OUT.mkdir()
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples, scene.cycles.use_denoising = 10, True
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1600, 869, 100
    scene.render.image_settings.file_format, scene.render.image_settings.color_mode = "PNG", "RGBA"
    world = list(bpy.data.collections["Final_233_World_Units"].all_objects)
    terrain = [obj for obj in world if obj.get("Source50Unit") == "MC_EC_InnerRavine"]
    assert len(terrain) == 3
    preserved = [obj for obj in scene.objects if obj.type == "MESH" and obj not in terrain]
    before_digest = h.frozen_digest(preserved)
    background = scene.world.node_tree.nodes["Background"]
    background.inputs["Color"].default_value = (.14, .20, .32, 1)
    background.inputs["Strength"].default_value = .55
    bpy.data.lights["Inspection_Sun"].energy = .8
    bpy.data.lights["Inspection_Sun"].color = (.60, .72, 1)
    inspection = bpy.data.collections.new("Depth_Comparison_Cameras")
    scene.collection.children.link(inspection)
    views = [
        ("gate-edge", [-144, 5.5, 130], [-144, -70, 50], "Standing two studs inside the accepted gate floor edge"),
        ("cp01-edge", [-130, 33.5, -112], [-30, -120, -70], "Standing two studs inside the accepted CP01 east edge"),
        ("crown-edge", [8, 155.5, -30], [160, -100, 55], "Standing two studs inside the accepted crown east edge"),
        ("owner-overall", [95, 340, 210], [-20, 25, -15], "Aerial composition comparison, not a player-height view"),
    ]
    cameras = {name: camera(inspection, name, eye, target) for name, eye, target, _ in views}
    results = []
    for name, _, _, _ in views:
        results.append(render(scene, "before54-" + name, cameras[name]))
    imported = bpy.data.collections.new("DP01_Open_Chasm_Candidate")
    scene.collection.children.link(imported)
    with bpy.data.libraries.load(str(KIT), link=False) as (from_data, to_data):
        to_data.objects = [name for name in from_data.objects if name.startswith("MC_DP_InnerChasm__")]
    assert len(to_data.objects) == 2
    for obj in to_data.objects:
        imported.objects.link(obj)
        obj["ReplacementUnit"] = "MC_EC_InnerRavine"
        obj["Library"] = "DP01"
    for obj in terrain:
        obj.hide_render, obj.hide_viewport = True, True
        obj["ArchivedOnlyForDepthComparison"] = True
    assert before_digest == h.frozen_digest(preserved)
    for name, _, _, _ in views:
        results.append(render(scene, "afterDP01-" + name, cameras[name]))
    blend = OUT / "MC_DEPTH_DP01_COMPARISON.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    manifest = json.loads((HERE / "dp01f/manifest.json").read_text())
    report = {"source": str(SOURCE.relative_to(ROOT)), "sourceSha256": sha(SOURCE),
              "fresh54ModelsSha256": binding["sha256"], "kit": str(KIT.relative_to(ROOT)), "kitSha256": sha(KIT),
              "unchangedOtherMeshObjects": len(preserved), "unchangedOtherMeshDigest": before_digest,
              "archivedOriginalTerrainParts": [obj.name for obj in terrain], "replacementParts": 2,
              "allOtherMeshGeometryFramesMaterialsVisibilityExact": True, "views": results,
              "cameraNotes": {name: note for name, _, _, note in views},
              "blend": {"path": str(blend.relative_to(ROOT)), "sha256": sha(blend)},
              "budget": manifest["proof"]["combinedBudget"], "mistAdded": False,
              "boundary": "Unretouched isolated Blender comparisons; native appearance, actual falls and client lifecycle remain unverified."}
    (OUT / "comparison-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("DEPTH_COMPARISON_PASS " + json.dumps({"views": len(results), "preserved": len(preserved), "budget": report["budget"]}), flush=True)


if __name__ == "__main__":
    main()
