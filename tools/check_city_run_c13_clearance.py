import bpy,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
bpy.ops.wm.open_mainfile(filepath=str(Path('assets/city_run/CityRun_C13_terminal.blend').resolve()))
rows=json.loads(Path('docs/artifacts/city-run/C13-current-native-audit.json').read_text())['records']
manifest=json.loads(Path('assets/city_run/manifest_C13_terminal.json').read_text())
def bvhbox(lo,hi):
 v=[(x,-z,y) for x in (lo[0],hi[0]) for y in (lo[1],hi[1]) for z in (lo[2],hi[2])]
 f=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
 return BVHTree.FromPolygons(v,f)
route=[]
for r in rows:
 if '/Obstacles/WalkingSurfaces/' not in r['path'] or not r.get('CanCollide') or r['cf'][0]<3650 or r['cf'][2]<0:continue
 x,y,z=r['cf'][:3];w,h,d=r['size'];name=r['path'].split('/')[-1]
 if name=='FinishTerrace':w=24;d=26;z=238
 lo=[x-3500-w/2+.35,y+h/2+.3,z-d/2+.35];hi=[x-3500+w/2-.35,y+h/2+6.3,z+d/2-.35]
 route.append((name,bvhbox(lo,hi)))
hits=[]
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 meta=manifest['meshes'][obj.name];sec=manifest['components'][meta['component']]['section']
 if sec in ('Calibration','RouteVisual','RouteSupport'):continue
 tree=BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],[list(p.vertices) for p in obj.data.polygons])
 for name,box in route:
  if tree.overlap(box):hits.append({'route':name,'mesh':obj.name})
r={'build':'C13_04','routeVolumes':len(route),'method':'Blender triangle/box surface intersection; 6-stud headroom above the 0.3-stud cosmetic floor allowance, 24-stud central finish corridor. Side terrace furniture excluded from walking core. Source geometry in Roblox world alignment.','intersections':hits}
Path('docs/artifacts/city-run/C13-clearance-check.json').write_text(json.dumps(r,indent=2));print(r)

