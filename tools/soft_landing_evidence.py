"""Package native captures and freeze the reviewed source revision."""
from pathlib import Path
import base64
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/artifacts/soft-landing-2026-10-01/r4'
for capture in (OUT / 'raw').glob('*.b64'):
    (OUT / f'{capture.stem}.jpg').write_bytes(base64.b64decode(capture.read_text()))

controllers = ['UiTheme', 'UiReveal', 'LobbyPresentation', 'LobbyView', 'LobbyUiController', 'LobbyIcons', 'ArrivalTransition', 'ArrivalEntranceView', 'OnboardingController']
sources = [f'src/StarterPlayer/StarterPlayerScripts/Controllers/{name}.luau' for name in controllers]
sources += ['src/ReplicatedStorage/Config/OnboardingConfig.luau', 'tools/ui-preview/SourceLoader.luau', 'tests/studio/SoftLandingEdit.luau', 'tests/studio/SoftLandingRecorder.luau']
manifest = {}
(OUT / 'source').mkdir(exist_ok=True)
for relative in sources:
    path = ROOT / relative
    snapshot = path.parent.name + '-' + path.name
    shutil.copy2(path, OUT / 'source' / snapshot)
    manifest[relative] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'snapshot': f'source/{snapshot}'}
digest = hashlib.sha256(json.dumps(manifest, sort_keys=True).encode()).hexdigest()
(OUT / 'source-manifest.json').write_text(json.dumps({'revision': 'Soft Landing R4', 'digest': digest, 'files': manifest}, indent=2))
print(json.dumps({'revision': 'Soft Landing R4', 'digest': digest, 'sourceFiles': len(manifest), 'captures': len(list(OUT.glob('*.jpg')))}))
