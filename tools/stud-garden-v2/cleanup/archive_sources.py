"""Preserve the exact Stud Garden source snapshot before scoped cleanup."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ARCHIVE = ROOT / 'archives/stud-garden/cleanup-20261006'
KEEP = {'CourseRuntime', 'Runtime', 'FruitRuntime', 'FruitMotion', 'HazardClock', 'Wayfinding'}

def contained(path):
    path = path.resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f'Outside project: {path}')
    return path

def sha(data):
    return hashlib.sha256(data).hexdigest()

files = list((ROOT / 'src/ServerStorage/CourseBuilders/StudGarden').glob('*.luau'))
files += list((ROOT / 'src/ServerStorage/CourseBuilders/StudGardenV2').glob('*.luau'))
files += [ROOT / p for p in (
    'src/ReplicatedStorage/Config/StudGardenConfig.luau',
    'src/ServerScriptService/Services/StudGardenService.luau',
    'src/ServerScriptService/Services/CourseService.luau',
    'tests/StudGardenHazards.luau', 'tests/StudGardenRuntime.luau',
    'tools/stud-garden-v2/test_hazard_clock.luau')]

records = []
for source in files:
    source = contained(source)
    relative = source.relative_to(ROOT)
    target = contained(ARCHIVE / 'source-before' / relative)
    data = source.read_bytes()
    if target.exists() and target.read_bytes() != data:
        raise ValueError(f'Existing archive differs: {relative}')
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        target.write_bytes(data)
    assert sha(target.read_bytes()) == sha(data)
    remove = source.parent.name == 'StudGarden' or (
        source.parent.name == 'StudGardenV2' and source.stem not in KEEP) or relative.as_posix() in {
            'src/ReplicatedStorage/Config/StudGardenConfig.luau',
            'tests/StudGardenHazards.luau', 'tests/StudGardenRuntime.luau'}
    records.append({'path': relative.as_posix(), 'bytes': len(data), 'sha256': sha(data),
                    'removeFromActiveTree': remove})

manifest = {'files': records, 'copied': len(records),
            'plannedRemovals': sum(r['removeFromActiveTree'] for r in records)}
contained(ARCHIVE / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps({'copied': manifest['copied'], 'plannedRemovals': manifest['plannedRemovals']}))
