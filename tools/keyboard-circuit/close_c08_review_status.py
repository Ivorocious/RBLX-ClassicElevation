import json
from pathlib import Path

root = Path.cwd()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
gate = json.loads((phase / "reviews/C08-FINAL-GATE.json").read_text(encoding="utf-8"))
assert gate["reviewGatePassed"] and gate["ownerCheckpointAccepted"] and len(gate["reviews"]) == 5
scores = " / ".join(f'{item["overallPhase1Score"]:.1f}' for item in gate["reviews"])
course = root / "docs/artifacts/keyboard-circuit/COURSE_BRIEF.md"
lines = course.read_text(encoding="utf-8").splitlines()
replacement = {
    "- **Status:**": f"- **Status:** Phase 1 C08 is accepted: the owner checkpoint and fresh original-five gate both passed. Independent scores are {scores}, each at least 8.5 with zero blockers. The gate audits all 82 frozen entries, fourteen sources and four native models. Startup audio readiness, real first-contact voices, stalled-clip movement/cleanup and narrow text layouts passed. Accepted geometry, key feel and sound treatment are retained. Phase 2 production remains on hold for its separate final pass.",
    "- **Next action:**": "- **Next action:** Phase 1 C08 is ready for the separately authorized Phase 2 final pass. [C08 final gate](phase1/reviews/C08-FINAL-GATE.json) records the exact five original judges, independent scores, report hashes and frozen package. Production expansion, whole-place save and publication remain outside this completed task.",
    "- **Operations / reviews in flight:**": "- **Operations / reviews in flight:** none. Source/native readiness checks and all five independent reviews are complete. Studio is in Edit with the owner's view restored within Studio rotation precision; Focus/FOV match. Earlier initial audio misses are historical; fresh readiness is solo/actual-avatar because the new multiplayer launch joined zero clients and was ended. Existing two-client shared holds remain separate. [C08 evidence](phase1/C08-REVIEW-BRIEF.md) states native, simulated and historical boundaries. No CPU/FPS gain, physical-device/full-race/20-racer result, whole-place save or publication is claimed.",
}
for index, line in enumerate(lines):
    for prefix, value in replacement.items():
        if line.startswith(prefix): lines[index] = value
course.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
index = phase / "reviews/INDEX.md"
content = index.read_text(encoding="utf-8")
before = "A fresh review by the same five High judges is pending on the frozen readiness package; [C08 final gate](C08-FINAL-GATE.json) records their later independent results."
assert before in content
after = f"All five original High judges independently pass the same frozen readiness package at {scores}, each with zero blockers. [C08 final gate](C08-FINAL-GATE.json) audits their exact identities, reports and package hashes."
content = content.replace(before, after, 1)
rows = "\n".join(f'| {item["reviewer"]} | {item["overallPhase1Score"]:.1f} | 0 | [JSON](R{number}-C08.json) |' for number, item in enumerate(gate["reviews"], 1))
marker = "## Historical C07 gate"
if marker not in content:
    marker = "## C07"
table = "\n\n| Original judge | Overall Phase 1 score | Blockers | Report |\n| --- | --- | --- | --- |\n" + rows + "\n\n"
if marker in content: content = content.replace(marker, table + marker, 1)
else: content = content.split("\n", 6)[0] + "\n" + table + content
index.write_text(content, encoding="utf-8", newline="\n")
for path in ["docs/TASKS.md", "docs/PLAYTEST_NOTES.md"]:
    with (root / path).open("a", encoding="utf-8", newline="\n") as stream:
        stream.write(f"\nC08 original-five gate closed: {scores}, each >=8.5 with zero blockers. Owner checkpoint accepted; Phase 1 complete. Phase 2 production remains on hold for its separate final pass. Frozen sources/native models are unchanged after scoring. No whole-place save or publication.\n")
print(json.dumps({"phase1Accepted": True, "scores": scores, "phase2ProductionAuthorized": False}))
