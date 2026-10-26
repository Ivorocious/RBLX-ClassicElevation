"""Reopen the combined scene and check its exact costs, operations and support tops."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
BASE=HERE.parent
OUT=HERE/'render01'
INV=Matrix(((1,0,0),(0,0,1),(0,-1,0)))


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def unit(obj):
    return obj.get('ArtRepairUnit')or obj.get('Detail54Unit')or obj.get('Source50Unit')or obj.get('NativeUnit')


def triangles(objects):
    vertices,faces=[],[]
    for obj in objects:
        offset=len(vertices)
        vertices.extend(INV@(obj.matrix_world@v.co)for v in obj.data.vertices)
        for p in obj.data.polygons:
            for i in range(1,len(p.vertices)-1):faces.append((offset+p.vertices[0],offset+p.vertices[i],offset+p.vertices[i+1]))
    return BVHTree.FromPolygons(vertices,faces,all_triangles=True)


def main():
    assert bpy.app.background
    report=json.loads((OUT/'source55-composition-report.json').read_text(encoding='utf-8'))
    scene_path=ROOT/report['blend']['path']
    assert sha(scene_path)==report['blend']['sha256']
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    scene=bpy.context.scene
    bpy.context.view_layer.update()
    art=[obj for name in ('Final_233_World_Units','DT54_Corrected_77_Details','Oct19_Reused_Bracketed_Banners','Source55_DP01_InnerChasm')
         for obj in bpy.data.collections[name].all_objects if obj.type=='MESH'and not obj.hide_render]
    counts={'units':len({unit(o)for o in art}),'meshes':len(art),'triangles':sum(len(p.vertices)-2 for o in art for p in o.data.polygons)}
    assert counts=={'units':315,'meshes':868,'triangles':259002}
    applied=[o for o in scene.objects if o.get('SurfaceSeparation55Path')]
    assert len(applied)==200
    saved={r['object']:r for r in json.loads((OUT/'source55-scenery-part-bounds.json').read_text(encoding='utf-8'))}
    matrix_error=0
    for obj in art:
        row=saved[obj.name]
        matrix_error=max(matrix_error,max(abs(a-b)for a,b in zip(row['matrix'],[v for line in obj.matrix_world for v in line])))
    assert matrix_error<.001
    records=json.loads(bpy.data.texts['Source54_ProtectedGameplay_Records.json'].as_string())
    proxy_collection=bpy.data.collections['Source55_Gameplay_Bounds_Reference_Not_Rendered']
    assert proxy_collection.hide_render and proxy_collection.hide_viewport
    assert len(proxy_collection.objects)==len(records['records'])==222
    finish=next(o for o in proxy_collection.objects if o['NativePath']=='Finish')
    assert list(finish['NativeSize'])==[28,12,24]and list(finish['NativeCourseLocalCF'])[:3]==[-5,156,-30]
    archived=list(bpy.data.collections['Source54_Original_Ravine_Recovery'].all_objects)
    assert len(archived)==3 and all(o.hide_render for o in archived)
    for obj in archived:obj.hide_viewport=False
    bpy.context.view_layer.update()
    terrain_names={'MC_EC_WestWoodedCliff','MC_EC_EastPanoramaSlope','MC_EC_NorthHighRidge','MC_EC_SouthValleyRidge'}
    outer=[o for o in art if unit(o)in terrain_names]
    new_inner=list(bpy.data.collections['Source55_DP01_InnerChasm'].all_objects)
    assert len(outer)==12 and len(new_inner)==2
    old_bvh,new_bvh=triangles(outer+archived),triangles(outer+new_inner)
    source=json.loads((BASE/'depth/source54-depth-inputs.json').read_text(encoding='utf-8'))
    supports=[]
    failures=[]
    probe_count=0
    for seat in source['groundContactBoxes']:
        row={'unit':seat['name'],'boxes':len(seat['boxes']),'probes':0,'maximumTerrainHeightDifference':0,
             'shift':[-.08,0,0]if seat['name']=='WestArchMiddleWing'else[0,0,0]}
        for box in seat['boxes']:
            f,size=box['frame'],box['size']
            half_x=max(0,size[0]/2-.01)
            half_z=max(0,size[2]/2-.01)
            for x in (-half_x,0,half_x):
                for z in (-half_z,0,half_z):
                    point=Vector((f[0]+f[3]*x+f[5]*z+row['shift'][0],500,f[2]+f[9]*x+f[11]*z))
                    before=old_bvh.ray_cast(point,Vector((0,-1,0)),2000)[0]
                    after=new_bvh.ray_cast(point,Vector((0,-1,0)),2000)[0]
                    row['probes']+=1;probe_count+=1
                    if before is None or after is None:
                        failures.append({'unit':seat['name'],'point':list(point),'before':None if before is None else list(before),'after':None if after is None else list(after)})
                    else:
                        difference=abs(before.y-after.y)
                        row['maximumTerrainHeightDifference']=max(row['maximumTerrainHeightDifference'],difference)
                        if difference>.003:failures.append({'unit':seat['name'],'point':list(point),'difference':difference})
        supports.append(row)
    assert not failures,failures[:5]
    assert probe_count==1341
    packet_path=ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/repair_source55_packet.json'
    packet=json.loads(packet_path.read_text(encoding='utf-8'))
    assert packet['sourceRevision']==55 and packet['buildRevision']==49
    modules={r['name']:r for r in packet['records']}
    assert modules['SurfaceSeparation']['sha256']=='cf0d7080f07a7d006c67614d62f72964483218a697f41c05c76ae73d81d1d57d'
    assert 'Layout.FinishGate = {point = v(-5, 150, -30), size = v(28, 12, 24), yaw = math.pi / 2}'in modules['Layout']['source']
    result={'pass':True,'blendSha256':sha(scene_path),'counts':counts,'surfaceOperations':len(applied),
            'maximumSavedMatrixError':matrix_error,'protectedNativeReferenceCounts':report['gameplayReference'],
            'source55FinishReference':{'size':[28,12,24],'centre':[-5,156,-30]},
            'groundedUnits':38,'existingGroundContactBoxes':149,'terrainSupportProbes':probe_count,
            'supportProbeEdgeInset':.01,
            'allExistingSupportTopHeightsPreservedAtFinalSeats':True,'supportChecks':supports,
            'source55Packet':{'path':str(packet_path.relative_to(ROOT)),'sha256':sha(packet_path),'modules':len(packet['records'])},
            'art03SupportProof':{'path':str((BASE/'art/proposal03/gallery-support-probes.json').relative_to(ROOT)),
                                 'sha256':sha(BASE/'art/proposal03/gallery-support-probes.json')},
            'art03SupportDetailsShiftIncludedOnce':True,'mistAdded':False,'readOnlyReopening':True,
            'nativeInstalledGeometryParity':False,'nativeAppearanceProof':False}
    (OUT/'source55-reopening-support-summary.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('FINAL55_REOPEN_PASS '+json.dumps({'counts':counts,'operations':len(applied),'supportProbes':probe_count,'matrixError':matrix_error}),flush=True)


if __name__=='__main__':main()
