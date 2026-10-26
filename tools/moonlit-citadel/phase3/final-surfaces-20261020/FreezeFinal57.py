import hashlib,json
from pathlib import Path
root=Path.cwd()
out=root/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020'
tools=root/'tools/moonlit-citadel/phase3/final-surfaces-20261020'
names=['art','layout','navigation','difficulty','runtime']
reviews=[out/f'reviews/judge_{n}57.md' for n in names]
assert all(p.is_file() for p in reviews),'Wait for all five independent review artifacts'
files=[out/n for n in ['repair_final57_packet.json','source-scope57.json','native-final-proofs57.json',
'native-install-check57.json','fresh-build-preflight57.json','add-details57.json','cleanup-final57.json',
'editor-restoration57.json','render-limits57.json','HANDOFF57.md','REVIEW_GATE57.json']]
files+=reviews
files+=[tools/'neighbors'/n for n in ['FINAL_POSE138.json','FINAL_SCENE138_KIT02_CHECK.json','FINAL_NEIGHBOR_FREEZE138.json']]
files+=[tools/'mesh-cleanup/proposal02'/n for n in ['FREEZE.json','NATIVE_SR02_FREEZE.json','upload-receipt.json']]
files+=[tools/'internal'/n for n in ['SOURCE_IMPLEMENTATION138_RECEIPT.json','surface-finishing138-unit-tests.json']]
files+=sorted(tools.glob('*.luau'))+[tools/'StageSource57.py']
records=[]
for p in files:
    assert p.is_file(),str(p)
    records.append({'path':p.relative_to(root).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
packet=json.loads((out/'repair_final57_packet.json').read_text(encoding='utf-8'))
for row in packet['records']:
    p=root/(f"src/ReplicatedStorage/Config/{row['name']}.luau" if row['name']=='MoonlitCitadelAmbienceConfig' else f"src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/{row['name']}.luau")
    assert p.read_text(encoding='utf-8').replace('\r\n','\n')==row['source'],row['name']
freeze={'source':57,'build':51,'candidate':packet['candidate'],'packetSHA256':hashlib.sha256((out/'repair_final57_packet.json').read_bytes()).hexdigest(),
'status':'native_and_source_implemented_visual_gate_hold','geometryAndPreservationVerified':True,'movingNativeAppearanceVerified':False,
'ownerAcceptance':'Pending','wholePlaceSaved':False,'published':False,'records':records}
(out/'FINAL_FREEZE57.json').write_text(json.dumps(freeze,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'pass':True,'frozenFiles':len(records),'sourceRecords':len(packet['records']),'packetSHA256':freeze['packetSHA256'],'status':freeze['status']}))

