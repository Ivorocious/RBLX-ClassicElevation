"""C01: clipped B10 railing and a measured, continuous Grand Arcade approach."""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
SOURCE = ROOT / "assets/lobby_blender/Skycourt_B10.blend"
scene = bpy.data.scenes.new("GrandArcadeConnection_C01")
bpy.context.window.scene = scene
scene.unit_settings.system = "NONE"
scene.unit_settings.scale_length = 1
COLORS = {
    "Stone": (.79, .70, .53), "Cream": (.95, .86, .67),
    "Pale": (.99, .94, .80), "FloorA": (.85, .81, .70),
    "FloorB": (.83, .79, .68), "DeepBlue": (.045, .12, .17),
    "Gold": (.88, .58, .16),
}
MATS = {}
for name, color in COLORS.items():
    material = bpy.data.materials.new("C01_" + name)
    material.diffuse_color = (*color, 1)
    MATS[name] = material
groups = {}
preserved = []

def mesh(name, material, vertices, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(MATS[material])
    data.update()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj["CandidateMaterial"] = material
    groups.setdefault((name.split("__")[0], material), []).append(obj)
    return obj

def box(section, mat, p, size, bevel=.04):
    x, y, z = p
    a, b, c = (v / 2 for v in size)
    obj = mesh(section + "__" + mat, mat,
        [(x+u*a, y+v*b, z+w*c) for u,v,w in [
            (-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
            (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],
        [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    if bevel:
        modifier = obj.modifiers.new("Soft masonry edge", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj

def height(depth):
    return max(0, min(4.2, (depth-1.5)*4.2/16))

def profile(section, mat, x0, x1, near, far, low_offset, high_offset):
    near_top, far_top = height(near)+high_offset, height(far)+high_offset
    near_low, far_low = height(near)+low_offset, height(far)+low_offset
    return mesh(section+"__"+mat, mat,
        [(x0,near,near_low),(x1,near,near_low),(x1,far,far_low),(x0,far,far_low),
         (x0,near,near_top),(x1,near,near_top),(x1,far,far_top),(x0,far,far_top)],
        [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])


def stage_front_boundary(source_path):
    with bpy.data.libraries.load(str(source_path), link=False) as (source, loaded):
        assert "Platform__Floor" in source.objects, "Missing stage walking surface"
        loaded.objects = ["Platform__Floor"]
    floor = loaded.objects[0]
    points = [floor.matrix_world @ vertex.co for vertex in floor.data.vertices]
    top = max(point.z for point in points)
    # The measured stage pivot is 49.5 studs beyond the C01 floor origin.
    boundary = sorted((point.x,point.y+49.5) for point in points
                      if abs(point.z-top) < 1e-6 and point.y <= 1e-6)
    assert len(boundary) == 49, "Unexpected 96-edge stage floor boundary"
    return boundary


def stage_boundary_depth(x, boundary):
    for (x0,y0),(x1,y1) in zip(boundary,boundary[1:]):
        if x0-1e-7 <= x <= x1+1e-7:
            return y0+(y1-y0)*(x-x0)/(x1-x0)
    raise AssertionError("Landing extends beyond the measured stage width")


def upper_landing_tile(mat, x0, x1, near, far, boundary):
    xs = [x0]+[x for x,_ in boundary if x0 < x < x1]+[x1]
    if far < min(stage_boundary_depth(x,boundary) for x in xs):
        return profile("UpperLanding",mat,x0,x1,near,far,-.025,0)
    intersections = []
    for a,b in zip(xs,xs[1:]):
        ha = stage_boundary_depth(a,boundary)-.0001
        hb = stage_boundary_depth(b,boundary)-.0001
        if (ha-far)*(hb-far) < 0:
            intersections.append(a+(b-a)*(far-ha)/(hb-ha))
    xs = sorted(xs+intersections)
    upper = [(x,min(far,stage_boundary_depth(x,boundary)-.0001)) for x in reversed(xs)]
    assert min(depth for _,depth in upper) > near, "Stage edge precedes the upper landing tile"
    polygon = [(x0,near),(x1,near)]+upper
    count = len(polygon)
    vertices = [(x,y,h) for h in (4.175,4.2) for x,y in polygon]
    faces = [tuple(range(count-1,-1,-1)),tuple(range(count,count*2))]
    faces.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
    return mesh("UpperLanding__"+mat,mat,vertices,faces)

# Keep the source's outer spans and their bevels; only the new entrance is cut away.
with bpy.data.libraries.load(str(SOURCE), link=False) as (source, loaded):
    loaded.objects = [name for name in source.objects if name.startswith("Guardrails_Rail_01__")]
assert len(loaded.objects) == 4, "Expected the four B10 front-rail material meshes"
for original in loaded.objects:
    mat = original.name.split("__")[1]
    for side in [-1, 1]:
        data = original.data.copy()
        bm = bmesh.new()
        bm.from_mesh(data)
        normal = (1,0,0) if side < 0 else (-1,0,0)
        plane = (-10,0,0) if side < 0 else (10,0,0)
        cut = bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
            dist=.00001, plane_co=plane, plane_no=normal, clear_inner=False, clear_outer=True)
        cut_edges = [edge for edge in cut["geom_cut"] if isinstance(edge, bmesh.types.BMEdge) and edge.is_boundary]
        if cut_edges:
            bmesh.ops.holes_fill(bm, edges=cut_edges, sides=0)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
        if not data.vertices:
            bpy.data.meshes.remove(data)
            continue
        # Source B10 axes are mirrored at import; this isolated asset uses the stage axes.
        for vertex in data.vertices:
            point = original.matrix_world @ vertex.co
            vertex.co = (-point.x, -point.y-48.5, point.z)
        data.materials.clear()
        data.materials.append(MATS[mat])
        obj = bpy.data.objects.new(f"LobbyRail{'Left' if side>0 else 'Right'}__{mat}", data)
        scene.collection.objects.link(obj)
        obj["CandidateMaterial"] = mat
        groups.setdefault((obj.name.split("__")[0], mat), []).append(obj)
        preserved.append({"material":mat,"source":original.name,"side":side,"vertices":len(data.vertices)})

# A broad lower landing leads to a 14.7-degree ramp, then a level stage landing.
stage_boundary = stage_front_boundary(ROOT / "assets/grand_arcade/A01/GrandArcade_A01.blend")
for section, near, far in [("LowerLanding",-2.5,1.5),("Ramp",1.5,17.5),("UpperLanding",17.5,27.5)]:
    profile(section,"Cream",-9,9,near,far,-.7,-.027)
    # Fine joints keep the visible floor at the exact collision height.
    count = max(1, math.ceil((far-near)/4))
    for row in range(count):
        depth0 = near+(far-near)*row/count+.028
        depth1 = near+(far-near)*(row+1)/count-.028
        for column in range(4):
            x0=-9+column*4.5+.025
            x1=x0+4.45
            material = "FloorA" if (row+column)%2 == 0 else "FloorB"
            if section == "UpperLanding":
                upper_landing_tile(material,x0,x1,depth0,depth1,stage_boundary)
            else:
                profile(section,material,x0,x1,depth0,depth1,-.025,0)
    for side in [-1,1]:
        # The solid parapet meets the old rail height and protects the complete route.
        center=side*9.45
        profile(section,"Cream",center-.55,center+.55,near,far,-.15,2.8)
        profile(section,"Pale",center-.67,center+.67,near,far,2.8,3.03)
        profile(section,"Gold",center-.58,center+.58,near,far,3.03,3.10)
        profile(section,"Stone",center-.62,center+.62,near,far,-.78,-.62)
        profile(section,"DeepBlue",center+side*.555-.025,center+side*.555+.025,near,far,.5,.8)
        profile(section,"DeepBlue",center+side*.555-.025,center+side*.555+.025,near,far,2.2,2.25)

for depth in [-.0,1.5,17.5,27.2]:
    for side in [-1,1]:
        x=side*9.45
        base=height(depth)
        box("PortalPosts","Cream",(x,depth,base+1.6),(1.42,1.42,3.2),.09)
        box("PortalPosts","Pale",(x,depth,base+3.23),(1.65,1.65,.20),.035)
        box("PortalPosts","Gold",(x,depth,base+3.36),(1.45,1.45,.08),.02)

# The bridge has a proper closed side profile rather than a floating incline.
for side in [-1,1]:
    x0,x1=side*9.15-.2,side*9.15+.2
    near,far=1.5,17.5
    mesh("RampFascia__Stone","Stone",
        [(x0,near,-.78),(x1,near,-.78),(x1,far,-.78),(x0,far,-.78),
         (x0,near,-.62),(x1,near,-.62),(x1,far,3.58),(x0,far,3.58)],
        [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
box("BridgePlinth","Stone",(0,12.5,-.93),(19.7,30, .30),.05)

for key,p in [("Origin",(0,0,0)),("Right",(10,0,0)),("Up",(0,0,10)),("Forward",(0,-10,0))]:
    marker=box("Marker"+key,"DeepBlue",p,(.12,.12,.12),0)
    marker.hide_render=True

exported=[]
info={}
for (section,mat),members in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in members: obj.select_set(True)
    bpy.context.view_layer.objects.active=members[0]
    if len(members)>1: bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=section+"__"+mat
    obj.data.calc_loop_triangles()
    info[obj.name]={"material":mat,"triangles":len(obj.data.loop_triangles)}
    assert info[obj.name]["triangles"]<20000
    exported.append(obj)

bpy.ops.object.select_all(action="DESELECT")
for obj in exported:obj.select_set(True)
bpy.context.view_layer.objects.active=exported[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/"GrandArcadeConnection_C01.fbx"),use_selection=True,
    object_types={"MESH"},axis_forward="-Z",axis_up="Y",apply_unit_scale=True,add_leaf_bones=False)

scene.world=bpy.data.worlds.new("ConnectionPreviewWorld")
scene.world.color=(.47,.64,.75)
cam_data=bpy.data.cameras.new("ConnectionReviewCamera")
cam=bpy.data.objects.new("ConnectionReviewCamera",cam_data)
scene.collection.objects.link(cam)
scene.camera=cam
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.display.shading.cavity_type="BOTH"
scene.display.shading.background_type="WORLD"
scene.view_settings.view_transform="Standard"
scene.render.resolution_x=1440
scene.render.resolution_y=1000
scene.render.resolution_percentage=100
for name,pos,target,ortho in [
    ("approach",(24,-25,14),(0,11,2.2),False),
    ("rail-preservation",(0,-40,22),(0,2,2),True),
    ("side-profile",(36,10,6),(0,10,2),False)]:
    cam.location=pos
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat("-Z","Y").to_euler()
    cam_data.type="ORTHO" if ortho else "PERSP"
    cam_data.ortho_scale=126
    cam_data.lens=28
    scene.render.filepath=str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"GrandArcadeConnection_C01.blend"))
report={
    "revision":"C01","floorOrigin":[1552,370,-892.5],"stagePivot":[1552,374.2,-942],
    "rampRunStuds":16,"rampRiseStuds":4.2,"slopeDegrees":math.degrees(math.atan(4.2/16)),
    "floorWidthStuds":18,"parapetClearWidthStuds":17.8,"railOpeningStuds":20,
    "sourceRail":str(SOURCE),"preservedSideGeometry":preserved,
    "meshes":info,"triangles":sum(row["triangles"] for row in info.values()),
    "nativeProof":"Pending lead installation and two-way walking checks; Blender views do not establish traversal.",
}
(OUT/"build-report.json").write_text(json.dumps(report,indent=2))
print("CONNECTION_CANDIDATE "+json.dumps({"meshes":len(info),"triangles":report["triangles"],"slopeDegrees":report["slopeDegrees"]}))
