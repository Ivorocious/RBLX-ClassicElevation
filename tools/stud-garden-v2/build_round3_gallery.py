"""Assemble owner-image comparisons from the preserved review evidence."""
import argparse
import html
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('candidate')
parser.add_argument('--native', action='store_true')
args = parser.parse_args()
base = Path(__file__).resolve().parents[2] / 'docs/artifacts/stud-garden-v2/phase2/round3'
candidate = args.candidate.lower()
views = base / f'offline-{candidate}/views'
rows = [
    ('Start clearance', '02-start', 'The start opening is taller; the board and rail clear the departure. Jump and camera behavior still need native play.'),
    ('Opening carts and stall', '03-stall-clearance', 'The stall is separated from the route. Both launch carts contain raised seed trays before the shared table.'),
    ('Garden tools', '04-tools', 'All six tools use shaped steel heads, sockets, wooden shafts and open grips. The fork has three separate tines.'),
    ('Checkpoint approaches', '06-cp2-approach', 'Side signs replace overhead checkpoint rails. The bench at checkpoint02 is separated. The full view set covers all nine checkpoints.'),
    ('Crop branch and common exit', '09-crop-layout', 'One broad loop and one narrow stake branch meet at the northern checkpoint, then share the tool exit.'),
    ('Candy grove', '19-grove-roots-approach', 'Rebuilt root crowns, connected bodies and raised knots lead through the fruit crossing. Root recognition remains an open visual finding on R305.'),
    ('Vine routes', '21-vine-layout', 'The broad leaf route is retained. Expert leaves are narrower and change height; route separation is screened in the current geometry.'),
    ('Harvest festival', '29-festival-layout', 'Cargo jumps, the basket and the final tools lead to a taller finish gate. The earlier late-section shortcut landing was removed.'),
]
cards = []
for number, (title, after, description) in enumerate(rows, 1):
    before = base / f'owner-images/owner-{number:02d}.png'
    after_path = base / f'native-{candidate}/{after}.jpg' if args.native else views / f'{after}.png'
    assert before.exists() and after_path.exists(), (before, after_path)
    after_label = 'After · actual Studio Edit preview' if args.native else 'After · offline geometry render'
    pair = ''.join(f'<figure><a href="{p.relative_to(base).as_posix()}"><img loading="lazy" src="{p.relative_to(base).as_posix()}" alt="{html.escape(title)} — {label}"></a><figcaption>{label}</figcaption></figure>' for p, label in ((before, 'Before · owner’s Studio image'), (after_path, after_label)))
    cards.append(f'<article id="area-{number}"><h2>{number:02d} / {html.escape(title)}</h2><p>{html.escape(description)}</p><div class="pair">{pair}</div></article>')
index = ''.join(f'<a href="{p.relative_to(base).as_posix()}"><img loading="lazy" src="{p.relative_to(base).as_posix()}" alt="{p.stem}"><span>{html.escape(p.stem.replace("-", " "))}</span></a>' for p in sorted(views.glob('*.png')))
status = 'Course preview installed in Edit mode; race integration and gameplay remain unverified.' if args.native else 'Offline candidate only; the live course has not been replaced.'
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Stud Garden V2 — Phase 2 comparisons</title><style>
:root{font:17px/1.55 system-ui,sans-serif;color:#243b2d;background:#f5f3ed}*{box-sizing:border-box}body{margin:0}main{max-width:1400px;padding:40px 28px 64px;margin:auto}h1{font-size:clamp(2rem,4vw,3.4rem);line-height:1.08;margin:.5em 0}h2{font-size:1.5rem;margin:0 0 8px}p{max-width:850px;margin:8px 0 20px}.eyebrow{letter-spacing:.13em;font-size:.8rem;font-weight:700}.status{border-left:4px solid #a57225;padding:14px 20px;background:#fff3d8;max-width:100%}nav{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0}a{color:#235a39}nav a{padding:6px 12px;border:1px solid #adb9ae;text-decoration:none}article{margin:46px 0;border-top:1px solid #cbd2c7;padding-top:22px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0;background:#e5e9df}img{display:block;width:100%;height:auto}figure img{aspect-ratio:8/5;object-fit:contain;background:#d9ded3}figcaption{padding:8px 12px;font-size:.85rem}.views{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.views a{text-decoration:none;background:#e5e9df}.views span{display:block;padding:8px 12px;font-size:.85rem}summary{font-weight:700;cursor:pointer;font-size:1.3rem;margin-bottom:20px}@media(max-width:800px){main{padding:24px 16px}.pair,.views{grid-template-columns:1fr}}
</style><main><div class="eyebrow">STUD GARDEN V2 / FINAL PHASE 2 QUALITY PASS</div>'''
evidence_note = 'The right image is the actual revised Studio Edit preview. The views use different camera positions to show the changed geometry.' if args.native else 'The right image is an offline Blender view rebuilt from exported geometry. Native lighting, surface studs and text layout can differ.'
page += f'<h1>Eight owner concerns.<br>Candidate {candidate.upper()}.</h1><p class="status"><strong>{status}</strong><br>The quality gate remains open. The <a href="ROUND3_REPORT.md">final report</a> records unresolved visual findings and the missing movement, expert reward, hazard and multiplayer checks. These images do not prove gameplay.</p><p>The left image in each pair is the owner’s original Studio screenshot. {evidence_note} Click any image for its full resolution.</p>'
page += '<nav>' + ''.join(f'<a href="#area-{i}">{i:02d} {html.escape(r[0])}</a>' for i, r in enumerate(rows, 1)) + '</nav>'
page += ''.join(cards)
if args.native:
    native_images = sorted((base / f'native-{candidate}').glob('*.jpg'))
    native_index = ''.join(f'<a href="{p.relative_to(base).as_posix()}"><img loading="lazy" src="{p.relative_to(base).as_posix()}" alt="{p.stem}"><span>{html.escape(p.stem.replace("-", " "))}</span></a>' for p in native_images)
    page += f'<details><summary>All {len(native_images)} actual Studio views</summary><div class="views">{native_index}</div></details>'
page += f'<details><summary>All {len(list(views.glob("*.png")))} offline approach and layout views</summary><p>Offline reconstruction; native images above take precedence for appearance.</p><div class="views">{index}</div></details></main></html>'
output = base / f'{candidate}-before-after.html'
output.write_text(page, encoding='utf-8')
print(json.dumps({'path':str(output), 'comparisons':len(rows), 'views':len(list(views.glob('*.png')))}))
