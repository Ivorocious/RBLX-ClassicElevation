"""Build five district accents without replacing the approved base kit."""
from pathlib import Path
import json, hashlib

ROOT = Path(__file__).resolve().parent
prefix = (ROOT / 'build_asset_kit.py').read_text().split('\ndef shell(')[0]
exec(compile(prefix, str(ROOT / 'build_asset_kit.py'), 'exec'))
BUILD = 'V3_DISTRICT_ADDON_01'
OUT = ROOT / 'district_addon01'
OUT.mkdir(exist_ok=True)

g = Geo()
g.box((0,0,7),(24,1,14),'brick')
g.box((0,-.6,1),(24,.3,2),'stone')
g.box((-3,-.57,6.6),(12,.2,11),'iron')
for z in range(2,12):
 g.box((-3,-.72,z),(11.6,.14,.16),'slate')
for x in (-9.3,3.3): g.box((x,-.8,6.6),(.5,.7,11.5),'stone')
g.box((-3,-.95,12.6),(14,1.5,.7),'iron')
g.box((8,-1.1,6),(4,1.2,5),'slate')
for z in (4.5,5.5,6.5,7.5): g.box((8,-1.75,z),(3.2,.14,.22),'iron')
g.beam((11,-.7,1),(11,-.7,12),.3,'iron')
g.beam((11,-.7,12),(7,-.7,12),.3,'iron')
for x in (-10.7,4.7):
 g.box((x,-2,1.8),(.6,.6,3.6),'gold')
 g.box((x,-2,2.7),(.65,.65,.5),'iron')
g.finish('V3_LoadingFacade','Industrial','Close','24-stud loading shutter, vent and conduit wall overlay; mount back against a shell. Closed opaque geometry.')

def pallet(g,x,y,z):
 for xx in (x-2,x+2): g.box((xx,y,z+.25),(.65,4,.5),'wood')
 for yy in (y-1.6,y-.8,y,y+.8,y+1.6): g.box((x,yy,z+.65),(5,.55,.3),'wood_plank')

g = Geo()
for x in (-3,3):
 for y in (-1.4,1.4):g.box((x,y,.35),(.6,.6,.7),'iron')
g.box((0,0,2.3),(7,4,3.6),'sage')
g.box((0,0,4.25),(7.5,4.5,.5),'iron')
for x in (-2.4,0,2.4):g.box((x,-2.06,2.5),(.18,.14,2.5),'teal')
g.box((0,-2.15,3.8),(2.4,.3,.2),'iron')
for z in (0,.8,1.6):pallet(g,6.5,0,z)
g.box((6.5,0,3.45),(3.8,3,2.1),'wood_plank')
g.finish('V3_ServiceStock','Industrial','Close','One reusable dumpster and pallet cluster; no transparent faces or small physics parts.')

g = Geo()
for x in (-7.5,0,7.5):g.box((x,0,4),(.4,.5,8),'wood')
g.box((0,.15,3.9),(16,.3,6.8),'teal')
g.box((0,-.08,1),(16,.22,1.2),'stone')
for z in (1,7):g.box((0,-.12,z),(16,.3,.4),'wood')
g.beam((-7,-.2,1),(0,-.2,7),.32,'wood')
g.beam((0,-.2,7),(7,-.2,1),.32,'wood')
g.box((4,-.28,5),(3.2,.15,2),'gold')
for x in (-7.5,7.5):g.box((x,0,.2),(2,2.6,.4),'stone')
g.finish('V3_WorksiteHoarding','Industrial','Close','Solid teal perimeter sheet and timber braces; route boundaries stay gameplay-owned.')

g = Geo()
for z in (0,.8):pallet(g,-3,0,z)
g.box((-3,0,3.3),(4.8,3.8,3.4),'sky')
for x in (-4.6,-1.4):g.box((x,0,5.04),(.2,3.85,.12),'iron')
for x in (2.4,3.5,4.6):
 g.box((x,0,.25),(.8,8,.5),'iron')
 g.box((x,0,.9),(.25,8,1),'slate')
 g.box((x,0,1.45),(.8,8,.3),'iron')
g.finish('V3_MaterialsStock','Industrial','Close','Wrapped pallet and three compact steel lengths in one mesh, placed at wall edges.')

g = Geo()
for x in (-10,10):
 for y in (-4,4):
  g.box((x,y,5.5),(.55,.55,11),'iron')
  g.box((x,y,.3),(1.2,1.2,.6),'stone')
  g.beam((x,y,8),(x*.65,y,10.5),.32,'iron')
g.box((0,0,11),(24,12,.5),'metal_panel')
for y in (-6,6):g.box((0,y,10.65),(24,.3,.8),'iron')
g.box((0,-6.2,10.65),(10,.18,.5),'gold')
g.finish('V3_ServiceCanopy','Industrial','Close','Dark steel loading canopy with an opaque roof and grounded footplates.')

bounds = {}
for index,(ob,rec) in enumerate(assets):
 coords=[v.co for v in ob.data.vertices]
 mn=[min(v[i] for v in coords) for i in range(3)]
 mx=[max(v[i] for v in coords) for i in range(3)]
 bounds[ob.name]={'centerBlender':[(a+b)/2 for a,b in zip(mn,mx)],'dimensions':[b-a for a,b in zip(mn,mx)]}
 ob.location=(index*32,0,0)
manifest={'build':BUILD,'baseKit':'V3_KIT_05','assets':[r for o,r in assets],'totals':{'uniqueAssets':len(assets),'triangles':sum(r['triangles'] for o,r in assets),'materials':1,'textures':1},'atlas':'../painted_atlas.png'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'bounds.json').write_text(json.dumps(bounds,indent=2))
bpy.ops.object.select_all(action='DESELECT')
for ob,rec in assets:ob.select_set(True)
bpy.context.view_layer.objects.active=assets[0][0]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CityRun_DistrictAddon.blend'))
bpy.ops.export_scene.fbx(filepath=str(OUT/'CityRun_DistrictAddon.fbx'),use_selection=True,object_types={'MESH'},global_scale=1,apply_unit_scale=False,axis_forward='-Z',axis_up='Y',use_triangles=True,path_mode='COPY',embed_textures=True,add_leaf_bones=False,bake_anim=False)
print(json.dumps(manifest['totals']))
