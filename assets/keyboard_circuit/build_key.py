"""Build the shared ordinary key in an isolated Blender process; one unit is one stud."""
from pathlib import Path
import bpy
import hashlib
import json
import time

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "K02"
OUT.mkdir(parents=True, exist_ok=True)
started = time.perf_counter()
verts = []
for z, half in ((0, .575), (.12, .575), (.75, .47), (.85, .43)):
    verts.extend([(-half, -half, z), (half, -half, z),
                  (half, half, z), (-half, half, z)])
faces = [(3, 2, 1, 0)]
for layer in range(3):
    for side in range(4):
        a = layer * 4 + side
        b = layer * 4 + (side + 1) % 4
        faces.append((a, b, b + 4, a + 4))
faces.append((12, 13, 14, 15))
mesh = bpy.data.meshes.new("KC_OrdinaryKey_28Triangles")
mesh.from_pydata(verts, [], faces)
mesh.update()
key = bpy.data.objects.new("KC_OrdinaryKey", mesh)
bpy.context.collection.objects.link(key)
material = bpy.data.materials.new("SandPlastic")
material.diffuse_color = (.82, .70, .53, 1)
key.data.materials.append(material)
for other in bpy.context.selected_objects:
    other.select_set(False)
bpy.context.view_layer.objects.active = key
key.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "KC_OrdinaryKey.blend"))
bpy.ops.export_scene.fbx(filepath=str(OUT / "KC_OrdinaryKey.fbx"),
    use_selection=True, object_types={"MESH"}, apply_unit_scale=True,
    axis_forward="-Z", axis_up="Y", bake_space_transform=True,
    mesh_smooth_type="OFF", use_mesh_modifiers=True, add_leaf_bones=False)
report = {"revision": "K02", "source": "Original mesh, Keyboard Circuit",
    "dimensions_studs": [1.15, .85, 1.15], "pivot": "bottom center",
    "axes_blender": "Z up", "runtime_axes": "Y up; verify after insertion",
    "vertices": len(verts), "triangles": sum(len(f)-2 for f in faces),
    "elapsed_seconds": round(time.perf_counter()-started, 3),
    "files": {p.name: {"bytes": p.stat().st_size,
        "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in OUT.iterdir() if p.suffix in {".blend", ".fbx"}}}
(OUT / "manifest.json").write_text(json.dumps(report, indent=2)+"\n")
print(json.dumps(report))
