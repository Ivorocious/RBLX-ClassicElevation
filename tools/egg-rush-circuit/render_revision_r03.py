"""Review native R03 geometry and native sampled peck poses in one background process."""
import importlib.util
import json
from pathlib import Path
import sys
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("r02_renderer",HERE/"render_revision_r02.py")
base=importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

def views(scene,camera,output):
    scene.render.resolution_x,scene.render.resolution_y=1280,896
    scene.render.engine="BLENDER_EEVEE"
    poses=json.loads((output.parent/"native-peck-pose-frames.json").read_text())
    objects={o.get("NativePath"):o for o in scene.objects if o.get("NativePath")}
    home={path:o.matrix_world.copy() for path,o in objects.items() if "GuardianPeck" in path}
    records=[]
    def render(name,target,offset,scale):
        camera.location=base.R_TO_B@(Vector(target)+Vector(offset))
        base.look_at(camera,base.R_TO_B@Vector(target))
        camera.data.ortho_scale=scale
        scene.render.filepath=str(output/(name+".png"))
        bpy.ops.render.render(write_still=True)
        records.append(dict(name=name,path=scene.render.filepath,target_roblox=target,offset_roblox=offset,ortho_scale=scale))
    render("00-whole-course",(0,22,6),(300,330,390),400)
    render("01-readable-hazards",(-66,6,100),(40,40,55),72)
    render("02-clear-incubator",(55,30,-87),(55,46,65),100)
    render("03-peck-home",(104,41,42),(52,37,82),115)
    for pose in poses["poses"]:
        for path,frame in pose["parts"].items():
            objects[path].matrix_world=base.native_frame(frame)
        render("04-peck-target-"+str(pose["target"]),(108,33,43),(52,37,82),115)
    for path,frame in home.items():objects[path].matrix_world=frame
    render("05-start-lap",(-4,7,90),(42,24,35),74)
    return records

base.render_views=views
if __name__=="__main__":base.main()
