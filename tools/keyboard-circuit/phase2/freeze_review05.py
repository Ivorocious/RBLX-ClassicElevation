from pathlib import Path
import hashlib, json

root = Path(__file__).resolve().parents[3]
package = root / "docs/artifacts/keyboard-circuit/phase2"
target = package / "P2-C01-I05-FROZEN.json"
assert not target.exists(), "Inspect existing freeze before retry"
source_dir = root / "src/ServerStorage/CourseBuilders/KeyboardCircuitPhase2"
staged = root / "tools/keyboard-circuit/phase2/staged"
sources = sorted(source_dir.glob("*.luau"))
assert len(sources) == 16
for path in sources:
    assert path.read_bytes() == (staged / path.name).read_bytes(), path.name
core_sources = sources + sorted(source_dir.glob("*.meta.json")) + [
    root / "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
    root / "src/StarterPlayer/StarterPlayerScripts/Controllers/LobbyUiController.luau",
]
paths = set(core_sources + list(staged.glob("*.luau")))
paths.update([
    root / "default.project.json",
    root / "docs/COURSE_WORKFLOW_V3.md",
    root / "docs/COURSE_CREATOR_WORKFLOW.md",
    root / "docs/artifacts/keyboard-circuit/PHASE2_START.md",
    root / "docs/artifacts/keyboard-circuit/keyboard-circuit.drawio",
    root / "docs/artifacts/keyboard-circuit/VISUAL_INSPIRATION_PROMPTS.md",
    package / "P2-C01-REVIEW-BRIEF.md",
    package / "I05-HANDOFF-PROPOSAL.md",
    package / "research/H08-continuous-diagnosis.md",
    package / "research/H08-clearance-diagnosis.md",
])
paths.update(package.glob("P2-C01*.json"))
paths.update((root / "tools/keyboard-circuit/phase2").glob("*.luau"))
for name in [
    "KeyboardCircuit_P2_C01_I05.rbxm", "KeyboardCircuit_Phase2EditableKit_K02_I05.rbxm",
    "P2-C01-current-edit-readonly-05.jpg", "P2-C01-overview-04.jpg",
    "P2-C01-CP1-avatar-05.jpg", "P2-C01-phone-landscape-05.jpg", "P2-C01-phone-portrait-05.jpg",
]:
    paths.add(package / "native" / name)
def entry(path):
    content = path.read_bytes()
    return {"path": path.relative_to(root).as_posix(), "bytes": len(content), "sha256": hashlib.sha256(content).hexdigest()}
entries = sorted([entry(path) for path in paths], key=lambda row: row["path"])
core = sorted([entry(path) for path in core_sources], key=lambda row: row["path"])
source_fingerprint = hashlib.sha256("".join(row["path"] + ":" + row["sha256"] + "\n" for row in core).encode()).hexdigest()
report = {
    "candidate": "KC_P2_C01-I05-UI01", "constructionIteration": 5, "previewUi": "KC_P2_UI01",
    "kitRevision": "KC_KIT_P2_01", "placeId": 85558151074819, "universeId": 10191126818,
    "sourceCount": 16, "coreSourceFileCount": len(core), "sourceFingerprint": source_fingerprint,
    "sourceFingerprintRule": "SHA256 of sorted coreSources path:sha256 plus LF for each row",
    "courseSha256": hashlib.sha256((package / "native/KeyboardCircuit_P2_C01_I05.rbxm").read_bytes()).hexdigest(),
    "kitSha256": hashlib.sha256((package / "native/KeyboardCircuit_Phase2EditableKit_K02_I05.rbxm").read_bytes()).hexdigest(),
    "coreSources": core, "entries": entries, "frozenEntryCount": len(entries),
    "requiredIndependentReviewers": 5, "eachRequiredOverallScore": 8.5, "eachRequiredUnresolvedBlockers": 0,
    "reviewReportsFrozen": False, "ownerPhase2Acceptance": "Pending",
    "limits": [
        "One automated continuous lap, not human three-lap timing or target proof",
        "Twenty-racer capacity, physical devices, cold cache, human sound/difficulty and shortcut savings unmeasured",
        "Earlier separate idle-session falls unassigned; bounded post-cleanup idle pass is separate",
        "No whole-place save, publication or Phase3 finishing",
    ],
}
target.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"candidate": report["candidate"], "entries":len(entries),"sourceFingerprint":source_fingerprint,"manifestSha256":hashlib.sha256(target.read_bytes()).hexdigest()}))

