"""Read original editable geometry in an isolated background Blender process."""
from pathlib import Path
import json
import hashlib
import bpy

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p/'default.project.json').exists())
SOURCE = ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/correction54/render03/MC_CORRECTION54_CANDIDATE.blend'
assert bpy.app.background
sha = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
assessment = json.loads((HERE.parent/'internal/self-surface-assessment56.json').read_text())
current = json.loads((HERE.parent/'internal/surface-objects56.json').read_text())['objects']
original = json.loads((ROOT/'tools/moonlit-citadel/phase3/repair-20261019/overlap/surface-objects54-bound.json').read_text())['objects']
paths = {r['path']: r for r in current}
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
rows=[]
for family in assessment['families']:
    if not family['exactParts']:
        continue
    for row in family['rows']:
        if row['minimumVisibleGap'] > .0005:
            continue
        meta = original[paths[row['path']]['sourceIndex']]
        obj = bpy.data.objects[meta['name']]
        rows.append({'asset':family['asset'],'path':row['path'],'name':obj.name,'data':obj.data.name,
                     'dataUsers':obj.data.users,'polygons':len(obj.data.polygons),'vertices':len(obj.data.vertices),
                     'uv':[l.name for l in obj.data.uv_layers], 'customNormals':obj.data.has_custom_normals,
                     'smoothFaces':sum(p.use_smooth for p in obj.data.polygons),
                     'materials':[m.name if m else None for m in obj.data.materials],
                     'matrix':list(meta['matrix']),'scale':list(obj.scale),'modifiers':[m.type for m in obj.modifiers],
                     'meshId':row['sourceMeshId'],'witnessFaces':row['faces'],
                     'witnessCoordinates':[[list(obj.data.vertices[v].co) for v in obj.data.polygons[i].vertices] for i in row['faces']]})
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==sha
(HERE/'original-mesh-inspection.json').write_text(json.dumps({'source':str(SOURCE.relative_to(ROOT)),'sha256':sha,'rows':rows},indent=2))
print('INSPECTED '+str(len(rows)),flush=True)
