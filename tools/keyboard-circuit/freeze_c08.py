import hashlib
import json
import re
from pathlib import Path

root = Path.cwd().resolve()
phase = root / "docs/artifacts/keyboard-circuit/phase1"
sources = sorted((root / "src/ServerStorage/CourseBuilders/KeyboardCircuit").glob("*.luau"))
sources += [root / path for path in [
    "src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitFeedback.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitAudio.luau",
    "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPreview.client.luau",
]]
assert len(sources) == 14
package = json.loads((phase / "C08-source-package.json").read_text(encoding="utf-8"))
names = {"KeyboardCircuitConfig": "ConfigSnapshot", "KeyboardCircuitPreview.client": "KeyboardCircuitPreview"}
for path in sources:
    name = names.get(path.stem, path.stem.removesuffix(".server"))
    assert path.read_text(encoding="utf-8") == package[name], "Source package differs: " + name

verification = json.loads((phase / "C08-native-verification.json").read_text(encoding="utf-8"))
exports = json.loads((phase / "C08-export-verification.json").read_text(encoding="utf-8"))
assert verification["sourceMatches"] == 14 and verification["oneVisibleSymbolPerJoinedKey"]
for name in ["C08-shared-hold-proof.json", "C08-installed-play-proof-corrected.json", "C08-single-enter-proof.json", "C08-CLOSING-STATE.json", "C08-export-verification.json", "C08-readiness-startup-proof.json", "C08-readiness-first-steps.json", "C08-readiness-movement-fault-corrected-proof.json", "C08-readiness-status-layout.json"]:
    assert json.loads((phase / name).read_text(encoding="utf-8"))["passed"], name
for item in exports["files"].values():
    data = (root / item["path"]).read_bytes()
    assert len(data) == item["bytes"] and hashlib.sha256(data).hexdigest() == item["sha256"]

files = set(sources)
files.update(p for p in phase.glob("C08*") if p.is_file() and p.suffix.lower() in {".json", ".md", ".png", ".jpg"} and p.name not in {"C08-evidence-manifest.json", "C08-freeze-verification.json"})
files.update(phase / n for n in ["KC_C08_press.png", "KC_C08_sample_owner_view.jpg", "KC_C08_study_owner_view.jpg", "EVIDENCE.md", "ASSET_CATALOG.md", "audio/README.md", "research/C08-performance/query-work-model.json", "research/C08-performance/query-work-model.luau", "research/C08-AUDIO-READINESS-SIMULATED-RECEIPT.json"])
files.update(phase.glob("research/C08-*.md"))
files.update(phase / "audio/C08" / n for n in ["retrieval.json", "source-readme.txt"] if (phase / "audio/C08" / n).exists())
files.update(root / item["path"] for item in exports["files"].values())
files.update(root / "tools/keyboard-circuit" / n for n in ["VerifyC08.luau", "CloseC08.luau", "CheckSingleEnterC08.luau", "CaptureProfileC08.luau", "TestContactC08.luau", "NormalProbeC08.luau", "ShuttleProbeC08.luau", "WarningProbeC08.luau", "HeadContactProbeC08.luau", "check_source.luau", "StartupReadinessC08.client.luau", "StageReadinessC08.server.luau", "FirstStepsReadinessC08.luau", "FaultReadinessC08.luau", "TestAudioReadinessC08.simulated.luau"])

def entry(path):
    data = path.read_bytes()
    return {"path": path.relative_to(root).as_posix(), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}

source_entries = sorted((entry(path) for path in sources), key=lambda item: item["path"])
fingerprint = hashlib.sha256("".join(item["path"] + "\0" + item["sha256"] + "\n" for item in source_entries).encode()).hexdigest()
manifest = {"revision": "KC_P1_C08", "sourceCount": 14, "sourceFingerprint": fingerprint, "sources": source_entries, "native": exports["files"], "files": sorted((entry(path) for path in files), key=lambda item: item["path"]), "phase": 1, "specialists": [{"scope": "Sound", "model": "gpt-6.1-sol", "effort": "xhigh"}, {"scope": "Stepping", "model": "gpt-6.1-sol", "effort": "xhigh"}, {"scope": "Optimization", "model": "gpt-6.1-sol", "effort": "max"}], "freshFiveJudgeReleaseGateAtFreeze": "pending", "ownerCheckpoint": "accepted", "historicalScoresInherited": False, "mutableStatusDocuments": ["docs/artifacts/keyboard-circuit/COURSE_BRIEF.md", "docs/artifacts/keyboard-circuit/phase1/reviews/INDEX.md"], "reviewOutputs": "Original-five reports and C08-FINAL-GATE.json are written after this frozen input package and are audited separately.", "wholePlaceSaved": False, "published": False}
destination = phase / "C08-evidence-manifest.json"
destination.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
for item in manifest["files"]:
    assert entry(root / item["path"]) == item
links = re.findall(r"\]\(([^)]+)\)", (phase / "C08-REVIEW-BRIEF.md").read_text(encoding="utf-8"))
for target in links:
    if "://" not in target:
        assert (phase / target).exists(), target
receipt = {"revision": "KC_P1_C08", "verifiedFiles": len(files), "sourceCount": 14, "sourceFingerprint": fingerprint, "manifestSha256": hashlib.sha256(destination.read_bytes()).hexdigest(), "nativeFiles": 4, "reviewBriefLocalLinks": "passed", "freshFiveJudgeReleaseGateAtFreeze": "pending", "ownerCheckpoint": "accepted", "passed": True}
(phase / "C08-freeze-verification.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps(receipt))
