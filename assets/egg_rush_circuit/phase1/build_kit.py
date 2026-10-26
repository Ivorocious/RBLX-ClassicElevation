"""Egg Rush reusable art kit. Run with Blender; never touches a live scene or Studio."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
import time
from collections import defaultdict
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

BUILD = "ER_P1_KIT_C03"
ROOT = Path(__file__).resolve().parent
PALETTE = {
    "Shell": "FFF0CA", "ShellShade": "E8D4A8", "Mint": "68CDB0",
    "Coral": "F67D60", "Lilac": "B688D8", "Honey": "B97B43",
    "Straw": "D89C53", "Iron": "646A78", "IronLight": "949BA9",
    "Ink": "343744", "Amber": "FFC04B", "GlassBlue": "8CC7DA",
}
MATERIALS = {}
ASSETS = []


class Geo:
    def __init__(self):
        self.vertices, self.faces, self.roles = [], [], []

    def mesh(self, vertices, faces, role):
        start = len(self.vertices)
        self.vertices.extend(vertices)
        self.faces.extend(tuple(start + i for i in f) for f in faces)
        self.roles.extend([role] * len(faces) if isinstance(role, str) else role)

    def box(self, center, size, role):
        x, y, z = center
        a, b, c = (v / 2 for v in size)
        self.mesh([(x + i*a, y + j*b, z + k*c)
                   for k in (-1, 1) for j in (-1, 1) for i in (-1, 1)],
                  [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                   (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)], role)

    def beam(self, a, b, width, depth, role):
        a, b = Vector(a), Vector(b)
        direction = (b - a).normalized()
        u = direction.cross(Vector((0, 0, 1)))
        if u.length < .01:
            u = direction.cross(Vector((0, 1, 0)))
        u.normalize()
        v = direction.cross(u).normalized()
        self.mesh([tuple(p + u*i*width/2 + v*j*depth/2)
                   for p in (a, b) for j in (-1, 1) for i in (-1, 1)],
                  [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                   (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)], role)

    def loops(self, loops, role, cap=True):
        n = len(loops[0])
        faces = [(j*n+i, j*n+(i+1)%n, (j+1)*n+(i+1)%n, (j+1)*n+i)
                 for j in range(len(loops)-1) for i in range(n)]
        if cap:
            faces += [tuple(reversed(range(n))),
                      tuple((len(loops)-1)*n+i for i in range(n))]
        self.mesh([p for loop in loops for p in loop], faces, role)


def square_loop(width, depth, z, cy=0, chamfer=.16):
    a, b = width/2, depth/2
    c = min(width, depth)*chamfer
    return [(x, y+cy, z) for x, y in
            [(-a+c, -b), (a-c, -b), (a, -b+c), (a, b-c),
             (a-c, b), (-a+c, b), (-a, b-c), (-a, -b+c)]]


def asset(name, family, geo, pivot, use, contacts=None):
    parts = []
    collection=bpy.data.collections.new("AUTHOR_"+name)
    bpy.context.scene.collection.children.link(collection)
    for role in sorted(set(geo.roles)):
        vertices, faces, vertex_map = [], [], {}
        for face, face_role in zip(geo.faces, geo.roles):
            if face_role != role:
                continue
            indices = []
            for index in face:
                point = tuple(round(v, 6) for v in geo.vertices[index])
                if point not in vertex_map:
                    vertex_map[point] = len(vertices)
                    vertices.append(point)
                indices.append(vertex_map[point])
            faces.append(tuple(indices))
        mesh = bpy.data.meshes.new(name + "_" + role)
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new("ER_" + name + "__" + role, mesh)
        collection.objects.link(obj)
        obj.data.materials.append(MATERIALS[role])
        obj["Build"], obj["Asset"], obj["Role"] = BUILD, name, role
        obj["VisualOnly"] = True
        parts.append(obj)
    coords = [v.co for obj in parts for v in obj.data.vertices]
    low = [min(v[i] for v in coords) for i in range(3)]
    high = [max(v[i] for v in coords) for i in range(3)]
    ASSETS.append(dict(name=name, family=family, parts=parts,
                       boundsBlender=[low, high],
                       dimensionsRobloxXYZ=[high[0]-low[0], high[2]-low[2], high[1]-low[1]],
                       pivot=pivot, use=use, contacts=contacts or []))


def egg(name, width=6, height=8, patch="Coral"):
    # Boundary-only voxel surface keeps the stepped body solid without buried tier faces.
    widths = [2, 4, 6, 8, 8, 8, 8, 6, 4, 2]
    occupied = {(x, y, z) for z, n in enumerate(widths)
                for x in range(-n//2, n//2) for y in range(-n//2, n//2)}
    geo = Geo()
    directions = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
    quads = [((1,0,0),(1,1,0),(1,1,1),(1,0,1)), ((0,1,0),(0,0,0),(0,0,1),(0,1,1)),
             ((1,1,0),(0,1,0),(0,1,1),(1,1,1)), ((0,0,0),(1,0,0),(1,0,1),(0,0,1)),
             ((0,0,1),(1,0,1),(1,1,1),(0,1,1)), ((0,1,0),(1,1,0),(1,0,0),(0,0,0))]
    for x, y, z in sorted(occupied):
        for direction, quad in zip(directions, quads):
            if (x+direction[0], y+direction[1], z+direction[2]) in occupied:
                continue
            mark = ((direction[1] < 0 and -2 <= x < 0 and 3 <= z < 6)
                    or (direction[0] > 0 and 0 <= y < 2 and 5 <= z < 7)
                    or (direction[1] > 0 and 0 <= x < 2 and 2 <= z < 4))
            geo.mesh([((x+dx)*width/8, (y+dy)*width/8, (z+dz)*height/10)
                      for dx, dy, dz in quad], [(0,1,2,3)], patch if mark else "Shell")
    asset(name, "Eggs", geo, "Bottom center; square cap stays horizontal in rest pose.",
          "One identical square-stepped silhouette at every scale. Controlled visual rolling only.")


def shell(name, width, depth, height, hollow=False, hinge=False):
    geo = Geo()
    cy = depth/2 if hinge else 0
    top = 0 if hinge else height
    bottom = top-height
    loops = [square_loop(width*.48, depth*.48, bottom, cy),
             square_loop(width*.48, depth*.48, bottom+height*.22, cy),
             square_loop(width*.74, depth*.74, bottom+height*.22, cy),
             square_loop(width*.74, depth*.74, bottom+height*.55, cy),
             square_loop(width, depth, bottom+height*.55, cy),
             square_loop(width, depth, top, cy)]
    if hollow:
        loops += [square_loop(width-2, depth-2, top, cy),
                  square_loop(width*.48-1, depth*.48-1, bottom+1.1, cy)]
    geo.loops(loops, "Shell")
    geo.box((width/2+.015, cy, top-height*.22), (.04, depth*.25, height*.3), "Mint")
    if hinge:
        contacts = [dict(center=[0, -.3, -depth/2], size=[width-.4, .6, depth-.2])]
        pivot = "Hinge center at X0 Y0 Z0; leaf extends +Y; flat walking top Z0. Rotate about local X."
    else:
        contacts = [] if hollow else [dict(center=[0, height-.3, 0], size=[width-.4, .6, depth-.4])]
        pivot = "Bottom center. Shell wall one stud minimum at rim; bowl bottom1.1 studs."
    asset(name, "Shells", geo, pivot,
          "Hollow open shell; no bounding-box collider." if hollow else "Thick stepped shell with a deliberately flat landing lip.", contacts)


def nest(name="NestRing", diameter=14):
    geo = Geo()
    for level in range(2):
        loops = []
        for radius, z in [(diameter/2, level*.8), (diameter/2, (level+1)*.8),
                          (diameter/2-1, (level+1)*.8), (diameter/2-1, level*.8),
                          (diameter/2, level*.8)]:
            loops.append([(radius*math.cos(i*math.tau/12), radius*math.sin(i*math.tau/12), z) for i in range(12)])
        geo.loops(loops, "Honey" if level == 0 else "Straw", cap=False)
    for angle in range(0, 360, 60):
        a = math.radians(angle)
        geo.box(((diameter/2-.4)*math.cos(a), (diameter/2-.4)*math.sin(a), 1), (1.1, 1.1, 2), "Honey")
    asset(name, "Shells", geo, "Bottom center; open center radius6 at authored size.",
          "Two broad twelve-sided straw bands, six broad bindings. Art ring; use separate floor if needed.")


def tube(geo, points, radius, wall, role, sides=12):
    loops = []
    for i, p in enumerate(points):
        direction = Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        direction.normalize()
        reference=Vector((1,0,0)) if abs(direction.x)<.9 else Vector((0,1,0))
        u=reference-direction*reference.dot(direction)
        u.normalize()
        v = direction.cross(u).normalized()
        loops.append((Vector(p), u, v))
    outer = [[tuple(p+radius*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides))) for j in range(sides)] for p,u,v in loops]
    inner = [[tuple(p+(radius-wall)*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides))) for j in range(sides)] for p,u,v in reversed(loops)]
    geo.loops(outer+inner+[outer[0]], role, cap=False)


def machinery():
    geo = Geo()
    geo.box((0,0,.45),(10,8,.9),"Shell")
    for y in (-3.7,3.7):
        geo.box((0,y,1.5),(10,.6,2.1),"Mint")
        for x in (-4.7,4.7):
            geo.box((x,y,1.4),(.6,.8,2.8),"Coral")
    for x in (-3.7,3.7):
        for y in (-2.4,2.4):
            geo.box((x,y,-.35),(1,1,.8),"Iron")
    asset("SlidingTray", "Machinery", geo, "Deck bottom center; travel axis local Y; deck topZ.9.",
          "Separate tray from fixed rails and native contact. Mint guards are across local X ends.",
          [dict(center=[0,.45,0],size=[10,.9,8])])
    geo = Geo()
    for x in (-3.7,3.7):
        geo.box((x,0,.45),(.75,22,.9),"IronLight")
    for y in (-10,0,10):
        geo.box((0,y,-.2),(10,1.1,.4),"Iron")
    asset("RailPair", "Machinery", geo, "Rail topZ.9; travel along local Y. Width8.15, length22.",
          "Fixed visual rails. Keep all exposed rails noncollidable unless a deliberate route requires otherwise.")
    geo = Geo()
    samples = [(0,8),(2,6.9),(4,4.4),(6,2.5),(9,1.1),(12,.6),(16,.6)]
    for (y0,z0),(y1,z1) in zip(samples,samples[1:]):
        for x in (-4,4):
            geo.beam((x,y0,z0+.8),(x,y1,z1+.8),.65,2,"Shell")
        geo.mesh([(-4,y0,z0),(4,y0,z0),(4,y1,z1),(-4,y1,z1),
                  (-4,y0,z0-.7),(4,y0,z0-.7),(4,y1,z1-.7),(-4,y1,z1-.7)],
                 [(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],"ShellShade")
    for y,z in (samples[0],samples[3],samples[-1]):
        for x in (-4.7,4.7):
            geo.box((x,y,z/2),(1.1,1.2,z+1.8),"Coral")
    asset("EggChute", "Machinery", geo, "Feed centerY0 height8; outletY16 height.6; bottom0.",
          "Broad six-section curved open trough, supported coral frame. Visual guide; hazard path is separate.")
    for name, points in [("PipeStraight",[(0,0,1.5),(0,10,1.5)]),
                         ("PipeElbow",[(0,0,1.5),(0,3,1.5),(0,4.5,2),(0,5.5,3),(0,6,4.5),(0,6,7)])]:
        geo=Geo()
        tube(geo,points,1.4,.28,"Mint")
        asset(name,"Machinery",geo,"Open mouth at localY0; bottom approximately0.","Hollow twelve-sided pipe; visible wall thickness. Decorative only.")
    geo=Geo()
    for x in (-5,5):
        geo.box((x,0,1),(1.6,2,2),"Coral")
        tube(geo,[(x-.75,0,1),(x+.75,0,1)],1.05,.25,"Coral")
    geo.box((0,0,1),(9,1.1,1.1),"Iron")
    asset("ShellHinge", "Machinery", geo, "Axle localX at Z1; mate leaf pivot to axle center.","Fixed coral hinge with gray axle. Leaf exported independently for animation.")
    geo=Geo()
    geo.box((0,0,.5),(1.4,1.4,1),"Coral")
    geo.box((0,0,1.4),(.75,.75,.9),"Amber")
    asset("WarningBeacon", "Machinery", geo, "Bottom center.","Amber visual warning; native light/sound/state belongs to runtime. No emissive hazard-red decoration.")


def workshop():
    geo=Geo()
    for x in (-7,0,7):
        geo.box((x,0,4),(1.2,2,8),"Shell")
    geo.box((0,0,8),(15.2,2,1.3),"Shell")
    geo.box((0,0,9),(16,2.8,.8),"Coral")
    geo.box((0,0,10),(6,2.6,1.2),"Coral")
    for x in (-3.5,3.5):
        geo.box((x,.45,4),(5.8,.5,6.2),"GlassBlue")
        geo.box((x,-.05,2.8),(5.8,.55,.4),"Mint")
    asset("WorkshopBay", "Workshop", geo, "Bottom center; facade faces-Y; rear+Y.","Two broad nursery windows and low stepped coral cornice. Flat opaque glass avoids transparency sorting.")
    geo=Geo()
    for x in (-4.8,4.8):
        geo.box((x,0,3.5),(1.5,2.4,7),"Mint")
    geo.box((0,0,7),(11,2.4,1.6),"Mint")
    geo.box((0,0,8.1),(7.5,2.4,.6),"Mint")
    asset("NurseryArch", "Workshop",geo,"Bottom center; opening8.1 wide×6.2 high.","Block-built mint service arch. No portal functionality.")
    geo=Geo()
    for x in (-5,5):
        for y in (-3.8,3.8):
            geo.box((x,y,4),(1.2,1.2,8),"Honey")
    geo.box((0,0,8),(12,9,.8),"Coral")
    geo.box((0,0,8.8),(9,8,.8),"Coral")
    asset("SortingShed", "Workshop",geo,"Bottom center; all four sides open.","Simple honey supports and stepped coral roof. Keep lower than route or beyond reachable gaps.")


def guardian():
    geo=Geo()
    for z,w,d,h in [(1,7,9,1.8),(3,9,11,2.2),(5.1,8,10,2),(6.5,6,8,.9)]:
        geo.box((0,0,z),(w,d,h),"Shell")
    geo.box((0,-4.2,7.2),(4.8,4,3.8),"Shell")
    geo.box((0,-4.4,9.3),(3.5,2.8,.6),"Shell")
    for y,z in [(-5,10),(-3.8,10.8),(-2.6,10.1)]:
        geo.box((0,y,z),(1,1.3,1.7),"Coral")
    geo.box((0,-6.65,7.2),(2.7,1.3,1),"Coral")
    for side in (-1,1):
        geo.box((side*4.3,-.2,4.4),(1.1,5.2,2.5),"Shell")
        geo.box((side*4.9,-.4,4.6),(.16,2.1,2.1),"Lilac")
        geo.box((side*2.44,-4.9,8),(.08,.95,.19),"Ink")
        geo.box((side*2.4,-3,.35),(2.2,3.1,.7),"Coral")
    asset("GuardianBody", "Guardian",geo,"Feet bottom0; faces-Y; tail socket(0,4.8,4.5).", "Sleepy block-built chicken. Separate movable tail; art only.")
    geo=Geo()
    geo.box((0,2.1,.2),(3.8,4.2,1.8),"Shell")
    for x,y,z,w,d,h,role in [(-2,4,1.4,2.5,1.6,5,"Mint"),(0,4.7,2.8,2.5,1.8,7,"Shell"),(2,4.1,2,2.5,1.8,6,"Coral"),(-2.2,4.5,4.2,2,1.6,3,"Lilac")]:
        geo.box((x,y,z),(w,d,h),role)
    asset("GuardianTail", "Guardian",geo,"Attachment center0; extends+Y; rotate localZ for sweep. Mate to body socket.", "Four broad stepped feather blocks. Runtime owns warning, sweep and matching visible contact volume.")


def export_assets(out):
    records=[]
    families=defaultdict(list)
    for record in ASSETS:
        families[record["family"]].append(record)
    for family, records_in_family in families.items():
        selected=[]
        for index, record in enumerate(records_in_family):
            # A package is an atlas; offsets are explicitly reversible after import.
            offset=Vector(((index%4)*28,(index//4)*30,0))
            record["packageOffsetBlender"]=list(offset)
            record["packageOffsetRoblox"]=[offset.x,offset.z,-offset.y]
            for obj in record["parts"]:
                obj.location=offset
                selected.append(obj)
        bpy.ops.object.select_all(action="DESELECT")
        for obj in selected:
            obj.select_set(True)
        bpy.context.view_layer.objects.active=selected[0]
        filepath=out/("ER_"+family+".fbx")
        bpy.ops.export_scene.fbx(filepath=str(filepath),use_selection=True,object_types={"MESH"},
                                 axis_forward="-Z",axis_up="Y",apply_unit_scale=True,
                                 apply_scale_options="FBX_SCALE_UNITS",use_mesh_modifiers=True,
                                 bake_anim=False,add_leaf_bones=False,path_mode="AUTO")
        for record in records_in_family:
            parts=[]
            for obj in record["parts"]:
                mesh=obj.data
                mesh.calc_loop_triangles()
                assert all(math.isfinite(c) for v in mesh.vertices for c in v.co)
                assert all(p.area>1e-9 for p in mesh.polygons),obj.name
                bm=bmesh.new();bm.from_mesh(mesh)
                nonmanifold=sum(not e.is_manifold for e in bm.edges)
                bm.free()
                parts.append(dict(name=obj.name,role=obj["Role"],triangles=len(mesh.loop_triangles),
                                  nonManifoldEdges=nonmanifold))
                obj.location=(0,0,0)
                obj.hide_render=True
            data={key:value for key,value in record.items() if key!="parts"}
            data["parts"],data["fbx"]=parts,filepath.name
            records.append(data)
    return records


def render_sheet(out):
    scene=bpy.context.scene
    for index,record in enumerate(ASSETS):
        col,row=index%5,index//5
        low,high=record["boundsBlender"]
        longest=max(high[i]-low[i] for i in range(3))
        scale=min(1,15/longest)
        center=Vector(((low[0]+high[0])/2,(low[1]+high[1])/2,low[2]))
        target=Vector((col*21,-row*23,0))
        for source in record["parts"]:
            obj=source.copy();obj.data=source.data
            scene.collection.objects.link(obj)
            obj.hide_render=False;obj.scale=(scale,)*3
            obj.location=target-center*scale
        font=bpy.data.curves.new(record["name"]+"Label","FONT")
        font.body=record["name"];font.size=1.1;font.align_x="CENTER"
        label=bpy.data.objects.new(font.name,font);scene.collection.objects.link(label)
        label.location=(col*21,-row*23-9,.04)
        label.data.materials.append(MATERIALS["Ink"])
    geo=Geo();geo.box((42,-42,-.35),(120,120,.5),"Shell")
    floor=bpy.data.meshes.new("PreviewFloor");floor.from_pydata(geo.vertices,[],geo.faces)
    floor_obj=bpy.data.objects.new("PreviewFloor",floor);scene.collection.objects.link(floor_obj)
    floor_obj.data.materials.append(MATERIALS["ShellShade"])
    camera_data=bpy.data.cameras.new("KitCamera")
    camera=bpy.data.objects.new("KitCamera",camera_data);scene.collection.objects.link(camera)
    camera.location=(118,-170,108)
    target=Vector((42,-36,0))
    camera.rotation_euler=(target-Vector(camera.location)).to_track_quat("-Z","Y").to_euler()
    camera_data.type="ORTHO";camera_data.ortho_scale=137;scene.camera=camera
    lamp_data=bpy.data.lights.new("BroadKey","AREA");lamp_data.energy=60000;lamp_data.shape="DISK";lamp_data.size=80
    lamp=bpy.data.objects.new("BroadKey",lamp_data);scene.collection.objects.link(lamp)
    lamp.location=(5,-30,90)
    scene.world=bpy.data.worlds.new("WarmStudio")
    scene.world.color=(.65,.65,.65)
    scene.render.engine="CYCLES";scene.cycles.samples=24
    scene.render.resolution_x=1800;scene.render.resolution_y=1500;scene.render.resolution_percentage=100
    scene.view_settings.view_transform="Standard"
    scene.render.image_settings.file_format="PNG"
    scene.render.filepath=str(out/"ER_kit_sheet.png")
    bpy.ops.render.render(write_still=True)


def verify_exports(out,records):
    results=[]
    for family in sorted({r["family"] for r in records}):
        filepath=out/("ER_"+family+".fbx")
        prior=set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(filepath),use_anim=False)
        imported=set(bpy.data.objects)-prior
        meshes=[obj for obj in imported if obj.type=="MESH"]
        expected=[r for r in records if r["family"]==family]
        assert len(meshes)==sum(len(r["parts"]) for r in expected),(family,"part count changed")
        worst_error=0
        for record in expected:
            prefix="ER_"+record["name"]+"__"
            parts=[obj for obj in meshes if obj.name.startswith(prefix)]
            assert len(parts)==len(record["parts"]),(family,record["name"])
            coords=[obj.matrix_world@v.co for obj in parts for v in obj.data.vertices]
            actual=[[min(v[i] for v in coords) for i in range(3)],
                    [max(v[i] for v in coords) for i in range(3)]]
            intended=[[record["boundsBlender"][edge][i]+record["packageOffsetBlender"][i]
                       for i in range(3)] for edge in range(2)]
            error=max(abs(actual[e][i]-intended[e][i]) for e in range(2) for i in range(3))
            assert error<.001,(record["name"],"bounds changed",actual,intended)
            assert all(len(obj.data.materials)==1 and len(obj.data.polygons)>0 for obj in parts)
            worst_error=max(error,worst_error)
        results.append(dict(file=filepath.name,parts=len(meshes),boundsErrorStuds=round(worst_error,7),
                            materialSlots="one per part",result="PASS"))
        for obj in imported:
            bpy.data.objects.remove(obj,do_unlink=True)
    return results


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,default=ROOT/"candidate_c01")
    parser.add_argument("--only",choices=["Eggs","Shells","Machinery","Workshop","Guardian"])
    parser.add_argument("--render",action="store_true")
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    started=time.perf_counter()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    if (out/"manifest.json").exists():
        raise RuntimeError("Candidate already exists. Choose a fresh --out to preserve manual edits and prior evidence.")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system="NONE"
    bpy.context.scene.unit_settings.scale_length=1
    for name,hex_color in PALETTE.items():
        rgb=tuple(int(hex_color[i:i+2],16)/255 for i in (0,2,4))
        rgb=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb)
        material=bpy.data.materials.new("ER_"+name);material.diffuse_color=(*rgb,1)
        material.use_nodes=True
        material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*rgb,1)
        material.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.82
        MATERIALS[name]=material
    if args.only in (None,"Eggs"):
        egg("EggCoral");egg("EggMint",patch="Mint");egg("EggLilac",patch="Lilac")
        egg("EggDisplay",width=2.25,height=3,patch="Mint")
    if args.only in (None,"Shells"):
        shell("ShellPad",8,6,2.4);shell("ShellBowl",12,10,4,hollow=True)
        shell("ShellLeaf",10,8,3.2,hinge=True);nest()
    if args.only in (None,"Machinery"):
        machinery()
    if args.only in (None,"Workshop"):
        workshop()
    if args.only in (None,"Guardian"):
        guardian()
    records=export_assets(out)
    manifest=dict(candidate=BUILD,blender=bpy.app.version_string,units="1 Blender unit =1 intended Roblox stud",
                  axes="Blender X right,Z up,front-Y; Roblox(X,Y,Z)=(BlenderX,BlenderZ,-BlenderY)",
                  exportSettings=dict(axis_forward="-Z",axis_up="Y",apply_scale_options="FBX_SCALE_UNITS"),
                  palette=PALETTE,assetCount=len(records),partCount=sum(len(r["parts"]) for r in records),
                  triangles=sum(p["triangles"] for r in records for p in r["parts"]),assets=records,
                  builderSHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  collision="Visual meshes only. Contacts are suggested separate native Roblox boxes in local Roblox XYZ.",
                  caveat="FBX importer color, scale, individual part placement, contact and performance require Studio verification.")
    manifest["blenderFbxRoundtrip"]=verify_exports(out,records)
    if args.render:
        render_sheet(out)
    for record in ASSETS:
        for obj in record["parts"]:
            obj.hide_set(True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"ER_phase1_kit.blend"))
    manifest["buildSeconds"]=round(time.perf_counter()-started,3)
    manifest["files"]={f.name:hashlib.sha256(f.read_bytes()).hexdigest()
                       for f in sorted(out.iterdir()) if f.suffix in (".fbx",".blend",".png")}
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({key:manifest[key] for key in ("candidate","assetCount","partCount","triangles","buildSeconds")}),flush=True)


if __name__=="__main__":
    main()
