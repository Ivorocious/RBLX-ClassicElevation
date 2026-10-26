from pathlib import Path

own = Path(__file__).resolve().parent
source = (own.parent / "verification51/CheckFilesystemAndMovingEvidence51.py").read_text(encoding="utf8")
source = source.replace("016c10fdcc4d70a75af996216a2cef4687b773a3a42bc7ea389b4608273e62c4",
                        "80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617")
source = source.replace("source51", "source52").replace("Source51", "Source52")
source = source.replace("InstallSource51", "InstallSource52").replace("MovingRendered51", "MovingRendered52")
source = source.replace("preservation51", "preservation52").replace("evidence51", "evidence52")
source = source.replace('"source": 51', '"source": 52').replace('"build": 45', '"build": 46')
source = source.replace('trace["source"] != 51', 'trace["source"] != 52').replace("MC_P3_CLOSEOUT_FC02", "MC_P3_CLOSEOUT_FC03")
source = source.replace('for label in ("crown51", "gallery51", "keepwindows51"):', 'for label in ("keepwindows52",):')
source = source.replace('.glob("moving-*.jpg")', '.glob("moving-keepwindows52-*.jpg")').replace('len(images) != 36', 'len(images) != 12')
source = source.replace('not 30 <= trace["duration"] <= 35', 'not 0 < trace["duration"] <= 56')
source = source.replace("Three sampled moving sequences, 12 original JPEG95 images each over 30.75 to 33.62 seconds.",
                        "One Source 52 sampled moving sequence, 12 original JPEG95 images over the actual duration recorded below; Source 51 sequences remain separate historical evidence.")
source = source.replace('frames = trace["frames"]', '''frames = trace["frames"]
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
            failures.append({"kind": "MissingPrefixScopeFlag", "sequence": label})''')
source = source.replace('"poseSamplesLogged": len(frames)', '"preservedPoseSamples": len(frames), "poseLogPrefixOnly": prefix_only, "transport": transport')
source = source.replace('"lastLoggedPoseSeconds": frames[-1]["time"],',
                        '"lastLoggedPoseSeconds": frames[-1]["time"], "unavailableFinalPoseSpanSeconds": max(0, trace["duration"] - frames[-1]["time"]) if prefix_only else None,')
source = source.replace('recorded poses are telemetry, not images.',
                        'preserved poses are telemetry, not images, and their prefix-only transport scope is stated separately.')
source = source.replace('The pose/callback counters do not replace missing raster frames.',
                        'The direct tool truncated the pose log; only 332 complete prefix poses are retained for this run. Complete run metadata and the 12 original images survive. The pose/callback counters do not replace missing raster frames.')
start = source.index("filesystem = filesystem_report()")
source = source[:start] + '''import sys

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
'''
(own / "CheckFilesystemAndMovingEvidence52.py").write_text(source, encoding="utf8", newline="")
print("Prepared Source52 filesystem and focused keep movement evidence checks")
