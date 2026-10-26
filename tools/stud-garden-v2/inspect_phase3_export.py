"""Record evaluated Blender bounds for a saved, immutable import candidate."""
import argparse
import json
from pathlib import Path
import sys
import bpy

parser=argparse.ArgumentParser()
parser.add_argument('folder',type=Path)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
m=json.loads((args.folder/'manifest.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(args.folder/(m['candidate']+'.blend')))
records={}
for row in m['meshes']:
    obj=bpy.data.objects[row['name']]
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    vertices=[(v.x,v.z,-v.y) for v in points]
    records[row['name']]={'bounds':[[min(v[k] for v in vertices) for k in range(3)],
                                   [max(v[k] for v in vertices) for k in range(3)]],
                         'triangles':len(obj.data.polygons)}
(args.folder/'export-bounds.json').write_text(json.dumps(records,indent=2))
print(json.dumps({'meshes':len(records),'triangles':sum(r['triangles'] for r in records.values())}))
