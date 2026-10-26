"""One broad stepped guardian tail, authored in the tested mechanism's local axes."""
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
import bmesh
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
HELPER=ROOT.parent/"phase1"/"build_kit.py"
spec=importlib.util.spec_from_file_location("egg_rush_kit",HELPER)
kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
BUILD="ER_GUARDIAN_SWEEP_C03"

# Bounds are Roblox-local XYZ; neighboring branch roots overlap into one solid.
BOXES=[
 (0,5,-1.5,.2,-1.5,1.5),(5,9,-1.5,1.2,-2.3,2.3),
 (7,19,-1.2,2,-4,-1.4),(19,22.5,-.8,2.6,-4,-1.4),(22.5,23.5,-.4,1.8,-3.5,-1.4),
 (7,15,-1.5,2.2,-1.9,.7),(15,25,-1,3.5,-1.9,.7),(25,27.5,-.5,3,-1.4,1),(27.5,29.25,0,2.4,-1.4,.7),
 (8,17,-1.3,2.6,.3,2.5),(17,25.5,-.6,3,.3,2.5),(25.5,27,-.2,2.2,.7,2.2),
 (6,17,-1.5,1.5,2.1,4),(17,23,-.9,2.3,2.1,4),(23,25.5,-.4,1.4,2.1,3.5),
]


def surface():
    coordinates=[sorted({box[i] for box in BOXES for i in (axis*2,axis*2+1)}) for axis in range(3)]
    coordinates[0]=sorted(set(coordinates[0]+[18,22]))
    count=[len(c)-1 for c in coordinates]
    occupied=set()
    for x in range(count[0]):
        for y in range(count[1]):
            for z in range(count[2]):
                index=(x,y,z)
                center=[(coordinates[a][index[a]]+coordinates[a][index[a]+1])/2 for a in range(3)]
                if any(all(box[a*2]<center[a]<box[a*2+1] for a in range(3)) for box in BOXES):
                    occupied.add(index)
    remaining=set(occupied);components=0
    while remaining:
        components+=1;stack=[remaining.pop()]
        while stack:
            cell=stack.pop()
            for a in range(3):
                for sign in (-1,1):
                    neighbor=list(cell);neighbor[a]+=sign;neighbor=tuple(neighbor)
                    if neighbor in remaining:remaining.remove(neighbor);stack.append(neighbor)
    assert components==1,"Feather branches must join the root."
    geo=kit.Geo();geo.occupied_cells=len(occupied)
    for axis in range(3):
        other=[i for i in range(3) if i!=axis]
        for sign in (-1,1):
            for layer in range(count[axis]):
                grid={}
                for cell in occupied:
                    if cell[axis]!=layer:continue
                    neighbor=list(cell);neighbor[axis]+=sign
                    if tuple(neighbor) in occupied:continue
                    x=(coordinates[0][cell[0]]+coordinates[0][cell[0]+1])/2
                    z=(coordinates[2][cell[2]]+coordinates[2][cell[2]+1])/2
                    role="Shell"
                    if axis==1 and sign==1:
                        if 19<=x<22.5 and z<-1.4:role="Lilac"
                        elif 18<=x<22 and -1.9<z<.7:role="Mint"
                        elif 17<=x<23 and z>2.1:role="Coral"
                    if axis==2 and sign==1 and z>3 and 17<=x<23:role="Coral"
                    grid[(cell[other[0]],cell[other[1]])]=role
                while grid:
                    u,v=min(grid);role=grid[(u,v)];width=1
                    while grid.get((u+width,v))==role:width+=1
                    height=1
                    while all(grid.get((i,v+height))==role for i in range(u,u+width)):height+=1
                    for i in range(u,u+width):
                        for j in range(v,v+height):del grid[(i,j)]
                    plane=coordinates[axis][layer+(sign==1)]
                    quad=[]
                    for i,j in [(u,v),(u+width,v),(u+width,v+height),(u,v+height)]:
                        p=[0,0,0];p[axis]=plane
                        p[other[0]]=coordinates[other[0]][i];p[other[1]]=coordinates[other[1]][j]
                        quad.append((p[0],-p[2],p[1]))
                    native_direction=[0,0,0];native_direction[axis]=sign
                    expected=Vector((native_direction[0],-native_direction[2],native_direction[1]))
                    normal=(Vector(quad[1])-Vector(quad[0])).cross(Vector(quad[2])-Vector(quad[0]))
                    if normal.dot(expected)<0:quad.reverse()
                    geo.mesh(quad,[(0,1,2,3)],role)
    return geo


def verify_shape(geo):
    native=[(x,z,-y) for x,y,z in geo.vertices]
    low=[min(v[i] for v in native) for i in range(3)]
    high=[max(v[i] for v in native) for i in range(3)]
    assert low==[0,-1.5,-4] and high==[29.25,3.5,4],(low,high)
    projection=min(-math.sin(math.radians(25))*x+math.cos(math.radians(25))*z for x,y,z in native)
    assert projection>=-13.65,projection
    return dict(boundsRoblox=[low,high],northProjectionMinimum=projection,northProjectionLimit=-13.65,
                northProjectionMargin=projection+13.65,
                occupiedCells=geo.occupied_cells,connectedComponents=1,
                statement="Static vertex bound only; native full-cycle refuge/contact/traversal proof still required.")


def verify_normals(record):
    def filled(p):
        return any(all(b[a*2]-1e-8<=p[a]<=b[a*2+1]+1e-8 for a in range(3)) for b in BOXES)
    faces=0
    for obj in record["parts"]:
        # Open color patches need the complete solid to establish their outward side.
        bm=bmesh.new();bm.from_mesh(obj.data)
        for face in bm.faces:
            center=face.calc_center_median();normal=face.normal
            p=(center.x,center.z,-center.y);n=(normal.x,normal.z,-normal.y)
            negative=filled([p[a]-n[a]*.0001 for a in range(3)])
            positive=filled([p[a]+n[a]*.0001 for a in range(3)])
            assert negative!=positive,(obj.name,"surface does not separate inside/outside")
            if positive:face.normal_flip()
        bm.to_mesh(obj.data);bm.free();obj.data.update()
        for face in obj.data.polygons:
            center=face.center;normal=face.normal
            p=(center.x,center.z,-center.y);n=(normal.x,normal.z,-normal.y)
            assert filled([p[a]-n[a]*.0001 for a in range(3)]),(obj.name,"inward probe missed solid")
            assert not filled([p[a]+n[a]*.0001 for a in range(3)]),(obj.name,"outward normal points inside")
            faces+=1
    return faces


def preview(out,record):
    scene=bpy.context.scene
    for obj in record["parts"]:obj.hide_render=False
    camera_data=bpy.data.cameras.new("TailCamera")
    camera=bpy.data.objects.new("TailCamera",camera_data);scene.collection.objects.link(camera)
    camera.location=(47,36,29)
    camera.rotation_euler=(Vector((14,0,1))-Vector(camera.location)).to_track_quat("-Z","Y").to_euler()
    camera_data.type="ORTHO";camera_data.ortho_scale=40;scene.camera=camera
    light_data=bpy.data.lights.new("BroadKey","AREA");light_data.energy=12000;light_data.size=30
    light=bpy.data.objects.new("BroadKey",light_data);scene.collection.objects.link(light);light.location=(10,15,32)
    scene.world=bpy.data.worlds.new("SoftStudio");scene.world.use_nodes=True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value=(.65,.7,.8,1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.7
    scene.render.engine="CYCLES";scene.cycles.samples=24
    scene.render.resolution_x=1600;scene.render.resolution_y=900;scene.render.resolution_percentage=100
    scene.view_settings.view_transform="Standard"
    scene.render.image_settings.file_format="PNG";scene.render.filepath=str(out/"GuardianSweepTail_oblique.png")
    bpy.ops.render.render(write_still=True)
    camera.location=(14,0,48);camera.rotation_euler=(Vector((14,0,0))-Vector(camera.location)).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(out/"GuardianSweepTail_plan.png")
    bpy.ops.render.render(write_still=True)


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--out",type=Path,default=ROOT/"candidate_c01")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    if (out/"manifest.json").exists():raise RuntimeError("Choose a fresh candidate output.")
    started=time.perf_counter();bpy.ops.wm.read_factory_settings(use_empty=True)
    kit.BUILD=BUILD;bpy.context.scene.unit_settings.system="NONE";bpy.context.scene.unit_settings.scale_length=1
    for role in ("Shell","Mint","Coral","Lilac"):
        h=kit.PALETTE[role];rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
        rgb=[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb]
        mat=bpy.data.materials.new("ER_"+role);mat.use_nodes=True;mat.diffuse_color=(*rgb,1)
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*rgb,1)
        mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.85;kit.MATERIALS[role]=mat
    geo=surface();shape=verify_shape(geo)
    kit.asset("GuardianSweepTail","GuardianSweepTail",geo,"Root0; Roblox+X outward, +Y up; match existing tail mechanism pivot directly.",
              "Four stepped branches and longer central feather, authored to native envelope; no opaque beam or stretched source tail.")
    shape["outwardFacesChecked"]=verify_normals(kit.ASSETS[0])
    records=kit.export_assets(out);roundtrip=kit.verify_exports(out,records)
    preview(out,kit.ASSETS[0])
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"GuardianSweepTail.blend"))
    manifest=dict(candidate=BUILD,units="1unit=1intended stud",axes="RobloxXYZ=(BlenderX,BlenderZ,-BlenderY)",
                  palette={role:kit.PALETTE[role] for role in kit.MATERIALS},shapeChecks=shape,
                  assets=records,assetCount=1,partCount=sum(len(r["parts"]) for r in records),
                  triangles=sum(p["triangles"] for r in records for p in r["parts"]),blenderFbxRoundtrip=roundtrip,
                  builderSHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  helperSHA256=hashlib.sha256(HELPER.read_bytes()).hexdigest(),
                  buildSeconds=round(time.perf_counter()-started,3))
    manifest["files"]={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(out.iterdir()) if f.suffix in (".blend",".fbx",".png")}
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:manifest[k] for k in ("candidate","assetCount","partCount","triangles","buildSeconds")}),flush=True)


if __name__=="__main__":main()
