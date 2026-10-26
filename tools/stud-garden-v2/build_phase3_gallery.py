"""Present final F04 native evidence and clearly labeled preserved F03 details."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/artifacts/stud-garden-v2/phase3'
native = sorted((OUT / 'f04/native').glob('*.png'))
previous = sorted((OUT / 'f03/native').glob('*.png'))
assert len(native) == 8 and len(previous) == 16
summary_path = OUT / 'FINAL_REVIEW_SUMMARY.json'
summary = json.loads(summary_path.read_text()) if summary_path.exists() else {'reviews': [], 'artBuildAndStaticReviewComplete': False}


def figure(path, label):
    relative = path.relative_to(OUT).as_posix()
    assert path.is_file()
    return f'<figure><a href="{relative}"><img loading="lazy" src="{relative}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>'


pairs = ''
for name in ('08-grove-reverse', '09-grove-root-detail'):
    pairs += '<div class="pair">'
    pairs += figure(OUT / f'f03/native/{name}.png', 'F03 · before · actual Studio')
    pairs += figure(OUT / f'f04/native/{name}.png', 'F04 · tapered ends · actual Studio')
    pairs += '</div>'
close = ''.join(figure(OUT / f'f04/native/{name}.png', label) for name, label in
                [('17-orchard-knot-close', 'F04 · orchard knot · actual Studio'),
                 ('18-grove-knot-close', 'F04 · grove knot · actual Studio')])
gallery = ''.join(figure(p, p.stem.replace('-', ' ')+' · actual Studio F04') for p in native)
old_gallery = ''.join(figure(p, p.stem.replace('-', ' ')+' · preserved F03 evidence') for p in previous)
review_rows = ''.join(f'<tr><td><a href="{row["report"]}">{html.escape(row["scope"])}</a></td><td>{row["score"]:.1f} / 10</td><td>{html.escape(row["disposition"])}</td></tr>' for row in summary['reviews'])
review_status = 'All three independent final reviews exceed 8.5; the required root correction is resolved.' if summary['artBuildAndStaticReviewComplete'] else 'Final independent reviews are being completed.'
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Stud Garden V2 · Phase 3 review</title><style>
:root{color-scheme:light;--ink:#26382c;--paper:#f4f1e8;--line:#c9d2c2}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.55 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:42px 28px}header{max-width:960px;margin-bottom:32px}h1{font:600 clamp(32px,4vw,56px)/1.1 Georgia,serif;margin:12px 0 20px}h2{font:600 30px/1.2 Georgia,serif;margin:48px 0 12px}p{max-width:950px}a{color:#2d683c}nav{display:flex;gap:20px;flex-wrap:wrap;border-block:1px solid var(--line);padding:14px 0}.eyebrow{text-transform:uppercase;letter-spacing:.15em;font-size:12px}.status{padding:18px 22px;background:#e4e9de;border-left:4px solid #6b844f;max-width:960px}.pair,.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}figure{margin:12px 0 22px}img{display:block;width:100%;height:auto;background:#d7dfd0}figcaption{font-size:13px;margin:8px 0;color:#506150}.gallery{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}table{border-collapse:collapse;margin:18px 0 28px}td,th{text-align:left;border-bottom:1px solid var(--line);padding:10px 24px 10px 0}small{color:#506150}code{font-size:.9em}footer{border-top:1px solid var(--line);margin-top:40px;padding-top:20px}@media(max-width:850px){.gallery{grid-template-columns:repeat(2,1fr)}}@media(max-width:600px){main{padding:24px 16px}.pair,.grid,.gallery{grid-template-columns:1fr}h2{font-size:26px}}
</style><main><header><div class="eyebrow">Stud Garden V2 / Phase 3 / 5 October 2026</div><h1>A full garden at racer height.</h1><p>Oversized flowers, thick bamboo, pink and aqua trees, layered planting and raised studs now surround all five settings. The final F04 preview includes the corrected tapered root knots and their matching physical shapes.</p></header>
<nav><a href="#native">Final Studio views</a><a href="#correction">Root before and after</a><a href="#prior">Preserved course details</a><a href="PHASE3_STATUS.md">Report and evidence</a><a href="f04/native/sgv2-phase3-f04-native.rbxm">F04 native recovery</a></nav>
<div class="status"><strong>F04 is installed and checked.</strong> ''' + review_status + ''' The candidate remains a disabled art preview. Gameplay, camera movement, twenty real racers and device performance are separate unverified gates.</div>
<h2 id="native">The final map in Roblox Studio</h2><p>Candidate <code>Workspace.SGV2_Phase3_F04</code>, fingerprint <code>75cbafea</code>, origin <code>(11800,80,3500)</code>. Eight actual native views cover the whole map and corrected grove. The northeast view includes a distant preserved preview and slightly clips the nearest boundary; the southwest view shows the complete map.</p>
<table><thead><tr><th>Independent scope</th><th>F04 score</th><th>Disposition</th></tr></thead><tbody>''' + review_rows + '''</tbody></table><div class="gallery">''' + gallery + '''</div>
<h2 id="correction">Short tapered ends; the same central height.</h2><p>These paired Studio images use matching course-relative camera positions. Nine cylinder visuals and contacts are replaced by convex tapered meshes. The crown surfaces, central growth balls, bark strips, gaps and surrounding garden remain unchanged. All 576 sampled mesh faces agree with native collision within 0.0013 studs. Click any image for full size.</p>
''' + pairs + '<div class="grid">' + close + '''</div>
<p><a href="f04/SGV2_Phase3_F04_Knots.fbx">Uploaded nine-mesh correction</a> · <a href="f04/SGV2_Phase3_F04.blend">Editable complete F04 scene</a> · <a href="f04/native-checks.json">Native contact and preservation checks</a> · <a href="f04/native/file-check.json">Recovery file hash</a></p>
<h2 id="prior">Preserved course details</h2><p>These sixteen images are explicitly from F03. They show all five settings, forward/reverse views, transitions and the destination before the knot repair. Native comparison verifies the other 4,955 parts are unchanged after translation, apart from the nine declared cylinder settings. They support whole-course review without pretending to be new F04 captures. The gate-post view has a clearer reverse supplement; the exterior destination view is partly obscured by a boundary tree.</p><details><summary>Show the sixteen labeled F03 views</summary><div class="gallery">''' + old_gallery + '''</div></details>
<footer><p>F04: 4,964 parts · 395 MeshParts · 3,300 colliders · 469,888 added-art triangles · zero scripts. R305 and F03 remain intact. Native save/restore and independent disk readback preserve the final fingerprint. No ordinary-control run, active hazard/recovery event, moving-camera test, real twenty-racer trial, timing or representative-device result is claimed. No publishing or race-control integration occurred.</p></footer></main></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps(dict(gallery=str(OUT/'index.html'), finalNativeViews=len(native), preservedF03Views=len(previous))))
