"""Build three Blender-first City Run market cars and an editable part manifest.

The cars are authored as separate Blender collections.  The JSON manifest is the
native Studio handoff: every visible part carries a local position, size, shape,
rotation, color, and explicit anchored/non-colliding flags.  Runtime code keeps
ownership of motion and the authoritative collision envelope.
"""

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


OUT = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)

# Keep the editable Blender scene near the origin while preserving world-space
# coordinates in the manifest and the Studio handoff.
BLENDER_ORIGIN = (3200.0, 0.0, 164.0)
PIVOTS = {
    "Car0": (3304.0, 15.0, 164.0),
    "Car1": (3242.0, 15.0, 164.0),
    "Car2": (3177.0, 15.0, 164.0),
}

COLORS = {
    "teal": (31, 126, 119),
    "saffron": (222, 157, 44),
    "coral": (190, 72, 62),
    "cream": (235, 216, 169),
    "dark": (24, 34, 39),
    "glass": (58, 104, 116),
    "glass_highlight": (107, 160, 164),
    "tire": (25, 29, 32),
    "hub": (131, 139, 132),
    "lamp": (248, 220, 139),
    "tail": (142, 35, 39),
    "chrome": (187, 190, 174),
    "road_dust": (92, 73, 53),
}

PIVOT_Y = 15.0
STREET_SURFACE_Y = 11.19995
WHEEL_CENTER_LOCAL_Y_BY_CAR = {"Car0": -0.90, "Car1": -0.88, "Car2": -0.92,
}
WHEEL_DIAMETER = 2.28
GEOMETRY_Y_OFFSET_BY_CAR = {
    name: STREET_SURFACE_Y - (PIVOT_Y + wheel_y - WHEEL_DIAMETER / 2.0)
    for name, wheel_y in WHEEL_CENTER_LOCAL_Y_BY_CAR.items()
}
COLLISION_ENVELOPE = {
    "size": [16.0, 6.0, 7.0],
    "centerWorldY": 15.4,
    "centerLocal": [0.0, 0.4, 0.0],
    "anchored": True,
    "canCollide": False,
    "owner": "CityRun runtime traffic collider",
}


bpy.ops.wm.read_factory_settings(use_empty=True)
SCENE = bpy.context.scene
SCENE.unit_settings.system = "NONE"



def world_to_blender(world):
    """Convert project world axes (X, Y-up, Z) to Blender (X, Y-depth, Z-up)."""

    x, y, z = world
    return (x - BLENDER_ORIGIN[0], -(z - BLENDER_ORIGIN[2]), y - BLENDER_ORIGIN[1])


def add_material(name, rgb, roughness=0.68, metallic=0.0):
    material = bpy.data.materials.new("C17Cars_" + name)
    material.diffuse_color = tuple(channel / 255 for channel in rgb) + (1.0,)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = material.diffuse_color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    return material


MATERIALS = {
    name: add_material(name, rgb, 0.56 if name in {"teal", "saffron", "coral"} else 0.72,
                       0.35 if name in {"hub", "chrome"} else 0.0)
    for name, rgb in COLORS.items()
}

COLLECTIONS = {}
MESH_OBJECTS = []


def new_unit(name, display_name, section="MarketTraffic"):
    collection = bpy.data.collections.new(name)
    SCENE.collection.children.link(collection)
    COLLECTIONS[name] = collection
    unit = {
        "name": name,
        "displayName": display_name,
        "section": section,
        "pivotWorld": list(PIVOTS[name]),
        "trafficCenterY": PIVOT_Y,
        "geometryYOffsetLocalY": round(GEOMETRY_Y_OFFSET_BY_CAR[name], 5),
        "wheelBottomWorldY": round(PIVOT_Y + WHEEL_CENTER_LOCAL_Y_BY_CAR[name] + GEOMETRY_Y_OFFSET_BY_CAR[name] - WHEEL_DIAMETER / 2.0, 5),
        "motion": {"direction": [1.0, 0.0, 0.0], "axis": "+X"},
        "collisionEnvelope": dict(COLLISION_ENVELOPE),
        "parts": [],
    }
    return unit


def link_object(obj, unit_name, part_name, role):
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    COLLECTIONS[unit_name].objects.link(obj)
    obj.name = f"{unit_name}_{part_name}"
    if obj.data:
        obj.data.name = f"{unit_name}_{part_name}_Mesh"
    obj["StudioUnit"] = unit_name
    obj["StudioPart"] = part_name
    obj["AuthoringRole"] = role
    obj["Anchored"] = True
    obj["CanCollide"] = False
    MESH_OBJECTS.append(obj)
    return obj


def local_world(unit, position):
    pivot = PIVOTS[unit["name"]]
    return (pivot[0] + position[0], pivot[1] + position[1], pivot[2] + position[2])


def make_cube(unit, part_name, position, size, material_name, rotation):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=world_to_blender(local_world(unit, position)))
    obj = bpy.context.object
    obj.scale = (size[0], size[2], size[1])
    obj.rotation_euler = tuple(math.radians(value) for value in rotation)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(MATERIALS[material_name])
    return link_object(obj, unit["name"], part_name, "block")


def make_cylinder(unit, part_name, position, size, material_name, rotation):
    # Blender's cylinder axis is local Z.  A 90-degree X rotation turns it into
    # the project's world-Z wheel axle while keeping the manifest dimensions in
    # the familiar [world-X, world-Y, world-Z] order.
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=20,
        radius=0.5,
        depth=1.0,
        location=world_to_blender(local_world(unit, position)),
        rotation=tuple(math.radians(value) for value in rotation),
    )
    obj = bpy.context.object
    obj.scale = (size[0], size[1], size[2])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(MATERIALS[material_name])
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return link_object(obj, unit["name"], part_name, "cylinder")


def make_wedge(unit, part_name, position, size, material_name, rotation, slope):
    """Create a triangular-prism wedge with its high end toward local -X."""

    sx, sy, sz = size
    bottom = -sy / 2.0
    top_negative_x = sy / 2.0 + slope * sy / 2.0
    top_positive_x = sy / 2.0 - slope * sy / 2.0
    local_vertices = [
        (-sx / 2, bottom, -sz / 2),
        (sx / 2, bottom, -sz / 2),
        (sx / 2, bottom, sz / 2),
        (-sx / 2, bottom, sz / 2),
        (-sx / 2, top_negative_x, -sz / 2),
        (sx / 2, top_positive_x, -sz / 2),
        (sx / 2, top_positive_x, sz / 2),
        (-sx / 2, top_negative_x, sz / 2),
    ]
    vertices = [(x, -z, y) for x, y, z in local_vertices]
    faces = [
        (0, 1, 2, 3),
        (4, 7, 6, 5),
        (0, 4, 5, 1),
        (1, 5, 6, 2),
        (2, 6, 7, 3),
        (3, 7, 4, 0),
    ]
    mesh = bpy.data.meshes.new(f"C17Cars_{unit['name']}_{part_name}")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(MATERIALS[material_name])
    mesh.update()
    obj = bpy.data.objects.new(part_name, mesh)
    COLLECTIONS[unit["name"]].objects.link(obj)
    obj.location = world_to_blender(local_world(unit, position))
    obj.rotation_euler = tuple(math.radians(value) for value in rotation)
    return link_object(obj, unit["name"], part_name, "wedge")


def add_part(unit, name, position, size, shape, color, rotation=(0.0, 0.0, 0.0), role="detail", **extra):
    if shape not in {"Block", "Cylinder", "Wedge"}:
        raise ValueError(f"Unsupported C17 car primitive: {shape}")
    if any(value <= 0 for value in size):
        raise ValueError(f"Part {unit['name']}/{name} has a non-positive size")
    if color not in COLORS:
        raise ValueError(f"Unknown C17 car color: {color}")
    position = (position[0], position[1] + GEOMETRY_Y_OFFSET_BY_CAR[unit["name"]], position[2])
    record = {
        "name": name,
        "position": [round(value, 4) for value in position],
        "size": [round(value, 4) for value in size],
        "shape": shape,
        "rotation": [round(value, 4) for value in rotation],
        "color": list(COLORS[color]),
        "material": color,
        "anchored": True,
        "canCollide": False,
        "role": role,
    }
    record.update(extra)
    if shape == "Wedge":
        wedge_slope = abs(float(extra.get("slope", 0.0)))
        record["actualBounds"] = {
            "localMin": [round(position[0] - size[0] / 2.0, 4), round(position[1] - size[1] / 2.0, 4), round(position[2] - size[2] / 2.0, 4)],
            "localMax": [round(position[0] + size[0] / 2.0, 4), round(position[1] + size[1] * (1.0 + wedge_slope) / 2.0, 4), round(position[2] + size[2] / 2.0, 4)],
        }
    unit["parts"].append(record)
    if shape == "Block":
        make_cube(unit, name, position, size, color, rotation)
    elif shape == "Cylinder":
        make_cylinder(unit, name, position, size, color, rotation)
    else:
        make_wedge(unit, name, position, size, color, rotation, extra.get("slope", 0.0))


def add_wheels(unit, wheel_x, wheel_y=-0.9, wheel_width=2.45):
    for x_index, x in enumerate((-wheel_x, wheel_x), 1):
        for z_index, z in enumerate((-2.52, 2.52), 1):
            add_part(
                unit,
                f"Wheel_{x_index}_{z_index}_Tire",
                (x, wheel_y, z),
                (2.28, 2.28, 0.56),
                "Cylinder",
                "tire",
                rotation=(90.0, 0.0, 0.0),
                role="wheel-tire",
            )
            outer_z = z + (0.56 + 0.12) / 2.0 * (1 if z > 0 else -1)
            add_part(
                unit,
                f"Wheel_{x_index}_{z_index}_Hub",
                (x, wheel_y, outer_z),
                (1.12, 1.12, 0.12),
                "Cylinder",
                "hub",
                rotation=(90.0, 0.0, 0.0),
                role="wheel-hub",
            )


def add_front_and_rear(unit, front_x, rear_x, width, lamp_y=0.72):
    add_part(unit, "Front_Bumper", (front_x, -0.02, 0), (0.34, 0.72, width - 0.18), "Block", "dark", role="bumper")
    add_part(unit, "Rear_Bumper", (rear_x, -0.05, 0), (0.34, 0.68, width - 0.18), "Block", "dark", role="bumper")
    add_part(unit, "Front_Grille", (front_x + 0.19, 0.08, 0), (0.10, 0.62, 2.25), "Block", "dark", role="grille")
    for sign in (-1, 1):
        add_part(unit, f"Front_Lamp_{sign}", (front_x + 0.2, lamp_y, sign * 1.55), (0.16, 0.54, 0.82), "Block", "lamp", role="headlamp")
        add_part(unit, f"Rear_Lamp_{sign}", (rear_x - 0.2, 0.55, sign * 1.62), (0.16, 0.48, 0.72), "Block", "tail", role="taillamp")
        add_part(unit, f"Mirror_{sign}", (1.35, 1.60, sign * 2.72), (0.38, 0.24, 0.18), "Block", "dark", role="mirror")


def add_side_windows_and_pillars(unit, x_positions, y, width, z_offset=2.31, glass_size=(1.55, 0.88, 0.08)):
    for sign in (-1, 1):
        for index, x in enumerate(x_positions, 1):
            add_part(unit, f"SideGlass_{sign}_{index}", (x, y, sign * z_offset), glass_size, "Block", "glass", role="side-window")
        for index, x in enumerate(x_positions[:-1], 1):
            add_part(unit, f"WindowPillar_{sign}_{index}", (x + 0.84, y, sign * (z_offset + 0.04)), (0.12, 1.02, 0.10), "Block", "dark", role="window-pillar")


def build_car0():
    unit = new_unit("Car0", "Teal market hatchback")
    add_part(unit, "Body_Lower", (0.0, 0.0, 0.0), (14.2, 1.38, 5.08), "Block", "teal", role="body")
    add_part(unit, "Front_Hood", (4.20, 0.83, 0.0), (4.55, 0.72, 4.72), "Block", "teal", role="hood")
    add_part(unit, "Rear_Deck", (-5.15, 0.78, 0.0), (2.55, 0.66, 4.62), "Block", "teal", role="rear-deck")
    add_part(unit, "Cabin_Shell", (-0.62, 1.60, 0.0), (6.72, 2.26, 4.46), "Wedge", "teal", role="cabin", slope=0.58)
    add_part(unit, "Cabin_RoofTrim", (-0.72, 2.78, 0.0), (4.42, 0.22, 4.18), "Block", "cream", role="roof-trim")
    add_part(unit, "Windshield", (2.10, 2.03, 0.0), (1.05, 0.84, 4.24), "Wedge", "glass_highlight", role="windshield", slope=0.60)
    add_side_windows_and_pillars(unit, (-2.15, -0.05, 1.50), 1.95, 4.46, glass_size=(1.34, 0.82, 0.08))
    for sign in (-1, 1):
        add_part(unit, f"DoorHandle_{sign}", (-0.55, 0.86, sign * 2.57), (0.72, 0.12, 0.10), "Block", "cream", role="door-handle")
        add_part(unit, f"SideSkirt_{sign}", (-0.10, -0.48, sign * 2.56), (11.8, 0.30, 0.16), "Block", "dark", role="side-skirt")
    add_front_and_rear(unit, 7.03, -7.03, 5.08)
    add_wheels(unit, 4.34, -0.90, 5.08)
    return unit


def build_car1():
    unit = new_unit("Car1", "Saffron market cab")
    add_part(unit, "Body_Lower", (0.0, 0.02, 0.0), (14.78, 1.50, 5.20), "Block", "saffron", role="body")
    add_part(unit, "Front_Hood", (4.52, 0.90, 0.0), (4.35, 0.78, 4.80), "Block", "saffron", role="hood")
    add_part(unit, "Rear_Box", (-5.08, 1.12, 0.0), (4.10, 1.62, 4.84), "Block", "saffron", role="rear-body")
    add_part(unit, "Cabin_Shell", (-0.95, 1.76, 0.0), (6.72, 2.62, 4.50), "Block", "saffron", role="cabin")
    add_part(unit, "Cabin_Roof", (-0.95, 3.12, 0.0), (5.70, 0.28, 4.20), "Block", "cream", role="roof-trim")
    add_part(unit, "Roof_MarketSign", (-0.40, 3.24, 0.0), (1.46, 0.28, 1.18), "Block", "cream", role="district-sign")
    add_part(unit, "Windshield", (2.16, 2.14, 0.0), (1.05, 0.92, 4.30), "Wedge", "glass_highlight", role="windshield", slope=0.16)
    add_side_windows_and_pillars(unit, (-2.38, -0.82, 0.72), 2.18, 4.62, glass_size=(1.52, 1.04, 0.08))
    for sign in (-1, 1):
        add_part(unit, f"MarketStripe_{sign}", (-0.25, 0.58, sign * 2.63), (11.25, 0.22, 0.13), "Block", "cream", role="paint-stripe")
        add_part(unit, f"DoorHandle_{sign}", (-0.90, 1.08, sign * 2.68), (0.78, 0.12, 0.10), "Block", "dark", role="door-handle")
        add_part(unit, f"SideSkirt_{sign}", (-0.10, -0.50, sign * 2.64), (12.0, 0.28, 0.16), "Block", "dark", role="side-skirt")
    add_front_and_rear(unit, 7.32, -7.32, 5.20, lamp_y=0.82)
    add_wheels(unit, 4.42, -0.88, 5.20)
    return unit


def build_car2():
    unit = new_unit("Car2", "Coral market coupe")
    add_part(unit, "Body_Lower", (0.0, -0.02, 0.0), (13.88, 1.26, 5.02), "Block", "coral", role="body")
    add_part(unit, "Front_Hood", (4.16, 0.70, 0.0), (4.70, 0.68, 4.66), "Block", "coral", role="hood")
    add_part(unit, "Rear_Deck", (-4.88, 0.88, 0.0), (3.18, 0.78, 4.70), "Block", "coral", role="rear-deck")
    add_part(unit, "Cabin_Shell", (-0.62, 1.42, 0.0), (6.72, 2.20, 4.32), "Wedge", "coral", role="cabin", slope=0.78)
    add_part(unit, "Cabin_RoofTrim", (-0.92, 2.63, 0.0), (3.62, 0.24, 4.10), "Block", "cream", role="roof-trim")
    add_part(unit, "Windshield", (2.02, 1.88, 0.0), (1.22, 0.84, 4.10), "Wedge", "glass_highlight", role="windshield", slope=0.78)
    add_side_windows_and_pillars(unit, (-2.03, -0.45, 1.08), 1.90, 4.22, glass_size=(1.26, 0.78, 0.08))
    add_part(unit, "Rear_Spoiler", (-6.14, 1.86, 0.0), (0.42, 0.22, 3.80), "Block", "cream", role="spoiler")
    for sign in (-1, 1):
        add_part(unit, f"AccentStripe_{sign}", (0.0, 0.52, sign * 2.56), (10.8, 0.18, 0.12), "Block", "cream", role="paint-stripe")
        add_part(unit, f"DoorHandle_{sign}", (-0.72, 0.80, sign * 2.58), (0.68, 0.12, 0.10), "Block", "cream", role="door-handle")
        add_part(unit, f"SideSkirt_{sign}", (-0.10, -0.47, sign * 2.55), (11.3, 0.26, 0.16), "Block", "dark", role="side-skirt")
    add_front_and_rear(unit, 6.88, -6.88, 5.02, lamp_y=0.68)
    add_wheels(unit, 4.18, -0.92, 5.02)
    return unit


UNITS = [build_car0(), build_car1(), build_car2()]


def add_preview_lighting():
    world = bpy.data.worlds.new("C17CarsWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.035, 0.055, 0.065, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
    SCENE.world = world

    for name, location, energy, size in [
        ("MarketKey", (45, -28, 34), 1200, 28),
        ("MarketFill", (-30, 18, 18), 850, 22),
        ("MarketRim", (100, 10, 26), 1100, 18),
    ]:
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        SCENE.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (math.radians(30), 0.0, math.radians(20))

    camera_data = bpy.data.cameras.new("C17CarsCamera")
    camera = bpy.data.objects.new("C17CarsCamera", camera_data)
    SCENE.collection.objects.link(camera)
    SCENE.camera = camera
    camera.location = (64, -52, 25)
    look_at = (42, 0, 1.0)
    camera.rotation_euler = (Vector(look_at) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 36
    SCENE.render.engine = "BLENDER_EEVEE"
    SCENE.render.resolution_x = 1800
    SCENE.render.resolution_y = 920
    SCENE.render.resolution_percentage = 100
    SCENE.render.image_settings.file_format = "PNG"
    SCENE.render.film_transparent = False
    SCENE.view_settings.look = "AgX - Medium High Contrast"
    SCENE.render.filepath = str(OUT / "C17_cars_preview.png")
    bpy.ops.render.render(write_still=True)


def export_fbx(path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in MESH_OBJECTS:
        obj.select_set(True)
    if MESH_OBJECTS:
        bpy.context.view_layer.objects.active = MESH_OBJECTS[0]
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"MESH"},
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        bake_space_transform=False,
        add_leaf_bones=False,
    )


def source_part_bounds(part):
    if part["shape"] == "Wedge":
        bounds = part["actualBounds"]
        return bounds["localMin"], bounds["localMax"]
    return (
        [part["position"][axis] - part["size"][axis] / 2.0 for axis in range(3)],
        [part["position"][axis] + part["size"][axis] / 2.0 for axis in range(3)],
    )


def derive_actual_bounds(parts, pivot):
    minimum = [float("inf")] * 3
    maximum = [float("-inf")] * 3
    for part in parts:
        part_minimum, part_maximum = source_part_bounds(part)
        for axis in range(3):
            minimum[axis] = min(minimum[axis], part_minimum[axis])
            maximum[axis] = max(maximum[axis], part_maximum[axis])
    size = [round(maximum[axis] - minimum[axis], 4) for axis in range(3)]
    center = [round((maximum[axis] + minimum[axis]) / 2.0, 4) for axis in range(3)]
    return {
        "localMin": [round(value, 4) for value in minimum],
        "localMax": [round(value, 4) for value in maximum],
        "size": size,
        "centerLocal": center,
        "worldMin": [round(pivot[axis] + minimum[axis], 4) for axis in range(3)],
        "worldMax": [round(pivot[axis] + maximum[axis], 4) for axis in range(3)],
        "centerWorld": [round(pivot[axis] + center[axis], 4) for axis in range(3)],
    }


def native_cframe(position, rotation):
    return {
        "position": [round(value, 4) for value in position],
        "rotation": [round(value, 4) for value in rotation],
        "rotationUnit": "degrees",
        "construction": "CFrame.new(position) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))",
    }


def make_native_record(source, name, position, size, shape, rotation, role, roblox_class, **extra):
    record = {
        "name": name,
        "position": [round(value, 4) for value in position],
        "size": [round(value, 4) for value in size],
        "shape": shape,
        "rotation": [round(value, 4) for value in rotation],
        "color": list(source["color"]),
        "material": "SmoothPlastic",
        "sourceMaterial": source["material"],
        "sourcePart": source["name"],
        "sourceShape": source["shape"],
        "sourcePosition": list(source["position"]),
        "sourceSize": list(source["size"]),
        "sourceActualBounds": source.get("actualBounds"),
        "robloxClass": roblox_class,
        "nativeSize": [round(value, 4) for value in size],
        "nativeRotation": [round(value, 4) for value in rotation],
        "nativeCFrame": native_cframe(position, rotation),
        "anchored": True,
        "canCollide": False,
        "canTouch": False,
        "canQuery": False,
        "role": role,
    }
    record.update(extra)
    return record


def expand_native_parts(blender_parts):
    native_parts = []
    for source in blender_parts:
        if source["shape"] == "Wedge":
            source_width, source_height, source_depth = source["size"]
            slope = abs(float(source["slope"]))
            lower_height = source_height * (1.0 - slope / 2.0)
            lower_position = list(source["position"])
            lower_position[1] -= source_height * slope / 4.0
            high_end_rotation = -90.0 if source["slope"] >= 0.0 else 90.0
            upper_height = source_height * slope
            upper_position = list(source["position"])
            upper_position[1] += source_height / 2.0
            native_parts.append(make_native_record(
                source,
                source["name"] + "_LowerBlock",
                lower_position,
                (source_width, lower_height, source_depth),
                "Block",
                (0.0, 0.0, 0.0),
                source["role"] + "-native-lower",
                "Part",
                decomposition="lower rectangular block of the custom Blender wedge",
            ))
            native_parts.append(make_native_record(
                source,
                source["name"] + "_UpperWedge",
                upper_position,
                (source_depth, upper_height, source_width),
                "Wedge",
                (0.0, high_end_rotation, 0.0),
                source["role"] + "-native-wedge",
                "WedgePart",
                decomposition="triangular upper section; WedgePart slopes along local +Z and is rotated to world -X",
                nativeHighEdgeLocalAxis="+Z",
                highEndWorldAxis="-X" if high_end_rotation == -90.0 else "+X",
            ))
        elif source["shape"] == "Cylinder":
            diameter_x, diameter_y, depth_z = source["size"]
            native_size = (depth_z, diameter_x, diameter_y)
            native_parts.append(make_native_record(
                source,
                source["name"],
                source["position"],
                native_size,
                "Cylinder",
                (0.0, 90.0, 0.0),
                source["role"],
                "Part",
                nativeShape="Cylinder",
                cylinderAxis="Roblox local X rotated to world Z",
            ))
        else:
            native_parts.append(make_native_record(
                source,
                source["name"],
                source["position"],
                source["size"],
                "Block",
                source["rotation"],
                source["role"],
                "Part",
            ))
    return native_parts


def validate_blender_units(units):
    assert len(units) == 3
    assert [unit["name"] for unit in units] == ["Car0", "Car1", "Car2"]
    for unit in units:
        assert len(unit["parts"]) >= 35
        assert unit["motion"]["direction"] == [1.0, 0.0, 0.0]
        assert unit["collisionEnvelope"]["size"] == [16.0, 6.0, 7.0]
        for part in unit["parts"]:
            assert set(("name", "position", "size", "shape", "rotation", "color", "anchored", "canCollide")) <= set(part)
            assert part["anchored"] is True
            assert part["canCollide"] is False
            assert part["shape"] in {"Block", "Cylinder", "Wedge"}


def validate_manifest(units):
    for unit in units:
        assert len(unit["parts"]) >= len(unit["blenderParts"])
        for part in unit["parts"]:
            required = {"name", "position", "size", "shape", "rotation", "color",
                        "nativeSize", "nativeRotation", "nativeCFrame", "robloxClass",
                        "anchored", "canCollide"}
            assert required <= set(part)
            assert part["anchored"] is True
            assert part["canCollide"] is False
            assert part["robloxClass"] in {"Part", "WedgePart"}
        assert all(part["shape"] != "Wedge" or part["robloxClass"] == "WedgePart" for part in unit["parts"])


validate_blender_units(UNITS)
for unit in UNITS:
    blender_parts = unit["parts"]
    derived_bounds = derive_actual_bounds(blender_parts, PIVOTS[unit["name"]])
    unit["blenderParts"] = blender_parts
    unit["parts"] = expand_native_parts(blender_parts)
    unit["blenderPartCount"] = len(blender_parts)
    unit["nativePartCount"] = len(unit["parts"])
    unit["collisionEnvelope"]["derivedActualBounds"] = derived_bounds
validate_manifest(UNITS)

derived_actual_bounds = {unit["name"]: unit["collisionEnvelope"]["derivedActualBounds"] for unit in UNITS}
traffic_envelope = dict(COLLISION_ENVELOPE)
traffic_envelope["derivedActualBoundsByUnit"] = derived_actual_bounds
manifest = {
    "build": "C17_Cars_02",
    "schema": "CityRunTrafficCarManifest.v2",
    "authoring": "Blender 5.2.1 source collections plus exact native Roblox decomposition",
    "district": "Market",
    "geometry": {
        "streetSurfaceWorldY": STREET_SURFACE_Y,
        "geometryOffsetLocalYByUnit": {name: round(value, 5) for name, value in GEOMETRY_Y_OFFSET_BY_CAR.items()},
        "wheelBottomWorldYByUnit": {name: round(PIVOT_Y + WHEEL_CENTER_LOCAL_Y_BY_CAR[name] + GEOMETRY_Y_OFFSET_BY_CAR[name] - WHEEL_DIAMETER / 2.0, 5) for name in PIVOTS},
        "visibleGeometry": "all Blender-authored car parts are lowered together; traffic pivots remain unchanged",
    },
    "axes": {
        "world": "X east, Y up, Z north",
        "blender": "X east, Y depth, Z up",
        "partPosition": "local to each traffic pivot",
        "rotationUnit": "degrees, XYZ Euler",
        "color": "RGB 0-255",
        "manifestParts": "unit.parts are direct native Studio parts; unit.blenderParts are source geometry records",
        "nativeSize": "Roblox BasePart.Size in world X,Y,Z order",
        "nativeCFrame": "CFrame.new(localPosition) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))",
        "cylinderRule": "Roblox Part.Shape=Cylinder uses local X as its axis; wheels use nativeSize=[depth,diameter,diameter] and nativeRotation=[0,90,0]",
        "wedgeRule": "Each Blender wedge is split into a lower Part block and an upper WedgePart; WedgePart slopes along local +Z, so nativeSize=[worldZWidth,height,worldXLength] and nativeRotation=[0,-90,0] gives the authored high end at world -X",
    },
    "traffic": {
        "direction": "+X",
        "runtimePivots": "Car0/Car1/Car2 pivot at world Y=15 and local traffic center Y=15",
        "collisionEnvelope": traffic_envelope,
        "visibleParts": "anchored and non-colliding; runtime owns the collider and motion",
    },
    "audio": {
        "engineRev": {"file": "car_engine_rev.wav", "assetId": "102058378010336"},
        "tireRoll": {"file": "car_tire_roll.wav", "assetId": "85943066947156"},
    },
    "colors": COLORS,
    "units": UNITS,
    "fbxCollections": [unit["name"] for unit in UNITS],
}
(OUT / "manifest_C17_cars.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

add_preview_lighting()
export_fbx(OUT / "CityRun_C17_cars.fbx")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "CityRun_C17_cars.blend"))

print(json.dumps({
    "build": manifest["build"],
    "units": len(UNITS),
    "parts": sum(len(unit["parts"]) for unit in UNITS),
    "collections": manifest["fbxCollections"],
    "fbx": str(OUT / "CityRun_C17_cars.fbx"),
    "blend": str(OUT / "CityRun_C17_cars.blend"),
    "manifest": str(OUT / "manifest_C17_cars.json"),
    "preview": str(OUT / "C17_cars_preview.png"),
}))
