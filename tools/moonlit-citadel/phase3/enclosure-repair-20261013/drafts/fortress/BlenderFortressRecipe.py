"""Lead-only Blender adapter; no scene access or writes on import."""
import importlib.util
from pathlib import Path
spec=importlib.util.spec_from_file_location("moonlit_fortress_geometry",Path(__file__).with_name("FortressRecipes.py"))
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
PALETTE=module.PALETTE

def recipes(a,e):
 result=[]
 for name,mesh in module.build_recipes().items():
  geometry=a._Mesh()
  for face,material in zip(mesh.faces,mesh.materials):
   geometry.add([(mesh.vertices[i][0],-mesh.vertices[i][2],mesh.vertices[i][1]) for i in face],[tuple(range(len(face)))],material)
  boxes=[]
  for box in mesh.occupied:
   low,high=box["low"],box["high"]
   lo=(low[0],-high[2],low[1]);hi=(high[0],-low[2],high[1])
   boxes.append(e.box_proxy(tuple((lo[i]+hi[i])/2 for i in range(3)),tuple(hi[i]-lo[i] for i in range(3))))
  result.append((name,geometry,boxes,"Closed base-pivot fortress unit; original course stays exact; opening proxies exclude intentional voids; roof proxies conservatively enclose closed slopes."))
 return result
