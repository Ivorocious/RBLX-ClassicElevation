"""Render accepted crown edge cameras and retain exact mesh sightline hits."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix,Vector

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "default.project.json").exists())
AXIS = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INVERSE = AXIS.inverted()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert bpy.app.background
    parser = argparse.ArgumentParser()
    parser.add_argument("--source",required=True)
    parser.add_argument("--output",required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    source,out = (ROOT / args.source).resolve(),(ROOT / args.output).resolve()
    assert source.is_relative_to(ROOT) and out.is_relative_to(ROOT)
    assert source.is_file() and not out.exists()
    source_hash = sha(source)
    out.mkdir(parents=True)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if hasattr(bpy.context.preferences.filepaths,"use_save_preview"):
        bpy.context.preferences.filepaths.use_save_preview = False
    scene = bpy.context.scene
    camera_collection = bpy.data.collections["Review_Cameras"]
    scene.cycles.samples = 12
    sun = bpy.data.lights["Inspection_Sun"]
    background = scene.world.node_tree.nodes["Background"]
    rays,views = [],[]
    poses = [
        ("east",(8,155.5,-30),(150,80,65),[(150,80,65),(210,115,150),(100,110,-50),(280,130,150),(50,90,90)]),
        ("south",(-8,155.5,-18),(56,80,94),[(56,80,94),(-36,50,55),(-144,50,110),(30,80,60),(100,50,80)]),
    ]
    graph = bpy.context.evaluated_depsgraph_get()
    for name,pos,focus,targets in poses:
        for target in targets:
            origin = AXIS @ Vector(pos)
            aim = AXIS @ Vector(target)
            delta = aim-origin
            hit,point,normal,index,obj,matrix = scene.ray_cast(graph,origin,delta.normalized(),distance=delta.length)
            record = {"camera":name,"positionCourseLocal":pos,"targetCourseLocal":target,"hit":hit}
            if hit:
                mesh = obj.evaluated_get(graph).data
                polygon = mesh.polygons[index]
                vertices = [tuple(INVERSE @ (matrix @ mesh.vertices[i].co)) for i in polygon.vertices]
                record.update({"object":obj.name,"source50Unit":obj.get("Source50Unit"),"asset":obj.get("AssetKey"),
                               "nativeProtectedPart":obj.get("FrozenNativePart"),"faceIndex":index,
                               "courseLocalHit":tuple(INVERSE @ point),"courseLocalPolygonVertices":vertices,
                               "materialSlot":polygon.material_index,"distanceStuds":(point-origin).length})
            rays.append(record)
        for profile in ["night","day"]:
            view_name = "crown-"+name+"-accepted-edge-"+profile
            data = bpy.data.cameras.new(view_name)
            camera = bpy.data.objects.new(view_name,data)
            camera_collection.objects.link(camera)
            camera.location = AXIS @ Vector(pos)
            camera.rotation_euler = (AXIS @ Vector(focus)-camera.location).to_track_quat("-Z","Y").to_euler()
            data.type,data.sensor_fit,data.clip_start,data.clip_end = "PERSP","VERTICAL",.05,3000
            data.angle_y = math.radians(70)
            camera["RobloxCourseLocalPosition"],camera["RobloxCourseLocalTarget"] = pos,focus
            camera["ActualAcceptedFloor"] = "Centre(-8,150,-30),size36x28; camera2studsinsideedge"
            scene.camera = camera
            if profile == "night":
                background.inputs["Color"].default_value = (.14,.20,.32,1)
                background.inputs["Strength"].default_value = .55
                sun.energy,sun.color = .8,(.60,.72,1)
            else:
                background.inputs["Color"].default_value = (.48,.56,.67,1)
                background.inputs["Strength"].default_value = .7
                sun.energy,sun.color = 2,(1,.94,.86)
            file = out/(view_name+".png")
            scene.render.filepath = str(file)
            print("RENDER_START "+view_name,flush=True)
            bpy.ops.render.render(write_still=True)
            views.append({"name":view_name,"file":file.name,"positionCourseLocal":pos,"targetCourseLocal":focus,"verticalFOV":70,"profile":profile,"sha256":sha(file),"bytes":file.stat().st_size})
            print("RENDER_DONE "+view_name,flush=True)
    blend = out / "MC_P3_CLOSEOUT_SOURCE50_EDGE_VIEWS.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    assert sha(source) == source_hash
    report = {"sourceBlend":str(source.relative_to(ROOT)),"sourceBlendSHA256":source_hash,"sourcePreserved":True,
              "geometryMoved":False,"floorMoved":False,"nativeProof":False,
              "boundary":"Unretouched isolated Blender composition with approximate lighting; ray hits identify assembled mesh polygons, pending matching native inspection.",
              "views":views,"rays":rays,"blend":{"file":blend.name,"sha256":sha(blend),"bytes":blend.stat().st_size},"scriptSHA256":sha(Path(__file__))}
    (out/"edge-view-and-face-report.json").write_text(json.dumps(report,indent=2)+"\n")
    print("CROWN_EDGE_COMPLETE "+json.dumps({"views":len(views),"rays":len(rays),"output":str(out)}),flush=True)


if __name__ == "__main__":
    main()
