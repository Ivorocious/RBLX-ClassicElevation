"""Author an articulated block chicken with a tucked, short neck."""
from __future__ import annotations
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import runpy
import time
import bpy
from mathutils import Euler, Matrix, Vector

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
OUT=HERE/"candidate_a02"
MODULE=REPO/"src/ServerStorage/CourseBuilders/EggRush/RestartP2/ChickenKit.luau"
BUILD="ER_CHICKEN_R04_A02"
spec=importlib.util.spec_from_file_location("native_box_kit",HERE.parent/"revision_r02/hazards/build_hazard_kit.py")
kit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)
kit.PALETTE={"Cream":(255,242,210),"Feather":(248,228,181),"Coral":(246,112,86),
             "Hot":(255,20,35),"Ink":(27,30,38),"Ivory":(255,253,238),"Foot":(239,155,68)}

def B(name,size,position,role="Cream",rx=0,ry=0,rz=0):
    return dict(name=name,size=size,position=position,role=role,angle=rz,angles=(rx,ry,rz))

TEMPLATES={
 "Body":[
  B("PearTorso",(35,25,33),(-5,15,0)),
  B("RoundRump",(19,21,28),(-16,15,0)),
  B("LowerBelly",(27,14,27),(-4,8,0)),
  B("ShoulderMantle",(27,14,30),(-1,24,0)),
  B("LowerBreast",(9,14,26),(7.5,17,0)),
  B("UpperBreastPuff",(10,9,26),(10,29.5,0)),
 ],
 "Head":[
  B("BroadHead",(16,10,14),(0,2,0)),
  B("CheekPuff",(14.4,4,8),(0,-4,3)),
  B("CombRoot",(3.5,1.6,13),(0,7.5,0),"Coral"),
  B("CombFront",(3.3,5.5,2.8),(0,10.6,-4.8),"Coral"),
  B("CombFrontHigh",(3.3,7.8,2.8),(0,11.75,-2.4),"Coral"),
  B("CombCrown",(3.3,9.3,2.8),(0,12.5,0),"Coral"),
  B("CombBackHigh",(3.3,7.3,2.8),(0,11.5,2.4),"Coral"),
  B("CombBack",(3.3,5.2,2.8),(0,10.45,4.8),"Coral"),
  B("Beak",(6,3,3),(0,-2,-8.5),"Hot"),
  B("WattleLeft",(2.6,4.3,2),(-2,-4.9,-5.2),"Coral",rz=-8),
  B("WattleRight",(2.6,4.3,2),(2,-4.9,-5.2),"Coral",rz=8),
 ],
 "Feet":[],
}
for side in (-1,1):
    TEMPLATES["Body"].extend([
     B(f"WingShoulder{side}",(21,11,3.3),(-4.5,19,side*16.5),"Cream",rz=-8),
     B(f"WingMiddleFeather{side}",(10,11,3.2),(-4,13.5,side*17.1),"Feather",rz=-12),
     B(f"WingRearFeather{side}",(10,9,3.2),(-12,14.4,side*17.1),"Feather",rz=-16),
    ])
    TEMPLATES["Feet"].extend([
     B(f"Leg{side}",(5,7.5,5),(0,3.4,side*8),"Foot"),
     B(f"Foot{side}",(12,3.2,7),(5.5,-.4,side*8),"Foot"),
     B(f"OuterToe{side}",(8,2.5,2.2),(13,0,side*8+side*2.7),"Foot",ry=side*7),
     B(f"MiddleToe{side}",(9.4,2.5,2.2),(13.8,0,side*8),"Foot"),
     B(f"InnerToe{side}",(8,2.5,2.2),(13,0,side*8-side*2.7),"Foot",ry=-side*7),
    ])
    TEMPLATES["Head"].extend([
     B(f"EyeWhite{side}",(4.3,4.7,.4),(side*7.9,2,-7.1),"Ivory",ry=-side*45),
     B(f"Pupil{side}",(2.4,3,.45),(side*8.15,1.9,-7.35),"Ink",ry=-side*45),
    ])
for index,(z,height,tilt) in enumerate([(-10,17,-20),(-5.2,22,-10),(0,25,0),(5.2,22,10),(10,17,20)],1):
    TEMPLATES["Body"].append(B(f"FanTail{index}",(4.5,height,5.2),(-23,20+height*.12,z),
                                  "Feather" if index%2 else "Cream",rx=tilt,rz=18))

ATTACHMENTS={"bodyFront":"+X","headFront":"-Z","shoulder":[18,25,0],
             "beakTip":[0,-2,-10],"headNeck":[0,-5,3],"headHome":[27,31,0],
             "neckLinkLength":6,"neckWidth":9,"hipCourse":[91,18,40]}

def create(parent,spec,mats):
    obj=kit.create_box(bpy.context.scene,parent,spec,mats)
    native=Euler(tuple(math.radians(a) for a in spec["angles"]),"XYZ").to_matrix()
    obj.rotation_euler=(kit.AXES@native@kit.INVERSE_AXES).to_euler()
    return obj

def look(camera,target):
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()

def preview_neck(scene,mats):
    anchor=Vector(ATTACHMENTS["shoulder"])
    # Head home faces native +X after a -90 degree native Y rotation.
    head_rot=Euler((0,-math.pi/2,0),"XYZ").to_matrix()
    end=Vector(ATTACHMENTS["headHome"])+head_rot@Vector(ATTACHMENTS["headNeck"])
    span=end-anchor
    direction=span.normalized()
    up=Vector((0,1,0));bend=(up-direction*up.dot(direction)).normalized()
    elbow=(anchor+end)/2+bend*math.sqrt(6**2-span.length_squared/4)
    group=bpy.data.objects.new("PreviewShortNeck",None);scene.collection.objects.link(group)
    group["PreviewOnly"]="Runtime builds these two links from the attachment contract."
    for name,a,b in [("PreviewNeckLower",anchor,elbow),("PreviewNeckUpper",elbow,end)]:
        spec=B(name,(9,6,9),(a+b)/2)
        obj=create(group,spec,mats)
        y=(b-a).normalized();x=y.cross(Vector((0,0,1))).normalized();z=x.cross(y).normalized()
        native=Matrix(((x.x,y.x,z.x),(x.y,y.y,z.y),(x.z,y.z,z.z)))
        obj.rotation_euler=(kit.AXES@native@kit.INVERSE_AXES).to_euler()

def main():
    started=time.perf_counter()
    OUT.mkdir(parents=True,exist_ok=True)
    assert not (OUT/"chicken_kit.blend").exists(),"Choose a fresh candidate folder."
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene;scene.name=BUILD
    mats={role:kit.material(role,rgb,role=="Hot",False) for role,rgb in kit.PALETTE.items()}
    records={}
    roots={}
    for key,definitions in TEMPLATES.items():
        root=bpy.data.objects.new(key,None);scene.collection.objects.link(root);roots[key]=root
        root["TemplateKey"]=key
        objects=[create(root,s,mats) for s in definitions]
        bpy.context.view_layer.update()
        exported,corners=[],[]
        for obj in objects:
            record,points=kit.inspect_part(obj);exported.append(record);corners.extend(points)
        low=kit.rounded(min(p[i] for p in corners) for i in range(3))
        high=kit.rounded(max(p[i] for p in corners) for i in range(3))
        records[key]={"partCount":len(exported),"lethalPartCount":sum(p["lethal"] for p in exported),
                      "boundsRoblox":[low,high],"parts":exported}
    assert sum(r["partCount"] for r in records.values())<=60
    kit.export_module(MODULE,records)
    module=MODULE.read_text(encoding="utf8").replace("HazardKit","ChickenKit").replace(
        "revision_r02/hazards/build_hazard_kit.py","chicken_r04/build_chicken.py")
    module=module.replace("Unknown Egg Rush hazard:","Unknown chicken template:")
    MODULE.write_text(module,encoding="utf8")
    manifest={"build":BUILD,"templates":records,"attachments":ATTACHMENTS,"palette":kit.PALETTE,
              "axes":"Roblox X,Y,Z -> Blender X,-Z,Y","checks":{"finite":True,"closedManifold":True,"positiveVolume":True,"orthonormalFrames":True},
              "proofBoundary":"Blender-authored native primitive kit and isolated assembly; no Studio movement/contact/camera proof."}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf8")
    roots["Head"].location=kit.AXES@Vector(ATTACHMENTS["headHome"])
    native=Euler((0,-math.pi/2,0),"XYZ").to_matrix()
    roots["Head"].rotation_euler=(kit.AXES@native@kit.INVERSE_AXES).to_euler()
    preview_neck(scene,mats)
    floor=create(None,B("PreviewFloor",(120,.3,90),(0,-2.2,0),"Ink"),mats)
    floor["PreviewOnly"]="Isolated studio floor; not exported to Roblox."
    scene.render.engine="BLENDER_EEVEE"
    scene.render.resolution_x,scene.render.resolution_y=1280,1024
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.view_settings.view_transform="AgX"
    scene.world=bpy.data.worlds.new("ChickenStudio");scene.world.use_nodes=True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value=(.12,.16,.21,1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.65
    for name,pos,power,size in [("BroadKey",(25,-45,80),95000,70),("Fill",(-40,30,50),45000,60)]:
        data=bpy.data.lights.new(name,"AREA");data.energy=power;data.shape="DISK";data.size=size
        light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=pos
        look(light,kit.AXES@Vector((0,20,0)))
    camera_data=bpy.data.cameras.new("ChickenCamera");camera_data.type="ORTHO";camera_data.ortho_scale=94
    camera=bpy.data.objects.new("ChickenCamera",camera_data);scene.collection.objects.link(camera);scene.camera=camera
    scene["Candidate"]=BUILD;scene["EvidenceBoundary"]=manifest["proofBoundary"]
    bpy.context.preferences.filepaths.save_version=0
    views=[("chicken_three_quarter",(85,48,85)),("chicken_profile",(0,31,110)),("chicken_front",(110,35,0))]
    for name,position in views:
        camera.location=kit.AXES@Vector(position);look(camera,kit.AXES@Vector((0,22,0)))
        scene.render.filepath=str(OUT/(name+".png"));bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"chicken_kit.blend"))
    files=[MODULE,OUT/"manifest.json",OUT/"chicken_kit.blend"]+[OUT/(name+".png") for name,_ in views]
    report={"build":BUILD,"parts":sum(r["partCount"] for r in records.values()),"templates":len(records),
            "seconds":round(time.perf_counter()-started,3),"hashes":{str(p.relative_to(REPO)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
    (OUT/"build_report.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
    print("CHICKEN_KIT_BUILD "+json.dumps(report))
    runpy.run_path(str(HERE/"verify_saved_chicken.py"),run_name="__main__")

if __name__=="__main__":main()
