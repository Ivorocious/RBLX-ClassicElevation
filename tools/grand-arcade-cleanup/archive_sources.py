"""Freeze the six Grand Arcade sources before retiring authoring-only modules."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = ROOT / 'archives/grand-arcade/cleanup-20261006'
snapshot = json.loads((ROOT / 'docs/artifacts/grand-arcade-cleanup-20261006/native-before.json').read_text())
records = []
for native_path, native_source in snapshot['sources'].items():
    relative = Path('src', *native_path.split('.')).with_suffix('.luau')
    source = (ROOT / relative).resolve()
    assert source.is_relative_to(ROOT)
    data = source.read_bytes()
    repo_text = data.decode('utf-8-sig').replace('\r\n', '\n').rstrip()
    studio_text = native_source.replace('\r\n', '\n').rstrip()
    if native_path == 'ServerScriptService.Services.GrandArcadeService':
        assert studio_text.count('\u00c2\u00b7') == 1
        studio_text = studio_text.replace('\u00c2\u00b7', '\u00b7')
    assert repo_text == studio_text, native_path
    target = ARCHIVE / 'source-before' / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        assert target.read_bytes() == data, relative
    else:
        target.write_bytes(data)
    assert target.read_bytes() == data
    native_target = ARCHIVE / 'native-source-before' / relative
    native_target.parent.mkdir(parents=True, exist_ok=True)
    native_target.write_text(native_source, encoding='utf-8')
    records.append({'path': relative.as_posix(), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                    'removeFromActiveTree': native_path.startswith('ServerStorage.')})
(ARCHIVE / 'source-manifest.json').write_text(json.dumps({'files': records, 'copied': len(records), 'plannedRemovals': 5}, indent=2)+'\n')
print('Six sources archived; differences are terminal whitespace and one known damaged separator in the live service. Five authoring modules will be retired.')
