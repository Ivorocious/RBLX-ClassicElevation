"""Pure closed-edge check and exact recipe metadata for lead integration."""
import collections,json
from pathlib import Path
from FortressRecipes import build_recipes
own=Path(__file__).parent
metadata={};report={}
for name,mesh in build_recipes().items():
 edges=collections.Counter()
 for face in mesh.faces:
  points=[tuple(round(x,6) for x in mesh.vertices[i]) for i in face]
  for a,b in zip(points,points[1:]+points[:1]):edges[tuple(sorted((a,b)))]+=1
 bad=[edge for edge,count in edges.items() if count!=2]
 material_edges={}
 for material in set(mesh.materials):
  me=collections.Counter()
  for face,role in zip(mesh.faces,mesh.materials):
   if role!=material:continue
   pts=[tuple(round(x,6) for x in mesh.vertices[i]) for i in face]
   for a,b in zip(pts,pts[1:]+pts[:1]):me[tuple(sorted((a,b)))]+=1
  material_edges[material]=sum(n!=2 for n in me.values())
 assert all(n==0 for n in material_edges.values()),(name,material_edges)
 assert not bad,(name,bad)
 metadata[name]=mesh.metadata()
 report[name]={"parts":metadata[name]["parts"],"triangles":metadata[name]["triangles"],"badWeldedEdges":0,"perMaterialBadEdges":material_edges,"blenderVerified":False}
shared=json.loads((own.parent/"geometry/recipe-check.json").read_text())
for record in shared["assets"]:
 occupied=[]
 for box in record["occupied_boxes_blender"]:
  lo,hi=box["low"],box["high"]
  occupied.append({"low":[lo[0],lo[2],-hi[1]],"high":[hi[0],hi[2],-lo[1]]})
 lo=[min(box["low"][i] for box in occupied) for i in range(3)];hi=[max(box["high"][i] for box in occupied) for i in range(3)]
 metadata[record["asset"]]={"parts":len(record["parts"]),"triangles":record["triangles"],"center":[(lo[i]+hi[i])/2 for i in range(3)],"size":[hi[i]-lo[i] for i in range(3)],"occupied":occupied}
(own/"asset-metadata.json").write_text(json.dumps(metadata,indent=2))
lines=["--!nonstrict","local v=Vector3.new","return {"]
vec=lambda x:"v("+",".join(str(round(a,6)) for a in x)+")"
for name,r in metadata.items():
 lines.append(name+"={parts="+str(r["parts"])+",triangles="+str(r["triangles"])+",center="+vec(r["center"])+",size="+vec(r["size"])+",occupied={")
 for box in r["occupied"]:lines.append("{low="+vec(box["low"])+",high="+vec(box["high"])+"},")
 lines.append("}},")
lines.append("}")
(own/"FortressGeometry.luau").write_text("\n".join(lines)+"\n")
(own/"geometry-check.json").write_text(json.dumps(report,indent=2))
print(json.dumps(report))
