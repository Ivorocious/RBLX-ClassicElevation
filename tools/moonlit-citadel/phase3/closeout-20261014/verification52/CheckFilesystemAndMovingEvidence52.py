import hashlib
import json
import math
from datetime import datetime, timezone
from pathlib import Path
import subprocess

from PIL import Image

ROOT = Path.cwd()
ART = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014"
PACKET_SHA = "80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding="utf8"))


def relative(path):
    return str(path.relative_to(ROOT)).replace("\\", "/")


def save(name, data):
    (ART / name).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf8")


def filesystem_report():
    baseline_file = ART / "before/current-source-all.json"
    packet_file = ART / "before/closeout_source52_packet.json"
    baseline, packet = load(baseline_file), load(packet_file)
    assert digest(packet_file.read_bytes()) == PACKET_SHA
    assert len(baseline["files"]) == 296 and len(packet["records"]) == 30
    allowed_names = {"WorldPlan", "WorldAssembly", "Source49WorldPlan", "SceneryRevisions", "WindowFinishingPlan", "CliffFinishingPlan"}
    prefix = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
    allowed = {prefix + name + ".luau" for name in allowed_names}
    inventory = subprocess.run(["rg", "--files", "--hidden", "--no-ignore", "src"], check=True,
                               capture_output=True, text=True).stdout.splitlines()
    current, failures = {}, []
    for path in inventory:
        path = path.replace("\\", "/")
        raw = (ROOT / path).read_bytes()
        current[path] = {"sha256": digest(raw), "bytes": len(raw)}
    changed, added, missing, unchanged = [], [], [], []
    for path, before in baseline["files"].items():
        actual = current.get(path)
        if actual is None:
            missing.append(path)
            failures.append({"kind": "MissingProductionFile", "path": path})
        elif actual != before:
            changed.append(path)
            if path not in allowed:
                failures.append({"kind": "UnapprovedProductionChange", "path": path, "expected": before, "actual": actual})
        else:
            unchanged.append(path)
    for path in current.keys() - baseline["files"].keys():
        added.append(path)
        if path not in allowed:
            failures.append({"kind": "UnapprovedNewProductionFile", "path": path})
    records = {}
    for path, actual in sorted(current.items()):
        records[path] = {"actual": actual, "before": baseline["files"].get(path),
                         "status": "added_allowed" if path in added and path in allowed else "changed_allowed" if path in changed and path in allowed
                         else "unchanged" if path in unchanged else "unapproved", "allowedArtFile": path in allowed}
    packet_matches = []
    for row in packet["records"]:
        path = "src/ReplicatedStorage/Config/" + row["name"] + ".luau" if row["name"] == "MoonlitCitadelAmbienceConfig" else prefix + row["name"] + ".luau"
        raw = (ROOT / path).read_bytes()
        normalized = raw.replace(b"\r\n", b"\n")
        match = digest(normalized) == row["sha256"]
        packet_matches.append({"path": path, "actualRawSHA256": digest(raw), "actualLFSHA256": digest(normalized),
                               "expectedPacketLFSHA256": row["sha256"], "pass": match})
        if not match:
            failures.append({"kind": "Source52PacketMismatch", "path": path})
    expected_existing = {prefix + name + ".luau" for name in ("WorldPlan", "WorldAssembly")}
    expected_added = allowed - expected_existing
    if set(changed) != expected_existing:
        failures.append({"kind": "ChangedExistingSet", "expected": sorted(expected_existing), "actual": sorted(changed)})
    if set(added) != expected_added:
        failures.append({"kind": "AddedFileSet", "expected": sorted(expected_added), "actual": sorted(added)})
    if len(current) != 300:
        failures.append({"kind": "ProductionFileCount", "expected": 300, "actual": len(current)})
    report = {"pass": not failures, "checkedAtUtc": datetime.now(timezone.utc).isoformat(), "source": 52, "build": 46, "candidate": packet["candidate"], "packetSHA256": PACKET_SHA,
              "baseline": relative(baseline_file), "baselineSHA256": digest(baseline_file.read_bytes()),
              "scope": "All raw-byte files under src, using the fresh post-Race-Flow baseline. No production files modified by this check.",
              "counts": {"before": len(baseline["files"]), "current": len(current), "unchanged": len(unchanged),
                         "changedExisting": len(changed), "added": len(added), "missing": len(missing), "packetRecords": len(packet_matches)},
              "allowedArtFiles": sorted(allowed), "changedExisting": sorted(changed), "added": sorted(added), "missing": sorted(missing),
              "packetSourceMatches": packet_matches, "actualFiles": records, "failures": failures,
              "inputHashes": {relative(packet_file): PACKET_SHA,
                              "tools/moonlit-citadel/phase3/closeout-20261014/InstallSource52.luau":
                                  digest((ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/InstallSource52.luau").read_bytes())}}
    save("filesystem-preservation52.json", report)
    return report


LUMA = [16,11,10,16,24,40,51,61,12,12,14,19,26,58,60,55,14,13,16,24,40,57,69,56,14,17,22,29,51,87,80,62,
        18,22,37,56,68,109,103,77,24,35,55,64,81,104,113,92,49,64,78,87,103,121,120,101,72,92,95,98,112,100,103,99]
CHROMA = [17,18,24,47,99,99,99,99,18,21,26,66,99,99,99,99,24,26,56,99,99,99,99,99,47,66,99,99,99,99,99,99] + [99] * 32
Q95 = {0: [max(1, min(255, (value * 10 + 50) // 100)) for value in LUMA],
       1: [max(1, min(255, (value * 10 + 50) // 100)) for value in CHROMA]}


def moving_report():
    failures, sequences, images = [], [], []
    for label in ("keepwindows52",):
        trace_file = ART / ("before/closeout_moving_" + label + ".json")
        trace = load(trace_file)
        receipt_file = trace_file.with_suffix(".json.receipt.json")
        if receipt_file.exists():
            receipt = load(receipt_file)
            if receipt.get("sha256") != digest(trace_file.read_bytes()):
                failures.append({"kind": "TraceReceiptHash", "sequence": label})
        frames = trace["frames"]
        prefix_only = trace.get("poseLogPrefixOnly", False)
        partial_file = trace_file.with_suffix(".partial.txt")
        transport = {"poseLogPrefixOnly": prefix_only, "fullPoseLogAvailable": not prefix_only}
        if prefix_only:
            assert partial_file.exists(), "Retain the original truncated tool output"
            transport.update({"originalPartialOutputPath": relative(partial_file),
                              "originalPartialOutputSHA256": digest(partial_file.read_bytes()),
                              "originalPartialOutputBytes": partial_file.stat().st_size,
                              "reportedToolCharacterLimit": 100000,
                              "note": "The direct Studio tool truncated its output. Run metadata survives; only complete prefix poses are preserved. No final poses were reconstructed."})
        elif partial_file.exists():
            failures.append({"kind": "MissingPrefixScopeFlag", "sequence": label})
        positions = [[min(frame["cf"][axis] for frame in frames), max(frame["cf"][axis] for frame in frames)] for axis in range(3)]
        excursion = math.sqrt(sum((high - low) ** 2 for low, high in positions))
        sequence_images = []
        for ordinal in range(1, 13):
            path = ART / ("views/moving-" + label + "-" + str(ordinal).zfill(2) + ".jpg")
            raw = path.read_bytes()
            with Image.open(path) as image:
                width, height, image_format, mode = image.width, image.height, image.format, image.mode
                q95_matches = image.quantization == Q95
                image.verify()
            row = {"path": relative(path), "sequence": label, "sampleOrdinal": ordinal, "bytes": len(raw), "sha256": digest(raw),
                   "width": width, "height": height, "format": image_format, "mode": mode,
                   "reportedCaptureJPEGQuality": 95, "standardJPEG95QuantizationTablesMatch": q95_matches,
                   "originalCaptureBytes": True, "captureTimestampInImageUnavailable": True}
            if image_format != "JPEG" or not q95_matches or (width, height) != (2040, 1109):
                failures.append({"kind": "ImageMetadata", "path": row["path"], "format": image_format, "dimensions": [width, height], "q95Matches": q95_matches})
            images.append(row)
            sequence_images.append(row["path"])
        if trace["source"] != 52 or trace["packet"] != PACKET_SHA or trace["hover"] is not False or trace["shadows"] is not True or abs(trace["clock"] - 19.2) > 0.001:
            failures.append({"kind": "TraceCandidateOrProfile", "sequence": label})
        if not 0.145 <= excursion <= 0.151 or not 0 < trace["duration"] <= 56:
            failures.append({"kind": "TraceMotionOrDuration", "sequence": label, "excursion": excursion, "duration": trace["duration"]})
        if any(frames[index]["time"] <= frames[index - 1]["time"] for index in range(1, len(frames))):
            failures.append({"kind": "NonMonotonicPoseTime", "sequence": label})
        sequences.append({"name": label, "tracePath": relative(trace_file), "traceSHA256": digest(trace_file.read_bytes()),
                          "traceBytes": trace_file.stat().st_size, "source": trace["source"], "packetSHA256": trace["packet"],
                          "durationSeconds": trace["duration"], "startUtcMillis": trace["startUtcMillis"], "endUtcMillis": trace["endUtcMillis"],
                          "clock": trace["clock"], "shadows": trace["shadows"], "hover": trace["hover"],
                          "visualSamples": len(sequence_images), "preservedPoseSamples": len(frames), "poseLogPrefixOnly": prefix_only, "transport": transport, "recordedCameraDriverCallbacks": trace["renderFrames"],
                          "observedWorldXYZRanges": positions, "observedExcursionStuds": excursion, "commandedEndpointSeparationStuds": 0.15,
                          "observedAlphaRange": [min(frame["alpha"] for frame in frames), max(frame["alpha"] for frame in frames)],
                          "endpointCoverageNote": "Pose telemetry is sampled and does not necessarily include either exact commanded endpoint.",
                          "firstLoggedPoseSeconds": frames[0]["time"], "lastLoggedPoseSeconds": frames[-1]["time"], "unavailableFinalPoseSpanSeconds": max(0, trace["duration"] - frames[-1]["time"]) if prefix_only else None,
                          "visualSamplePaths": sequence_images,
                          "scope": "12 original JPEG visual samples while the camera driver interpolated back and forth between endpoints 0.15 stud apart; preserved poses are telemetry, not images, and their prefix-only transport scope is stated separately."})
    actual = {relative(path) for path in (ART / "views").glob("moving-keepwindows52-*.jpg")}
    expected = {row["path"] for row in images}
    if actual != expected or len(images) != 12:
        failures.append({"kind": "MovingImageInventory", "expected": sorted(expected), "actual": sorted(actual)})
    driver = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/MovingRendered52.luau"
    writer = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/save_capture.py"
    report = {"pass": not failures, "indexedAtUtc": datetime.now(timezone.utc).isoformat(), "source": 52, "build": 46, "candidate": "MC_P3_CLOSEOUT_FC03", "packetSHA256": PACKET_SHA,
              "counts": {"sequences": len(sequences), "images": len(images), "uniqueImageHashes": len({row["sha256"] for row in images})},
              "dimensions": [2040, 1109], "JPEGQuality": 95, "sequences": sequences, "images": images, "failures": failures,
              "evidenceBoundary": "One Source 52 sampled moving sequence, 12 original JPEG95 images over the actual duration recorded below; Source 51 sequences remain separate historical evidence. This is not video, every rendered frame, visual FPS, gameplay or performance proof. The direct tool truncated the pose log; only 332 complete prefix poses are retained for this run. Complete run metadata and the 12 original images survive. The pose/callback counters do not replace missing raster frames. Image ordinals are sequence membership only; no exact image-to-pose timestamp synchronization is claimed.",
              "originalByteBoundary": "The owned capture writer saves supplied original JPEG bytes exclusively without resizing or recompression. Hashes index the saved originals; no visual judgment is made by this metadata check.",
              "inputHashes": {relative(driver): digest(driver.read_bytes()), relative(writer): digest(writer.read_bytes())}}
    save("moving-evidence52.json", report)
    return report


import sys

mode = sys.argv[1] if len(sys.argv) > 1 else "filesystem"
assert mode in {"filesystem", "moving"}
if mode == "filesystem":
    report = filesystem_report()
    print(json.dumps({"pass": report["pass"], "counts": report["counts"], "failures": report["failures"]}))
else:
    report = moving_report()
    print(json.dumps({"pass": report["pass"], "counts": report["counts"], "failures": report["failures"],
                      "durations": [row["durationSeconds"] for row in report["sequences"]]}))
assert report["pass"], report["failures"]
