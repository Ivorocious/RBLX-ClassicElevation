"""Assemble the exact final draft in isolated Blender for composition inspection."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

import bpy
from mathutils import Matrix, Vector

ROOT = next(path for path in Path(__file__).resolve().parents if (path / "default.project.json").exists())
ARTIFACTS = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/blender"
FINAL_PLAN = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json"
OLD_PLAN = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/combined-plan49.json"
NATIVE_LAYOUT = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/final/enclosure_source49_layout.json"
PALETTE = {"Stone": (155,164,175), "StoneLight": (193,196,195), "StoneDark": (109,121,140),
           "Slate": (63,80,109), "SlateBand": (90,106,132), "Iron": (72,83,102), "Brass": (174,140,83),
           "Lead": (79,73,64), "Leaf": (70,99,80), "Flower": (148,143,174), "Earth": (104,86,63),
           "Wood": (101,77,53), "Foliage": (70,117,67), "Needles": (62,102,73),
           "Rock": (100,112,116), "RockA": (100,112,116), "RockB": (100,112,116), "Grass": (91,119,75)}
QUIET = {"Amber": (172,120,61), "AmberLight": (210,169,108), "AmberPale": (227,195,140)}
FOCAL = {"Amber": (210,145,54), "AmberLight": (241,190,98), "AmberPale": (255,223,157)}
GRAND = {"Stone": (124,134,149), "StoneLight": (185,190,193), "StoneDark": (80,96,116), "Slate": (43,60,86)}
SOURCES = {
    "BL02": ("assets/moonlit_citadel/bl02/MC_BL02_sample.blend", "assets/moonlit_citadel/bl02/manifest.json"),
    "C01": ("assets/moonlit_citadel/phase3/candidate01/MC_P3_WORLD_KIT.blend", "assets/moonlit_citadel/phase3/candidate01/manifest.json"),
    "RW01": ("assets/moonlit_citadel/phase3/rework-20261012/rw01/MC_P3_REWORK_KIT.blend", "assets/moonlit_citadel/phase3/rework-20261012/rw01/manifest.json"),
    "AR01": ("assets/moonlit_citadel/phase3/art-repair-20261013/ar01/MC_ART_REPAIR_KIT.blend", "assets/moonlit_citadel/phase3/art-repair-20261013/ar01/manifest.json"),
    "TL01": ("assets/moonlit_citadel/phase3/tower-landscape-20261013/tl01/MC_TOWER_LANDSCAPE_KIT.blend", "assets/moonlit_citadel/phase3/tower-landscape-20261013/tl01/manifest.json"),
    "ER01": ("assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/MC_ENCLOSURE_KIT.blend", "assets/moonlit_citadel/phase3/enclosure-repair-20261013/er01/manifest.json"),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cf(row):
    return Matrix(((row[3],row[4],row[5],row[0]), (row[6],row[7],row[8],row[1]),
                   (row[9],row[10],row[11],row[2]), (0,0,0,1)))


AXIS = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
AXIS_INVERSE = AXIS.inverted()
IMPORT_FLIP = Matrix.Diagonal((-1,1,-1,1))


def scale(values):
    return Matrix.Diagonal((*values,1))


def linear(channel):
    value = channel / 255
    return value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4


def collection(name, parent):
    item = bpy.data.collections.new(name)
    parent.children.link(item)
    return item


material_cache = {}


def material(rgb, role="", emission=0):
    key = (*rgb, role, emission)
    if key in material_cache:
        return material_cache[key]
    mat = bpy.data.materials.new("Inspection_" + role + "_" + "_".join(str(round(v,2)) for v in rgb))
    mat.use_nodes = True
    color = tuple(linear(channel) for channel in rgb) + (1,)
    mat.diffuse_color = color
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = .88 if role in {"Rock","RockA","RockB","Earth","Grass"} else .72
    if role in {"Iron","Brass","Lead"}:
        shader.inputs["Metallic"].default_value = .45
    if emission:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = emission
    material_cache[key] = mat
    return mat


def world_appearance(unit, part):
    role = part["material"]
    rgb = PALETTE.get(role, QUIET.get(role, part["rgb"]))
    if unit.get("materialRole") == "GrandStone":
        rgb = GRAND.get(role,rgb)
    emission = 0
    if unit["asset"] == "MC_WindowGlass":
        if unit.get("materialRole") == "MainKeepWindow":
            rgb,emission = FOCAL.get(role,rgb),1.3
        elif unit.get("materialRole") == "SecondaryWarmWindow":
            rgb,emission = QUIET.get(role,rgb),.55
    return material(rgb,role,emission)


def main():
    assert bpy.app.background, "Use isolated background Blender."
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="source50_01")
    parser.add_argument("--engine", default="CYCLES", choices=["CYCLES","BLENDER_WORKBENCH"])
    parser.add_argument("--samples", type=int, default=16)
    parser.add_argument("--view", action="append")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    assert args.name.replace("_", "").isalnum()
    output = ARTIFACTS / args.name
    assert not output.exists(), "Preserve any earlier inspection; choose a new output name."
    output.mkdir(parents=True)
    started = time.perf_counter()
    plan_packet = json.loads(FINAL_PLAN.read_text())
    units = plan_packet["units"]
    assert len(units) == 233
    old_units = {u["name"]:u for u in json.loads(OLD_PLAN.read_text())["units"]}
    native = json.loads(NATIVE_LAYOUT.read_text())
    input_files = [FINAL_PLAN,OLD_PLAN,NATIVE_LAYOUT,Path(__file__)]
    manifests,export_parts,asset_parts = {},{},{}
    for key,(blend,manifest) in SOURCES.items():
        data = json.loads((ROOT / manifest).read_text())
        manifests[key] = data
        input_files.extend([ROOT / blend, ROOT / manifest])
        for part in data["export_parts"]:
            export_parts[(key,part["name"])] = part
            asset_parts.setdefault((key,part["asset"]), []).append(part)
    inputs_before = {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in input_files}

    def canonical(library,asset):
        if library == "P3":
            return "RW01" if ("RW01",asset) in asset_parts else "C01"
        return library

    # Template rotations come from frozen native Source49, including the legacy BL02/P3 import basis.
    template_rotations = {}
    for p in native["parts"]:
        if not p["path"].startswith("Decoration.Phase3World.") or p["class"] != "MeshPart":
            continue
        pieces = p["path"].split(".")
        unit = old_units[pieces[3]]
        row = cf(unit["localCF"]).to_3x3().inverted() @ cf(p["cf"]).to_3x3()
        key = (canonical(unit["library"],unit["asset"]),pieces[-1])
        if key in template_rotations:
            assert max(abs(row[i][j]-template_rotations[key][i][j]) for i in range(3) for j in range(3)) < .001
        else:
            template_rotations[key] = row

    needed = {}
    for unit in units:
        key = canonical(unit["library"],unit["asset"])
        for part in asset_parts[(key,unit["asset"])]:
            needed.setdefault(key,set()).add(part["name"])
    base_meshes = [p for p in native["parts"] if "Phase3World" not in p["path"] and p["class"] == "MeshPart" and p["transparency"] < 1]
    for p in base_meshes:
        asset = p["attrs"]["SourceAsset"]
        key = "RW01" if ("RW01",asset) in asset_parts else "C01" if ("C01",asset) in asset_parts else "BL02"
        name = p["path"].split(".")[-1]
        assert (key,name) in export_parts,(key,name)
        needed.setdefault(key,set()).add(name)
    source_objects = {}
    for key,names in needed.items():
        with bpy.data.libraries.load(str(ROOT / SOURCES[key][0]),link=False) as (source,destination):
            missing = names - set(source.objects)
            assert not missing,(key,sorted(missing))
            destination.objects = sorted(names)
        for name,obj in zip(sorted(names),destination.objects):
            assert obj.type == "MESH"
            source_objects[(key,name)] = obj

    # The new background process owns this scene; no editor or source .blend is opened or changed.
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj,do_unlink=True)
    scene = bpy.context.scene
    root = collection("MC_Source50_Inspection",scene.collection)
    world_collection = collection("Final_233_World_Units",root)
    protected_collection = collection("Unchanged_Source49_Visible_Course",root)
    camera_collection = collection("Review_Cameras",root)
    light_collection = collection("Approximate_Inspection_Lighting",root)
    centered = {}
    mappings = []
    world_count = 0

    def centered_mesh(key,name):
        identity = (key,name)
        if identity not in centered:
            mesh = source_objects[identity].data.copy()
            mesh.name = "InspectionCentered_" + key + "_" + name
            center = Vector(export_parts[identity]["center"])
            for vertex in mesh.vertices:
                vertex.co -= center
            mesh.materials.clear()
            centered[identity] = mesh
        return centered[identity]

    for unit in units:
        key = canonical(unit["library"],unit["asset"])
        parent = collection(unit["name"],world_collection)
        for part in asset_parts[(key,unit["asset"])]:
            name = part["name"]
            matrix_rotation = template_rotations.get((key,name))
            if matrix_rotation is None:
                matrix_rotation = IMPORT_FLIP.to_3x3() if key in {"ER01","TL01","AR01"} else Matrix.Identity(3)
            origin = Vector(tuple(part["roblox_center"][i] * unit["scale"][i] for i in range(3)))
            local = Matrix.Translation(origin) @ matrix_rotation.to_4x4()
            matrix = AXIS @ cf(unit["localCF"]) @ local @ scale(unit["scale"]) @ IMPORT_FLIP @ AXIS_INVERSE
            obj = bpy.data.objects.new(unit["name"] + "__" + part["material"],centered_mesh(key,name))
            parent.objects.link(obj)
            obj.matrix_world = matrix
            obj.data.materials.append(world_appearance(unit,part)) if len(obj.data.materials) == 0 else None
            obj.material_slots[0].link = "OBJECT"
            obj.material_slots[0].material = world_appearance(unit,part)
            obj["AssetKey"],obj["NativeLibrary"],obj["Source50Unit"] = unit["asset"],unit["library"],unit["name"]
            obj["RobloxLocalCF"],obj["AuthorScale"] = unit["localCF"],unit["scale"]
            world_count += 1
            mappings.append({"unit":unit["name"],"asset":unit["asset"],"library":unit["library"],"sourceBlend":SOURCES[key][0],"sourcePart":name,
                             "robloxLocalCF":unit["localCF"],"scale":unit["scale"],"templateRotation":sum([list(row) for row in matrix_rotation],[]),
                             "blenderMatrix":sum([list(row) for row in matrix],[])})

    base_count,primitive_count = 0,0
    for p in base_meshes:
        asset = p["attrs"]["SourceAsset"]
        key = "RW01" if ("RW01",asset) in asset_parts else "C01" if ("C01",asset) in asset_parts else "BL02"
        name = p["path"].split(".")[-1]
        part = export_parts[(key,name)]
        size = [p["size"][i] / part["roblox_size"][i] for i in range(3)]
        matrix = AXIS @ cf(p["cf"]) @ scale(size) @ IMPORT_FLIP @ AXIS_INVERSE
        obj = bpy.data.objects.new("Accepted_"+p["path"],centered_mesh(key,name))
        protected_collection.objects.link(obj)
        obj.matrix_world = matrix
        emission = 1.2 if p["material"] == "Neon" else 0
        mat = material(tuple(channel * 255 for channel in p["color"]),part["material"],emission)
        if not obj.data.materials:
            obj.data.materials.append(mat)
        obj.material_slots[0].link = "OBJECT"
        obj.material_slots[0].material = mat
        obj["FrozenNativePart"] = p["path"]
        base_count += 1
    for p in native["parts"]:
        if "Phase3World" in p["path"] or p["class"] == "MeshPart" or p["transparency"] >= 1:
            continue
        bpy.ops.mesh.primitive_cube_add(size=1)
        obj = bpy.context.object
        for coll in list(obj.users_collection):
            coll.objects.unlink(obj)
        protected_collection.objects.link(obj)
        obj.name = "AcceptedPrimitive_" + p["path"]
        obj.matrix_world = AXIS @ cf(p["cf"]) @ scale(p["size"]) @ AXIS_INVERSE
        obj.data.materials.append(material(tuple(channel*255 for channel in p["color"]),p["material"],1.2 if p["material"]=="Neon" else 0))
        obj["FrozenNativePart"],obj["InspectionShapeBoundary"] = p["path"],"Native Part box; attached GUI lettering not reconstructed"
        primitive_count += 1

    scene.render.engine = args.engine
    if args.engine == "CYCLES":
        scene.cycles.samples = args.samples
        scene.cycles.use_denoising = True
        scene.cycles.use_adaptive_sampling = True
        scene.cycles.adaptive_threshold = .04
    scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage = 1600,1000,100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast" if "Medium High Contrast" in [i.name for i in scene.bl_rna.properties] else "None"
    scene.view_settings.exposure = .65
    scene.world = bpy.data.worlds.new("Source50_Inspection_World")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    sun_data = bpy.data.lights.new("Inspection_Sun","SUN")
    sun = bpy.data.objects.new("Inspection_Sun",sun_data)
    light_collection.objects.link(sun)
    sun.rotation_euler = (math.radians(28),math.radians(-35),math.radians(-35))
    sun_data.angle = math.radians(15)
    for name,point in [("Gate",(-144,3,146)),("CP01",(-144,31,-112)),("CP02",(-80,55,28)),("CP03",(112,75,-52)),("CP04",(112,109,-86)),("Crown",(-8,153,-30))]:
        light = bpy.data.lights.new("Inspection_Warm_"+name,"POINT")
        light.energy,light.color,light.shadow_soft_size = 450, (1,.62,.28),6
        obj = bpy.data.objects.new(light.name,light)
        light_collection.objects.link(obj)
        obj.location = AXIS @ Vector(point)

    views = [
        ("01-crown-east-southeast-standing",(-8,155.5,-30),(172,124,4),70,"night"),
        ("02-crown-east-southeast-standing-day",(-8,155.5,-30),(172,124,4),70,"day"),
        ("03-crown-southwest-standing",(-23.5,155.5,-18.5),(-140,85,115),70,"night"),
        ("04-gallery-reseated-glass-standing",(-60,57.5,46),(18,65,78),70,"night"),
        ("05-west-cp01-window-cliff",(-144,33.5,-112),(-252,50,-80),70,"night"),
        ("06-upper-machinery-windows",(112,111.5,-86),(225,135,-100),70,"night"),
        ("07-upper-keep-crown-windows",(-8,155.5,-30),(-8,169,-60),70,"night"),
        ("08-cliffs-cp02-reverse",(-80,57.5,28),(-155,113,-135),70,"day"),
        ("09-overall-fortress-landscape",(-510,400,450),(0,55,-10),70,"day"),
    ]
    rendered = []
    for name,position,target,fov,profile in views:
        if args.view and name not in args.view:
            continue
        data = bpy.data.cameras.new(name)
        camera = bpy.data.objects.new(name,data)
        camera_collection.objects.link(camera)
        camera.location = AXIS @ Vector(position)
        camera.rotation_euler = (AXIS @ Vector(target) - camera.location).to_track_quat("-Z","Y").to_euler()
        data.type,data.sensor_fit,data.clip_start,data.clip_end = "PERSP","VERTICAL",.05,3000
        data.angle_y = math.radians(fov)
        camera["RobloxCourseLocalPosition"],camera["RobloxCourseLocalTarget"],camera["VerticalFOV"] = position,target,fov
        scene.camera = camera
        if profile == "night":
            background.inputs["Color"].default_value = (.14,.20,.32,1)
            background.inputs["Strength"].default_value = .55
            sun_data.energy,sun_data.color = .8,(.60,.72,1)
            scene.world.color = (.035,.055,.10)
        else:
            background.inputs["Color"].default_value = (.48,.56,.67,1)
            background.inputs["Strength"].default_value = .7
            sun_data.energy,sun_data.color = 2,(1,.94,.86)
            scene.world.color = (.25,.33,.45)
        if args.engine == "BLENDER_WORKBENCH":
            scene.display.shading.light = "STUDIO"
            scene.display.shading.color_type = "MATERIAL"
            scene.display.shading.show_shadows = True
            scene.display.shading.show_cavity = True
            scene.display.shading.background_type = "WORLD"
        scene.render.filepath = str(output/(name+".png"))
        print("RENDER_START "+name,flush=True)
        bpy.ops.render.render(write_still=True)
        rendered.append({"name":name,"file":name+".png","profile":profile,"positionCourseLocal":position,"targetCourseLocal":target,"verticalFOV":fov,"bytes":(output/(name+".png")).stat().st_size,"sha256":sha(output/(name+".png"))})
        print("RENDER_DONE "+name,flush=True)

    blend_file = output / "MC_P3_CLOSEOUT_SOURCE50.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_file))
    changed = [str(p.relative_to(ROOT)) for p in input_files if sha(p)!=inputs_before[str(p.relative_to(ROOT)).replace('\\','/')]]
    assert not changed,changed
    report = {"candidate":"Source50 draft; final 233-unit plan", "blenderVersion":bpy.app.version_string,"unitCount":len(units),"worldMaterialParts":world_count,
              "acceptedVisibleMeshParts":base_count,"acceptedVisibleNativePrimitiveParts":primitive_count,"inputHashes":inputs_before,"sourceFilesPreserved":not changed,
              "axis":"Blender=(Roblox.X,-Roblox.Z,Roblox.Y); inverse Roblox=(Blender.X,Blender.Z,-Blender.Y)",
              "placement":"Per material-centred export mesh with frozen native template rotations and FBX basis compensation; final CF and scale applied exactly.",
              "courseBoundary":"Unchanged Source49 visible native geometry supplies course context. Native Part shapes are boxes; attached GUI text and runtime motion are not reproduced.",
              "renderBoundary":"Unretouched Blender composition inspection. Lighting, enum textures, sky/effects, GUI lettering and runtime motion are not native Roblox proof.",
              "engine":args.engine,"samples":args.samples,"nativeVisualProof":False,"studioTouched":False,"liveBlenderTouched":False,"newAssetOrUpload":False,
              "blend":{"file":blend_file.name,"bytes":blend_file.stat().st_size,"sha256":sha(blend_file)},"views":rendered,"assemblyMapping":mappings,"elapsedSeconds":round(time.perf_counter()-started,2)}
    (output/"assembly-camera-mapping.json").write_text(json.dumps(report,indent=2)+"\n")
    print("ASSEMBLY_COMPLETE "+json.dumps({"output":str(output),"units":len(units),"worldParts":world_count,"acceptedMeshParts":base_count,"visibleParts":primitive_count,"views":len(rendered),"seconds":report["elapsedSeconds"]}),flush=True)


if __name__ == "__main__":
    main()
