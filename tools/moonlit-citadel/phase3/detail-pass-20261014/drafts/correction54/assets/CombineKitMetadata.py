import hashlib
import json
from pathlib import Path

ROOT=Path.cwd()
OLD=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
NEW=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01'
def load(path):return json.loads(path.read_text(encoding='utf8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

old,new=[load(path/'manifest.json') for path in (OLD,NEW)]
parts=old['export_parts']+new['export_parts'];assets=old['assets']+new['assets']
assert len(parts)==29 and len({p['name'] for p in parts})==29 and len(assets)==9
assert parts[:26]==old['export_parts']
provenance={str(path.relative_to(ROOT)).replace('\\','/'):sha(path) for folder in (OLD,NEW) for path in (folder/'manifest.json',folder/'MC_DETAIL_KIT_DT01.fbx' if folder==OLD else folder/'MC_WALL_GARDEN_DG01.fbx',folder/'occupied-geometry.json')}
manifest={'candidate':'MC_P3_DETAILS_DT02','logicalLibrary':'DT01','nativeLibraryName':'MoonlitCitadel_Detail_DT02Library',
          'axes':'Roblox=(X,Z,-Y)','units':'1 Blender unit = 1 intended stud','part_count':29,
          'export_triangles':sum(row['triangles'] for row in parts),'assets':assets,'export_parts':parts,
          'provenance':provenance,'old26PartRowsExact':True,'nativeImportVerified':False,
          'assemblyRule':'Copy all8verifiedR01native templates unchanged; import/prove only3newgarden material meshes'}
occupied=load(OLD/'occupied-geometry.json')['assets']|load(NEW/'occupied-geometry.json')['assets']
assert len(occupied)==9 and all(occupied[name]==row for name,row in load(OLD/'occupied-geometry.json')['assets'].items())
(NEW/'combined-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
(NEW/'combined-occupied-geometry.json').write_text(json.dumps({'axes':'Roblox XYZ','logicalLibrary':'DT01','nativeLibraryName':'MoonlitCitadel_Detail_DT02Library','assets':occupied,'provenance':provenance},indent=2)+'\n',encoding='utf8')
print(json.dumps({'parts':29,'assets':9,'triangles':manifest['export_triangles'],'old26PartRowsExact':True}))
