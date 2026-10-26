"""Export flat, chipped playable stone surfaces with inexpensive convex collision."""

import bpy
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
exec((BASE / "create_ascent_props.py").read_text().split("RESULT=build()")[0])
OUT = BASE / "v8"
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new("AscentV8Surfaces")
bpy.context.window.scene = scene


def surface(name, material, outline):
    col = collection(name)
    n = len(outline)
    verts = [(x * .78, y * .78, 0) for x, y in outline]
    verts += [(x, y, 3.5) for x, y in outline]
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, n * 2))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    mesh.materials.append(mat(material))
    return finish(col, name, 3.5)


props = [
    surface("GraniteLedge", "Granite", [(-6, -4), (-4.8, -5), (4.4, -5), (6, -3.6),
                                           (6, 3.6), (4.9, 5), (-4.4, 5), (-6, 3.7)]),
    surface("BasaltStep", "Basalt", [(-6, -3.5), (-4.5, -5), (4.4, -5), (6, -3.4),
                                         (6, 3.5), (4.5, 5), (-4.4, 5), (-6, 3.4)]),
    surface("CausewaySlab", "Limestone", [(-6, -4.6), (-5.4, -5), (5.3, -5), (6, -4.2),
                                              (6, 4.4), (5.5, 5), (-5.3, 5), (-6, 4.5)]),
]
objects = [o for col in scene.collection.children for o in col.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT / "AscentV8Surfaces.fbx"), use_selection=True,
                         object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                         apply_unit_scale=True, bake_space_transform=False, add_leaf_bones=False)
manifest = {"props": props, "colors": {o.name: list(o.data.materials[0].diffuse_color[:3]) for o in objects}}
(OUT / "surfaces-manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "AscentV8Surfaces.blend"))
print(json.dumps(manifest))
