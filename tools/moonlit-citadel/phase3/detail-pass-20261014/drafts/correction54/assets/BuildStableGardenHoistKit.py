"""Build and preview DT01 in a new background Blender process."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
SOURCE52=ROOT/'tools/moonlit-citadel/phase3/closeout-20261014/drafts/keep-surface52/render01/MC_KEEP_SURFACE52_CANDIDATE.blend'
BUILD='MC_P3_GARDEN_HOIST_DG02_R01'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path,name):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module


def roblox_box(box):
    low,high=box['low'],box['high']
    return {'low':[low[0],low[2],-high[1]],'high':[high[0],high[2],-low[1]]}


def mesh_audit(obj):
    mesh=obj.data;mesh.calc_loop_triangles()
    bm=bmesh.new();bm.from_mesh(mesh)
    boundary=sum(edge.is_boundary for edge in bm.edges)
    nonmanifold=sum(not edge.is_manifold for edge in bm.edges)
    islands=[];unseen=set(bm.faces)
    while unseen:
        first=unseen.pop();faces={first};pending=[first]
        while pending:
            for edge in pending.pop().edges:
                for face in edge.link_faces:
                    if face in unseen:unseen.remove(face);faces.add(face);pending.append(face)
        volume=sum(face.verts[0].co.dot(face.verts[i].co.cross(face.verts[i+1].co))/6
                   for face in faces for i in range(1,len(face.verts)-1))
        islands.append(volume)
    bm.free()
    zero=sum(t.area<=1e-12 for t in mesh.loop_triangles)
    assert boundary==nonmanifold==zero==0,(obj.name,boundary,nonmanifold,zero)
    assert all(volume>1e-10 for volume in islands),(obj.name,'inward/flat island',islands)
    return {'name':obj.name,'triangles':len(mesh.loop_triangles),'vertices':len(mesh.vertices),
            'boundary_edges':boundary,'nonmanifold_edges':nonmanifold,'zero_area_triangles':zero,
            'closed_islands':len(islands),'minimum_island_volume':min(islands),'outward_island_winding':True}


def material(a,key,rgb):
    mat=bpy.data.materials.new('MC_P3_'+key);mat.use_nodes=True
    color=tuple(a._linear(value) for value in rgb)+(1,)
    mat.diffuse_color=color;shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=color;shader.inputs['Roughness'].default_value=.8
    if key in {'Iron','Brass'}:shader.inputs['Metallic'].default_value=.45
    mat['PaletteRGB']=list(rgb);mat['ProceduralDetailNeedsBakeForRoblox']=False
    return mat


def camera(collection,name,point,target,ortho):
    data=bpy.data.cameras.new(name);obj=bpy.data.objects.new(name,data);collection.objects.link(obj)
    obj.location=point;obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.type='ORTHO';data.ortho_scale=ortho;data.clip_end=500
    return obj


def previews(authored,root,out,palette,a):
    scene=bpy.context.scene;display=bpy.data.collections.new('DG02R01_Preview_Only');root.children.link(display)
    copies=[]
    for original in authored.objects:
        obj=original.copy();obj.data=original.data;obj.name='Preview_'+original.name;display.objects.link(obj);copies.append(obj)
    wallmat=bpy.data.materials.new('DG02R01_Preview_Wall');wallmat.use_nodes=True
    rgba=tuple(a._linear(channel) for channel in (193,196,195))+(1,)
    wallmat.diffuse_color=rgba;wallmat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=rgba
    wall=a._Mesh();wall.box((0,.48,4),(33,.68,24),'PreviewWall')
    a._object(display,'PreviewOnly_ExistingWall',wall,dict(palette,PreviewWall=wallmat),0,'Excluded from FBX')
    scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
    scene.render.resolution_x=1440;scene.render.resolution_y=960;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.world=bpy.data.worlds.new('DG02R01_Daylight');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.38,.46,.57,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
    sun_data=bpy.data.lights.new('DG02R01_Sun','SUN');sun=bpy.data.objects.new('DG02R01_Sun',sun_data);display.objects.link(sun)
    sun.rotation_euler=(math.radians(28),math.radians(-22),math.radians(-27));sun_data.energy=2.4;sun_data.angle=.18
    scene.view_settings.view_transform='AgX'
    views=[('01-supported-garden','MC_DG_WallGarden24',(27,-40,20),(0,-1.95,5),34),
           ('02-wall-hoist-front','MC_DG_WallHoist',(18,-24,10),(0,-2.6,-.2),14),
           ('03-wall-hoist-rooting','MC_DG_WallHoist',(13,-8,4),(0,-2.8,-.4),12)]
    records=[]
    for name,asset,point,target,scale in views:
        for obj in copies:obj.hide_render=not obj.name.endswith(asset)
        scene.camera=camera(display,name,point,target,scale);scene.render.filepath=str(out/(name+'.png'))
        print('RENDER_START '+name,flush=True);bpy.ops.render.render(write_still=True)
        path=out/(name+'.png');records.append({'file':path.name,'asset':asset,'sha256':sha(path),'bytes':path.stat().st_size,
            'dimensions':[1440,960],'camera':list(point),'target':list(target),'orthographicScale':scale,'originalBlenderRender':True,
            'boundary':'Kit geometry inspection only; not installed-map or native appearance proof'})
    return records


def main():
    assert bpy.app.background,'Use only isolated background Blender.'
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);out=args.output.resolve()
    assert out.is_relative_to(ROOT) and (not out.exists() or not any(out.iterdir())),'Preserve prior outputs.'
    paths=[Path(__file__),HERE/'StableGardenHoistRecipe.py',ROOT/'assets/moonlit_citadel/bl02/architecture.py',ROOT/'assets/moonlit_citadel/phase3/drafts/world_kit.py',
           SOURCE52,ROOT/'docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan52.json',
           ROOT/'docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before/closeout_source52_packet.json']
    paths.extend([HERE/'GardenHoistRecipe.py', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/manifest.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/MC_GARDEN_HOIST_DG02.fbx', HERE/'garden-hoist-final-freeze.json', HERE/'GardenRecipe.py', ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/DetailRecipes.py', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01/manifest.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01/authored-geometry.json', ROOT/'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/FINAL_FREEZE53.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01/manifest.json'])
    hashes={str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in paths}
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE52))
    scene=bpy.context.scene
    inspection={'source':str(SOURCE52.relative_to(ROOT)),'sha256':sha(SOURCE52),'objects':len(scene.objects),
                'meshes':sum(obj.type=='MESH' for obj in scene.objects),
                'protectedVisibleMeshes':len(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects),
                'worldMeshes':len(bpy.data.collections['Final_233_World_Units'].all_objects),
                'keepRelief':list(bpy.data.objects['GrandRearCentralPinnacle__StoneLight'].get('NativePartLocalScaleOverride')),
                'readOnlyInspection':True}
    assert inspection['protectedVisibleMeshes']==717 and inspection['worldMeshes']==639 and inspection['keepRelief']==[1,1,1.04]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if hasattr(bpy.context.preferences.filepaths,'use_save_preview'):bpy.context.preferences.filepaths.use_save_preview=False
    a=load(paths[2],'dt_architecture');e=load(paths[3],'dt_exporter');recipes=load(paths[1],'dt_recipes')
    e.BUILD=BUILD;e.MAX_LIBRARY_TRIANGLES=14000;e.MAX_ASSET_TRIANGLES=5000;e.MAX_EXPORT_PARTS=32
    root=e.new_collection(BUILD,bpy.context.scene.collection);authored=e.new_collection('DG02R01_Authored_Base_Pivot_Units',root)
    exported=e.new_collection('DG02R01_Export_Material_Parts',root);palette={key:material(a,key,rgb) for key,rgb in recipes.PALETTE.items()}
    objects=[];occupied={};notes={}
    for name,g,note in recipes.build_recipes(a,e):
        assert 2<=len(set(g.colors))<=4,(name,'material budget')
        obj=a._object(authored,name,g,palette,0,note);obj['Build']=BUILD;obj['Role']='Noncolliding additive detail'
        objects.append(obj);occupied[name]=g.occupied;notes[name]=note
    bpy.context.view_layer.update();assets,parts=e.export_units(objects,exported,occupied)
    for obj in exported.objects:
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='BEAUTY',ngon_method='BEAUTY')
        bm.to_mesh(obj.data);bm.free();obj.data.update(calc_edges=True)
    topology=[mesh_audit(obj) for obj in exported.objects]
    assert all(len(face.vertices)==3 for obj in exported.objects for face in obj.data.polygons)
    assert len(assets)==2 and sum(p['triangles'] for p in parts)<14000
    actual=[];bounds={}
    for asset in assets:
        bounds[asset['asset']]={'origin':[0,0,0],'front':[0,0,1],'up':[0,1,0],
                              'bounds':roblox_box({'low':asset['bounds'][0],'high':asset['bounds'][1]}),
                              'occupiedBoxes':[roblox_box(box) for box in asset['occupied_boxes_blender']],
                              'occupied':[roblox_box(box) for box in asset['occupied_boxes_blender']],
                              'meshParts':sum(part['asset']==asset['asset'] for part in parts),
                              'triangles':asset['geometry']['triangles'],'mountingNotes':notes[asset['asset']]}
    for obj in exported.objects:
        obj.data.calc_loop_triangles()
        actual.append({'name':obj.name,'asset':obj['AssetKey'],'vertices':[[v.co.x,v.co.z,-v.co.y] for v in obj.data.vertices],
                       'triangles':[list(face.vertices) for face in obj.data.loop_triangles]})
    out.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in exported.objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=next(iter(exported.objects))
    bpy.ops.export_scene.fbx(filepath=str(out/'MC_GARDEN_HOIST_DG02_R01.fbx'),use_selection=True,object_types={'MESH'},
                             axis_forward='-Z',axis_up='Y',apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',
                             use_mesh_modifiers=True,bake_anim=False,add_leaf_bones=False)
    manifest={'exportAllFacesExplicitTriangles':True,'curveRepair':'Only one Iron wheel and six Brass coils use fixed axial torus frames; all other actual vertex geometry is preserved.', 'candidate':BUILD,'units':'1 Blender unit = 1 intended stud','axes':'Roblox=(X,Z,-Y)',
              'front':'Authored intended Roblox +Z, Blender -Y; root must verify actual native import basis before placement',
              'pivot':'All authored unit origins zero; facade back planes -0.10/-0.14 intended stud, ground/roof base Y near0',
              'assets':assets,'export_parts':parts,'part_count':len(parts),'export_triangles':sum(p['triangles'] for p in parts),
              'material_part_topology':topology,'palette':recipes.PALETTE,'source_hashes':hashes,'nativeImportVerified':False}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    (out/'authored-geometry.json').write_text(json.dumps({'axes':'Roblox XYZ','parts':actual},separators=(',',':'))+'\n',encoding='utf8')
    (out/'occupied-geometry.json').write_text(json.dumps({'axes':'Roblox XYZ','assets':bounds},indent=2)+'\n',encoding='utf8')
    (out/'source52-inspection.json').write_text(json.dumps(inspection,indent=2)+'\n',encoding='utf8')
    luau=['--!nonstrict','return {']
    for name,row in bounds.items():
        luau.append('\t['+json.dumps(name)+']={meshParts='+str(row['meshParts'])+',triangles='+str(row['triangles'])+',boxes={')
        for box in row['occupiedBoxes']:
            low,high=box['low'],box['high'];centre=[(a+b)/2 for a,b in zip(low,high)];size=[b-a for a,b in zip(low,high)]
            luau.append('\t\t{center=Vector3.new('+','.join(f'{v:.9g}' for v in centre)+'),size=Vector3.new('+','.join(f'{v:.9g}' for v in size)+')},')
        luau.append('\t}},')
    luau.append('}');(out/'DetailGeometry.luau').write_text('\n'.join(luau)+'\n',encoding='utf8')
    authored.hide_render=True;authored.hide_viewport=True;exported.hide_render=True;exported.hide_viewport=True
    views=previews(authored,root,out,palette,a)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'MC_GARDEN_HOIST_DG02_R01.blend'))
    for path,digest in hashes.items():assert sha(ROOT/path)==digest,'Input altered: '+path
    receipt={'pass':True,'candidate':BUILD,'assets':len(assets),'meshParts':len(parts),'triangles':manifest['export_triangles'],
             'materialPartsClosedManifoldOutward':True,'source52Preserved':True,'source52Inspection':inspection,
             'studioTouched':False,'liveBlenderTouched':False,'uploaded':False,'previews':views,'inputHashes':hashes,
             'files':{p.name:{'bytes':p.stat().st_size,'sha256':sha(p)} for p in out.iterdir() if p.is_file()}}
    (out/'build-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
    print('DT01_BUILD_DONE '+json.dumps({'assets':len(assets),'parts':len(parts),'triangles':manifest['export_triangles'],'output':str(out)}),flush=True)


if __name__=='__main__':main()
