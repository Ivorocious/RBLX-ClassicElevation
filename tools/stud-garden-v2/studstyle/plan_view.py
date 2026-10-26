"""Show the actual protected supports and proposed scenery footprints in course space."""
from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle

BASE=Path(__file__).resolve().parents[3]/'docs/artifacts/stud-garden-v2/studstyle-20261006'
data=json.loads((BASE/'baseline-geometry.json').read_text())
fig,ax=plt.subplots(figsize=(16,16))
origin=np.array([1563,257,-1053])
for p in data['parts']:
    if not p['collide'] or p['transparency']>.99: continue
    r=np.array(p['cf'][3:]).reshape(3,3)
    c=np.array(p['cf'][:3])-origin
    h=np.abs(r)@np.array(p['size'])/2
    if h[0]>100 or h[2]>100: continue
    col='#777777'
    if p['role'] in ('Walk','Refuge'): col='#28a16b'
    if p['path'].startswith('RefinedGardenBoundaries.'): col='#e87722'
    ax.add_patch(Rectangle((c[0]-h[0],c[2]-h[2]),h[0]*2,h[2]*2,color=col,alpha=.3))
for p in data['parts']:
    if not p['path'].startswith('Checkpoints.'): continue
    c=np.array(p['cf'][:3])-origin
    ax.text(c[0],c[2],p['name'][-3:],ha='center',va='center',fontsize=12,color='blue')
for x in range(-180,181,20):
    for z in range(-180,181,20):
        ax.text(x,z,f'{x},{z}',fontsize=5,alpha=.48,ha='center')
ax.set(xlim=(-200,200),ylim=(200,-200),aspect='equal',xlabel='X',ylabel='Z')
ax.set_xticks(range(-200,201,20));ax.set_yticks(range(-200,201,20));ax.grid(alpha=.2)
fig.tight_layout();fig.savefig(BASE/'baseline-plan.png',dpi=130)
