from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parents[3]
folder = root / 'docs/artifacts/moonlit-citadel/phase2'
review = folder / 'revision06/review_runtime'
rows = []
for name in ('BoundaryCases', 'PrivateResetCase'):
    for parent in ('ServerStorage', 'ReplicatedStorage'):
        path = review / ('R06' + name + '.luau')
        rows.append({'instancePath': parent + '/MoonlitPhase2Tools/' + name, 'source': path.read_text(encoding='utf-8'), 'class': 'ModuleScript'})
for name, path, parent, kind in (
    ('R06RuntimeBootstrap', review / 'R06RuntimeBootstrap.server.luau', 'ServerScriptService', 'Script'),
    ('R06RuntimeBootstrap', review / 'R06RuntimeBootstrap.client.luau', 'StarterPlayer/StarterPlayerScripts', 'LocalScript'),
):
    rows.append({'instancePath': parent + '/' + name, 'source': path.read_text(encoding='utf-8'), 'class': kind})
for row in rows:
    row['sha256'] = hashlib.sha256(row['source'].encode()).hexdigest()
packet = {'candidate': 'MC_P2_C01_R06', 'kind': 'Owned two-client diagnostic overlay', 'sources': rows}
path = folder / 'MC_P2_R06_runtime_overlay01.json'
assert not path.exists()
path.write_text(json.dumps(packet), encoding='utf-8')
print(json.dumps({'path': str(path), 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'sources': len(rows)}))
