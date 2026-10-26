from pathlib import Path
import json
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

root = Path(__file__).resolve().parents[4]
folder = root / "docs/artifacts/keyboard-circuit/phase2"
data = json.loads((folder / "P2-I09-offline-geometry-01.json").read_text(encoding="utf-8"))
order = ["F00","O01","H02","O02","H03","CP1","O03","H04","H05","O04","CP2","O05","H06","H07","O06","CP3","O07","H08","H01","O08","F01","F00"]
fig, ax = plt.subplots(figsize=(10,10), facecolor="#f7f4ed")
ax.set_facecolor("#f7f4ed")

def point(value): return value[0]-22500, -(value[2]+1600)
normal = []
for unit in order:
    a,b = point(data["contacts"][unit]["entry"]), point(data["contacts"][unit]["exit"])
    normal.extend([a,b])
    if unit not in {"F00","F01","CP1","CP2","CP3"}:
        mid = ((a[0]+b[0])/2,(a[1]+b[1])/2)
        ax.scatter(*mid,s=55,color="#245572",zorder=3)
        ax.annotate(unit,mid,xytext=(5,5),textcoords="offset points",fontsize=10,color="#143243")
ax.plot(*zip(*normal),color="#245572",linewidth=2.8,label="Normal: all 16 encounters")
for key,b in data["branches"].items():
    route = [point(b["start"])] + [point(row["position"]) for row in b["path"]] + [point(b["merge"])]
    ax.plot(*zip(*route),"--",color="#805bb2",linewidth=2.3)
    ax.scatter(*zip(*route[1:-1]),color="#805bb2",s=16,zorder=4)
    mid=route[len(route)//2]
    label="Stagger Cut" if key=="X03" else "Bracket Spine"
    ax.annotate(label,mid,xytext=(-18,12),textcoords="offset points",fontsize=10,color="#684090",weight="bold")
ax.plot([],[],"--",color="#805bb2",linewidth=2.3,label="Expert: two optional precision cuts")
for label,unit in [("Start","F00"),("1","H02"),("2","CP1"),("3","H04"),("4","CP2"),("5","H06"),("6","CP3"),("7","H08")]:
    p = point(data["contacts"][unit]["exit"])
    ax.scatter(*p,color="#e4aa35",edgecolor="#143243",s=175,zorder=5)
    ax.annotate(label,p,ha="center",va="center",fontsize=10,weight="bold",zorder=6)
ax.scatter([],[],color="#e4aa35",edgecolor="#143243",s=85,label="Start + seven recovery checkpoints")
ax.set_aspect("equal")
ax.set_title("Keyboard Circuit • I09 • Two laps",fontsize=18,pad=20,color="#143243")
ax.set_xlabel("World X relative to course origin (studs)")
ax.set_ylabel("World −Z relative to course origin (studs)")
ax.grid(alpha=.14)
ax.legend(loc="lower right",fontsize=9,framealpha=.95)
fig.text(.5,.018,"Authored bank positions and precision-cap centers. Schematic route view; not a native screenshot or human timing proof.",ha="center",fontsize=8,color="#516576")
fig.tight_layout(rect=(0,.035,1,1))
fig.savefig(folder / "native/I09-route-plan.png",dpi=160)
print("Saved I09 authored route schematic")
