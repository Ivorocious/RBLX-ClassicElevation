from pathlib import Path
import bpy,json,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;V3=ROOT.parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_Final03_Assets.blend'))
new={o.name:o for o in bpy.data.objects if o.name.startswith('F03_') and o.type=='MESH'}
with bpy.data.libraries.load(str(V3/'CityRun_V3_Stage1.blend'),link=False)as(src,dst):
 dst.objects=[n for n in src.objects if n.startswith('V3_')]
old={o.name:o for o in dst.objects if o}
source={**old,**new}
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
plan=json.loads((ROOT/'layout.json').read_text())
groups={}
for name in ['Architecture','Props','Roofs','Course reference - not exported']:
 c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);groups[name]=c
records={r['id']:r for r in json.loads((ROOT/'manifest.json').read_text())['assets']}
records.update({r['id']:r for r in json.loads((V3/'stage1-manifest.json').read_text())['assets']})
for i,p in enumerate(plan['placements']):
 s=source[p['asset']];o=s.copy();o.data=s.data
 o.name=f'{i+1:03d}_{p["label"]}';o.hide_set(False);o.hide_render=False
 d=records[p['asset']]['dimensionsRobloxXYZ'];sz=p['size']
 o.scale=(sz[0]/d[0],sz[2]/d[2],sz[1]/d[1])
 x,y,z=p['pos'];o.location=(x-3500,-z,y);o.rotation_euler=(0,0,math.radians(p['yaw']))
 o['LayoutIndex']=i+1;o['V3AssetId']=p['asset'];o['Build']=plan['build']
 groups[p['category']].objects.link(o)
# Carry finish landmarks into the Blender preview as source reference geometry.
refs=json.loads((V3.parents[2]/'docs/artifacts/city-run/v3/stage2/course-colliders.json').read_text())
for i,(name,x,y,z,sx,sy,sz)in enumerate(refs):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(x-3500,-z,y));o=bpy.context.object
 o.name=f'REFERENCE_{i}_{name}';o.dimensions=(sx,sz,sy);o.hide_render=True;o.display_type='WIRE';o['NotForExport']=True
 for c in list(o.users_collection):c.objects.unlink(o)
 groups['Course reference - not exported'].objects.link(o)
for r in plan.get('accentParts',[]):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(r['pos'][0]-3500,-r['pos'][2],r['pos'][1]));o=bpy.context.object
 o.name='ACCENT_'+r['name'];o.dimensions=(r['size'][0],r['size'][2],r['size'][1]);o['NativeAccent']=True
 m=bpy.data.materials.new(r['name']);m.diffuse_color=tuple(v/255 for v in r['color'])+(1,);o.data.materials.append(m)
bpy.context.scene.name=plan['build'];bpy.context.scene['RobloxOrigin']=[3500,0,0]
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityRun_Final03_Assembly.blend'))
errors=[];tris=0
for o in bpy.context.scene.objects:
 if 'LayoutIndex'not in o:continue
 p=plan['placements'][o['LayoutIndex']-1];x,y,z=p['pos']
 if max(abs(o.location[j]-[x-3500,-z,y][j])for j in range(3))>.002:errors.append(o.name+' position')
 o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
report={'build':plan['build'],'visualPlacements':len(plan['placements']),'visualTriangles':tris+12*len(plan.get('accentParts',[])),'nativeAccentParts':len(plan.get('accentParts',[])),'newTextureRGBA8Bytes':128*128*4,'errors':errors,'courseReferences':len(refs),'newNativeSourceMatched':1111}
(ROOT/'blender-audit.json').write_text(json.dumps(report,indent=2));print(json.dumps(report));assert not errors

from mathutils.bvhtree import BVHTree
clearance=[]
for asset,point in [('F03_C13_Surface_StationMain_00_06',(3823.555664,97.538887,57)),('F03_C13_Surface_StationMain_00_00',(3705,88.428574,50.857143))]:
 o=next(o for o in bpy.context.scene.objects if o.get('V3AssetId')==asset and 'LayoutIndex' in o)
 verts=[o.matrix_world@v.co for v in o.data.vertices];faces=[list(f.vertices)for f in o.data.polygons]
 tree=BVHTree.FromPolygons(verts,faces);q=Vector((point[0]-3500,-point[2],point[1]));hit=tree.find_nearest(q)
 clearance.append(dict(asset=asset,headCenter=list(point),nearestSurfaceDistance=hit[3]))
(ROOT/'clearance-geometry.json').write_text(json.dumps(clearance,indent=2));print('GEOMETRY_CLEARANCE',json.dumps(clearance))
