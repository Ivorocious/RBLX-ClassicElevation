"""Offline geometry study, not a native rendered or gameplay view."""
import json
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from EnclosureRecipes import SECTORS,FOOTING_CUTS,sample_height

folder=Path(__file__).resolve().parent
def sector(x,z):
    if z<-228:return "MC_EC_NorthHighRidge"
    if z>228:return "MC_EC_SouthValleyRidge"
    if x<-276:return "MC_EC_WestWoodedCliff"
    if x>246:return "MC_EC_EastPanoramaSlope"
    return "MC_EC_InnerRavine"
def surface(x,z):return sample_height(sector(x,z),x,z)

xs=np.linspace(-390,390,131);zs=np.linspace(-355,350,119)
values=np.array([[surface(float(x),float(z)) for x in xs] for z in zs])
fig,ax=plt.subplots(figsize=(12,10))
image=ax.contourf(xs,zs,values,levels=[-130,-95,-60,-30,0,60,120,180,240,300,340],cmap="terrain")
fig.colorbar(image,ax=ax,label="Authored terrain height (course-local studs)")
ax.plot([-266,236,236,-266,-266],[-216,-216,216,216,-216],"--",color="#a43b2b",linewidth=1,label="Unchanged fall footprint")
for name,box,_ in FOOTING_CUTS:
    x0,x1,z0,z1=box
    ax.plot([x0,x1,x1,x0,x0],[z0,z0,z1,z1,z0],color="#554562",linewidth=.65)
woods=json.loads((folder/"woodland-roots.json").read_text())
ax.scatter([row["point"][0] for row in woods],[row["point"][2] for row in woods],s=20,color="#234a29",marker="^",label="Triangulated tree roots")
for name,x,z in [("Start",-144,146),("CP01",-144,-112),("CP02",-80,28),("CP03",112,-52),("CP04",112,-86),("Crown",-8,-30)]:
    ax.scatter([x],[z],s=32,color="#f7f1dd",edgecolor="#333333",zorder=4)
    ax.annotate(name,(x,z),xytext=(5,7),textcoords="offset points",fontsize=8,zorder=5)
ax.annotate("Crown panorama: low east/southeast saddle",xy=(320,170),xytext=(-15,310),arrowprops={"arrowstyle":"->"},fontsize=9)
ax.set_aspect("equal");ax.invert_yaxis();ax.legend(loc="upper left",fontsize=8)
ax.set_title("Enclosure massing — authored mesh surface and fortress recesses\nOffline design study; native presentation still required")
ax.set_xlabel("Local X");ax.set_ylabel("Local Z")
fig.tight_layout();fig.savefig(folder/"massing-study.png",dpi=150);plt.close(fig)

fig,axes=plt.subplots(2,1,figsize=(13,8))
for ax,axis,coordinates,points,title in [
    (axes[0],"x",np.linspace(-390,390,400),[("CP01",-144,31)],"West/east profile through CP01 at Z-112"),
    (axes[1],"z",np.linspace(-355,350,400),[("CP04",-86,109),("CP03",-52,75)],"North/south profile beside machinery at X112")]:
    heights=[surface(float(value),-112) if axis=="x" else surface(112,float(value)) for value in coordinates]
    ax.fill_between(coordinates,-130,heights,color="#71896b",alpha=.8);ax.plot(coordinates,heights,color="#3c514b")
    ax.axhline(-23,color="#a43b2b",linestyle="--",label="Unchanged fall/reset Y-23")
    for label,coordinate,y in points:
        ax.scatter([coordinate],[y],color="#bd7e38");ax.annotate(label,(coordinate,y),xytext=(6,8),textcoords="offset points")
    ax.set_title(title);ax.set_ylim(-135,350);ax.set_ylabel("Local height");ax.grid(alpha=.2);ax.legend(fontsize=8)
axes[0].set_xlabel("Local X");axes[1].set_xlabel("Local Z")
fig.suptitle("Climb enclosure height study — exact triangulated terrain sampling, not a native image")
fig.tight_layout();fig.savefig(folder/"climb-profiles.png",dpi=150);plt.close(fig)
