from pathlib import Path
import json,hashlib
root=Path('assets/city_run/v3');art=Path('docs/artifacts/city-run/v3/stage2/build02')
layout=json.loads((root/'stage2-layout.json').read_text());audit=json.loads((art/'audit.json').read_text())
files=['CityRun_V3_Stage2.blend','CityRun_V3_Stage2.rbxm','stage2-layout.json','assemble_stage2.luau','plan_stage2.py','assemble_stage2_blender.py','audit_stage2.luau']
manifest={'build':layout['build'],'scope':'V3 scenery assembly; gameplay inherited unchanged from preserved V2','studioSource':'ServerStorage.CityRunInspectionSources.Rebuilt','editorPreview':'Workspace.CityRunV3Stage2Preview (8000 studs east)','instances':350,'visualTriangles':137672,'uniqueVisualMeshes':31,'files':[{ 'path':n,'bytes':(root/n).stat().st_size,'sha256':hashlib.sha256((root/n).read_bytes()).hexdigest()}for n in files],'metrics':{k:audit[k]for k in ['original','optimized','rebuilt']},'nativeRoundTrip':{'bytes':1013060,'descendants':4298,'pivotSame':True,'visualParts':350},'reviews':{'LunaMaxGrounding':8.2,'LunaMaxReadability':8.2,'TerraHigh':8.2,'SolLow':8.6},'runtime':'Inspection starts and UI loads; manual variant-switch test pending','performance':'No measured mobile FPS, memory, or20player claim','evidence':[{'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(art.glob('*.jpg'))]}
(root/'stage2-manifest.json').write_text(json.dumps(manifest,indent=2))
assert len(manifest['evidence'])==17
print('Manifest written: 17 native screenshots, 7 source/export files')
