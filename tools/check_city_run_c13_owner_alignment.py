import bpy,json
from pathlib import Path
bpy.ops.wm.open_mainfile(filepath=str(Path('assets/city_run/CityRun_C13_terminal.blend').resolve()))
rows=json.loads(Path('docs/artifacts/city-run/C13-owner-review-native-audit.json').read_text())['records']
live={r['path'].split('/')[-1]:r for r in rows if '/Decoration/C13Terminal/' in r['path']}
fail=[];maxerr=0;count=0
for obj in bpy.context.scene.objects:
 if obj.type!='MESH' or obj.name.startswith('Marker'):continue
 r=live.get(obj.name)
 if not r:fail.append({'mesh':obj.name,'reason':'missing'});continue
 pts=[obj.matrix_world@v.co for v in obj.data.vertices]
 low=[min(p[i] for p in pts) for i in range(3)];high=[max(p[i] for p in pts) for i in range(3)]
 center=[(low[i]+high[i])/2 for i in range(3)];size=[high[i]-low[i] for i in range(3)]
 expected=[center[0]+3500,center[2],-center[1],size[0],size[2],size[1]]
 actual=r['cf'][:3]+r['size'];error=max(abs(a-b) for a,b in zip(expected,actual));maxerr=max(maxerr,error);count+=1
 if error>.003:fail.append({'mesh':obj.name,'maxError':error})
report={'build':'C13_05','checkedLiveMeshes':count,'maxCoordinateOrSizeError':maxerr,'tolerance':.003,'failures':fail}
Path('docs/artifacts/city-run/C13_05-source-alignment.json').write_text(json.dumps(report,indent=2));print(report);assert not fail
