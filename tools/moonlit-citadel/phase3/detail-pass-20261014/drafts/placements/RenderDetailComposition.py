"""Add the measured DT01 R01 plan to a preserved Source52 composition and render comparisons."""
import hashlib
import importlib.util
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
SOURCE=ROOT/'tools/moonlit-citadel/phase3/closeout-20261014/drafts/keep-surface52/render01/MC_KEEP_SURFACE52_CANDIDATE.blend'
KIT_BASE=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
KIT=KIT_BASE/'MC_DETAIL_KIT_DT01.blend'
PLAN=HERE/'detail-placement-plan.json'
HELPER=ROOT/'tools/moonlit-citadel/phase3/closeout-20261014/drafts/crown-refinement/RenderCrownRefinement.py'
spec=importlib.util.spec_from_file_location('saved_render_helpers',HELPER)
helpers=importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
AXIS,INVERSE=helpers.AXIS,helpers.INVERSE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frozen_digest(objects):
    h=hashlib.sha256()
    for obj in sorted(objects,key=lambda o:o.name):
        h.update(obj.name.encode())
        h.update(str(tuple(v for line in obj.matrix_world for v in line)).encode())
        h.update(str((obj.hide_render,obj.hide_viewport,obj.visible_camera,obj.visible_shadow)).encode())
        if obj.type=='MESH':
            h.update(str([tuple(v.co)for v in obj.data.vertices]).encode())
            h.update(str([(tuple(p.vertices),p.material_index,p.use_smooth)for p in obj.data.polygons]).encode())
            h.update(str([(m.name,tuple(m.diffuse_color))if m else None for m in obj.data.materials]).encode())
    return h.hexdigest()


def main():
    assert bpy.app.background
    out=HERE/'render02'
    assert not out.exists(),'Preserve earlier original evidence.'
    out.mkdir()
    source_sha,kit_sha,plan_sha=sha(SOURCE),sha(KIT),sha(PLAN)
    report=json.loads(PLAN.read_text())
    assert report['supportVerified'] and len(report['units'])==78
    assert sha(ROOT/report['metadataPath'])==report['metadataSHA256']
    manifest=json.loads((KIT_BASE/'manifest.json').read_text())
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene=bpy.context.scene
    scene.cycles.samples=12
    scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage=1600,900,100
    if hasattr(bpy.context.preferences.filepaths,'use_save_preview'):
        bpy.context.preferences.filepaths.use_save_preview=False
    old_world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
    protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
    assert len(old_world)==639 and len(protected)==717
    old_digest,protected_digest=frozen_digest(old_world),frozen_digest(protected)
    collections={}
    for name in ('DT01_Additive_78_Details','DT01_Inspection_Cameras'):
        collection=bpy.data.collections.new(name)
        scene.collection.children.link(collection)
        collections[name]=collection
    render_collection=collections['DT01_Additive_78_Details']
    camera_collection=collections['DT01_Inspection_Cameras']
    views=[]
    wanted={part['name']for part in manifest['export_parts']}
    with bpy.data.libraries.load(str(KIT),link=False)as (from_data,to_data):
        assert wanted.issubset(set(from_data.objects))
        to_data.objects=[name for name in from_data.objects if name in wanted]
    templates={obj.name:obj for obj in to_data.objects}
    assert len(templates)==26
    for part in manifest['export_parts']:
        obj=templates[part['name']]
        points=[obj.matrix_world@vertex.co for vertex in obj.data.vertices]
        low=Vector(tuple(min(point[a]for point in points)for a in range(3)))
        high=Vector(tuple(max(point[a]for point in points)for a in range(3)))
        assert max(abs((low[a]+high[a])*.5-part['center'][a])for a in range(3))<.001,(obj.name,'pivot')
        assert max(abs(high[a]-low[a]-part['size'][a])for a in range(3))<.001,(obj.name,'bounds')
    mappings=[]
    for unit in report['units']:
        transform=AXIS@helpers.frame(unit['localCF'])@Matrix.Diagonal((*unit['scale'],1))@INVERSE
        for part in manifest['export_parts']:
            if part['asset']!=unit['asset']:
                continue
            template=templates[part['name']]
            obj=template.copy()
            obj.name=unit['name']+'__'+part['material']
            render_collection.objects.link(obj)
            obj.matrix_world=transform@template.matrix_world
            obj.hide_viewport,obj.hide_render=False,False
            obj['Detail53Unit'],obj['AssetKey'],obj['District']=unit['name'],unit['asset'],unit['district']
            obj['RobloxLocalCF'],obj['AuthorScale']=unit['localCF'],unit['scale']
            obj['NativeCanCollide'],obj['NativeCanQuery'],obj['NativeCanTouch']=False,False,False
            mappings.append({'object':obj.name,'unit':unit['name'],'asset':unit['asset'],'material':part['material'],
                             'triangles':part['triangles'],'blenderMatrix':[value for line in obj.matrix_world for value in line]})
    assert len(mappings)==250 and sum(row['triangles']for row in mappings)==92092
    bpy.context.view_layer.update()
    for name,position,target in (
        ('02-detail53-gate-after',(-144,5.5,138),(-144,25,30)),
        ('03-detail53-west-climb',(-144,33.5,-112),(-252,50,-80)),
        ('04-detail53-gallery-standing',(-60,57.5,46),(18,65,78)),
        ('05-detail53-crown-standing',(6,155.5,-18),(38,85,106)),
        ('06-detail53-overall',(-510,400,450),(0,55,-10)),
    ):
        views.append(helpers.render(scene,camera_collection,out,name,position,target,'night'))
    assert frozen_digest(old_world)==old_digest
    assert frozen_digest(protected)==protected_digest
    saved=out/'MC_DETAIL53_CANDIDATE.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(saved))
    assert sha(SOURCE)==source_sha and sha(KIT)==kit_sha and sha(PLAN)==plan_sha
    output={'baseSource':52,'sourceBlend':str(SOURCE.relative_to(ROOT)),'sourceBlendSHA256':source_sha,
            'kitBlendSHA256':kit_sha,'planSHA256':plan_sha,'metadataSHA256':report['metadataSHA256'],
            'newUnits':78,'newMeshParts':250,'newTriangles':92092,'oldWorldParts':639,'oldProtectedObjects':717,
            'oldWorldDigest':old_digest,'oldProtectedDigest':protected_digest,'oldGeometryMaterialsVisibilityPreserved':True,
            'assemblyMapping':mappings,'views':views,'blend':{'file':saved.name,'sha256':sha(saved),'bytes':saved.stat().st_size},
            'scriptSHA256':sha(Path(__file__)),'studioTouched':False,'liveBlenderTouched':False,'externalUpload':False,
            'boundary':'Unretouched isolated Blender assembly of frozen Source52 plus measured DT01 R01 additions. Lighting is approximate inspection night; this is an art comparison, not native Roblox rendering proof.'}
    (out/'detail-composition-report.json').write_text(json.dumps(output,indent=2)+'\n')
    print('DETAIL_RENDER_COMPLETE '+json.dumps({'views':len(views),'units':78,'oldPreserved':True,'blend':str(saved)}),flush=True)


if __name__=='__main__':
    main()
