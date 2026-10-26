"""SGV2 M02 crop silhouettes; retains the reviewed M01 kit and source unchanged."""
from pathlib import Path
source = Path(__file__).with_name("build_sample_kit.py").read_text()
exec(compile(source.split("# Pot is a hollow revolved profile")[0], str(Path(__file__).with_name("build_sample_kit.py")), "exec"))
REVISION = "SGV2_M02"


def revolved(name, rings, x, y, material, sides=10, rotation=0):
    vertices=[(x+r*math.cos(a*math.tau/sides+rotation),y+r*math.sin(a*math.tau/sides+rotation),z) for r,z in rings for a in range(sides)]
    faces=[]
    for j in range(len(rings)-1):
        for a in range(sides):
            faces.append((j*sides+a,j*sides+(a+1)%sides,(j+1)*sides+(a+1)%sides,(j+1)*sides+a))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(rings)-1)*sides,len(rings)*sides))])
    return mesh(name, vertices, faces, material)


for i,(x,y,s) in enumerate([(-1.1,0,1),(1.2,0.7,0.83),(0,-1.2,0.7)]):
    rings=[(0.13*s,0.05),(0.55*s,0.55*s),(1.04*s,1.35*s),(1.18*s,2.1*s),(0.88*s,2.72*s),(0.4*s,2.85*s)]
    revolved("TaperedStrawberry",rings,x,y,"red",10,i*0.2)
    for j in range(5):
        a=j*math.tau/5+i*0.3
        blade((x,y,2.78*s),(math.cos(a),math.sin(a),-0.12),1.65*s,0.83*s,"leaf",0.18)
    for row,(radius,z) in enumerate([(0.61,0.73),(1.08,1.65),(1.04,2.28)]):
        for j in range(7):
            a=j*math.tau/7+row*0.43
            block((x+(radius+0.025)*s*math.cos(a),y+(radius+0.025)*s*math.sin(a),z*s),
                  (0.16*s,0.11*s,0.27*s),"seed",0,(0,0,a+math.pi/2))
finish_asset("BerryTuft",1,"Soil center; pointed fruits face all directions; decoration only",[0.85,1.4])

for i,(x,y,h) in enumerate([(-0.95,0,3.5),(1.1,0.8,2.9)]):
    revolved("PointedCarrot",[(0.09,-0.35),(0.25,h*0.15),(0.66,h*0.52),(0.95,h*0.88),(0.8,h)],x,y,"orange",8,i*0.2)
    for j in range(6):
        a=j*math.tau/6+i*0.4
        blade((x,y,h-0.08),(math.cos(a)*0.48,math.sin(a)*0.48,0.9),2.8+(j%2)*0.5,0.88,"leaf" if j%2 else "lime",0.3)
finish_asset("CarrotPair",2,"Soil center; bury pointed roots by0.35; decoration only",[0.8,1.4])

block((204,0,5),(10,10,10),"seed")
finish_asset("Calibration10",0,"10x10x10 import scale witness at authoredX204",[1,1])
assets[-1]["origin"]=[204,0,0]
all_meshes=[obj for obj in bpy.context.scene.objects if obj.type=="MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in all_meshes: obj.select_set(True)
bpy.context.view_layer.objects.active=all_meshes[0]
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f"{REVISION}.blend"))
bpy.ops.export_scene.fbx(filepath=str(ROOT/f"{REVISION}.fbx"),use_selection=True,object_types={"MESH"},
                        apply_unit_scale=True,axis_forward="-Z",axis_up="Y",path_mode="COPY",embed_textures=False,bake_anim=False)
manifest={"revision":REVISION,"units":"authored studs; verify Calibration10", "assets":assets,
          "materials":PALETTE,"meshObjects":len(all_meshes),"triangles":sum(a["triangles"] for a in assets),
          "provenance":"Original geometry; no third-party asset or texture","textures":0}
(ROOT/f"{REVISION}.json").write_text(json.dumps(manifest,indent=2)+"\n")
for asset in assets:
    for name in asset["parts"]:
        obj=bpy.data.objects[name]
        if asset["name"]=="Calibration10": obj.hide_render=True
        else: obj.location.x-=asset["origin"][0]+(5 if asset["name"]=="BerryTuft" else -5)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-0.4))
floor=bpy.context.object; mat=bpy.data.materials.new("PreviewBackdrop"); mat.diffuse_color=(0.7,0.68,0.6,1); floor.data.materials.append(mat)
bpy.ops.object.camera_add(location=(11,-22,13))
camera=bpy.context.object; camera.rotation_euler=(Vector((0,0,2.3))-camera.location).to_track_quat("-Z","Y").to_euler()
camera.data.type="ORTHO"; camera.data.ortho_scale=20; bpy.context.scene.camera=camera
bpy.ops.object.light_add(type="AREA",location=(-8,-10,20)); bpy.context.object.data.energy=4500; bpy.context.object.data.size=18
scene=bpy.context.scene; scene.world.color=(0.65,0.65,0.65); scene.render.engine="CYCLES"; scene.cycles.samples=24
scene.render.resolution_x=1500; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"; scene.render.filepath=str(ROOT/f"{REVISION}-inspection.png"); scene.view_settings.view_transform="Standard"
bpy.ops.render.render(write_still=True)
print(json.dumps({"revision":REVISION,"meshes":len(all_meshes),"triangles":manifest["triangles"]}))
