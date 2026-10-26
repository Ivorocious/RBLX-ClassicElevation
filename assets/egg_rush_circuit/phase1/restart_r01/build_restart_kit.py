"""Fresh Egg Rush Phase 1 shell/chicken sources; isolated Blender execution only."""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys
import time

import bpy
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parent
HELPER = ROOT.parent / "build_kit.py"
SPEC = importlib.util.spec_from_file_location("er_restart_geometry_helpers", HELPER)
kit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(kit)
BUILD = "ER_P1_R01_K01"
kit.BUILD = BUILD
PALETTE = dict(kit.PALETTE)
Geo = kit.Geo


def block(x0, x1, y0, y1, z0, z1, role="Shell"):
    assert x1 > x0 and y1 > y0 and z1 > z0
    return (x0, x1, y0, y1, z0, z1, role)


def centered(x, y, z, w, d, h, role="Shell"):
    return block(x-w/2, x+w/2, y-d/2, y+d/2, z-h/2, z+h/2, role)


def contains(boxes, point):
    tolerance = 1e-7
    return any(b[0]-tolerance <= point[0] <= b[1]+tolerance
               and b[2]-tolerance <= point[1] <= b[3]+tolerance
               and b[4]-tolerance <= point[2] <= b[5]+tolerance for b in boxes)


def union_geometry(boxes, surface=None, cuts=None):
    """Keep only the complete solid boundary, then merge adjacent same-role faces."""
    cuts = cuts or ((), (), ())
    axes = [sorted({b[2*a+e] for b in boxes for e in (0, 1)} | set(cuts[a]))
            for a in range(3)]
    occupied = {}
    for i in range(len(axes[0])-1):
        x = (axes[0][i]+axes[0][i+1])/2
        for j in range(len(axes[1])-1):
            y = (axes[1][j]+axes[1][j+1])/2
            for k in range(len(axes[2])-1):
                z = (axes[2][k]+axes[2][k+1])/2
                roles = [b[6] for b in boxes if b[0] < x < b[1] and b[2] < y < b[3]
                         and b[4] < z < b[5]]
                if roles:
                    occupied[i, j, k] = roles[-1]
    planes = defaultdict(set)
    for cell, base_role in occupied.items():
        for axis in range(3):
            u, v = (axis+1) % 3, (axis+2) % 3
            for sign in (-1, 1):
                neighbor = list(cell)
                neighbor[axis] += sign
                if tuple(neighbor) in occupied:
                    continue
                plane = cell[axis]+(sign == 1)
                center = [(axes[a][cell[a]]+axes[a][cell[a]+1])/2 for a in range(3)]
                center[axis] = axes[axis][plane]
                normal = [0, 0, 0]
                normal[axis] = sign
                role = surface(center, normal, base_role) if surface else base_role
                planes[axis, sign, plane, role].add((cell[u], cell[v]))
    geo = Geo()
    for (axis, sign, plane, role), cells in sorted(planes.items()):
        u, v = (axis+1) % 3, (axis+2) % 3
        while cells:
            u0, v0 = min(cells)
            u1 = u0+1
            while (u1, v0) in cells:
                u1 += 1
            v1 = v0+1
            while all((uu, v1) in cells for uu in range(u0, u1)):
                v1 += 1
            cells.difference_update((uu, vv) for uu in range(u0, u1) for vv in range(v0, v1))
            vertices = []
            for uu, vv in ((u0, v0), (u1, v0), (u1, v1), (u0, v1)):
                point = [0, 0, 0]
                point[axis] = axes[axis][plane]
                point[u], point[v] = axes[u][uu], axes[v][vv]
                vertices.append(point)
            geo.mesh(vertices, [(0, 1, 2, 3) if sign == 1 else (3, 2, 1, 0)], role)
    assert occupied and geo.faces
    return geo


def solid_asset(name, family, boxes, pivot, use, contacts=None, surface=None, cuts=None):
    kit.asset(name, family, union_geometry(boxes, surface, cuts), pivot, use, contacts)
    record = kit.ASSETS[-1]
    # Material pieces can be open surfaces; orient them against the complete solid.
    corrected = 0
    for obj in record["parts"]:
        mesh = obj.data
        for polygon in mesh.polygons:
            center, normal = polygon.center.copy(), polygon.normal.copy()
            plus = contains(boxes, center+normal*.001)
            minus = contains(boxes, center-normal*.001)
            assert plus != minus, (name, obj.name, tuple(center), "ambiguous boundary")
            if plus:
                polygon.flip()
                corrected += 1
        mesh.update()
    record["surfaceConstruction"] = "Axis-aligned solid union; buried faces removed, coplanar same-role rectangles merged."
    record["materialBoundaryNormalCorrections"] = corrected
    return record


def shell_fragment():
    boxes = [block(-3, 3, -1.25, 1.25, -2.4, -1.8),
             block(-4, 4, -1.75, 1.75, -1.8, -.9),
             block(-5, 5, -1.75, 1.75, -.9, 0),
             block(-4, 4, -2.25, 2.25, -.9, 0)]

    def surface(p, n, role):
        if n[1] < 0 and -3 <= p[0] <= -1 and -.85 < p[2] < -.15:
            return "Coral"
        if n[0] > 0 and -.9 <= p[1] <= .9 and -.85 < p[2] < -.15:
            return "Mint"
        return role

    record = solid_asset("ShellFragment", "R01Shells", boxes,
                         "Flat top Z0; bottom center XY0; Roblox topY0.",
                         "Short fixed shell landing:10 sideways by4.5 forward, squared stepped corners.",
                         [dict(center=[0, -.3, 0], size=[8, .6, 4.5])], surface,
                         ([-3, -1], [-.9, .9], [-.85, -.15]))
    record["usableTopBlender"] = dict(x=[-4, 4], y=[-2.25, 2.25], z=0)


def leaf(name, width, patch):
    half = width/2
    boxes = [block(-half+2, half-2, 1, 7, -3.4, -2.9),
             block(-half+1, half-1, .5, 7.5, -2.9, -2.5),
             block(-half+1, half-1, 0, .8, -2.5, 0),
             block(-half+1, -half+2, 0, 1.4, -2.5, 0),
             block(half-2, half-1, 0, 1.4, -2.5, 0),
             block(-half, -half+1, 1, 7, -2.5, 0),
             block(half-1, half, 1, 7, -2.5, 0),
             block(-half+1, half-1, 4.5, 8, -2.5, 0)]

    def surface(p, n, role):
        if n[1] > 0 and abs(p[1]-8) < .001 and -2 <= p[0] <= 0 and -1.9 <= p[2] <= -.5:
            return patch
        if abs(n[0]) > .9 and abs(abs(p[0])-half) < .001 and 2 <= p[1] <= 3.8 and -1.9 <= p[2] <= -.5:
            return "Mint" if patch == "Lilac" else "Coral"
        if n[2] > .9 and abs(p[2]+2.5) < .001:
            return "ShellShade"
        return role

    contact = dict(center=[0, -.3, -6.25], size=[width-2, .6, 3.5])
    record = solid_asset(name, "R01Shells", boxes,
                         "Hinge axis localX through0; flat rim/top Z0; extends Blender+Y /Roblox-Z.",
                         "Open rear cup with floorZ-2.5; solid front landing Y4.5..8. No contact over the rear recess.",
                         [contact], surface,
                         ([-2, 0], [2, 3.8], [-1.9, -.5]))
    record["hingeBlender"] = dict(origin=[0, 0, 0], axis=[1, 0, 0])
    record["usableTopBlender"] = dict(x=[-half+1, half-1], y=[4.5, 8], z=0)
    record["recessBlender"] = dict(x=[-half+2, half-2], y=[1.4, 4.5], floorZ=-2.5, rimZ=0)
    assert not contains(boxes, (0, 2.5, -.2)), name
    assert contains(boxes, (0, 2.5, -2.7)), name
    assert all(contains(boxes, (x, y, -.3))
               for x in (-half+1+.01, 0, half-1-.01)
               for y in (4.51, 6.25, 7.99)), name


def cylinder_x(geo, x0, x1, y, z, radius, role, sides=12):
    loops = [[(x, y+radius*math.cos(i*math.tau/sides), z+radius*math.sin(i*math.tau/sides))
              for i in range(sides)] for x in (x0, x1)]
    geo.loops(loops, role)


def hinge(name, width):
    geo = Geo()
    half = width/2
    # The central fixed bridge sits below the root; only outboard journals expose the axis.
    geo.box((0, -.4, -.9), (width+1.2, 1.1, .65), "Iron")
    for sign in (-1, 1):
        x = sign*(half+.85)
        geo.box((x, -.25, -.8), (1.5, 2, 1.5), "Coral")
        cylinder_x(geo, x-.65, x+.65, 0, 0, .85, "Coral")
        outside = x+sign*.68
        cylinder_x(geo, outside-.035, outside+.035, 0, 0, .47, "IronLight")
        cylinder_x(geo, outside+sign*.04-.02, outside+sign*.04+.02, 0, 0, .26, "Mint")
    kit.asset(name, "R01Shells", geo,
              "Same origin as leaf:axle localX through BlenderY0,Z0. No placement offset.",
              "Static outboard coral housings; recessed lower bridge behind the leaf root. Front landing Y4.5..8 stays clear.")
    kit.ASSETS[-1]["hingeBlender"] = dict(origin=[0, 0, 0], axis=[1, 0, 0], leafWidth=width)


def guardian():
    boxes = [centered(0, .3, 2.5, 7.8, 8.5, 3.8),
             centered(0, .55, 4.1, 8.8, 8.0, 3.5),
             centered(0, 1.0, 5.7, 7.0, 6.8, 1.5),
             centered(0, -3.15, 4.6, 6.5, 3.1, 5.6),
             centered(0, -4.35, 7.8, 4.8, 4.0, 3.6),
             centered(0, -4.15, 9.65, 3.6, 3.2, .65),
             centered(0, -6.75, 7.55, 2.5, 1.0, 1.1, "Coral"),
             centered(0, -7.4, 7.35, 1.7, .6, .65, "Coral")]
    for y, top in [(-5.5, 11.0), (-4.25, 11.8), (-3, 11.25)]:
        boxes.append(block(-.6, .6, y-.7, y+.7, 9.65, top, "Coral"))
    for sign in (-1, 1):
        boxes += [centered(sign*4.5, .45, 4.15, 1.35, 5.6, 3.0),
                  centered(sign*4.4, .7, 5.8, .9, 3.9, .7),
                  centered(sign*2.35, -3.7, .45, 2.4, 3.6, .9, "Coral"),
                  centered(sign*2.35-.6, -5.0, .35, .95, 1.5, .7, "Coral"),
                  centered(sign*2.35+.6, -5.0, .35, .95, 1.5, .7, "Coral")]

    def surface(p, n, role):
        if abs(n[0]) > .9:
            if abs(p[0]) > 4.9 and -1.7 <= p[1] <= 2.5 and 3.0 <= p[2] <= 5.65:
                if p[1] < 1.7 or p[2] < 4.8:
                    return "Lilac"
            if abs(abs(p[0])-2.4) < .001:
                eye_y, eye_z = p[1], p[2]
                if -5.65 <= eye_y <= -4.25:
                    bottom = 8.05 <= eye_z <= 8.28
                    ends = (eye_y <= -5.4 or eye_y >= -4.5) and 8.28 < eye_z <= 8.7
                    if bottom or ends:
                        return "Ink"
        return role

    record = solid_asset("GuardianBody", "R01Guardian", boxes,
                         "Feet bottom0; faces Blender-Y /Roblox+Z. Tail socket Blender(0,4.1,4.5).",
                         "D02-inspired sleepy block chicken:distinct head/chest, broad stepped violet wings and coral feet. Art only.",
                         surface=surface,
                         cuts=([], [-5.65, -5.4, -4.5, -4.25, -1.7, 1.7, 2.5],
                               [3.0, 4.8, 5.65, 8.05, 8.28, 8.7]))
    record["attachmentBlender"] = dict(GuardianTail=[0, 4.1, 4.5])
    tail_boxes = [block(-2.5, 2.5, -.45, 2.7, -1.1, .7),
                  block(-3.2, -1.0, 1.4, 3.2, -.4, 4.2, "Mint"),
                  block(-3.2, -1.0, 2.2, 3.2, 4.2, 5.7, "Lilac"),
                  block(-1.0, 1.2, 2, 3.8, -.4, 5.8),
                  block(-.8, 1.2, 2.6, 3.8, 5.8, 6.8),
                  block(1.2, 3.4, 1.8, 3.5, -.4, 4.7, "Coral"),
                  block(1.2, 3.0, 2.5, 3.5, 4.7, 6.0, "Coral")]
    solid_asset("GuardianTail", "R01Guardian", tail_boxes,
                "Root0; extends Blender+Y; mate to GuardianBody socket(0,4.1,4.5); localZ would be sweep axis.",
                "Upright few-piece D02 tail pose; no course sweep envelope or contacts are implied.")


def make_materials():
    for name, hex_color in PALETTE.items():
        srgb = [int(hex_color[i:i+2], 16)/255 for i in (0, 2, 4)]
        rgb = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in srgb]
        material = bpy.data.materials.new("ER_"+name)
        material.diffuse_color = (*rgb, 1)
        material.use_nodes = True
        material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1)
        material.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .78
        kit.MATERIALS[name] = material


def record_named(name):
    return next(record for record in kit.ASSETS if record["name"] == name)


def preview_asset(name, matrix=Matrix.Identity(4)):
    objects = []
    for source in record_named(name)["parts"]:
        obj = source.copy()
        obj.data = source.data
        bpy.context.scene.collection.objects.link(obj)
        obj.hide_render = False
        obj.matrix_world = matrix
        objects.append(obj)
    return objects


def preview_geometry(geo, name):
    objects = []
    for role in sorted(set(geo.roles)):
        mesh = bpy.data.meshes.new(name+role)
        faces = [face for face, face_role in zip(geo.faces, geo.roles) if face_role == role]
        mesh.from_pydata(geo.vertices, [], faces)
        mesh.update()
        obj = bpy.data.objects.new(name+role, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.data.materials.append(kit.MATERIALS[role])
        objects.append(obj)
    return objects


def scale_marker(x=-9, y=6, base=-3.4):
    geo = Geo()
    for offset in (-.5, .5):
        geo.box((x+offset, y, base+1.1), (.8, .9, 2.2), "IronLight")
    geo.box((x, y, base+3.3), (2.0, 1.0, 2.2), "IronLight")
    geo.box((x, y, base+4.95), (1.1, 1.0, 1.1), "IronLight")
    for offset in (-1.4, 1.4):
        geo.box((x+offset, y, base+3.3), (.7, .9, 2.1), "IronLight")
    return preview_geometry(geo, "ScaleMarker5p5Studs")


def setup_preview():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.render.resolution_x, scene.render.resolution_y = 1800, 1200
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.world = bpy.data.worlds.new("RestartNeutralWorld")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.68, .73, .8, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .7
    lamp_data = bpy.data.lights.new("RestartBroadKey", "AREA")
    lamp_data.energy, lamp_data.size = 4500, 18
    lamp = bpy.data.objects.new("RestartBroadKey", lamp_data)
    scene.collection.objects.link(lamp)
    lamp.location = (-8, 0, 22)
    lamp.rotation_euler = (Vector((0, 4, 0))-lamp.location).to_track_quat("-Z", "Y").to_euler()
    camera_data = bpy.data.cameras.new("RestartCamera")
    camera = bpy.data.objects.new("RestartCamera", camera_data)
    scene.collection.objects.link(camera)
    camera_data.type = "ORTHO"
    scene.camera = camera
    return camera


def render_view(out, name, camera, location, target, span, objects):
    scene = bpy.context.scene
    camera.location = location
    camera.rotation_euler = (Vector(target)-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = span
    scene.render.filepath = str(out/(name+".png"))
    bpy.ops.render.render(write_still=True)
    for obj in objects:
        bpy.data.objects.remove(obj, do_unlink=True)


def render_views(out):
    camera = setup_preview()
    for size, width in (("Wide", 12), ("Crown", 8)):
        for pose, degrees in (("open", 0), ("closed", 82)):
            objects = preview_asset("ShellHinge"+size)
            objects += preview_asset("ShellLeaf"+size, Matrix.Rotation(math.radians(degrees), 4, "X"))
            objects += scale_marker(x=-width/2-3.5)
            geo = Geo()
            geo.box((0, 4, -3.575), (29, 22, .35), "ShellShade")
            objects += preview_geometry(geo, "AssemblyFloor")
            render_view(out, "ShellLeaf"+size+"_"+pose, camera,
                        (18, 26, 18), (-1.5, 3.2, .4), 25, objects)
    for view, location in (("front", (13, -25, 14)), ("side", (25, -4, 12))):
        objects = preview_asset("GuardianBody")
        objects += preview_asset("GuardianTail", Matrix.Translation((0, 4.1, 4.5)))
        objects += scale_marker(x=-8, y=-1, base=0)
        geo = Geo()
        geo.box((0, 0, -.25), (30, 30, .4), "ShellShade")
        objects += preview_geometry(geo, "GuardianFloor")
        render_view(out, "Guardian_"+view, camera, location, (0, 0, 5.5), 25, objects)
    objects = []
    for name, position in (("ShellFragment", (-15, -9, 0)), ("ShellLeafWide", (0, -9, 0)),
                           ("ShellLeafCrown", (16, -9, 0)), ("ShellHingeWide", (0, -9, 0)),
                           ("ShellHingeCrown", (16, -9, 0)), ("GuardianBody", (-7, 12, 0)),
                           ("GuardianTail", (-7, 16.1, 4.5))):
        objects += preview_asset(name, Matrix.Translation(position))
    objects += scale_marker(x=10, y=12, base=0)
    geo = Geo()
    geo.box((0, 5, -3.8), (58, 52, .5), "ShellShade")
    objects += preview_geometry(geo, "KitFloor")
    render_view(out, "ER_P1_R01_kit", camera, (39, -49, 42), (0, 5, 1), 59, objects)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out = args.out.resolve()
    if out.exists() and any(out.iterdir()):
        raise RuntimeError("Fresh output directory required; historical/partial candidates are never overwritten.")
    out.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "NONE"
    bpy.context.scene.unit_settings.scale_length = 1
    make_materials()
    shell_fragment()
    leaf("ShellLeafWide", 12, "Mint")
    leaf("ShellLeafCrown", 8, "Lilac")
    hinge("ShellHingeWide", 12)
    hinge("ShellHingeCrown", 8)
    guardian()
    records = kit.export_assets(out)
    roundtrip = kit.verify_exports(out, records)
    if args.render:
        render_views(out)
    for record in kit.ASSETS:
        for obj in record["parts"]:
            obj.hide_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"ER_P1_R01_kit.blend"))
    manifest = dict(candidate=BUILD, phase=1, blender=bpy.app.version_string,
                    units="1 Blender unit =1 intended Roblox stud",
                    axes="RobloxXYZ=(BlenderX,BlenderZ,-BlenderY)",
                    exportSettings=dict(axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_UNITS"),
                    palette=PALETTE, assets=records, assetCount=len(records),
                    partCount=sum(len(r["parts"]) for r in records),
                    triangles=sum(p["triangles"] for r in records for p in r["parts"]),
                    builderSHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                    helperSHA256=hashlib.sha256(HELPER.read_bytes()).hexdigest(),
                    blenderFbxRoundtrip=roundtrip,
                    collision="Art only. Manifest contacts are native Roblox XYZ, never a bounding-box fill over the recess.",
                    pose="Open leaf angle0; closed pose82deg localX is a visual assembly check, not runtime tuning.",
                    renderViews=[p.name for p in sorted(out.glob("*.png"))],
                    buildSeconds=round(time.perf_counter()-started, 3),
                    caveat="Fresh offline candidate only. Native scale, material placement, moving joins, contact/carry, player view and owner Phase1 assessment remain required.")
    manifest["files"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in sorted(out.iterdir()) if p.suffix in (".fbx", ".blend", ".png")}
    (out/"manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({k: manifest[k] for k in ("candidate", "assetCount", "partCount", "triangles", "buildSeconds")}), flush=True)


if __name__ == "__main__":
    main()
