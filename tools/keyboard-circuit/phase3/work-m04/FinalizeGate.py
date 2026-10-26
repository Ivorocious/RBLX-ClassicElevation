from argparse import ArgumentParser
from datetime import datetime, timezone
import math
import json
import re
import sys

sys.dont_write_bytecode = True
from FreezeInputs import (
    CANDIDATE, COUNTS, FOLDER, GLOBAL_SOURCES, HISTORY_INPUTS, LAYOUT, MAP_REVISION, ORIGIN,
    REQUIRED_RECEIPTS, REVISION, SKY, VIEW_NAMES, WORK, check_counts, check_origin,
    check_source_agreement, check_views, identity, latest_receipt, passed_receipt,
    read, record, relative, repo_path, require, sha, validate_candidate,
    verify_inputs, write_new,
)


def check_review(path, freeze_path, freeze, freeze_sha, number):
    review = passed_receipt(path)
    require(review.get("reviewer") == f"R{number}", f"{path.name}: wrong reviewer identity")
    require(review.get("model") == "gpt-6.1-sol" and review.get("reasoningEffort", review.get("reasoning")) == "high", f"{path.name}: requires Sol 6.1 High")
    require(review.get("independent") is True and (review.get("wholeOutcomeReview") is True or review.get("wholeCandidate") is True), f"{path.name}: requires independent whole-candidate judgment")
    if "nativeModel" in review:
        require(review["nativeModel"] == "Workspace." + CANDIDATE, f"{path.name}: wrong native model")
    for name in ("inheritedScoresUsed", "otherReviewerJudgmentsRead", "candidateMutated"):
        require(review.get(name) is False, f"{path.name}: {name} must be explicitly false")
    freeze_ref = review.get("freezePath", review.get("sourceFreeze"))
    require(isinstance(freeze_ref, str) and (freeze_ref == freeze_path.name or freeze_ref == relative(freeze_path)), f"{path.name}: wrong freeze path")
    require(review.get("freezeSha256", review.get("sourceFreezeSha256")) == freeze_sha and review.get("nativeSha256") == freeze["nativeSha256"], f"{path.name}: review did not judge this exact frozen candidate")
    require(review.get("verifiedFrozenInputs") == freeze["count"] and review.get("hashOrLengthMismatches") == [], f"{path.name}: reviewer must verify every frozen input")
    require(review.get("blockers") == [] and review.get("blockerCount", 0) == 0 and not review.get("requiredRepairs"), f"{path.name}: unresolved blockers or required repairs")
    score = review.get("overallScore", review.get("score"))
    require(isinstance(score, (int, float)) and not isinstance(score, bool) and math.isfinite(score) and 8.5 <= score <= 10, f"{path.name}: individual score must be 8.5 to 10")
    report_path = path.with_suffix(".md")
    require(report_path.is_file() and report_path.stat().st_size > 0, f"Missing independent written review: {report_path.name}")
    return {
        "reviewer": f"R{number}", "agent": review.get("agent"), "model": "gpt-6.1-sol",
        "reasoningEffort": "high", "independent": True, "wholeOutcomeReview": True,
        "score": score, "blockers": 0, "passed": True,
        "json": record(path), "markdown": record(report_path),
        "sourceFreezeSha256": freeze_sha, "nativeSha256": freeze["nativeSha256"],
    }


def check_post_review(freeze, freeze_sha, original_sources):
    post_path = latest_receipt("native-post-review")
    source_path = latest_receipt("native-post-review-source-agreement")
    post = passed_receipt(post_path)
    sources = passed_receipt(source_path)
    check_source_agreement(sources, source_path.name)
    for key in ("rows", "unrelated", "resources", "descendants", "archived"):
        require(sources.get(key) == original_sources.get(key), f"Post-review {key} changed from frozen native source agreement")
    require(post.get("editRunning") is False, "Post-review native comparison must run in Edit")
    require(post.get("sourceFreezeSha256") == freeze_sha and post.get("nativeSha256") == freeze["nativeSha256"], "Post-review native receipt must bind the exact reviewed freeze and native export")
    require(post.get("activeCourses") == [CANDIDATE] and post.get("inertOlderCourses") == 16 and post.get("sources") == 28, "Post-review native course/source/archive inventory changed")
    check_origin(post.get("origin"), "post-review native comparison")
    require(post.get("unrelated") == original_sources.get("unrelated"), "Unrelated maps changed after review")
    require(post.get("geometryRows") in (original_sources["descendants"], original_sources["descendants"] + 1), "Post-review native geometry comparison is incomplete")
    if "resources" in post:
        check_counts(post["resources"], "post-review resources")
    return post_path, source_path, post


def main():
    parser = ArgumentParser(description="Close M04 only after every frozen input, native check and three independent reviews pass.")
    parser.add_argument("--freeze", default="P3-M04-FREEZE-01.json")
    parser.add_argument("--gate", default="P3-M04-FINAL-GATE-01.json")
    parser.add_argument("--review-id", default="01")
    args = parser.parse_args()
    require(re.fullmatch(r"P3-M04-FREEZE-\d{2,}\.json", args.freeze), "Invalid M04 freeze filename")
    require(re.fullmatch(r"P3-M04-FINAL-GATE-\d{2,}\.json", args.gate), "Invalid M04 gate filename")
    require(re.fullmatch(r"\d{2,}", args.review_id), "Invalid fresh review suffix")
    freeze_path, gate_path = FOLDER / args.freeze, FOLDER / args.gate
    require(not gate_path.exists(), "Do not replace a final gate; use a fresh gate number")
    freeze = read(freeze_path)
    identity(freeze, freeze_path.name)
    require(freeze.get("revision") == REVISION and freeze.get("mapRevision") == MAP_REVISION and freeze.get("layout") == LAYOUT, "Freeze revision/layout mismatch")
    require(freeze.get("requiredLaps") == 2 and freeze.get("snapshotSources") == 28 and freeze.get("globalSources") == 4, "Freeze course/source scope mismatch")
    require(freeze.get("placeId") == 85558151074819 and freeze.get("universeId") == 10191126818, "Freeze belongs to another experience")
    check_origin(freeze.get("origin"), "freeze")
    check_counts(freeze.get("resources", {}), "freeze")
    require(freeze.get("gate") == {"reviewerCount": 3, "minimumIndividualScore": 8.5, "maximumBlockers": 0}, "Review gate differs from the current owner commission")
    entries = freeze.get("inputs", [])
    require(freeze.get("count") == len(entries), "Frozen input count mismatch")
    verify_inputs(entries)
    freeze_sha = sha(freeze_path)
    receipt_paths = {stem: repo_path(path) for stem, path in freeze.get("receipts", {}).items()}
    require(set(receipt_paths) == set(REQUIRED_RECEIPTS), "Freeze required receipt mapping incomplete")
    for stem, path in receipt_paths.items():
        require(path == latest_receipt(stem), f"New {stem} evidence exists after this freeze; review a fresh freeze")
    receipts, ids, scene_path = validate_candidate(receipt_paths)
    require(freeze.get("sourceScene") == relative(scene_path), "Native scene changed after freezing")
    check_views(scene_path)
    require(freeze.get("nativeSha256") == receipts["native-recovery"]["nativeSha256"] and freeze.get("skyFaceIds") == ids, "Native export or Sky faces differ from the freeze")
    frozen_paths = {row["path"] for row in entries}
    mandatory = set(GLOBAL_SOURCES) | {relative(path) for path in (WORK / "sources").glob("*.luau")}
    mandatory.update(relative(path) for path in receipt_paths.values())
    mandatory.update(relative(FOLDER / "views-m04" / f"{name}.png") for name in VIEW_NAMES)
    mandatory.update(relative(path) for path in SKY.iterdir() if path.is_file())
    mandatory.update(relative(FOLDER / name) for name in HISTORY_INPUTS)
    mandatory.update(relative(path) for path in (WORK / "FreezeInputs.py", WORK / "FinalizeGate.py", WORK / "BuildPlayReceipt.py", WORK / "PostReview.server.luau", WORK / "OtherMapHandoff.client.luau", FOLDER / "KC_P3_M04_01_Native.rbxm", FOLDER / "KC_P3_M04_01_Native-before-streaming-01.rbxm", FOLDER / "KC_P3_M04_01_Offline.blend", FOLDER / "views-m04/render-manifest.json", scene_path))
    brief = freeze.get("briefCopy", {})
    brief_path = repo_path(brief.get("copy"))
    require(brief_path.is_relative_to(FOLDER / "history-m04") and brief_path.name == "COURSE_BRIEF.md" and brief.get("sha256") == sha(brief_path), "Review-time course brief copy missing or changed")
    mandatory.add(relative(brief_path))
    require(mandatory.issubset(frozen_paths), "Required candidate inputs omitted from freeze: " + ", ".join(sorted(mandatory - frozen_paths)))
    agreement_path = FOLDER / args.freeze.replace("FREEZE", "freeze-agreement")
    agreement = passed_receipt(agreement_path)
    require(agreement.get("sourceFreeze") == relative(freeze_path) and agreement.get("sourceFreezeSha256") == freeze_sha and agreement.get("count") == len(entries), "Freeze agreement differs from reviewed inputs")
    reviews = [check_review(FOLDER / f"P3-M04-R{number}-review-{args.review_id}.json", freeze_path, freeze, freeze_sha, number) for number in (1, 2, 3)]
    agents = [review["agent"] for review in reviews]
    require(all(agent is None for agent in agents) or (all(isinstance(agent, str) and agent for agent in agents) and len(set(agents)) == 3), "Reviewer agent identities are duplicated or incomplete")
    post_path, post_sources_path, post = check_post_review(freeze, freeze_sha, receipts["native-source-agreement"])
    verify_inputs(entries)
    require(sha(freeze_path) == freeze_sha, "Freeze changed during gate verification")
    created = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    result = {
        "passed": True, "status": "pass", "candidate": CANDIDATE, "revision": REVISION,
        "mapRevision": MAP_REVISION, "layout": LAYOUT, "origin": ORIGIN, "requiredLaps": 2,
        "createdUtc": created, "requirements": {"independentReviewers": 3, "minimumIndividualScore": 8.5, "maximumBlockersPerReviewer": 0},
        "freeze": {**record(freeze_path), "verifiedInputs": len(entries), "byteOrHashMismatches": []},
        "freezeAgreement": record(agreement_path), "reviews": reviews,
        "minimumIndividualScore": min(review["score"] for review in reviews), "allIndividualReviewGatesPassed": True,
        "native": {**record(FOLDER / "KC_P3_M04_01_Native.rbxm"), "roundTripPassed": True, "freshSourceRebuildPassed": True},
        "checks": [{**record(path), "passed": True} for path in receipt_paths.values()] + [{**record(path), "passed": True} for path in (post_path, post_sources_path)],
        "effectsLifecycle": {"ordinaryCleanupCasesPassed": 8, "otherMapHandoff": {**record(receipt_paths["effects-other-map-handoff"]), "passed": True, "courseId": "city_run", "realServerTeleport": True, "directArchiveHandoff": True, "expectedLightingAndSkyApplied": True, "originalLobbyRestored": True}},
        "postReview": {"nativeMode": "Edit", "nativeRowsCompared": post["geometryRows"], "snapshotSourcesMatched": 28, "globalSourcesMatched": 4, "activeCourses": [CANDIDATE], "inertOlderCourses": 16},
        "resources": COUNTS, "inertEffectAnchors": 97, "skyFaceIds": ids,
        "normalContinuousSeconds": receipts["normal-two-lap"].get("continuousSeconds"),
        "expertContinuousSeconds": receipts["expert-two-lap"].get("continuousSeconds"),
        "ownerTest": "Play -> F6 -> Keyboard Circuit -- 2 Laps", "ownerAcceptance": "pending",
        "scope": {"computerControlUsed": False, "cameraControlUsed": False, "wholePlaceSave": False, "published": False},
        "limits": ["Same frozen M04 local technical gate; no inherited scores or averaging.", "Offline close views approximate native fonts and lighting; real Sky loads and lifecycle checks are separate evidence.", "Resource and callback samples do not certify FPS, device, networking, multiplayer, human pacing, subjective sound or owner visual acceptance."],
    }
    write_new(gate_path, result)
    print(json.dumps({"passed": True, "gate": relative(gate_path), "scores": [row["score"] for row in reviews], "sourceFreezeSha256": freeze_sha}))


if __name__ == "__main__":
    main()
