from pathlib import Path
import json
import re
import sys

root = Path(__file__).resolve().parents[4]
folder = root / 'docs/artifacts/keyboard-circuit'
normal = json.loads((folder/'phase2/P2-I09-normal-two-lap-summary-03.json').read_text())
expert = json.loads((folder/'phase2/P2-I09-expert-two-lap-summary-03.json').read_text())
final = len(sys.argv) > 1 and sys.argv[1] == 'final'
brief = folder/'COURSE_BRIEF.md'
text = brief.read_text(encoding='utf-8')
status = '- **Status:** `Workspace.KeyboardCircuit_P2_I09_Experience03`, revision `KC_P2_I09_03`, layout `KC_LAYOUT_P2_I09_03`, is installed at `(22500,330,-1600)`. Normal retains sixteen encounters/eight mechanisms; two optional Expert cuts retain twelve encounters/six mechanisms, both Enter sections and all four sound districts. Four midpoint saves give seven checkpoints plus start. Candidate02 failed pale-ink/obscured-panel reviews; current03 fixes both and passes 24 native contrast checks plus400 sign text-region sightlines.'
status += ' Fresh current03 races, focused tests, native recovery and five exact-candidate reviews pass; owner Phase2 acceptance is pending.' if final else ' Fresh current03 Normal/Expert races pass; focused tests, native recovery and final independent reviews are being completed.'
text = re.sub(r'^- \*\*Status:\*\*.*$',lambda _:status,text,count=1,flags=re.M)
reviewers = '- **Reviewers:** /root/kc_i09_r1_visual, /root/kc_i08_r2_route, /root/kc_i08_r3_hazards, /root/kc_i09_r4_experience and /root/kc_i08_r5_engineering, each gpt-6.1-sol / high. Five independent overall judgments must each score at least8.5 with zero blockers on the same frozen current03 candidate. No average or inherited score substitutes for an individual pass.'
text = re.sub(r'^- \*\*Reviewers:\*\*.*$',lambda _:reviewers,text,count=1,flags=re.M)
timing = f"Fresh current03 clean continuous two-lap tests pass Normal{normal['continuousSeconds']:.3f}s and Expert{expert['continuousSeconds']:.3f}s, with ten natural gates/eight midpoint saves/zero recoveries each. Enrollment including initial setup is {normal['serverEnrollmentSeconds']:.3f}/{expert['serverEnrollmentSeconds']:.3f}s. Both Expert endpoints are physically shorter and faster on each lap; mechanism arrivals are unpaired. The owner permits longer Expert time to retain the experience. Automated clean traversal does not establish typical-human time, mistake distribution, controlled same-phase savings or subjective difficulty. Ordinary movement and zero artificial timing holds are verified. [Current evidence](phase2/P2-I09-REVIEW-BRIEF-03.md)."
text = re.sub(r'^Fresh I09 continuous two-lap movement tests.*$',lambda _:timing,text,count=1,flags=re.M)
if final:
    next_action = '- **Next action:** owner playtest and Phase2 acceptance. Play → F6 → Keyboard Circuit — 2 Laps starts the current course; the same button restarts and Lobby exits. Five technical passes do not constitute owner acceptance or typical-human pacing proof. [Final report](phase2/P2-I09-FINAL-REPORT-03.md).'
    text = re.sub(r'^- \*\*Next action:\*\*.*$',lambda _:next_action,text,count=1,flags=re.M)
brief.write_text(text,encoding='utf-8')
prompts = folder/'VISUAL_INSPIRATION_PROMPTS.md'
text = prompts.read_text(encoding='utf-8').replace('work-i09/Layout.luau govern','work-i09-03/sources/Layout.luau govern')
prompts.write_text(text,encoding='utf-8')
(folder/'route-preview.png').write_bytes((folder/'phase2/native/I09-route-plan-03.png').read_bytes())
print(json.dumps({'currentBrief':True,'stage':'final' if final else 'verification','routePreview':'current03 coordinate schematic'}))
