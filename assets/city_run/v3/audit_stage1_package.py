"""Verify the delivered editable library and per-asset export receipts."""
from pathlib import Path
import bpy,json,hashlib
ROOT=Path(__file__).resolve().parent
m=json.loads((ROOT/'stage1-manifest.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(ROOT/m['editableSource']))
failures=[];materials=set();images=set();triangles=0
for r in m['assets']:
 ob=bpy.data.objects.get(r['id'])
 if ob is None or ob.type!='MESH':failures.append(r['id']+': missing mesh');continue
 ob.data.calc_loop_triangles();triangles+=len(ob.data.loop_triangles)
 if len(ob.data.loop_triangles)!=r['triangles']:failures.append(r['id']+': triangles')
 if max(abs(a-b) for a,b in zip(ob.dimensions,r['dimensionsBlenderXYZ']))>.001:failures.append(r['id']+': dimensions')
 if not any(c.name==r['id'] for c in ob.users_collection):failures.append(r['id']+': named collection')
 if len(ob.data.materials)!=1:failures.append(r['id']+': material count')
 for mat in ob.data.materials:
  materials.add(mat.name)
  for n in mat.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image:images.add(n.image.name)
 f=ROOT/r['fbx']
 if not f.exists() or hashlib.sha256(f.read_bytes()).hexdigest()!=r['sha256']:failures.append(r['id']+': export hash')
 for field in ['attachmentsRobloxLocal','renderRecommendation']:
  if field not in r:failures.append(r['id']+': '+field)
for p in m['packages']:
 if hashlib.sha256((ROOT/p['file']).read_bytes()).hexdigest()!=p['sha256']:failures.append(p['file']+': upload hash')
result={'build':m['build'],'assets':len(m['assets']),'triangles':triangles,'referencedMaterials':sorted(materials),'referencedImages':sorted(images),'failures':failures,'passed':not failures and triangles==22746 and len(materials)==len(images)==1,'scope':'Editable source and export integrity; no runtime performance claim'}
(ROOT/'stage1-package-audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
