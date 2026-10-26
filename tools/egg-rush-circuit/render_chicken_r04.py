"""Reconstruct the native chicken and native sampled controller poses."""
import importlib.util
import json
import runpy
from pathlib import Path
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("course_renderer",HERE/"render_revision_r02.py")
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)

def views(scene,camera,output):
    (output/"animation").mkdir(exist_ok=True)
    pose_data=json.loads((output.parent/"native-pose-frames.json").read_text())
    objects={o.get("NativePath"):o for o in scene.objects if o.get("NativePath")}
    prefix="Obstacles.Mechanisms.GuardianPeck."
    groups={
        "Body":[o for p,o in objects.items() if p.startswith(prefix+"Body.")],
        "Head":[o for p,o in objects.items() if p.startswith(prefix+"Head.")],
        "FootLeft":[o for p,o in objects.items() if p.startswith(prefix+"Feet.Left.")],
        "FootRight":[o for p,o in objects.items() if p.startswith(prefix+"Feet.Right.")],
        "NeckLower":[objects[prefix+"NeckLower"]],
        "NeckUpper":[objects[prefix+"NeckUpper"]],
    }
    homes={o.name:o.matrix_world.copy() for members in groups.values() for o in members}
    group_homes={key:base.native_frame(frame) for key,frame in zip(pose_data["groups"],pose_data["home"])}
    def pose(row):
        for key,frame in zip(pose_data["groups"],row["pose"]):
            delta=base.native_frame(frame)@group_homes[key].inverted()
            for obj in groups[key]:obj.matrix_world=delta@homes[obj.name]
        for index,color in enumerate(row.get("markers",[]),1):
            obj=objects.get("Decoration.RevisionR03.PeckTarget"+str(index))
            if obj:obj.material_slots[0].material=base.material(color,1,False)
    records=[]
    def render(name,target,offset,scale,width=1280):
        scene.render.resolution_x,scene.render.resolution_y=width,int(width*.7)
        camera.location=base.R_TO_B@(Vector(target)+Vector(offset))
        base.look_at(camera,base.R_TO_B@Vector(target));camera.data.ortho_scale=scale
        scene.render.filepath=str(output/(name+".png"));bpy.ops.render.render(write_still=True)
        records.append(dict(name=name,path=scene.render.filepath))
    render("01-chicken-home",(102,35,43),(60,35,90),110)
    render("02-chicken-side",(102,35,43),(95,25,0),108)
    for impact in pose_data["impacts"]:
        pose(impact);render("03-peck-target-"+str(impact["target"]),(105,32,43),(60,35,90),112)
    for index,row in enumerate(pose_data["frames"]):
        pose(row);render("animation/frame_%03d"%index,(105,34,43),(60,35,90),128,720)
    pose({"pose":pose_data["home"]})
    records.append(dict(name="native-pose-animation",frames=len(pose_data["frames"]),seconds=pose_data["frames"][-1]["time"],
                        boundary="Native controller transforms reconstructed in Blender, not a native Studio recording."))
    return records

base.render_views=views
if __name__=="__main__":
    runpy.run_path(str(base.REPO/"assets/egg_rush_circuit/phase2/chicken_r04/verify_saved_chicken.py"),run_name="__main__")
    base.main()
