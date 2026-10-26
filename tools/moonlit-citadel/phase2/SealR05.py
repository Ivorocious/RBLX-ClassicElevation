import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKET = ROOT / "docs/artifacts/moonlit-citadel/phase2"
CANDIDATE = "MC_P2_C01_R05"
NATIVE = "e4b6fd6521fc5e3021c1ca322772c05f2fa8b4b87ec310cd09f79c1f43d4c6e4"
MANIFEST = PACKET / f"{CANDIDATE}_FINAL_MANIFEST.json"
GATE = PACKET / f"{CANDIDATE}_FINAL_GATE.json"
IDEATION_GATE = PACKET / f"{CANDIDATE}_IDEATION_GATE.json"
files = set()
checks = {}


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def artifact_path(value):
    path = Path(value.replace("\\", "/"))
    if path.is_absolute():
        return path
    return ROOT / path if (ROOT / path).is_file() else PACKET / path


def verify(path, expected):
    path = path.resolve()
    require(path.is_relative_to(ROOT), f"Input outside project: {path}")
    require(path.is_file(), f"Missing input: {path}")
    require(digest(path) == expected, f"Hash mismatch: {path.relative_to(ROOT)}")
    files.add(path)


def add_tree(path):
    for child in path.rglob("*"):
        if child.is_file() and child.suffix not in {".b64", ".pyc", ".log"}:
            files.add(child.resolve())


def check_links():
    count = 0
    for name in [f"{CANDIDATE}_FINAL_REPORT.md", f"{CANDIDATE}_FINAL_HANDOFF.md"]:
        page = PACKET / name
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", page.read_text(encoding="utf-8-sig")):
            if re.match(r"[a-z]+://|#", target):
                continue
            path = (page.parent / target.split("#", 1)[0].strip("<>")).resolve()
            require(path.is_file() or path in {MANIFEST, GATE, IDEATION_GATE}, f"Broken link in {name}: {target}")
            count += 1
    return count


critical = {
    f"{CANDIDATE}_native_final.rbxm": NATIVE,
    f"{CANDIDATE}_native_fresh.rbxm": NATIVE,
    f"{CANDIDATE}_recovery01_standalone.rbxl": "5ab7a1a495bbebace85f6842f08025b40cf5ce7b1cdb5aa141e768222a19039e",
    f"{CANDIDATE}_recovery01_library.rbxm": "8780de8ba426ac3113ef2539b422d7c302d044acff753cfa327c2395611b719b",
    "MC_P2_original_R05_postinstall_library_20261011.rbxm": "e6b33a25ae3475612aaf3a71b2c6e5836de631a8466ad02e5155db703f1d85e5",
    "MC_P2_original_R05_preinstall_library_20261011.rbxm": "9a0ae81ee73216043257294fd35c0c73bf055ab377272a49909ac79a2090bcf2",
    "MC_P2_original_R05_preinstall_P1_20261011.rbxm": "7019c52ff336186830c20905eb561dd613b395bdc0e9ea798de7ae437cac9837",
    "MC_P2_original_R05_postinstall_P1_20261011.rbxm": "7019c52ff336186830c20905eb561dd613b395bdc0e9ea798de7ae437cac9837",
    "MC_P2_original_R05_archived_FinalB_20261011.rbxm": "322ad87987028e029bd66105b78d00cd04d27a1d9db2c8548f27187d5927879b",
}
for name, expected in critical.items():
    verify(PACKET / name, expected)
checks["exactNativeRecoveryAndOriginalFiles"] = len(critical)

readback = read(PACKET / f"{CANDIDATE}_readback01_manifest.json")
require(len(readback["sources"]) == 232, "Expected 232 current source mappings")
for name, expected in readback["hashes"].items():
    verify(artifact_path(name), expected)
for row in readback["sources"]:
    verify(ROOT / row["sourcePath"], row["sha256"])
checks["readbackFrozenInputs"] = len(readback["hashes"])
checks["currentSourceMappings"] = len(readback["sources"])

guards = read(PACKET / f"{CANDIDATE}_production_guards.json")
require(len(guards["sources"]) == 12, "Expected 12 production guards")
for row in guards["sources"]:
    path = ROOT / row["file"]
    source = path.read_bytes().decode("utf-8-sig").replace("\r\n", "\n").encode("utf-8")
    require(hashlib.sha256(source).hexdigest() == row["sha256"], f"Production guard mismatch: {row['file']}")
    require(len(source) == row["sourceBytes"], f"Production source length mismatch: {row['file']}")
    files.add(path.resolve())
checks["normalizedProductionGuards"] = 12

archive_file = ROOT / "docs/artifacts/moonlit-citadel/history/r04-finalB-before-r05-repair/preservation-receipt.json"
archives = read(archive_file)
archive_map = {row["original"].replace("\\", "/"): row for row in archives}
for row in archives:
    verify(ROOT / row["archive"], row["sha256"])
old_manifest = PACKET / "MC_P2_C01_R04_FINAL_MANIFEST.json"
historical = read(old_manifest)
for row in historical["artifacts"]:
    key = row["path"].replace("\\", "/")
    path = ROOT / archive_map[key]["archive"] if key in archive_map else artifact_path(key)
    verify(path, row["sha256"])
files.update({archive_file, old_manifest})
checks["historicalR04ArtifactsWithExplicitArchiveResolution"] = len(historical["artifacts"])
checks["preR05MutableArchives"] = len(archives)

closing = read(PACKET / f"{CANDIDATE}_CLOSING_RECEIPT.json")
reviews = []
for role in ["route", "runtime", "visual"]:
    path = PACKET / closing["reviews"][role]
    review = read(path)
    require(review["candidate"] == CANDIDATE, f"Wrong Creator candidate: {role}")
    require(review.get("finalVerdict", review.get("verdict")) == "PASS", f"Creator review failed: {role}")
    require(review.get("nativeHashChecked", review.get("nativeSha256")) == NATIVE, f"Creator native differs: {role}")
    require(review["blockers"] == [], f"Creator blockers: {role}")
    for name, meta in review.get("artifactHashes", {}).items():
        verify(artifact_path(name), meta["sha256"] if isinstance(meta, dict) else meta)
    reviews.append({"role": role, "json": path.relative_to(ROOT).as_posix(), "sha256": digest(path), "reportSha256": digest(path.with_suffix(".md")), "verdict": "PASS", "blockers": []})
checks["sameThreeCreatorReviewers"] = "PASS"

ideation_reviews = []
for name in ["route/R05_REVIEW.json", "runtime/R05_REVIEW.json", "visual/r05/R05_ADDENDUM.json"]:
    path = PACKET / "ideation-review" / name
    review = read(path)
    require(review["candidate"] == CANDIDATE, f"Wrong Ideation candidate: {name}")
    require(review["verdict"].startswith("PASS"), f"Ideation review failed: {name}")
    for field in ["confirmedRouteBlockers", "confirmedImplementationBlockers"]:
        require(not review.get(field), f"Ideation blockers: {name}")
    for field in ["primaryInputHashes", "inputHashes", "supportingReviewOutputHashes"]:
        for input_name, meta in review.get(field, {}).items():
            verify(artifact_path(input_name), meta["sha256"] if isinstance(meta, dict) else meta)
    ideation_reviews.append({"path": path.relative_to(ROOT).as_posix(), "sha256": digest(path), "verdict": review["verdict"]})
checks["sameThreeIdeationReviewers"] = "PASS_TECHNICAL_SCOPE"

geometry = read(PACKET / f"repairs/{CANDIDATE}/geometry-check/receipt.json")
require(geometry["currentPierIntrusions"] == 0, "Remaining authored pier intrusion")
require(geometry["currentCoplanarHorizontalFloorFaces"] == 0, "Remaining tested coplanar floor face")
trial = read(PACKET / "evidence/r05-focused03-extracted02/Trial.json")
require(trial["complete"] and trial["final"]["finished"] and trial["final"]["official"], "Fresh route did not finish through shared services")
require(trial["final"]["falls"] == 0 and trial["final"]["checkpoint"] == 4, "Fresh route checkpoint/fall result differs")
red = read(PACKET / "evidence/r05-red-body-extracted01/MC_P2_C01_R05_RedBody02.json")
require(red["passed"], "Fresh red-body recovery failed")
closure = read(PACKET / "ideation-review/lead/R05_LIVE_CLOSURE.json")
require(closure["result"] == "PASS_READ_ONLY_CLOSURE" and closure["nativeSha256"] == NATIVE, "Live closure candidate differs")
require(closing["localhostReceiver"]["closed"], "Evidence receiver still open")
require(not closing["wholeOriginalPlaceSaved"] and not closing["published"] and not closing["phase3Commissioned"], "Phase boundary differs")
require(closing["ideation"]["technicalVerdict"] == "PASS", "Ideation acceptance missing")
checks.update({"boundedGeometry": "PASS", "freshSharedEEEAndActualRedRecovery": "PASS", "liveReadOnlyClosureAndReceiverCleanup": "PASS"})

for index_name in ["INDEX.json", "SUPPLEMENTAL_INDEX.json"]:
    index = read(PACKET / f"repairs/{CANDIDATE}/views/{index_name}")
    require(index["nativeHash"] == NATIVE, "View index candidate differs")
    for row in index.get("before", []) + index.get("after", []) + index.get("views", []):
        path = Path(row["path"])
        require(path.is_file(), f"Missing native view: {path}")
        if "sha256" in row:
            verify(path, row["sha256"])
        files.add(path.resolve())
checks["finalReportAndHandoffLocalLinks"] = check_links()

for pattern in [f"{CANDIDATE}*", "MC_P2_original_R05*"]:
    files.update(path.resolve() for path in PACKET.glob(pattern) if path.is_file())
for path in [PACKET / f"repairs/{CANDIDATE}", PACKET / "reviews/R05_runtime_recovery", PACKET / "ideation-review/visual/r05"]:
    add_tree(path)
for pattern in [f"*{CANDIDATE}*", "*R05*"]:
    files.update(path.resolve() for path in (PACKET / "reviews").glob(pattern) if path.is_file())
for path in (PACKET / "evidence").glob(f"{CANDIDATE}*"):
    if path.is_file() and path.suffix != ".b64":
        files.add(path.resolve())
for folder in ["r05-focused03-extracted02", "r05-red-body-extracted01"]:
    add_tree(PACKET / "evidence" / folder)
for folder in ["route", "runtime", "lead"]:
    files.update(path.resolve() for path in (PACKET / "ideation-review" / folder).glob("*R05*") if path.is_file())
    files.update(path.resolve() for path in (PACKET / "ideation-review" / folder).glob("*r05*") if path.is_file())
files.update(path.resolve() for path in Path(__file__).parent.glob("*R05*") if path.is_file())
for name in ["docs/BUGS.md", "docs/DECISIONS.md", "docs/PLAYTEST_NOTES.md", "docs/TASKS.md", "docs/artifacts/moonlit-citadel/COURSE_BRIEF.md", "docs/artifacts/moonlit-citadel/PHASE2_START.md", "default.project.json"]:
    files.add((ROOT / name).resolve())
files.difference_update({MANIFEST, GATE, IDEATION_GATE})
files = {path for path in files if path.suffix not in {".b64", ".pyc"}}
artifacts = [{"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size, "sha256": digest(path)} for path in sorted(files)]
recorded = datetime.now(timezone.utc).isoformat()
manifest = {
    "candidate": CANDIDATE, "recordedUTC": recorded, "nativeSha256": NATIVE,
    "scope": "Completed bounded Phase2 R05 repair, exact installation/recovery, same three Creator and three Ideation independent technical reviews; file-only final seal after live control release",
    "checks": checks, "sourceMappings": readback["sources"], "productionSourceGuards": guards,
    "artifacts": artifacts, "artifactCount": len(artifacts), "reviews": reviews,
    "ideationReviews": ideation_reviews, "precisionQualifications": closing["geometry"],
    "resourceDelta": closing["resourceDelta"], "capacityClaim": closing["capacityClaim"],
    "control": closing["control"], "ownerPhase1": "ACCEPTED", "ownerPhase2": "PENDING",
    "separateOpenChecks": closing["separateOpenChecks"], "wholeOriginalPlaceSaved": False, "published": False,
    "excludedCircularRecords": [MANIFEST.name, GATE.name, IDEATION_GATE.name],
    "ideationExactInputGate": "Ideation seals its separate gate against this completed manifest and Creator gate",
}
MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
for row in artifacts:
    require(digest(ROOT / row["path"]) == row["sha256"], f"Input changed during seal: {row['path']}")
gate = {
    "candidate": CANDIDATE, "recordedUTC": recorded, "result": "PASS_SCOPED_PHASE2_R05",
    "nativeSha256": NATIVE, "manifest": MANIFEST.name, "manifestSha256": digest(MANIFEST),
    "allFrozenArtifactsRechecked": True, "artifactCount": len(artifacts), "checks": checks,
    "sameThreeCreatorReviewers": reviews, "sameThreeIdeationTechnicalReviewers": ideation_reviews,
    "blockers": [], "numericGate": None, "ownerPhase1": "ACCEPTED", "ownerPhase2": "PENDING",
    "precisionQualifications": closing["geometry"], "separateOpenChecks": closing["separateOpenChecks"],
    "controlReleased": True, "additionalLiveCalls": False, "wholeOriginalPlaceSaved": False,
    "published": False, "phase3Commissioned": False,
}
GATE.write_text(json.dumps(gate, indent=2) + "\n", encoding="utf-8")
require(MANIFEST.is_file() and GATE.is_file(), "Final records missing")
check_links()
print(json.dumps({"result": gate["result"], "artifacts": len(artifacts), "checks": checks, "manifestSha256": digest(MANIFEST), "gateSha256": digest(GATE), "ownerPhase2": "PENDING"}, indent=2))
