"""Validate pure mesh recipes and write draft-only occupied/surface metadata."""
from collections import Counter
import json
import math
from pathlib import Path
from EnclosureRecipes import BOTTOM,SECTORS,terrain,sample_height,single_tree_recipes,FOOTING_CUTS

folder=Path(__file__).resolve().parent
report={}
metadata={}
recipes={name:terrain(name) for name in SECTORS}
recipes.update({name:(mesh,{}) for name,mesh in single_tree_recipes().items()})
for name,(mesh,data) in recipes.items():
    directed=Counter();edges=Counter();volume=0
    for face in mesh.faces:
        for i,a in enumerate(face):
            b=face[(i+1)%len(face)];edges[tuple(sorted((a,b)))]+=1;directed[(a,b)]+=1
        a=mesh.vertices[face[0]]
        for i in range(1,len(face)-1):
            b,c=mesh.vertices[face[i]],mesh.vertices[face[i+1]]
            cross=(b[1]*c[2]-b[2]*c[1],b[2]*c[0]-b[0]*c[2],b[0]*c[1]-b[1]*c[0])
            volume+=sum(a[j]*cross[j] for j in range(3))/6
    assert all(count==2 for count in edges.values()),name+" has an open/nonmanifold edge"
    assert all(directed[(b,a)]==count for (a,b),count in directed.items()),name+" has inconsistent winding"
    assert volume>0,name+" faces inward"
    low,high=mesh.bounds()
    material_triangles=Counter()
    for face,material in zip(mesh.faces,mesh.materials):material_triangles[material]+=len(face)-2
    assert max(material_triangles.values())<15000,"Partition native terrain meshes below15k triangles"
    data.update({"parts":len(set(mesh.materials)),"triangles":mesh.triangles(),"low":low,"high":high,
                 "center":[(low[i]+high[i])/2 for i in range(3)],"size":[high[i]-low[i] for i in range(3)],"bottomY":BOTTOM,"materialTriangles":dict(material_triangles)})
    metadata[name]=data
    report[name]={"parts":data["parts"],"triangles":data["triangles"],"materialTriangles":dict(material_triangles),"low":low,"high":high,"closed":True,"outward":True,"signedVolume":volume}

def vector(value):return "v("+",".join(str(round(item,6)) for item in value)+")"
lines=["--!nonstrict","local v=Vector3.new","local assets={"]
for name,data in metadata.items():
    lines.append('["'+name+'"]={parts='+str(data["parts"])+',triangles='+str(data["triangles"])+',center='+vector(data["center"])+',size='+vector(data["size"])+',bottomY='+str(BOTTOM)+',')
    if "xs" in data:
        lines.append("xs={"+",".join(map(str,data["xs"]))+"},zs={"+",".join(map(str,data["zs"]))+"},")
        lines.append("heights={"+",".join("{"+",".join(map(str,row))+"}" for row in data["heights"])+"},},")
    else:lines.append("occupied={{low="+vector(data["low"])+",high="+vector(data["high"])+",top={}}},},")
lines.append("}")
lines.extend('''
for _,meta in assets do
    if not meta.xs then continue end
    local occupied={}
    for row=1,#meta.zs-1 do
        for column=1,#meta.xs-1 do
            local a=v(meta.xs[column],meta.heights[row][column],meta.zs[row])
            local b=v(meta.xs[column+1],meta.heights[row][column+1],meta.zs[row])
            local c=v(meta.xs[column],meta.heights[row+1][column],meta.zs[row+1])
            local d=v(meta.xs[column+1],meta.heights[row+1][column+1],meta.zs[row+1])
            local triangles=if (row+column)%2==0 then {{a,c,d},{a,d,b}} else {{a,c,b},{b,c,d}}
            for _,top in triangles do
                local low=v(math.min(top[1].X,top[2].X,top[3].X),meta.bottomY,math.min(top[1].Z,top[2].Z,top[3].Z))
                local high=v(math.max(top[1].X,top[2].X,top[3].X),math.max(top[1].Y,top[2].Y,top[3].Y),math.max(top[1].Z,top[2].Z,top[3].Z))
                table.insert(occupied,{low=low,high=high,top=top})
            end
        end
    end
    meta.occupied=occupied
end
return assets
'''.strip().splitlines())
(folder/"EnclosureGeometry.luau").write_text("\n".join(lines)+"\n")
(folder/"terrain-metadata.json").write_text(json.dumps(metadata,separators=(",",":"))+"\n")
(folder/"recipe-check.json").write_text(json.dumps(report,indent=2)+"\n")
def sector_at(x,z):
    if z<-228:return "MC_EC_NorthHighRidge"
    if z>228:return "MC_EC_SouthValleyRidge"
    if x<-276:return "MC_EC_WestWoodedCliff"
    if x>246:return "MC_EC_EastPanoramaSlope"
    return "MC_EC_InnerRavine"
seats=[]
for name,box,soil in FOOTING_CUTS:
    x0,x1,z0,z1=box
    samples=[(x,z) for x in (x0,(x0+x1)/2,x1) for z in (z0,(z0+z1)/2,z1)]
    values=[sample_height(sector_at(x,z),x,z) for x,z in samples]
    assert min(values)>=soil-.03,name+" has a floating ground foot"
    seats.append({"name":name,"rockSeatTargetY":soil,"actualSamples":values,"lowestActualY":min(values),
                  "highestActualY":max(values),"minimumBurial":min(values)-(soil-4),"higherTerraceIntersection":max(values)>soil+.1})
(folder/"footing-check.json").write_text(json.dumps(seats,indent=2)+"\n")

# Reuse the three-tree edit units only on shoulders where all rigid roots can be buried naturally.
choices=[]
targets=[("MC_EC_WestWoodedCliff",12), ("MC_EC_NorthHighRidge",12), ("MC_EC_EastPanoramaSlope",7), ("MC_EC_SouthValleyRidge",7)]
for sector,maximum in targets:
    xs,zs=SECTORS[sector]
    candidates=[]
    for x in range(math.ceil(xs[0]+28),math.floor(xs[-1]-28),12):
        for z in range(math.ceil(zs[0]+28),math.floor(zs[-1]-28),12):
            if not (x<-278 or x>250 or z<-232 or z>232):continue
            for yaw in (0,.65,1.3,1.95):
                scale=1.25
                evergreen=len(candidates)%2==0
                roots=[(-9,-7),(8,6),(-5,9)] if evergreen else [(-8,-3),(7,1),(-1,6)]
                values=[sample_height(sector,x+(math.cos(yaw)*u+math.sin(yaw)*w)*scale,z+(-math.sin(yaw)*u+math.cos(yaw)*w)*scale) for u,w in roots]
                spread=max(values)-min(values)
                ground=sample_height(sector,x,z)
                if spread<=6 and ground>80:
                    score=spread+.002*abs(ground-190)
                    candidates.append((score,x,z,yaw,scale,evergreen,values,ground))
    candidates.sort()
    planted=[]
    for _,x,z,yaw,scale,evergreen,values,ground in candidates:
        if any(math.hypot(x-row["point"][0],z-row["point"][2])<42 for row in planted):continue
        point=[x,min(values)-.35,z]
        row={"sector":sector,"asset":"MC_P3_Rural_EvergreenGrove" if evergreen else "MC_P3_Rural_BroadleafClump",
             "point":point,"yaw":yaw,"scale":scale,"rootSurfaceHeights":values,"rootBurial":[value-(point[1]-2*scale) for value in values],"centerSurfaceHeight":ground}
        planted.append(row)
        if len(planted)>=maximum:break
    choices.extend(planted)
for sector,maximum in [("MC_EC_WestWoodedCliff",14),("MC_EC_NorthHighRidge",8),("MC_EC_EastPanoramaSlope",3)]:
    xs,zs=SECTORS[sector]
    candidates=[]
    for x in range(math.ceil(xs[0]+22),math.floor(xs[-1]-22),14):
        for z in range(math.ceil(zs[0]+22),math.floor(zs[-1]-22),14):
            value=sample_height(sector,x,z)
            if value<95:continue
            distance=min((math.hypot(x-row["point"][0],z-row["point"][2]) for row in choices),default=200)
            if distance<26:continue
            # Alternate high and middle shoulders; do not line the entire outer silhouette evenly.
            score=abs(value-(155 if len(candidates)%2 else 230))+.025*abs(z+40)
            candidates.append((score,x,z,value))
    candidates.sort()
    planted=[]
    for _,x,z,value in candidates:
        if any(math.hypot(x-row["point"][0],z-row["point"][2])<30 for row in planted):continue
        planted.append({"sector":sector,"asset":"MC_EC_SlopePine" if len(planted)%3!=1 else "MC_EC_SlopeBroadleaf",
                        "point":[x,value-.35,z],"yaw":len(planted)*.79,"scale":1.15+(len(planted)%3)*.1,
                        "rootSurfaceHeights":[value],"rootBurial":[.35+2*(1.15+(len(planted)%3)*.1)],"centerSurfaceHeight":value})
        if len(planted)>=maximum:break
    choices.extend(planted)
tree_lines=["--!nonstrict","local v=Vector3.new","return {"]
for index,row in enumerate(choices):
    tree_lines.append('{name="RidgeWoodland'+str(index+1)+'",sector="'+row["sector"]+'",asset="'+row["asset"]+'",point='+vector(row["point"])+',yaw='+str(row["yaw"])+',scale='+str(row["scale"])+',rootBurial={'+','.join(str(round(value,6)) for value in row["rootBurial"])+'}},')
tree_lines.append("}")
(folder/"WoodlandPlacements.luau").write_text("\n".join(tree_lines)+"\n")
(folder/"woodland-roots.json").write_text(json.dumps(choices,indent=2)+"\n")
print("terrain",sum(item["parts"] for item in report.values()),sum(item["triangles"] for item in report.values()),"woodland units",len(choices))
for name,item in report.items():print(name,item["triangles"],item["low"],item["high"])
