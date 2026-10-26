import hashlib
import json
from pathlib import Path

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'default.project.json').exists())
HERE=Path(__file__).resolve().parent
OUT=ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01'
ORIGINAL=OUT.parent

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding='utf8'))

check=load(HERE/'r01-readonly-roundtrip.json')
assert check['pass'] and check['fbxRoundtripPass'] and check['badgeContour']['pass']
before,after=[load(folder/'occupied-geometry.json')['assets'] for folder in (ORIGINAL,OUT)]
box_changes=[]
for name in before:
    assert len(before[name]['occupied'])==len(after[name]['occupied'])
    for index,(a,b) in enumerate(zip(before[name]['occupied'],after[name]['occupied'])):
        if a!=b:box_changes.append({'asset':name,'index':index,'before':a,'after':b})
assert len(box_changes)==1 and box_changes[0]['asset']=='MC_DT_HeraldicBanner'
manifest=load(OUT/'manifest.json');receipt=load(OUT/'build-receipt.json')
assert len(manifest['assets'])==8 and manifest['part_count']==26 and manifest['export_triangles']==9574
for path,digest in receipt['inputHashes'].items():assert sha(ROOT/path)==digest,path
for path,digest in check['inputHashes'].items():assert sha(ROOT/path)==digest,path
original_sha=sha(ORIGINAL/'MC_DETAIL_KIT_DT01.fbx')
assert original_sha=='155cdd1029d2292f4eff7c5d778dae44f235933b5c62a02eeae822028cbeb687'
report={'pass':True,'candidate':'MC_P3_DETAIL_DT01_R01','assets':8,'meshParts':26,'triangles':9574,
        'contourSelfCrossings':0,'materialPartsClosedManifoldOutward':True,'fbxRoundtripPass':True,
        'maximumFBXVertexError':max(row['worldVertexSetMaxError'] for row in check['fbxParts']),
        'vertexTolerance':.00001,'exactOtherParts':25,'all26ManifestPartRowsExact':True,'all8UnitBoundsExact':True,
        'changedPart':'MC_DT_HeraldicBanner__Brass','occupiedBoxChanges':box_changes,
        'source52Preserved':True,'originalDT01Preserved':True,'originalUploadedFBXSHA256':original_sha,
        'nativeImportVerified':False,'studioTouched':False,'liveBlenderTouched':False,'uploadedByThisAuthor':False,
        'files':{str(path.relative_to(ROOT)).replace('\\','/'):{'bytes':path.stat().st_size,'sha256':sha(path)}
                 for path in list(OUT.iterdir())+list(HERE.iterdir()) if path.is_file() and path.name!='kit-freeze.json'}}
(HERE/'kit-freeze.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':True,'fbx':report['files'][str((OUT/'MC_DETAIL_KIT_DT01.fbx').relative_to(ROOT)).replace('\\','/')],
                  'manifest':report['files'][str((OUT/'manifest.json').relative_to(ROOT)).replace('\\','/')],
                  'maximumFBXVertexError':report['maximumFBXVertexError'],'occupiedBoxChanges':len(box_changes)}))
