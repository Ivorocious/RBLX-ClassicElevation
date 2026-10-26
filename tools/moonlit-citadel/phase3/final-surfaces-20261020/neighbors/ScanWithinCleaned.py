"""Independently scan self/within-unit faces using real replacement polygon IDs."""
import json
import sys
from pathlib import Path
import numpy as np
import ScanNeighbors as scan

BASE=Path(__file__).resolve().parent
name=sys.argv[1]if len(sys.argv)>1 else 'final-cleaned'
DATA=BASE/name;OUT=BASE/(name+'-within');OUT.mkdir(exist_ok=True)
meta=json.loads((DATA/'current56-objects.json').read_text(encoding='utf8'))
npz=np.load(DATA/'current56-triangles.npz');triangles,owners,faces=npz['triangles'],npz['owners'],npz['faces']
(OUT/'current56-objects.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf8')
np.savez_compressed(OUT/'current56-triangles.npz',triangles=triangles,owners=owners,faces=faces)
scan.OWN=OUT
scan.scan(meta['objects'],triangles,owners,faces,scope='within-and-self')
