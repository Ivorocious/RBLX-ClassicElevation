from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[3]
revision = root / 'assets/shipwreck_cove/revision'
paths = list((root / 'src/ServerStorage/CourseBuilders/ShipwreckCove').glob('*.luau'))
paths += [root / name for name in (
    'src/ReplicatedStorage/Config/ShipwreckConfig.luau',
    'src/ReplicatedStorage/Shared/ShipwreckHazards.luau',
    'src/ServerScriptService/Services/CourseService.luau',
    'default.project.json',
)]
paths += [revision / name for name in (
    'layout29.py', 'routes29.py', 'ground29.py', 'grounding29.json',
    'layout29.json', 'manifest29.json', 'build_palm29.py',
    'ShipwreckCove_Palm29.blend', 'ShipwreckCove_SC_MAP_29.blend',
    'ShipwreckCove_SC29_CANDIDATE_05.rbxm', 'assemble_blender.py',
)]
paths += list((root / 'docs/artifacts/shipwreck-cove/review29').glob('*.md'))
paths += list((root / 'docs/artifacts/shipwreck-cove/review29').glob('*.json'))
paths += list((root / 'docs/artifacts/shipwreck-cove/review29/perf-profile').glob('*.*'))
paths += [revision / name for name in (
    'layout28.json', 'layout.json', 'manifest13.json', 'manifest25.json',
    'manifest26.json', 'manifest27.json', 'manifestHorizon27.json',
    'manifest28.json', 'manifest28b.json', 'ShipwreckCove_Revision13.blend',
    'ShipwreckCove_Kit25.blend', 'ShipwreckCove_Kit26.blend',
    'KitHorizon27.blend', 'ShipwreckCove_Kit27.blend',
    'ShipwreckCove_Kit28.blend', 'ShipwreckCove_Wave28B.blend',
)]
paths += [revision.parent / 'phase1' / name for name in ('manifest.json', 'ShipwreckCove_Kit04.blend')]
output = revision / 'ShipwreckCove_SC29_CANDIDATE_05_source.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in paths:
        assert path.is_file(), path
        archive.write(path, path.relative_to(root))
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
print(output, output.stat().st_size, len(paths))
