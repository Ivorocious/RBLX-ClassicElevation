import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parents[4]
# The script lives four folders below the repository root.
if not (root/'src').is_dir():
    root=Path.cwd()
out=root/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020'
old=json.loads((root/'docs/artifacts/moonlit-citadel/phase3/veil-20261020/repair_veil56_packet.json').read_text(encoding='utf-8'))
records=[]
for p in sorted((root/'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse').glob('*.luau')):
    records.append({'name':p.stem,'source':p.read_text(encoding='utf-8').replace('\r\n','\n')})
p=root/'src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau'
records.append({'name':p.stem,'source':p.read_text(encoding='utf-8').replace('\r\n','\n')})
assert len(records)==37
packet={'sourceRevision':57,'buildRevision':51,'candidate':'MC_P3_FINAL_SURFACES_20261020','records':records,
'previousPacketSHA256':'995134fe3e5e6e895c3a48b51e5a360509b6b6d8a90ed27a604eec414e01e31b',
'ownerCorrection':'Final full-scene surface pass; retain original floor, veil, contacts, hazards, arrows and finish.'}
raw=(json.dumps(packet,ensure_ascii=False,indent=2)+'\n').encode()
(out/'repair_final57_packet.json').write_bytes(raw)
hashes={r['name']:hashlib.sha256(r['source'].encode()).hexdigest() for r in records}
oldmap={r['name']:hashlib.sha256(r['source'].encode()).hexdigest() for r in old['records']}
scope={'packetSHA256':hashlib.sha256(raw).hexdigest(),'source':57,'build':51,'records':len(records),'moduleHashes':hashes,
'unchanged':[n for n in hashes if oldmap.get(n)==hashes[n]],'changed':[n for n in hashes if n in oldmap and oldmap[n]!=hashes[n]],'added':[n for n in hashes if n not in oldmap]}
(out/'source-scope57.json').write_text(json.dumps(scope,indent=2)+'\n',encoding='utf-8')
print(json.dumps(scope))

