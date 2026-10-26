"""Package verified native photographs, reviews and recovery pointers locally."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'docs/artifacts/stud-garden-v2/refinement-20261005'
FINAL = BASE / 'r02'

def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

receipt = read_json(FINAL / 'install-receipt.json')
archive = BASE / 'native/sgv2-r02-native.rbxm'
assert sha(archive) == receipt['archive']['sha256']
assert archive.stat().st_size == receipt['archive']['bytes']
state = read_json(FINAL / 'final-edit-check.json')
assert state['course']['geometry']['hash'] == '3b36ec9d'
assert state['course']['contentHash'] == 'e6789f4c'
assert not state['running'] and not state['enabled'] and not state['temporaryTests']
scores = {}
for scope in ('ART', 'ROUTE', 'CONTACT'):
    path = BASE / f'reviews/{scope}_FINAL_R02.md'
    text = path.read_text(encoding='utf-8-sig')
    score = float(re.search(r'(\d+(?:\.\d+)?)/10', text).group(1))
    assert score >= 8.5 and '3b36ec9d' in text and 'e6789f4c' in text
    scores[scope.lower()] = score

sources = list((ROOT / 'tools/stud-garden-v2/refinement').glob('*.luau'))
sources += list((ROOT / 'tools/stud-garden-v2/refinement').glob('*.py'))
sources += [ROOT / 'tools/stud-garden-v2' / p for p in (
    'Fingerprint.luau', 'CleanupFingerprint.luau', 'closing/NativeKit.luau',
    'closing/RoutePresentation.luau', 'closing/DescribeCourse.luau')]
source_hashes = []
for path in sources:
    relative = path.relative_to(ROOT)
    destination = FINAL / 'source' / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(path, destination)
    source_hashes.append({'path': relative.as_posix(), 'sha256': sha(path)})
(FINAL / 'source-manifest.json').write_text(json.dumps(source_hashes, indent=2))

summary = {
    'candidate': 'SGV2_Refinement_R02', 'geometry': '3b36ec9d', 'content': 'e6789f4c',
    'scores': scores, 'publicEnabled': False, 'published': False, 'running': False,
    'counts': {'parts': 6884, 'colliders': 3627, 'meshes': 377, 'instances': 7554,
               'embeddedScripts': 0, 'sourceMeshTriangleInstances': 280368},
    'ownerBaseline': {'parts': 7030, 'colliders': 4138, 'meshes': 417,
                      'sourceMeshTriangleInstances': 537092},
    'foliage': {'removedSmallBushes': 500, 'removedGenericFlowers': 67,
                'replacementShrubGroups': 24},
    'archive': receipt['archive'],
    'nativeTests': {
        'cropExpert': '12 connected steps, six real jumps',
        'vineExpert': '17 connected steps, eight real jumps',
        'mainConnections': '13 selected connections plus corrected connected basket and fork sequences',
        'killContacts': 10, 'checkpointRecoveries': 9, 'timedEncounters': 2,
        'deliberateExpertMissRecoveries': 2, 'namedWallContactCases': 12,
        'staticFirstTwentyCheckpointSlots': 180,
    },
    'limits': ['No complete main-route/finish race', 'No real twenty-racer test',
               'No human difficulty or timing validation', 'No measured FPS/device gain',
               'No exhaustive bypass proof', 'Saved console is truncated'],
}
(BASE / 'SUMMARY.json').write_text(json.dumps(summary, indent=2))

views = [
    ('17-display-overview.jpg', 'Central botanical display', 'Image 6: fewer large plants, a golden flower centerpiece, bamboo, broad rosettes and a defined bed.'),
    ('19-pet-fence.jpg', 'Pet garden frontage', 'Image 1: the raised display has a joined fence beside checkpoint 02.'),
    ('20-candy-divider.jpg', 'Grove separator', 'Image 2: planted panels separate the adjacent routes.'),
    ('21-vine-dividers.jpg', 'Vine and checkpoint boundaries', 'Images 3 and 4: pale playable leaves remain distinct from the dark walls and landmark.'),
    ('22-market-dividers.jpg', 'Market boundaries', 'Image 4: harvest wagons and the vine district stay separated.'),
    ('23-fork-wall-extension.jpg', 'Extended tool wall', 'Image 5: a continuous capped wall runs along the tool return.'),
    ('04-crown.jpg', 'Beanstalk crown', 'Image 8: broad attached leaves, raised studs and a formed terminal shoot.'),
    ('16-tree-grounding.jpg', 'Grounded tree detail', 'A close native view shows the complete trunk. The earlier apparent gap was a foreground flower.'),
    ('09-large-rosette.jpg', 'Broad leaf detail', 'Joined thick leaves, visible veins and raised studs.'),
    ('24-thumbnail.jpg', 'Whole course in the current place', 'The preserved Lobby overlaps this distant composition. Use the central display view for its thumbnail.'),
]
available = {p.name: p for p in (BASE / 'r01/native-views').glob('*.jpg')}
if '04-crown.jpg' not in available:
    crown = next(p for p in available if p.startswith('04'))
    views = [(crown if name == '04-crown.jpg' else name, title, caption) for name, title, caption in views]
figures = []
for name, title, caption in views:
    assert name in available, name
    source = f'r01/native-views/{name}'
    figures.append(f'<figure><a href="{source}"><img loading="lazy" src="{source}" alt="{html.escape(title)}"></a><figcaption><strong>{html.escape(title)}</strong><p>{html.escape(caption)}</p></figcaption></figure>')
score_text = ' · '.join(f'{k.title()} {v:.1f}/10' for k, v in scores.items())
document = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Stud Garden V2 — R02 native review</title><style>
*{box-sizing:border-box}body{margin:0;background:#f2f5ed;color:#213b2b;font:17px/1.5 system-ui,sans-serif}main{max-width:1300px;margin:auto;padding:40px 24px}h1{font-size:clamp(30px,4vw,55px);line-height:1.1;margin:12px 0}p{max-width:78ch}a{color:#176139}nav{display:flex;gap:22px;flex-wrap:wrap;margin:24px 0}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}figure{margin:0;background:white;overflow:hidden;border:1px solid #d5dfd0}figure:first-child{grid-column:1/-1}img{width:100%;display:block}figcaption{padding:18px}figcaption p{margin:5px 0 0;color:#536756;font-size:15px}.scores{font-weight:650}.limits{padding:16px 20px;border-left:4px solid #78975c;background:#e6ecde;margin:24px 0 32px}@media(max-width:700px){.grid{grid-template-columns:1fr}main{padding:26px 16px}}</style><main>
<p>ACTUAL ROBLOX STUDIO VIEWS · OCTOBER 6, 2026</p><h1>Stud Garden V2</h1><p>Final owner refinement R02. Less filler, larger focal plants, a grand studded beanstalk, stronger boundaries and tighter expert routes.</p>
'''
document += f'<p class="scores">{html.escape(score_text)}</p>'
document += '<nav><a href="REPORT.md">Changes and test evidence</a><a href="SUMMARY.json">Exact counts</a><a href="native/sgv2-r02-native.rbxm">Final native model</a></nav><p class="limits">All three independent reviews pass for this refinement. Public selection is disabled and nothing was published. Complete races, twenty-player flow, human difficulty, race timing and device performance remain unverified.</p><section class="grid">'
document += ''.join(figures) + '</section></main></html>'
(BASE / 'NATIVE_PREVIEW.html').write_text(document, encoding='utf-8')

old_diff = BASE / 'owner-differences.json'
history = BASE / 'owner-differences.superseded.json'
if not history.exists():
    shutil.copyfile(old_diff, history)
old_diff.write_text(json.dumps({
    'status': 'Superseded: path-keyed dictionaries lose duplicate-named native parts.',
    'use': ['reviews/CONTACT_R01_NATIVE_AUDIT.json', 'reviews/CONTACT_R02_ARCHIVE_COMPARE.json'],
    'verifiedPreservation': ['12 GardenEntryBench parts', '13 BasketDisplayStand parts',
                             '13 BasketFloor parts', '105 LastTrowel parts', 'FinalRoot remains absent'],
    'limits': 'These are exact multiset comparisons with the current owner baseline. The superseded record is retained only as diagnostic history.'
}, indent=2))

files = [archive, FINAL / 'install-receipt.json', FINAL / 'final-edit-check.json',
         FINAL / 'native-geometry.json', FINAL / 'source-manifest.json']
files += [BASE / f'reviews/{scope}_FINAL_R02.md' for scope in ('ART', 'ROUTE', 'CONTACT')]
files += [available[name] for name, _, _ in views]
(FINAL / 'evidence-manifest.json').write_text(json.dumps([
    {'path': p.relative_to(BASE).as_posix(), 'bytes': p.stat().st_size, 'sha256': sha(p)}
    for p in files
], indent=2))
print(json.dumps({'candidate': summary['candidate'], 'scores': scores, 'sources': len(source_hashes), 'galleryViews': len(views), 'archiveSha256': sha(archive)}))
