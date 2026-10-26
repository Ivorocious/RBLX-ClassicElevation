"""Adapt the established renderer to the current native archive and all retained meshes."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
source=(ROOT/'tools/stud-garden-v2/render_offline.py').read_text()
source=source.replace('parents[2]','parents[3]')
source=source.replace('origin=Vector((9200,80,3500))',"origin=Vector(data['attributes']['CourseOrigin']['value'])")
source=source.replace("for version in ('M01','M02'):\n    with bpy.data.libraries.load(str(root/f'assets/stud_garden_v2/phase1/SGV2_{version}.blend'),link=False) as (a,b):", "for asset_file in [root/f'assets/stud_garden_v2/phase1/SGV2_{version}.blend' for version in ('M01','M02')]+[root/'docs/artifacts/stud-garden-v2/phase3/f04/SGV2_Phase3_F04.blend']:\n    with bpy.data.libraries.load(str(asset_file),link=False) as (a,b):")
source=source.replace("missing=[]\nfor i,p", "missing=[]\nlabels={}\nfor label in data['labels']:\n    if 'partPath' in label:labels.setdefault(label['partPath'],[]).append(label)\nfor i,p")
source=source.replace("p.get('labels',[])","labels.get(p['path'],[])")
source=source.replace("tuple((v[i]-center[i])/max(size[i],1e-6) for i in range(3))", "tuple((v[i]-center[i])/max(size[i],1e-6)*(1 if i==1 else -1) for i in range(3))")
source=source.replace("size=[min(p['size'])]*3 if p['shape']=='Ball' else p['size']", "size=[min(p['size'])]*3 if p['shape']=='Ball' else ([p['size'][0],min(p['size'][1:]),min(p['size'][1:])] if p['shape']=='Cylinder' else p['size'])")
source=source.replace("scene.render.engine='CYCLES';scene.cycles.samples=12", "assert not missing, f'Missing source geometry: {missing}'\nscene.render.engine='CYCLES';scene.cycles.samples=16")
source=source.replace("for view in views:","bpy.ops.wm.save_as_mainfile(filepath=str(args.output.parent/(data['attributes']['CandidateId']+'_Offline.blend')))\nfor view in views:")
source=source.replace("assert not missing, f'Missing source geometry: {missing}'", "assert not missing, f'Missing source geometry: {missing}'\nmesh_metrics=[{'path':p['path'],'name':p['name'],'triangles':sum(len(face)-2 for face in sources[p['name']][1])} for p in data['parts'] if p['class']=='MeshPart' and p['transparency']<.99]\n(args.output.parent/'mesh-source-metrics.json').write_text(json.dumps({'visibleMeshPartInstances':len(mesh_metrics),'sourceTriangleInstances':sum(p['triangles'] for p in mesh_metrics),'rows':mesh_metrics,'limits':'Measured from original local Blender mesh topology instantiated as in the archive. Native primitive triangles, GPU batching, memory and device performance excluded.'},indent=2))")
source=source.replace("bpy.ops.render.render(write_still=True)","bpy.ops.render.render(write_still=True)\n    print('CLOSING_VIEW '+view['name'],flush=True)")
source=source.replace("data['candidate']","data['attributes']['CandidateId']")
(ROOT/'tools/stud-garden-v2/closing/render_preview.py').write_text(source)
views=[
    {'name':'01-overview','eye':[-320,255,345],'target':[0,24,0],'ortho':520},
    {'name':'02-formed-tool-and-separation','eye':[-76,19,145],'target':[-46,10,106]},
    {'name':'03-checkpoint-01','eye':[-128,14,87],'target':[-152,17,78]},
    {'name':'04-strange-grove','eye':[10,15,-154],'target':[58,22,-127]},
    {'name':'05-beanstalk-entrance','eye':[76,14.6,-59],'target':[108,35,43],'lens':25},
    {'name':'06-harvest-market','eye':[129,22,81],'target':[133,18,154],'lens':28},
]
(ROOT/'docs/artifacts/stud-garden-v2/closing-20261005/c02-offline/preview-views.json').write_text(json.dumps(views,indent=2))
print(json.dumps({'views':len(views),'renderer':'tools/stud-garden-v2/closing/render_preview.py'}))
