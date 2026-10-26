"""Audit source geometry and a local FBX reimport without changing Studio."""
from pathlib import Path
import bpy,json,math,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;OUT=ROOT.parents[2]/'docs/artifacts/city-run/v3'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
manifest=json.loads((ROOT/'manifest.json').read_text());checks=[];expected={}
for ob in list(bpy.context.scene.objects):
 if not ob.get('V3AssetId'):continue
 me=ob.data;me.calc_loop_triangles();zero=sum(t.area<1e-7 for t in me.loop_triangles)
 uses={}
 for poly in me.polygons:
  for edge in poly.edge_keys:uses[edge]=uses.get(edge,0)+1
 planes=[poly for poly in me.polygons if all(uses[e]==1 for e in poly.edge_keys)]
 inward=[poly.index for poly in planes if poly.normal.x*poly.center.x+poly.normal.y*poly.center.y < -0.001]
 uv=me.uv_layers.active
 validUV=bool(uv) and all(math.isfinite(c) and 0<=c<=1 for p in uv.data for c in p.uv)
 expected[ob.name]={'dimensions':list(ob.dimensions),'triangles':len(me.loop_triangles)}
 checks.append({'id':ob.name,'zeroAreaTriangles':zero,'uvValid':validUV,'materialSlots':len(me.materials),'negativeScale':any(v<=0 for v in ob.scale),'isolatedArtworkFaces':len(planes),'inwardArtworkFaces':inward,'dimensions':list(ob.dimensions)})
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'CityRun_V3_AssetKit.fbx'))
roundtrip=[]
for ob in bpy.context.scene.objects:
 if ob.type!='MESH':continue
 me=ob.data;me.calc_loop_triangles();e=expected.get(ob.name)
 roundtrip.append({'id':ob.name,'expectedFound':bool(e),'dimensionsMaxError':max(abs(a-b)for a,b in zip(ob.dimensions,e['dimensions'])) if e else None,'trianglesMatch':len(me.loop_triangles)==e['triangles'] if e else False,'materials':len(me.materials),'hasImage':any(n.type=='TEX_IMAGE' and n.image for m in me.materials if m and m.use_nodes for n in m.node_tree.nodes)})
result={'build':manifest['build'],'sourceAssets':len(checks),'sourceChecks':checks,'roundtripChecks':roundtrip,'localFbxRoundtripPassed':len(roundtrip)==len(checks) and all(r['expectedFound'] and r['dimensionsMaxError']<.001 and r['trianglesMatch'] and r['hasImage'] for r in roundtrip),'sourcePassed':all(r['zeroAreaTriangles']==0 and not r['inwardArtworkFaces'] and r['uvValid'] and r['materialSlots']==1 and not r['negativeScale'] for r in checks),'packageSHA256':hashlib.sha256((ROOT/'CityRun_V3_AssetKit.fbx').read_bytes()).hexdigest(),'note':'Local Blender source and FBX reimport only; not Roblox import, mobile frame-time or map validation.'}
(OUT/'asset-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items()if k not in ['sourceChecks','roundtripChecks']}))
