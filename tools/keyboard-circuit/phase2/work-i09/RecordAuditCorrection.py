from pathlib import Path
import hashlib
import json
import shutil

root=Path(__file__).resolve().parents[4]
folder=root/'docs/artifacts/keyboard-circuit/phase2'
initial=folder/'P2-I09-source-freeze-01.json'
final=folder/'P2-I09-source-freeze-02.json'
a=json.loads(initial.read_text());b=json.loads(final.read_text())
left={row['path']:row['sha256'] for row in a['entries']};right={row['path']:row['sha256'] for row in b['entries']}
changed=[path for path in left if left[path]!=right[path]]
assert changed==['tools/keyboard-circuit/phase2/work-i09/NativeAudit.server.luau']
audit=json.loads((folder/'P2-I09-native-feature-audit-02.json').read_text())
assert {r['id']:r['skips'] for r in audit['branches']}=={'X03':'O02,H03','X02':'H07,O06'}
result={'passed':True,'candidate':a['candidate'],'revision':a['revision'],'initialFreezeSha256':hashlib.sha256(initial.read_bytes()).hexdigest(),
        'finalFreezeSha256':hashlib.sha256(final.read_bytes()).hexdigest(),'changedInputs':changed,'unchangedInputs':len(left)-len(changed),
        'gameSourceChanges':0,'geometryChanges':0,'rawTracesChanged':False,'nativeExportChanged':False,
        'correction':'NativeAudit reads the authored Skips attribute instead of the nonexistent SkippedSequences attribute; current audit now reports both exact skip lists. Stale X01 representative-study text corrected in the current brief.',
        'boundary':'One test-only attribute-read correction. Current gameplay, geometry, native export and passing traces are unchanged; all final judgments must bind freeze02 independently.'}
(folder/'P2-I09-audit-field-correction-01.json').write_text(json.dumps(result,indent=2)+'\n')
history=folder/'history/I09-before-audit-field-fix/reviews'
history.mkdir(parents=True,exist_ok=True)
for path in (folder/'reviews').glob('I09-R*.*'):
    target=history/path.name
    if not target.exists(): shutil.copy2(path,target)
brief=folder/'P2-I09-REVIEW-BRIEF-01.md'
text=brief.read_text()
text=text.replace('P2-I09-source-freeze-01.json','P2-I09-source-freeze-02.json').replace('P2-I09-freeze-agreement-01.json','P2-I09-freeze-agreement-02.json').replace('P2-I09-native-feature-audit-01.json','P2-I09-native-feature-audit-02.json')
text=text.replace(result['initialFreezeSha256'],result['finalFreezeSha256'])
marker='## Required judgment files'
text=text.replace(marker,'## Final audit correction\n\nR5 identified a receipt-only mismatch: NativeAudit read SkippedSequences while the builder authors Skips. The one fixture read is corrected, the fresh audit reports O02/H03 and H07/O06, and final freeze02 records 39 unchanged inputs, one test-only delta and zero gameplay/geometry changes. Raw traces and native export are unchanged. [Correction receipt](P2-I09-audit-field-correction-01.json). Initial judgments are preserved in history; every final judgment independently binds freeze02. The stale X01 study paragraph in the current brief is also corrected.\n\n'+marker)
brief.write_text(text)
print(json.dumps(result))
