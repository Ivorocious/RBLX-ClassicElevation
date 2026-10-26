import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT=Path.cwd()
ART=ROOT/'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014'
OWN=Path(__file__).resolve().parent
def load(path):return json.loads(path.read_text(encoding='utf8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

packet=load(ART/'source53-packet.json');plan=load(ART/'combined-plan53.json')
audit=load(ART/'final/native-audit53.json');fs=load(ART/'filesystem-preservation53.json');trace=load(ART/'native-capture-trace53.json')
images=[]
for row in trace['originals']:
    path=ART/row['path']
    with Image.open(path) as image:
        dims=list(image.size);format=image.format;image.verify()
    assert sha(path)==row['sha256'] and path.stat().st_size==row['bytes'] and dims==[row['width'],row['height']] and format=='JPEG'
    images.append({'path':row['path'],'sha256':row['sha256'],'bytes':row['bytes'],'dimensions':dims,'profile':row['profile']})
assert len(images)==8 and audit['pass'] and fs['pass']
paths=['source53-packet.json','combined-plan53.json','final/native-audit53.json','final/native-audit53-receipt.json',
       'final/source53-models.rbxm','final/source53-modules.rbxm','final/dt01-r01-library.rbxm','filesystem-preservation53.json',
       'native-capture-trace53.json','before/dt01-native-vertex-proof.json']
report={'source':53,'build':47,'candidate':'MC_P3_DETAILS_DT01','packetKeys':list(packet),'packetSHA256':sha(ART/'source53-packet.json'),
        'records':len(packet.get('records',[])),'planKeys':list(plan),'planUnits':len(plan['units']),
        'nativeExpected':audit['expected'],'filesystemKeys':list(fs),
        'filesystemCounts':{'before':fs['before'],'after':fs['after'],'unchanged':len(fs['unchanged']),'modified':len(fs['modified']),'added':len(fs['added'])},
        'filesystemFailureCount':len(fs.get('failures',[])),
        'nativeLedger':audit['detailLedger'],'nativePreservation':audit['preservation'],'sourceGuard':audit['sourceGuard'],
        'otherRoots':audit['otherMaps'],'geometryPass':audit['geometry']['geometryPass'],'traceKeys':list(trace),
        'images':images,'inputHashes':{str(ART/path):sha(ART/path) for path in paths},
        'pendingNativeCacheLocal':not (ART/'final/native-cache53.rbxm').exists(),
        'draftOnly':True,'studioTouched':False,'productionEdited':False}
(OWN/'evidence-summary53.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({key:report[key] for key in ('packetKeys','packetSHA256','records','planKeys','planUnits','nativeExpected','filesystemKeys','filesystemCounts','traceKeys','pendingNativeCacheLocal')}))
