"""Compare one measured corrective composition from ordinary route-height cameras."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/placements'
SOURCE=BASE/'render02/MC_DETAIL53_CANDIDATE.blend'
R01=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
DG02=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final'
PLAN=HERE/'correction54-placement-plan.json'
spec=importlib.util.spec_from_file_location('composition_helpers',BASE/'RenderDetailComposition.py')
h=importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
AXIS,INVERSE=h.AXIS,h.INVERSE


def camera(collection,name,point,target):
    data=bpy.data.cameras.new(name)
    obj=bpy.data.objects.new(name,data)
    collection.objects.link(obj)
    obj.location=AXIS@Vector(point)
    obj.rotation_euler=(AXIS@Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.sensor_fit,data.clip_start,data.clip_end='VERTICAL',.05,3000
    data.angle_y=math.radians(70)
    obj['CourseLocalEye'],obj['CourseLocalTarget']=point,target
    return obj


def render(scene,out,name,cam,profile):
    scene.camera=cam
    background=scene.world.node_tree.nodes['Background']
    sun=bpy.data.lights['Inspection_Sun']
    if profile=='night':
        background.inputs['Color'].default_value=(.14,.20,.32,1)
        background.inputs['Strength'].default_value=.55
        sun.energy,sun.color=.8,(.60,.72,1)
    else:
        background.inputs['Color'].default_value=(.48,.56,.67,1)
        background.inputs['Strength'].default_value=.7
        sun.energy,sun.color=2,(1,.94,.86)
    path=out/(name+'.png')
    if not path.exists():
        scene.render.filepath=str(path)
        print('RENDER_START '+name,flush=True)
        bpy.ops.render.render(write_still=True)
        print('RENDER_DONE '+name,flush=True)
    else:
        print('PRESERVED_ORIGINAL '+name,flush=True)
    return {'file':path.name,'sha256':h.sha(path),'bytes':path.stat().st_size,
            'eye':list(cam['CourseLocalEye']),'target':list(cam['CourseLocalTarget']),
            'verticalFOV':70,'aspect':[1920,1043],'profile':'approximate '+profile,'retouched':False}


def visibility(scene,cam,objects):
    graph=bpy.context.evaluated_depsgraph_get()
    rows={}
    for obj in objects:
        if obj.get('AssetKey')not in ('MC_DG_WallGarden24','MC_DG_WallHoist'):continue
        if obj.get('AssetKey')=='MC_DG_WallGarden24' and not obj.name.endswith('__Foliage'):continue
        name=obj['Detail54Unit']
        summary=rows.setdefault(name,{'samples':0,'visibleSamples':0,'projectedVisibleTrianglePixels':0})
        for face in obj.data.polygons:
            points=[obj.matrix_world@obj.data.vertices[index].co for index in face.vertices]
            centre=sum(points,Vector())/len(points)
            ndc=world_to_camera_view(scene,cam,centre)
            if not(.01<ndc.x<.99 and .01<ndc.y<.99 and ndc.z>0):continue
            summary['samples']+=1
            delta=centre-cam.location
            hit,point,normal,index,blocker,matrix=scene.ray_cast(graph,cam.location,delta.normalized(),distance=delta.length+.001)
            if not hit or blocker.get('Detail54Unit')!=name or (point-centre).length>.03:continue
            summary['visibleSamples']+=1
            projected=[world_to_camera_view(scene,cam,point)for point in points]
            for i in range(1,len(projected)-1):
                a,b,c=projected[0],projected[i],projected[i+1]
                summary['projectedVisibleTrianglePixels']+=abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x))*.5*1920*1043
        summary['projectedVisibleTrianglePixels']=round(summary['projectedVisibleTrianglePixels'],1)
    return rows


def load_templates(folder,blend_name):
    manifest=json.loads((folder/'manifest.json').read_text())
    wanted=[part['name']for part in manifest['export_parts']]
    with bpy.data.libraries.load(str(folder/blend_name),link=False)as (from_data,to_data):
        assert set(wanted).issubset(set(from_data.objects))
        to_data.objects=list(wanted)
    templates={name:obj for name,obj in zip(wanted,to_data.objects)}
    for part in manifest['export_parts']:
        obj=templates[part['name']]
        points=[obj.matrix_world@vertex.co for vertex in obj.data.vertices]
        low=[min(point[a]for point in points)for a in range(3)]
        high=[max(point[a]for point in points)for a in range(3)]
        assert max(abs((low[a]+high[a])*.5-part['center'][a])for a in range(3))<.001,(obj.name,'pivot')
        assert max(abs(high[a]-low[a]-part['size'][a])for a in range(3))<.001,(obj.name,'bounds')
    return templates,manifest


def main():
    assert bpy.app.background
    out=HERE/'render03'
    assert not (out/'MC_CORRECTION54_CANDIDATE.blend').exists(),'Preserve completed evidence.'
    out.mkdir(exist_ok=True)
    plan=json.loads(PLAN.read_text())
    assert plan['supportVerified'] and len(plan['units'])==77
    assert h.sha(ROOT/plan['metadataPath'])==plan['metadataSHA256']
    source_hash,plan_hash=h.sha(SOURCE),h.sha(PLAN)
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene=bpy.context.scene
    scene.cycles.samples=12
    scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1920,1043,100
    world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
    protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
    old_details=list(bpy.data.collections['DT01_Additive_78_Details'].all_objects)
    assert len(world)==639 and len(protected)==717 and len(old_details)==250
    world_digest,protected_digest=h.frozen_digest(world),h.frozen_digest(protected)
    cc=bpy.data.collections.new('Correction54_Comparable_Cameras')
    scene.collection.children.link(cc)
    cameras={name:camera(cc,name,point,target)for name,point,target in (
        ('gate',[-144,5.5,138],[-144,25,30]),
        ('west',[-144,33.5,-112],[-252,50,-80]),
        ('machinery',[112,111.5,-90],[186,105,-108]),
        ('arrival',[-174,21,46],[-231,4,105]),
    )}
    views=[]
    templates,manifest=load_templates(R01,'MC_DETAIL_KIT_DT01.blend')
    newer,new_manifest=load_templates(DG02,'MC_GARDEN_HOIST_DG02_R01.blend')
    templates.update(newer)
    parts=manifest['export_parts']+new_manifest['export_parts']
    for obj in old_details:obj.hide_render=True;obj.hide_viewport=True
    collection=bpy.data.collections.new('DT54_Corrected_77_Details')
    scene.collection.children.link(collection)
    mappings=[]
    for unit in plan['units']:
        transform=AXIS@h.helpers.frame(unit['localCF'])@Matrix.Diagonal((*unit['scale'],1))@INVERSE
        for part in parts:
            if part['asset']!=unit['asset']:continue
            template=templates[part['name']]
            obj=template.copy()
            obj.name='D54_'+unit['name']+'__'+part['material']
            collection.objects.link(obj)
            obj.matrix_world=transform@template.matrix_world
            obj.hide_viewport,obj.hide_render=False,False
            obj['Detail54Unit'],obj['AssetKey']=unit['name'],unit['asset']
            obj['NativeCanCollide'],obj['NativeCanQuery'],obj['NativeCanTouch']=False,False,False
            mappings.append({'object':obj.name,'unit':unit['name'],'asset':unit['asset'],'material':part['material'],'triangles':part['triangles'],
                             'matrix':[value for row in obj.matrix_world for value in row]})
    assert len(mappings)==242 and sum(row['triangles']for row in mappings)==84222
    bpy.context.view_layer.update()
    projected={name:visibility(scene,cam,list(collection.objects))for name,cam in cameras.items()}
    (out/'garden-hoist-projected-visibility.json').write_text(json.dumps(projected,indent=2)+'\n')
    for name,profile in [('west','night'),('machinery','night')]:
        views.append(render(scene,out,'after54-'+name+'-'+profile,cameras[name],profile))
    assert h.frozen_digest(world)==world_digest and h.frozen_digest(protected)==protected_digest
    saved=out/'MC_CORRECTION54_CANDIDATE.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(saved))
    assert h.sha(SOURCE)==source_hash and h.sha(PLAN)==plan_hash
    report={'baseSource':53,'sourceBlendSHA256':source_hash,'planSHA256':plan_hash,'metadataSHA256':plan['metadataSHA256'],
            'counts':plan['counts'],'combined':plan['combined'],'views':views,'projection':projected,'mapping':mappings,
            'oldWorldDigest':world_digest,'oldProtectedDigest':protected_digest,'old52ArtGeometryMaterialsVisibilityExact':True,
            'source53OriginalDetailsArchived':250,'old53SourcePreserved':True,
            'blend':{'file':saved.name,'sha256':h.sha(saved),'bytes':saved.stat().st_size},'scriptSHA256':h.sha(Path(__file__)),
            'boundary':'Original isolated Blender comparisons with vertical70,1920x1043 and exact commanded ordinary route poses; approximate day/night lighting. This is composition evidence, not native appearance or owner acceptance.',
            'studioTouched':False,'liveBlenderTouched':False,'externalUpload':False}
    (out/'correction54-composition-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('CORRECTION54_RENDER_DONE '+json.dumps({'views':len(views),'counts':plan['counts'],'old52Exact':True,'projection':projected}),flush=True)


if __name__=='__main__':main()
