from argparse import ArgumentParser
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import re


ROOT = Path(__file__).resolve().parents[4]
WORK = Path(__file__).resolve().parent
FOLDER = ROOT / "docs/artifacts/keyboard-circuit/phase3"
SKY = ROOT / "assets/sky/keyboard-archive"
CANDIDATE = "KeyboardCircuit_P3_M04_01"
REVISION = "KC_P3_M04_01"
MAP_REVISION = "KC_MAP_M04_01"
LAYOUT = "KC_LAYOUT_P2_I09_03"
ORIGIN = [2222, 330, -1158]
COUNTS = {"parts": 8808, "pressTargets": 2989, "colliders": 282, "queryParts": 3289, "touchParts": 0}
GLOBAL_SOURCES = (
    "src/ServerScriptService/Services/StudioDevService.luau",
    "src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau",
    "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau",
)
REQUIRED_RECEIPTS = (
    "native-source-agreement", "filesystem-agreement", "native-preservation",
    "native-motion-clearance", "native-visibility", "native-resource-inventory",
    "native-play-checks", "effects-lifecycle", "effects-other-map-handoff", "effects-death", "native-sky-load",
    "normal-two-lap", "expert-two-lap", "normal-race-effects", "expert-race-effects", "native-recovery",
)
VIEW_NAMES = (
    "start-station", "normal-expert-choice", "checkpoint-shuttle-exit",
    "falling-key-warning", "repaired-brackets", "archive-skybox-overview",
)
SKY_PROPERTIES = ("SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp")
HISTORY_INPUTS = (
    "P3-M02-FREEZE-01.json", "P3-M02-FINAL-GATE-01.json",
    "P3-M02-frozen-before-M03-01.zip", "KC_P3_M02_01_Native.rbxm",
    "KC_P3_M02_OwnerBeforeM03_01.rbxm", "KC_P3_M03_EnclosureRecovery_01.rbxm",
    "P3-M03-enclosure-recovery-01.json", "P3-M03-M02-frozen-recovery-01.json",
    "P3-M03-M02-owner-before-01.json",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path):
    return path.resolve().relative_to(ROOT).as_posix()


def repo_path(value):
    require(isinstance(value, str) and "\\" not in value, f"Invalid repository path: {value}")
    part = Path(value)
    require(not part.is_absolute() and ".." not in part.parts, f"Unsafe repository path: {value}")
    path = (ROOT / part).resolve()
    require(path.is_relative_to(ROOT), f"Path leaves the repository: {value}")
    return path


def read(path):
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    require(isinstance(data, dict), f"Expected a JSON object: {relative(path)}")
    return data


def record(path):
    require(path.is_file(), f"Missing input: {relative(path)}")
    return {"path": relative(path), "bytes": path.stat().st_size, "sha256": sha(path)}


def identity(data, label, candidate_required=True):
    value = data.get("candidate")
    aliases = {CANDIDATE, "Workspace." + CANDIDATE, REVISION}
    require(value in aliases or (not candidate_required and value is None), f"{label}: wrong or absent M04 candidate")
    for key in ("revision", "prototypeRevision", "candidateRevision"):
        if key in data:
            require(data[key] == REVISION, f"{label}: wrong {key}")
    for key in ("map", "mapRevision"):
        if key in data:
            require(data[key] == MAP_REVISION, f"{label}: wrong {key}")
    for key in ("layout", "layoutRevision"):
        if key in data:
            require(data[key] == LAYOUT, f"{label}: wrong {key}")


def passed_receipt(path):
    data = read(path)
    identity(data, path.name)
    require(data.get("passed") is True, f"{path.name}: native receipt did not pass")
    for key in ("failures", "sourceFailures", "byteOrHashMismatches", "hashOrLengthMismatches"):
        require(not data.get(key), f"{path.name}: unresolved {key}")
    require(data.get("running") is not True, f"{path.name}: fixture is still running")
    return data


def latest_receipt(stem):
    pattern = re.compile(r"P3-M04-" + re.escape(stem) + r"-(\d+)\.json$")
    matches = [(int(match[1]), path) for path in FOLDER.glob(f"P3-M04-{stem}-*.json")
               if (match := pattern.fullmatch(path.name))]
    require(matches, f"Missing receipt: P3-M04-{stem}-NN.json")
    return max(matches, key=lambda row: row[0])[1]


def check_counts(data, label):
    for name, expected in COUNTS.items():
        require(data.get(name) == expected, f"{label}: expected {name}={expected}, got {data.get(name)}")


def check_origin(value, label):
    if isinstance(value, str):
        value = [float(part.strip()) for part in value.split(",")]
    require(value == ORIGIN, f"{label}: owner origin changed")


def check_source_agreement(data, label):
    require(data.get("datamodel") == "Edit", f"{label}: final source agreement must be in Edit")
    require(data.get("snapshotCount") == 28 and data.get("globalCount") == 4, f"{label}: expected 28 snapshot and four global sources")
    require(data.get("active") == [CANDIDATE], f"{label}: expected one active M04 course")
    check_origin(data.get("origin"), label)
    check_counts(data.get("resources", {}), label)
    archived = data.get("archived", [])
    require(len(archived) == 16 and {"KeyboardCircuit_P3_M02_01", "KeyboardCircuit_P3_M03_01"}.issubset(archived), f"{label}: M02/M03 recovery history missing")
    require(data.get("archivedScriptsDisabled") is True, f"{label}: archived scripts are not inert")
    expected = {relative(path) for path in (WORK / "sources").glob("*.luau")} | set(GLOBAL_SOURCES)
    require(len(expected) == 32, f"{label}: expected exactly 28 durable M04 source files")
    rows = data.get("rows", [])
    require(len(rows) == 32 and {row.get("repository") for row in rows} == expected, f"{label}: exact source rows incomplete or duplicated")
    for row in rows:
        path = repo_path(row["repository"])
        require(path.stat().st_size == row.get("bytes") and sha(path) == row.get("sha256"), f"{label}: source byte mismatch: {row['repository']}")
    require(not (WORK / "sources/ArchiveBackdrop.luau").exists(), f"{label}: physical archive source remains active")
    return expected


def check_filesystem_agreement(data, expected):
    rows = data.get("rows", [])
    require(data.get("exactRows") == 32 and len(rows) == 32 and {row.get("path") for row in rows} == expected, "Filesystem agreement must contain 32 exact rows")
    for row in rows:
        actual = record(repo_path(row["path"]))
        require(row.get("matches") is True and row.get("bytes") == row.get("nativeBytes") == actual["bytes"] and row.get("sha256") == row.get("nativeSha256") == actual["sha256"], f"Filesystem/native source mismatch: {row['path']}")


def check_run(data, route):
    require(data.get("routeChoice") == route, f"{route}: wrong traversal route")
    require(data.get("active") is False, f"{route}: traversal is still active")
    require(data.get("requestedLaps") == 2, f"{route}: expected two fresh laps")
    require(data.get("setupCalls") == 1 and data.get("setup", {}).get("attempts") == 1, f"{route}: unexpected setup intervention")
    require(data.get("fixtureHoldSeconds") == 0 and len(data.get("gates", [])) == 10 and len(data.get("midpointReceipts", [])) == 8, f"{route}: natural route crossings incomplete")
    require(data.get("finalState", {}).get("recoveries") == 0 and data.get("finalState", {}).get("finished") is True, f"{route}: final traversal did not finish cleanly")
    state = data.get("serverState", {})
    require(state.get("requiredLaps") == state.get("completedLaps") == 2 and state.get("finished") is True, f"{route}: server did not confirm two completed laps")
    records = data.get("records", [])
    require(records and all(row.get("arrived") is True and row.get("finishSupport") == row.get("expectedSupport") for row in records), f"{route}: native movement/support check failed")
    movement = data.get("movement", {})
    require(movement.get("useJumpPower") is False and all(abs(movement.get(name, 0) - value) < .001 for name, value in (("walkSpeed", 16), ("jumpHeight", 7.2), ("gravity", 196.2))), f"{route}: movement tuning changed")


def check_sky_proof(proof, ids, label):
    require(proof.get("passed") is True and proof.get("skyReady") is True and proof.get("skyApplied") is True, f"{label}: real Sky was not applied")
    loads = proof.get("sky", proof)
    require(loads.get("loaded") == 6 and loads.get("failed") == 0 and proof.get("orientation") == [0, 0, 0], f"{label}: incomplete loads or wrong Sky orientation")
    faces = proof.get("faces", [])
    require(len(faces) == 6 and {row.get("property") for row in faces} == set(SKY_PROPERTIES), f"{label}: six exact Sky properties required")
    for face in faces:
        require(face.get("actual") == face.get("configured") == ids[face["property"]] and face.get("fetchStatus") == "Success", f"{label}: actual Sky face or load mismatch")


def check_sky_assets():
    upload = read(SKY / "upload-status.json")
    manifest = read(SKY / "texture-manifest.json")
    require(upload.get("status") == "uploaded" and upload.get("placeId") == 85558151074819, "Real sky uploads for the intended place are required")
    faces = upload.get("faces", {})
    require(set(faces) == set(SKY_PROPERTIES), "Upload record must specify all six Sky faces")
    ids = {}
    for name in SKY_PROPERTIES:
        face = faces[name]
        require(isinstance(face.get("assetId"), str) and re.fullmatch(r"rbxassetid://[1-9]\d*", face["assetId"]), f"{name}: real asset ID missing")
        require(Path(face["file"]).name == face["file"], f"{name}: invalid face filename")
        texture = manifest.get("roblox_faces", {}).get(name, {})
        require(texture.get("file") == face["file"] and texture.get("sha256") == sha(SKY / face["file"]), f"{name}: final texture manifest mismatch")
        ids[name] = face["assetId"]
    require(len(set(ids.values())) == 6, "Six distinct uploaded sky faces are required")
    source = (WORK / "sources/ArchiveSkyConfig.luau").read_text(encoding="utf-8-sig")
    require(re.search(r"Ready\s*=\s*true", source), "ArchiveSkyConfig is not ready")
    for name, asset_id in ids.items():
        require(re.search(re.escape(name) + r'\s*=\s*["\']' + re.escape(asset_id) + r'["\']', source), f"{name}: durable configuration differs from uploaded face")
    return ids


def check_recovery(data):
    path = FOLDER / "KC_P3_M04_01_Native.rbxm"
    require(path.is_file() and data.get("nativeSha256") == sha(path) and data.get("courseBytes") == path.stat().st_size, "Native export differs from recovery receipt")
    require(data.get("active") == [CANDIDATE], "Native recovery must preserve one active M04")
    require(len(data.get("preserved", [])) == 16 and {"KeyboardCircuit_P3_M02_01", "KeyboardCircuit_P3_M03_01"}.issubset(data["preserved"]), "Native recovery lost M02/M03 history")
    for key in ("roundTrip", "freshSourceRebuild"):
        proof = data.get(key, {})
        require(proof.get("passed") is True and proof.get("leftCount") == proof.get("rightCount"), f"Native {key} failed")
        for name in ("differences", "sourceFailures", "externalReferences", "countFailures"):
            require(not proof.get(name), f"Native {key}: unresolved {name}")
        check_counts(proof.get("counts", {}), key)
        require(proof["counts"].get("sourceSnapshots") == 28, f"Native {key}: wrong snapshot count")


def check_other_map_handoff(data):
    identity(data, "other-map handoff")
    require(data.get("passed") is True and data.get("courseId") == "city_run", "Passing existing City Run handoff is required")
    for name in ("realServerTeleport", "directArchiveHandoff", "expectedLightingAndSkyApplied", "originalLobbyRestored"):
        require(data.get(name) is True, f"Other-map handoff unverified: {name}")

    def reject_failed_evidence(value):
        if isinstance(value, dict):
            require(value.get("passed", True) is True and not value.get("failed") and not value.get("failures"), "Other-map handoff contains failed evidence")
            status = value.get("status", "")
            if isinstance(status, str):
                status = status.lower().replace("_", "-").replace(" ", "-")
                require(not status.startswith(("fail", "not-run", "notrun")), "Other-map handoff contains failed or not-run evidence")
            for child in value.values():
                reject_failed_evidence(child)
        elif isinstance(value, list):
            for child in value:
                reject_failed_evidence(child)

    reject_failed_evidence(data)


def check_race_effects(data, route):
    require(data.get("routeChoice") == route and data.get("running") is False, f"{route}: effect observer is not complete")
    require(data.get("lapSweeps") == 2 and data.get("maxSweepContactLevel", 0) > .6, f"{route}: actual lap sweeps missing")
    waves = data.get("waves", {})
    require(set(waves) == {"Creamy", "Thocky", "Clacky", "Clicky"}, f"{route}: all four reactive families required")
    for family, wave in waves.items():
        require(wave.get("maxOwnEntries", 0) > 0 and wave.get("maxHeight", 0) - wave.get("minHeight", 0) > .05, f"{route}: {family} lacks real key-reactive movement")
    diagnostics = data.get("finalDiagnostics", {})
    for name, expected in (("localPartCount", 101), ("underlightCount", 64), ("waveBarCount", 28), ("pendingAnchorCount", 0), ("updateConnections", 1), ("entryConnections", 1), ("restoreFailures", 0)):
        require(diagnostics.get(name) == expected, f"{route}: wrong final effect {name}")
    require(diagnostics.get("streamingComplete") is True, f"{route}: incomplete streamed effects")


def check_play_components(play):
    expected = {
        "hud", "heldPress", "brackets", "warningCycle", "liftRide", "fallRecovery",
        "cleanSessionSources", "lifecycle", "deathRespawn", "sky", "otherMapHandoff",
        "normal", "expert", "normalEffects", "expertEffects",
    }
    require(expected.issubset(play), "Native Play aggregate is missing required components")
    for name in expected:
        proof = play[name]
        require(isinstance(proof, dict) and proof.get("passed") is True, f"Native Play component failed: {name}")
        identity(proof, "native play " + name)
        path = repo_path(proof.get("path"))
        require(path.parent == FOLDER and proof.get("bytes") == path.stat().st_size and proof.get("sha256") == sha(path), f"Native Play component reference mismatch: {name}")
        raw = passed_receipt(path)
        if name.endswith("Effects"):
            check_race_effects(raw, name.removesuffix("Effects"))


def validate_candidate(receipt_paths):
    require(set(receipt_paths) == set(REQUIRED_RECEIPTS), "Required M04 receipt mapping is incomplete")
    receipts = {stem: passed_receipt(path) for stem, path in receipt_paths.items()}
    expected = check_source_agreement(receipts["native-source-agreement"], "native-source-agreement")
    check_filesystem_agreement(receipts["filesystem-agreement"], expected)
    play = receipts["native-play-checks"]
    check_play_components(play)
    for name, proof in play.items():
        if isinstance(proof, dict) and "passed" in proof:
            identity(proof, "native play " + name)
            require(proof["passed"] is True, f"Native play component failed: {name}")
    ids = check_sky_assets()
    lifecycle = receipts["effects-lifecycle"]
    steps = {row.get("name"): row for row in lifecycle.get("steps", [])}
    required_steps = {
        "real F6 entry and resolved readiness", "real F6 restart removes old client state",
        "Lobby cleanup and exact baseline", "ownership-token exit ordering",
        "local preview-disable cleanup and reactivation", "client-local candidate removal and restoration",
        "actual audio cancellation stops the cosmetic profile", "server-supported respawn cleanup and fresh client",
    }
    require(len(lifecycle.get("steps", [])) == 8 and set(steps) == required_steps and all(row.get("passed") is True for row in steps.values()), "All eight ordinary lifecycle cases must pass")
    check_other_map_handoff(receipts["effects-other-map-handoff"])
    proofs = lifecycle.get("skyProofs", [])
    require(proofs, "Lifecycle must prove the real six-face Sky on activation")
    for row in proofs:
        check_sky_proof(row.get("proof", {}), ids, row.get("activation", "lifecycle sky"))
    sky = receipts["native-sky-load"]
    check_sky_proof(sky.get("skyProof", sky), ids, "native-sky-load")
    death = receipts["effects-death"]
    for name in ("diedObserved", "oldFoldersRemoved", "exactBaselineWhileDead", "autoRespawnObserved", "characterRemovalObserved", "exactBaselineAfterLobby"):
        require(death.get(name) is True, f"Death/respawn cleanup unverified: {name}")
    for route in ("normal", "expert"):
        check_run(receipts[f"{route}-two-lap"], route)
        check_race_effects(receipts[f"{route}-race-effects"], route)
    check_recovery(receipts["native-recovery"])
    check_counts(receipts["native-resource-inventory"].get("after", {}), "native resources")
    require(receipts["native-resource-inventory"].get("gameplayInventoryUnchanged") is True, "Gameplay inventory preservation failed")
    scene_path = latest_receipt("native-scene")
    scene = read(scene_path)
    identity(scene, scene_path.name)
    check_origin(scene.get("origin"), "native scene")
    parts = scene.get("parts", [])
    require(len(parts) == COUNTS["parts"] and not any("ArchiveBackdrop" in row.get("path", "") for row in parts), "Native scene contains an enclosure or wrong part inventory")
    anchors = [row for row in parts if row.get("path", "").startswith("MapEnvironment.ArchiveEffectParts.")]
    require(len(anchors) == 97 and all(row.get("transparency") == 1 and row.get("castShadow") is False for row in anchors), "Expected 97 inert decorative anchors")
    return receipts, ids, scene_path


def check_views(scene_path):
    views = FOLDER / "views-m04"
    manifest = read(views / "render-manifest.json")
    identity(manifest, "render-manifest")
    require(set(manifest.get("renderedViews", [])) == set(VIEW_NAMES), "All six M04 views must finish before freezing")
    require(manifest.get("sourceScene") == relative(scene_path) and manifest.get("sourceSceneSha256") == sha(scene_path), "Views use a stale native scene")
    require(manifest.get("rendererSha256") == sha(WORK / "RenderPreview.py"), "Renderer changed after the views were saved")
    for name in VIEW_NAMES:
        require(manifest.get("outputHashes", {}).get(name) == sha(views / f"{name}.png"), f"View hash mismatch: {name}")
    sky = manifest.get("skyEnvironment", {})
    require(sky.get("physicalEnclosureParts") == 0, "Offline views contain an archive enclosure")
    for field, filename in (("panorama", "panorama-source.png"), ("textureManifest", "texture-manifest.json"), ("uploadStatus", "upload-status.json")):
        require(sky.get(field) == relative(SKY / filename) and sky.get(field + "Sha256") == sha(SKY / filename), f"Views use stale sky {field}")


def verify_inputs(entries):
    require(entries and len({row.get("path") for row in entries}) == len(entries), "Frozen input list is empty or duplicated")
    for row in entries:
        path = repo_path(row.get("path"))
        require(path.is_file() and row.get("bytes") == path.stat().st_size and row.get("sha256") == sha(path), f"Frozen byte/hash mismatch: {row.get('path')}")


def write_new(path, data):
    with path.open("x", encoding="utf-8", newline="\n") as output:
        output.write(json.dumps(data, indent=2) + "\n")


def main():
    parser = ArgumentParser(description="Freeze complete passing M04 review inputs without replacing prior freezes.")
    parser.add_argument("--freeze", default="P3-M04-FREEZE-01.json")
    args = parser.parse_args()
    match = re.fullmatch(r"P3-M04-FREEZE-(\d{2,})\.json", args.freeze)
    require(match, "Use a new P3-M04-FREEZE-NN.json filename")
    number = match[1]
    freeze_path = FOLDER / args.freeze
    agreement_path = FOLDER / f"P3-M04-freeze-agreement-{number}.json"
    brief_path = FOLDER / "history-m04" / number / "COURSE_BRIEF.md"
    require(not any(path.exists() for path in (freeze_path, agreement_path, brief_path)), "Existing closure files are immutable; choose a fresh freeze number")
    receipt_paths = {stem: latest_receipt(stem) for stem in REQUIRED_RECEIPTS}
    receipts, ids, scene_path = validate_candidate(receipt_paths)
    check_views(scene_path)
    files = {path for path in WORK.rglob("*") if path.is_file() and path.suffix in {".luau", ".py", ".cjs", ".json", ".md", ".rbxm"} and "__pycache__" not in path.parts}
    files.update(repo_path(name) for name in GLOBAL_SOURCES)
    files.update(path for path in SKY.iterdir() if path.is_file())
    files.update(path for path in (ROOT / "assets/keyboard_circuit/K02").iterdir() if path.is_file())
    files.update((FOLDER / "views-m04").glob("*"))
    for path in FOLDER.glob("P3-M04-*"):
        if path.is_file() and not re.search(r"(?:FREEZE|freeze-agreement|FINAL-GATE|FINAL-REPORT|-R[123]-review|post-review)", path.name):
            files.add(path)
    files.update(FOLDER / name for name in HISTORY_INPUTS)
    files.update((FOLDER / "KC_P3_M04_01_Native.rbxm", FOLDER / "KC_P3_M04_01_Native-before-streaming-01.rbxm", FOLDER / "KC_P3_M04_01_Offline.blend", SKY / "native-load-diagnosis-01.json", WORK / "OtherMapHandoff.client.luau"))
    files.update(ROOT / name for name in ("docs/artifacts/keyboard-circuit/FINAL_TUNING_START.md", "docs/artifacts/keyboard-circuit/PHASE3_START.md", "docs/COURSE_WORKFLOW_V3.md", "docs/artifacts/keyboard-circuit/keyboard-circuit.drawio"))
    require(all(path.is_file() for path in files), "Missing freeze input(s): " + ", ".join(relative(path) for path in sorted(files) if not path.is_file()))
    entries = [record(path) for path in sorted(files)]
    source_brief = ROOT / "docs/artifacts/keyboard-circuit/COURSE_BRIEF.md"
    brief_bytes = source_brief.read_bytes()
    brief_hash = hashlib.sha256(brief_bytes).hexdigest()
    entries.append({"path": relative(brief_path), "bytes": len(brief_bytes), "sha256": brief_hash})
    created = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    result = {
        "candidate": CANDIDATE, "revision": REVISION, "mapRevision": MAP_REVISION,
        "layout": LAYOUT, "baseCourseRevision": "KC_P2_I09_03", "origin": ORIGIN,
        "placeId": 85558151074819, "universeId": 10191126818, "requiredLaps": 2,
        "createdUtc": created, "gate": {"reviewerCount": 3, "minimumIndividualScore": 8.5, "maximumBlockers": 0},
        "snapshotSources": 28, "globalSources": 4, "resources": COUNTS,
        "nativeSha256": receipts["native-recovery"]["nativeSha256"], "skyFaceIds": ids,
        "receipts": {stem: relative(path) for stem, path in receipt_paths.items()},
        "sourceScene": relative(scene_path), "count": len(entries), "inputs": sorted(entries, key=lambda row: row["path"]),
        "briefCopy": {"source": relative(source_brief), "copy": relative(brief_path), "sha256": brief_hash},
        "boundary": "Exact M04 sources, fixtures, final native checks, descriptive and failed-attempt evidence, six views, recovery assets, sky inputs and recoverable M02/M03 history. The mutable course brief is copied at freeze time. Fresh independent whole-candidate judgments and post-review Edit checks are separate outputs. No owner acceptance, human pacing/audio, device/FPS, multiplayer or publication claim.",
    }
    verify_inputs(entries[:-1])
    require(source_brief.read_bytes() == brief_bytes, "Mutable brief changed during freezing; retry with stable inputs")
    brief_path.parent.mkdir(parents=True, exist_ok=True)
    with brief_path.open("xb") as output:
        output.write(brief_bytes)
    verify_inputs(result["inputs"])
    write_new(freeze_path, result)
    verify_inputs(result["inputs"])
    agreement = {"passed": True, "candidate": CANDIDATE, "revision": REVISION, "sourceFreeze": relative(freeze_path), "sourceFreezeSha256": sha(freeze_path), "count": len(entries), "byteOrHashMismatches": []}
    write_new(agreement_path, agreement)
    print(json.dumps(agreement))


if __name__ == "__main__":
    main()
