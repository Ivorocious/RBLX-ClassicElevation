from pathlib import Path
import bpy,json,math
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'CityRun_V3_Stage2.blend'))
p=json.loads((ROOT/'stage2-layout.json').read_text());rows={o['LayoutIndex']:o for o in bpy.context.scene.objects if 'LayoutIndex' in o};errors=[]
for i,v in enumerate(p['placements'],1):
 o=rows.get(i)
 if o is None:errors.append(f'Missing {i}');continue
 if o['V3AssetId']!=v['asset']:errors.append(f'Wrong asset {i}')
 x,y,z=v['pos'];target=(x-3500,-z,y)
 if max(abs(o.location[j]-target[j])for j in range(3))>.002:errors.append(f'Position {i}')
 if max(abs(o.dimensions[j]-[v['size'][0],v['size'][2],v['size'][1]][j])for j in range(3))>.01:errors.append(f'Size {i}')
 if abs(o.rotation_euler.z-math.radians(v['yaw']))>.001:errors.append(f'Rotation {i}')
 if o.get('Build')!=p['build']:errors.append(f'Build {i}')
tris=sum(sum(len(poly.vertices)-2 for poly in o.data.polygons)for o in rows.values());unique=len(set(o.data.name for o in rows.values()))
assert len(rows)==350 and unique==31 and tris==137672
assert bpy.context.scene.name==p['build']
result={'build':p['build'],'instances':len(rows),'sharedMeshes':unique,'triangles':tris,'errors':errors,'referenceObjects':len([o for o in bpy.context.scene.objects if o.get('NotForExport')])}
(ROOT/'stage2-blender-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));assert not errors
