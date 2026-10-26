from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle
BASE=Path(__file__).resolve().parents[3]/"docs/artifacts/stud-garden-v2/density-20261006"
data=json.loads((BASE/"baseline-geometry.json").read_text())
origin=np.array([1563,257,-1176])
fig,ax=plt.subplots(figsize=(15,15))
corners=np.array([[x,y,z] for x in [-1,1] for y in [-1,1] for z in [-1,1]])
def hull(points):
    pts=sorted(set(map(tuple,points)))
    def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lo=[];hi=[]
    for p in pts:
        while len(lo)>=2 and cross(lo[-2],lo[-1],p)<=0:lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi)>=2 and cross(hi[-2],hi[-1],p)<=0:hi.pop()
        hi.append(p)
    return lo[:-1]+hi[:-1]
for p in data["parts"]:
    if p["transparency"]>.95:continue
    c=np.array(p["cf"][:3])-origin;r=np.array(p["cf"][3:]).reshape(3,3);s=np.array(p["size"])/2
    if max(s)>90:continue
    pts=(corners*s)@r.T+c
    h=hull([(-q[2],-q[0]) for q in pts])
    isroute=p["collide"] and p["role"] in ["Walk","Refuge"]
    color="#309e5b" if isroute else ("#dc382f" if p["touch"] else "#846f50")
    alpha=.45 if isroute else .11
    ax.add_patch(Polygon(h,facecolor=color,edgecolor="none",alpha=alpha))
for p in data["parts"]:
    if p["path"].startswith("Checkpoints."):
        c=np.array(p["cf"][:3])-origin
        ax.text(-c[2],-c[0],p["name"][-3:],ha="center",va="center",color="#184cda",fontsize=10,bbox=dict(facecolor="white",alpha=.7,edgecolor="none"))
zones=[(-102,110),(-20,95),(86,145),(31,58),(-92,-120),(-80,-165),(-35,-172),(-2,-90),(43,-130),(92,-74),(159,-175)]
for i,(x,z) in enumerate(zones,1):
    ax.add_patch(Circle((-z,-x),10,fill=False,edgecolor="#e83b2e",lw=2))
    ax.text(-z,-x,str(i),ha="center",va="center",fontsize=11,color="#bd1616",weight="bold")
ax.set(xlim=(-200,200),ylim=(-200,200),aspect="equal",xlabel="-Local Z (screen right)",ylabel="-Local X (screen up)")
ax.set_xticks(range(-200,201,20));ax.set_yticks(range(-200,201,20));ax.grid(alpha=.18)
ax.set_title("S05 protected route (green), scenery (brown), owner void centres (red)")
fig.tight_layout();fig.savefig(BASE/"baseline-pocket-plan.png",dpi=150)

