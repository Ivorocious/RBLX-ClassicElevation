"""Reusable Egg Rush surroundings; isolated Blender build, no Studio or uploads."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import sys
import time
from pathlib import Path

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
HELPER=ROOT.parent/"phase1"/"build_kit.py"
spec=importlib.util.spec_from_file_location("egg_rush_kit_helpers",HELPER)
kit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)
Geo=kit.Geo
BUILD="ER_WORLD_KIT_C03"
PALETTE={**kit.PALETTE,"Rock":"868993","RockShade":"707580",
         "Green":"63C448","GreenShade":"4BA83B","Window":"4C9EC4"}


def prism(geo,polygon,depth,role,cy=0):
    n=len(polygon)
    vertices=[(x,cy+y,z) for y in (-depth/2,depth/2) for x,z in polygon]
    geo.mesh(vertices,[tuple(reversed(range(n))),tuple(n+i for i in range(n))]+
             [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],role)


def arch(geo,width=10,spring=5,thickness=1.4,depth=2.4,role="Mint",cx=0,cy=0,z=0):
    outer=width/2;inner=outer-thickness
    for side in (-1,1):
        geo.box((cx+side*(outer+inner)/2,cy,z+spring/2),(thickness,depth,spring),role)
    for i in range(10):
        a,b=i*math.pi/10,(i+1)*math.pi/10
        polygon=[(cx+r*math.cos(t),z+spring+r*math.sin(t))
                 for r,t in [(outer,a),(outer,b),(inner,b),(inner,a)]]
        prism(geo,polygon,depth,role,cy)


def support(name,width=10,depth=6,height=20,cap=True):
    geo=Geo()
    crown=.55 if cap else 0
    loops=[kit.square_loop(width,depth,-height,chamfer=.17),
           kit.square_loop(width*.91,depth*.94,-height*.48,chamfer=.14),
           kit.square_loop(width*.82,depth*.77,-crown,chamfer=.12)]
    geo.loops(loops,"Rock")
    if cap:
        geo.loops([kit.square_loop(width*.86,depth*.83,-crown,chamfer=.1),
                   kit.square_loop(width*.86,depth*.83,0,chamfer=.1)],"Green")
    kit.asset(name,"Supports",geo,
              "TOP CENTER at0. Rock extends down; green cap topBlenderZ0 =RobloxY0.",
              "One isolated support per cream pad; outer bottom footprint equals authored width/depth. Scale height about top pivot; cap narrower than pad.")


def shrub():
    geo=Geo()
    # Three broad connected crowns; every block is a major part of the silhouette.
    for x,y,w,d,h in [(-2.7,0,3.3,3.6,3.8),(0,.45,4,4.2,6.1),(2.8,.35,3.4,3.4,4.5)]:
        geo.box((x,y,h/2),(w,d,h),"GreenShade")
        geo.box((x,y,h-.2),(w*.8,d*.82,1.4),"Green")
    kit.asset("ShrubGroup","Nature",geo,"Bottom center; authored width8.85,height6.6,depth4.2.",
              "Six large blocks in three connected crowns. Keep below route sightlines and away from jump gaps.")


def nursery():
    geo=Geo()
    # The arch remains a real opening through the wall, rather than a dark door sticker.
    for side in (-1,1):
        geo.box((side*5.5,0,4.7),(3,2.4,9.4),"Shell")
    for i in range(10):
        a,b=i*math.pi/10,(i+1)*math.pi/10
        xa,za=4*math.cos(a),4+4*math.sin(a)
        xb,zb=4*math.cos(b),4+4*math.sin(b)
        prism(geo,[(xa,za),(xb,zb),(xb,9.4),(xa,9.4)],2.4,"Shell")
    arch(geo,width=8,spring=4,thickness=.8,depth=2.5,role="Coral")
    geo.box((0,0,9.6),(14.8,3.1,.8),"Coral")
    geo.box((0,0,10.2),(6.5,2.9,.5),"Coral")
    kit.asset("NurseryWallBay","Buildings",geo,"Bottom center; facade faces Blender-Y /Roblox+Z.",
              "Cream facade with actual arched opening and simple coral roofline; no paving lines, studs or small trim.")
    geo=Geo()
    arch(geo,width=10,spring=5,thickness=1.4,depth=3,role="Mint")
    kit.asset("MintPipeArch","Buildings",geo,"Bottom center; opening7.2 wide; springBlenderZ5,peak inner8.6.",
              "Thick mint arch for nursery pipe housing; ten broad arc segments; true opening.")
    geo=Geo()
    arch(geo,width=8,spring=4,thickness=.9,depth=1.2,role="Mint")
    polygon=[(-3.1,0),(3.1,0),(3.1,4)]+[(3.1*math.cos(i*math.pi/10),4+3.1*math.sin(i*math.pi/10)) for i in range(1,11)]
    prism(geo,polygon,.28,"Window",cy=.25)
    geo.box((0,-.02,1.1),(6.2,.7,.45),"Shell")
    kit.asset("MintArchWindow","Buildings",geo,"Bottom center; opaque blue inset faces Blender-Y.",
              "Readable mint arched frame, broad blue window and cream sill; native glow optional and separate.")


def radial(geo,rings,role,sides=16):
    loops=[[(r*math.cos(i*math.tau/sides),r*math.sin(i*math.tau/sides),z)
            for i in range(sides)] for r,z in rings]
    geo.loops(loops,role)


def incubator():
    geo=Geo()
    geo.box((0,0,1),(14,14,2),"Shell")
    radial(geo,[(5.8,2),(5.8,3)],"Mint")
    radial(geo,[(5.8,12),(5.8,13.1),(5.2,13.1),(5.2,14.1),(3.8,16),(2.8,16),(2.8,16.7),(1.4,16.7)],"Mint")
    for angle in (45,135,225,315):
        a=math.radians(angle)
        geo.box((5*math.cos(a),5*math.sin(a),7.5),(.8,.8,9),"Shell")
    geo.box((0,0,17.2),(2,2,1),"Coral")
    geo.box((0,-6.5,2.2),(3.8,1.5,1.1),"Mint")
    kit.asset("IncubatorHousing","Landmarks",geo,"Bottom center; open chamberBlenderZ3..12,inner diameterabout9.",
              "Cream base/four supports and mint stepped dome. Put existing square-stepped egg inside; optional native transparent window remains separate.")
    geo=Geo()
    geo.box((0,0,0),(21,3.4,1.6),"Shell")
    for x in (-10.5,10.5):
        geo.box((x,0,.2),(3,4,3.2),"Coral")
    for x in (-6,0,6):
        geo.box((x,-1.77,.1),(2,.14,.6),"Mint")
    kit.asset("GateLintel","Landmarks",geo,"MIDPOINT at0; beam spansX±12. Local clearance controlled by installation height.",
              "Simple cream/coral entry beam; separate posts/trigger stay native. No text or hazard-red emission.")


def render_sheet(out):
    scene=bpy.context.scene
    for index,record in enumerate(kit.ASSETS):
        col,row=index%5,index//5
        low,high=record["boundsBlender"]
        scale=min(1,16/max(high[i]-low[i] for i in range(3)))
        center=Vector(((low[0]+high[0])/2,(low[1]+high[1])/2,low[2]))
        for source in record["parts"]:
            obj=source.copy();obj.data=source.data
            scene.collection.objects.link(obj)
            obj.hide_render=False;obj.scale=(scale,)*3
            obj.location=Vector((col*22,-row*25,0))-center*scale
        font=bpy.data.curves.new(record["name"]+"Label","FONT")
        font.body=record["name"];font.size=1.05;font.align_x="CENTER"
        label=bpy.data.objects.new(font.name,font);scene.collection.objects.link(label)
        label.location=(col*22,-row*25-9,.04);font.materials.append(kit.MATERIALS["Ink"])
    geo=Geo();geo.box((44,-13,-.35),(120,70,.5),"ShellShade")
    mesh=bpy.data.meshes.new("PreviewFloor");mesh.from_pydata(geo.vertices,[],geo.faces)
    obj=bpy.data.objects.new("PreviewFloor",mesh);scene.collection.objects.link(obj)
    mesh.materials.append(kit.MATERIALS["ShellShade"])
    camera_data=bpy.data.cameras.new("WorldKitCamera")
    camera=bpy.data.objects.new("WorldKitCamera",camera_data);scene.collection.objects.link(camera)
    camera.location=(110,-116,90)
    camera.rotation_euler=(Vector((44,-14,4))-Vector(camera.location)).to_track_quat("-Z","Y").to_euler()
    camera_data.type="ORTHO";camera_data.ortho_scale=125;scene.camera=camera
    lamp_data=bpy.data.lights.new("BroadKey","AREA");lamp_data.energy=60000;lamp_data.shape="DISK";lamp_data.size=70
    lamp=bpy.data.objects.new("BroadKey",lamp_data);scene.collection.objects.link(lamp);lamp.location=(15,-35,85)
    scene.world=bpy.data.worlds.new("SoftStudio");scene.world.use_nodes=True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value=(.65,.7,.8,1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.7
    scene.render.engine="CYCLES";scene.cycles.samples=24
    scene.render.resolution_x=1900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
    scene.view_settings.view_transform="Standard"
    scene.render.image_settings.file_format="PNG";scene.render.filepath=str(out/"ER_world_kit_sheet.png")
    bpy.ops.render.render(write_still=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,default=ROOT/"candidate_c01")
    parser.add_argument("--support-width",type=float,default=10)
    parser.add_argument("--support-depth",type=float,default=6)
    parser.add_argument("--support-height",type=float,default=20)
    parser.add_argument("--render",action="store_true")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    if min(args.support_width,args.support_depth)<3 or args.support_height<3:
        raise ValueError("Support width/depth/height must be at least3 studs.")
    started=time.perf_counter()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    if (out/"manifest.json").exists():
        raise RuntimeError("Choose a fresh --out; completed candidates are preserved.")
    kit.BUILD=BUILD
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system="NONE"
    bpy.context.scene.unit_settings.scale_length=1
    for name,hex_color in PALETTE.items():
        rgb=tuple(int(hex_color[i:i+2],16)/255 for i in (0,2,4))
        rgb=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb)
        mat=bpy.data.materials.new("ER_"+name);mat.diffuse_color=(*rgb,1);mat.use_nodes=True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*rgb,1)
        mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.87
        kit.MATERIALS[name]=mat
    for label,factor in [("Low",.5),("Standard",1),("Tall",1.6)]:
        support("RockSupport"+label,args.support_width,args.support_depth,args.support_height*factor)
    support("BareRock",args.support_width*.7,args.support_depth*.9,args.support_height*.35,False)
    shrub();nursery();incubator()
    records=kit.export_assets(out)
    manifest=dict(candidate=BUILD,blender=bpy.app.version_string,
                  units="1 Blender unit=1 intended stud",axes="RobloxXYZ=(BlenderX,BlenderZ,-BlenderY)",
                  palette=PALETTE,assetCount=len(records),partCount=sum(len(r["parts"]) for r in records),
                  triangles=sum(p["triangles"] for r in records for p in r["parts"]),assets=records,
                  builderSHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  helperSHA256=hashlib.sha256(HELPER.read_bytes()).hexdigest(),
                  parameters=dict(supportWidth=args.support_width,supportDepth=args.support_depth,supportHeight=args.support_height),
                  collision="All art visual only. Pads and intentional gameplay contacts remain native.",
                  warning="Do not fill jump gaps with scenery or continuous banks. Top cap is smaller than authored pad footprint.")
    manifest["blenderFbxRoundtrip"]=kit.verify_exports(out,records)
    if args.render:
        render_sheet(out)
    for record in kit.ASSETS:
        for obj in record["parts"]:
            obj.hide_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"ER_world_kit.blend"))
    manifest["buildSeconds"]=round(time.perf_counter()-started,3)
    manifest["files"]={f.name:hashlib.sha256(f.read_bytes()).hexdigest()
                       for f in sorted(out.iterdir()) if f.suffix in (".fbx",".blend",".png")}
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({key:manifest[key] for key in ("candidate","assetCount","partCount","triangles","buildSeconds")}),flush=True)


if __name__=="__main__":
    main()
