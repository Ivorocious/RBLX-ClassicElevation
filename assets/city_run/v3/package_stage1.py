"""Combine editable source libraries without replacing uploaded packages."""
from pathlib import Path
import bpy, json, hashlib

ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_AssetKit.blend'))
base=json.loads((ROOT/'manifest.json').read_text())
addon=json.loads((ROOT/'district_addon01/manifest.json').read_text())
with bpy.data.libraries.load(str(ROOT/'district_addon01/CityRun_DistrictAddon.blend'),link=False) as (src,dst):
 dst.objects=[r['id'] for r in addon['assets']]
material=bpy.data.materials['V3_Shared_Painted_Atlas']
export=ROOT/'district_addon01/exports';export.mkdir(exist_ok=True)
for ob in dst.objects:
 col=bpy.data.collections.new(ob.name);bpy.context.scene.collection.children.link(col);col.objects.link(ob)
 ob.data.materials.clear();ob.data.materials.append(material)
 ob.location=(0,0,0)
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bpy.ops.export_scene.fbx(filepath=str(export/(ob.name+'.fbx')),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_triangles=True,path_mode='COPY',embed_textures=True,add_leaf_bones=False,bake_anim=False)
bounds=json.loads((ROOT/'district_addon01/bounds.json').read_text())
for r in addon['assets']:
 file=export/(r['id']+'.fbx')
 r['fbx']='exports/'+file.name
 r['fbxBytes']=file.stat().st_size;r['sha256']=hashlib.sha256(file.read_bytes()).hexdigest()
 c=bounds[r['id']]['centerBlender'];d=bounds[r['id']]['dimensions']
 center=[c[0],c[2],-c[1]];size=[d[0],d[2],d[1]]
 r['snapGridStuds']=1
 r['attachmentsRobloxLocal']={'base':[0,0,0],'top':[center[0],center[1]+size[1]/2,center[2]],'front':[center[0],center[1],center[2]+size[2]/2],'back':[center[0],center[1],center[2]-size[2]/2]}
 r['renderRecommendation']=dict(base['assets'][0]['renderRecommendation'])
 r['reusesSharedMaterial']='V3_Shared_Painted_Atlas'
 r['mountingGuide']='../MOUNTING.md'
(ROOT/'district_addon01/manifest.json').write_text(json.dumps(addon,indent=2))
rows=json.loads(json.dumps(base['assets']+addon['assets']))
for r in rows:
 r['fbx']=('district_addon01/' if r['id'] in bounds else 'exports/')+r['fbx']
 r['texture']='painted_atlas.png'

for i,r in enumerate(rows):
 bpy.data.objects[r['id']].location=((i%9)*44,(i//9)*90,0)
bpy.context.scene.name='CityRun_V3_Stage1'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityRun_V3_Stage1.blend'))
packages=[]
for file,asset_id in [('CityRun_V3_AssetKit.fbx','113491549212344'),('district_addon01/CityRun_DistrictAddon.fbx','94105724616140')]:
 packages.append({'file':file,'assetId':asset_id,'sha256':hashlib.sha256((ROOT/file).read_bytes()).hexdigest()})
result={'build':'V3_KIT_05+V3_DISTRICT_ADDON_01','scope':'Stage1 visual assets only','editableSource':'CityRun_V3_Stage1.blend','packages':packages,'totals':{'uniqueAssets':len(rows),'triangles':sum(r['triangles'] for r in rows),'maxAssetTriangles':max(r['triangles'] for r in rows),'materials':1,'textures':1},'atlas':base['atlas'],'robloxTextureId':'rbxassetid://117032649495568','assets':rows}
(ROOT/'stage1-manifest.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result['totals']))
