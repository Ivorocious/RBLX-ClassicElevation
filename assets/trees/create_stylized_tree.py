"""Build the tree in a new Blender scene and export selected geometry for Roblox."""
import bpy
import math
from pathlib import Path
from mathutils import Vector, Quaternion

OUTPUT = Path(r"C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\trees")
assert "StylizedOak" not in bpy.data.scenes, "Tree scene already exists; inspect before rebuilding."
scene = bpy.data.scenes.new("StylizedOak")
bpy.context.window.scene = scene
scene.unit_settings.system = 'NONE'

def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = mat.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Roughness'].default_value = 0.9
    return mat

bark = material('WarmBark', (0.25, 0.12, 0.055))
leaves = [material('Leaves' + str(i), color) for i, color in enumerate([
    (0.17, 0.36, 0.075), (0.26, 0.46, 0.10), (0.36, 0.56, 0.14),
])]
objects = []

def branch(name, start, end, bottom, top):
    direction = Vector(end) - Vector(start)
    bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=bottom, radius2=top,
                                   depth=direction.length, location=(Vector(start) + Vector(end)) / 2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    obj.data.materials.append(bark)
    objects.append(obj)
    return obj

branch('Trunk', (0, 0, 0), (0.25, 0, 6.4), 0.72, 0.29)
branch('BranchLeft', (0.1, 0, 3.4), (-2.0, 0.2, 7.4), 0.34, 0.12)
branch('BranchRight', (0.2, 0, 4.2), (2.0, 0.5, 7.6), 0.3, 0.10)
branch('BranchBack', (0.2, 0, 4.8), (0.3, 1.8, 8.0), 0.24, 0.08)
for i in range(5):
    angle = i * math.tau / 5
    branch('Root' + str(i + 1), (math.cos(angle) * 1.2, math.sin(angle) * 1.2, 0.12),
           (0, 0, 0.7), 0.12, 0.4)

clusters = [
    ((-1.9, 0, 7.1), (2.5, 2.3, 1.85), 0),
    ((2.0, 0.25, 7.6), (2.55, 2.35, 2.0), 1),
    ((0.2, 1.75, 8.3), (2.8, 2.4, 2.15), 0),
    ((-0.2, -1.5, 8.5), (2.75, 2.2, 2.05), 1),
    ((0.0, 0.0, 10.0), (2.55, 2.3, 2.05), 2),
]
for i, (position, scale, color) in enumerate(clusters):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=position)
    obj = bpy.context.object
    obj.name = 'Canopy' + str(i + 1)
    obj.scale = scale
    obj.rotation_euler.z = i * 0.7
    obj.data.materials.append(leaves[color])
    objects.append(obj)

bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
triangles = 0
for obj in objects:
    obj.data.calc_loop_triangles()
    triangles += len(obj.data.loop_triangles)

bpy.ops.export_scene.fbx(filepath=str(OUTPUT / 'StylizedOak.fbx'), use_selection=True,
                         object_types={'MESH'}, axis_forward='-Z', axis_up='Y',
                         apply_unit_scale=True, bake_anim=False, add_leaf_bones=False)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'CONSOLE':
            area.type = 'VIEW_3D'
        if area.type == 'VIEW_3D' and area.spaces.active.type == 'VIEW_3D':
            area.spaces.active.shading.color_type = 'MATERIAL'
            area.spaces.active.region_3d.view_distance = 20
            area.spaces.active.region_3d.view_location = (0, 0, 5.5)
            area.spaces.active.region_3d.view_rotation = Quaternion((0.880, 0.280, 0.116, 0.364)).normalized()
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT / 'StylizedOak.blend'))
print({'objects': len(objects), 'triangles': triangles, 'height': 12.05, 'export': str(OUTPUT / 'StylizedOak.fbx')})
