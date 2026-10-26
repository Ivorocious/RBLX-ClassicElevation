"""Assemble accepted art03, DP01f and the frozen physical separation operations."""
import copy
import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=ROOT/'tools/moonlit-citadel/phase3/repair-20261019'
SOURCE=BASE/'art/proposal03/MC_ART_REPAIR55_PROPOSAL.blend'
KIT=BASE/'depth/dp01f/MC_DEPTH_CHASM_DP01.blend'
OPS=BASE/'overlap/expected-native-patch-manifest.json'
CLOSURE=BASE/'overlap/remaining-family-closure.proposed.json'
MAPPING=BASE/'overlap/surface-objects54-bound.json'
NATIVE=ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json'
OUT=HERE/'render01'
AXIS=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INV=AXIS.inverted()
ORIGIN=Vector((4000,300,2600))


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def frame(v):
    return Matrix(((v[3],v[4],v[5],v[0]),(v[6],v[7],v[8],v[1]),(v[9],v[10],v[11],v[2]),(0,0,0,1)))


def unit(obj):
    return obj.get('ArtRepairUnit') or obj.get('Detail54Unit') or obj.get('Source50Unit') or obj.get('NativeUnit')


def digest(objects):
    result=hashlib.sha256()
    for obj in sorted(objects,key=lambda o:o.name):
        result.update(obj.name.encode())
        result.update(repr(tuple(tuple(row)for row in obj.matrix_world)).encode())
        result.update(repr((obj.hide_render,obj.hide_viewport)).encode())
        result.update(repr([tuple(v.co)for v in obj.data.vertices]).encode())
        result.update(repr([(tuple(p.vertices),p.material_index,p.use_smooth)for p in obj.data.polygons]).encode())
        result.update(repr([(m.name,tuple(m.diffuse_color))if m else None for m in obj.data.materials]).encode())
    return result.hexdigest()


def bounds(obj):
    points=[INV@(obj.matrix_world@v.co)for v in obj.data.vertices]
    low=[min(v[k]for v in points)for k in range(3)]
    high=[max(v[k]for v in points)for k in range(3)]
    return {'low':low,'high':high}


def native_bounds(obj,cf):
    points=[cf.inverted()@INV@(obj.matrix_world@v.co)for v in obj.data.vertices]
    low=Vector(tuple(min(v[k]for v in points)for k in range(3)))
    high=Vector(tuple(max(v[k]for v in points)for k in range(3)))
    return (low+high)/2,high-low


def property_value(record,key):
    v=record['props'].get(key,record['props'].get(key.lower()))
    return v.get('value')if isinstance(v,dict)else v


def attributes(record):
    return record['attrs']if isinstance(record['attrs'],dict)else{}


def gameplay_records(scene,native):
    records=native['editable']['records']
    selected={path:record for path,record in records.items()if property_value(record,'CanCollide')is True
              or attributes(record).get('MoonlitHazard')is True
              or attributes(record).get('GuidanceKind')=='SolidMeshArrow' or path=='Finish'}
    counts={'colliders':sum(property_value(r,'CanCollide')is True for r in selected.values()),
            'walkables':sum(attributes(r).get('MCWalkable')is True for r in selected.values()),
            'hazards':sum(attributes(r).get('MoonlitHazard')is True for r in selected.values()),
            'arrows':sum(attributes(r).get('GuidanceKind')=='SolidMeshArrow'for r in selected.values())}
    assert counts=={'colliders':147,'walkables':135,'hazards':55,'arrows':19}
    text=bpy.data.texts.new('Source54_ProtectedGameplay_Records.json')
    text.write(json.dumps({'sourcePath':str(NATIVE.relative_to(ROOT)),'sourceSha256':sha(NATIVE),'records':selected,
                           'expectedOnlyPhysicalTriggerChange':{'path':'Finish','size':[28,12,24],'courseLocalCentre':[-5,156,-30]}},sort_keys=True))
    collection=bpy.data.collections.new('Source55_Gameplay_Bounds_Reference_Not_Rendered')
    scene.collection.children.link(collection)
    cube=bpy.data.meshes.new('Reference_Bounds_Cube')
    cube.from_pydata([(-.5,-.5,-.5),(-.5,-.5,.5),(-.5,.5,-.5),(-.5,.5,.5),(.5,-.5,-.5),(.5,-.5,.5),(.5,.5,-.5),(.5,.5,.5)],[],
                     [(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)])
    cube.update()
    for path,record in selected.items():
        cf=property_value(record,'CFrame')[:]
        size=property_value(record,'Size')[:]
        cf[:3]=[cf[k]-ORIGIN[k]for k in range(3)]
        if path=='Finish':
            size=[28,12,24]
            cf[1]=156
        obj=bpy.data.objects.new('NativeBounds_'+path.replace('/','.'),cube)
        collection.objects.link(obj)
        obj.matrix_world=AXIS@frame(cf)@Matrix.Diagonal((*size,1))
        obj.display_type='WIRE'
        obj.hide_render=True
        obj['NativePath']=path
        obj['BoundsReferenceOnly']=True
        obj['NativeClass']=record['class']
        obj['NativeCanCollide']=property_value(record,'CanCollide')is True
        obj['NativeCanQuery']=property_value(record,'CanQuery')is True
        obj['NativeCanTouch']=property_value(record,'CanTouch')is True
        obj['NativeSize']=size
        obj['NativeCourseLocalCF']=cf
        if path=='Finish':obj['Source55FinishResize']=True
    collection.hide_viewport=True
    collection.hide_render=True
    return dict(counts,records=len(selected),collection=collection.name,notIncludedInSceneryMeshCost=True,
                boundary='Editor-only bounds and original captured records; native installed geometry parity remains the lead native audit.')


def camera(collection,name,point,target):
    data=bpy.data.cameras.new(name)
    obj=bpy.data.objects.new(name,data)
    collection.objects.link(obj)
    obj.location=AXIS@Vector(point)
    obj.rotation_euler=(AXIS@Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.sensor_fit='VERTICAL'
    data.angle_y=math.radians(70)
    data.clip_start,data.clip_end=.05,4000
    obj['CourseLocalEye'],obj['CourseLocalTarget']=point,target
    return obj


def main():
    assert bpy.app.background and not OUT.exists(),'Use isolated background Blender and preserve prior outputs'
    guards={SOURCE:'55f5905706c298a88063771c60f9bef11f6dddda48f5e05fa41c3afb21bbe278',
            KIT:'383999a71c32058b6beebea2b2ef11367426afd586a471bb1da683ab5958bb02',
            OPS:'5af0e812c6581fddd949c2d9726a665d47f5196a02fc7a4539a96634327a090e',
            CLOSURE:'c1dcb99c8d053db22392f742c5b4d18f98b47e5c72388c170b85c275f7cb811b',
            NATIVE:'d7194e7110daaeb386aece58e3c9c984f22f111afae5be363d43bdf70d229892'}
    for path,value in guards.items():assert sha(path)==value,path
    inputs={str(path.relative_to(ROOT)):value for path,value in guards.items()}
    inputs[str(MAPPING.relative_to(ROOT))]=sha(MAPPING)
    inputs[str(Path(__file__).relative_to(ROOT))]=sha(Path(__file__))
    operations=json.loads(OPS.read_text(encoding='utf-8'))['operations']
    assert len(operations)==200
    mapping={r['nativePath']:r['name']for r in json.loads(MAPPING.read_text(encoding='utf-8'))['objects']}
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    bpy.context.view_layer.update()
    scene=bpy.context.scene
    art=[obj for name in ('Final_233_World_Units','DT54_Corrected_77_Details','Oct19_Reused_Bracketed_Banners')
         for obj in bpy.data.collections[name].all_objects if obj.type=='MESH'and not obj.hide_render]
    protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
    assert len(art)==869 and len(protected)==717 and len({unit(o)for o in art})==315
    terrain=[obj for obj in art if unit(obj)=='MC_EC_InnerRavine']
    assert len(terrain)==3
    targets={bpy.data.objects[mapping[row['path']]]for row in operations}
    assert len(targets)==200
    unaffected=[obj for obj in scene.objects if obj.type=='MESH'and obj not in targets and obj not in terrain]
    unaffected_digest=digest(unaffected)
    mesh_data_digest=hashlib.sha256(repr([(obj.name,[tuple(v.co)for v in obj.data.vertices],
                                          [tuple(p.vertices)for p in obj.data.polygons])for obj in sorted(targets,key=lambda o:o.name)]).encode()).hexdigest()
    corrections=[]
    for row in operations:
        obj=bpy.data.objects[mapping[row['path']]]
        assert not obj.hide_render,obj.name
        after=row['afterCFrame'][:]
        after[:3]=[after[k]-ORIGIN[k]for k in range(3)]
        before=after[:]
        before[:3]=row['beforeCoursePosition']
        before_cf,after_cf=frame(before),frame(after)
        old_centre,old_size=native_bounds(obj,before_cf)
        before_size=Vector(row['beforeSize'])
        old_error=max(max(abs(v)for v in old_centre),max(abs(old_size[k]-before_size[k])for k in range(3)))
        assert old_error<.005,(row['path'],old_error)
        scale=Vector(tuple(row['afterSize'][k]/before_size[k]for k in range(3)))
        adjustment=AXIS@after_cf@Matrix.Diagonal((*scale,1))@before_cf.inverted()@INV
        obj.matrix_world=adjustment@obj.matrix_world
        bpy.context.view_layer.update()
        after_centre,after_size=native_bounds(obj,after_cf)
        after_error=max(max(abs(v)for v in after_centre),max(abs(after_size[k]-row['afterSize'][k])for k in range(3)))
        assert after_error<.005,(row['path'],after_error)
        obj['SurfaceSeparation55Path']=row['path']
        obj['SurfaceSeparation55Rules']=';'.join(row['rules'])
        corrections.append({'path':row['path'],'object':obj.name,'rules':row['rules'],'beforeError':old_error,
                            'afterError':after_error,'nativeSizeAfter':row['afterSize'],'nativeCourseLocalCFAfter':after})
    assert digest(unaffected)==unaffected_digest
    final_mesh_data=hashlib.sha256(repr([(obj.name,[tuple(v.co)for v in obj.data.vertices],
                                        [tuple(p.vertices)for p in obj.data.polygons])for obj in sorted(targets,key=lambda o:o.name)]).encode()).hexdigest()
    assert final_mesh_data==mesh_data_digest
    archive=bpy.data.collections.new('Source54_Original_Ravine_Recovery')
    scene.collection.children.link(archive)
    for obj in terrain:
        for collection in list(obj.users_collection):collection.objects.unlink(obj)
        archive.objects.link(obj)
        obj.hide_render,obj.hide_viewport=True,True
    replacement=bpy.data.collections.new('Source55_DP01_InnerChasm')
    scene.collection.children.link(replacement)
    with bpy.data.libraries.load(str(KIT),link=False)as(from_data,to_data):
        to_data.objects=[name for name in from_data.objects if name.startswith('MC_DP_InnerChasm__')]
    assert len(to_data.objects)==2
    for obj in to_data.objects:
        replacement.objects.link(obj)
        obj['Source50Unit']='MC_EC_InnerRavine'
        obj['AssetKey']='MC_DP_InnerChasm'
        obj['NativeLibrary']='DP01'
    final_art=[obj for obj in art if obj not in terrain]+list(to_data.objects)
    bpy.context.view_layer.update()
    assert len(final_art)==868 and len({unit(obj)for obj in final_art})==315
    triangles=sum(len(p.vertices)-2 for obj in final_art for p in obj.data.polygons)
    assert triangles==259002,triangles
    physics=gameplay_records(scene,json.loads(NATIVE.read_text(encoding='utf-8')))
    cameras=bpy.data.collections.new('Source55_Final_Inspection_Cameras')
    scene.collection.children.link(cameras)
    views={
        'gallery-owner':bpy.data.objects['GalleryOwnerPhoto3'],
        'crown-exterior':bpy.data.objects['CrownExterior'],
        'gate-depth':camera(cameras,'Source55_GateDepth',[-144,5.5,130],[-144,-70,50]),
        'crown-depth':camera(cameras,'Source55_CrownDepth',[8,155.5,-30],[160,-100,55]),
    }
    scene.render.engine='CYCLES'
    scene.cycles.samples,scene.cycles.use_denoising=12,True
    scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1920,1043,100
    scene.render.image_settings.file_format='PNG'
    OUT.mkdir()
    images=[]
    for name,cam in views.items():
        path=OUT/('after55-'+name+'.png')
        scene.camera,scene.render.filepath=cam,str(path)
        print('FINAL55_RENDER_START '+name,flush=True)
        bpy.ops.render.render(write_still=True)
        cf=INV@cam.matrix_world
        images.append({'file':path.name,'sha256':sha(path),'bytes':path.stat().st_size,'dimensions':[1920,1043],
                       'cameraCourseLocalCF':[cf[0][3],cf[1][3],cf[2][3],cf[0][0],cf[0][1],cf[0][2],cf[1][0],cf[1][1],cf[1][2],cf[2][0],cf[2][1],cf[2][2]],
                       'verticalFOV':math.degrees(cam.data.angle_y),'retouched':False,'approximateBlenderLighting':True})
        print('FINAL55_RENDER_DONE '+name,flush=True)
    scene.camera=views['gallery-owner']
    bpy.context.view_layer.update()
    assert digest(unaffected)==unaffected_digest
    rows=[]
    for obj in final_art:
        rows.append({'object':obj.name,'unit':unit(obj),'asset':obj.get('AssetKey'),'bounds':bounds(obj),
                     'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),
                     'matrix':[v for line in obj.matrix_world for v in line]})
    blend=OUT/'MC_SOURCE55_FINAL_COMPOSITION.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    report={'pass':True,'sourceRevision':55,'buildRevision':49,'inputHashes':inputs,
            'counts':{'units':315,'meshes':868,'triangles':triangles},'surfaceOperations':corrections,
            'surfaceOperationCount':len(corrections),'surfaceOperationMeshDataExact':True,
            'otherMeshObjectsExact':len(unaffected),'otherMeshObjectsDigest':unaffected_digest,
            'originalThreeRavinePartsArchived':True,'allArt03RetiredPartsStillArchived':True,
            'gameplayReference':physics,'views':images,'actualSceneryPartBounds':len(rows),
            'blend':{'path':str(blend.relative_to(ROOT)),'bytes':blend.stat().st_size,'sha256':sha(blend)},
            'mistAdded':False,'lightingArt03Unchanged':True,'studioTouched':False,'liveBlenderTouched':False,'productionChanged':False,
            'nativeAppearanceProof':False,'boundary':'Offline integrated authored geometry and reference records; root owns installed native preservation, physics, import, moving-view and owner acceptance checks.'}
    (OUT/'source55-composition-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    (OUT/'source55-scenery-part-bounds.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
    print('FINAL55_COMPOSITION_PASS '+json.dumps({'counts':report['counts'],'operations':len(corrections),'images':len(images),'physics':physics}),flush=True)


if __name__=='__main__':main()
