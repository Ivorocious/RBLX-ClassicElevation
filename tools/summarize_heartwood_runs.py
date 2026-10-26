"""Summarize saved HA03 scripted runs without treating them as human pacing."""

import argparse
import hashlib
import json
import math
from datetime import datetime, timezone
from pathlib import Path


BUILD = "HA_V1_03"
KINDS = (
    "continuous_main", "continuous_shortcuts",
    "matched_x01_main", "matched_x01_shortcut",
    "matched_x02_main", "matched_x02_shortcut", "failed_x02_and_replay",
)
METRICS = ("elapsed", "travel", "wait", "replay")
STATE_KEYS = ("position", "checkpoint", "status", "official", "grounded",
              "speed", "jumpHeight", "useJumpPower")
SCOPE = (
    "Solo Studio server-driven movement with actual client cue acknowledgements. "
    "An initial setup reposition is separate from sequence timing. These are scripted "
    "travel, phase/cue waits and authored replay costs; they do not establish human "
    "race pacing, difficulty, success rates, multiplayer, network-delay or device performance."
)


def number(value):
    return not isinstance(value, bool) and isinstance(value, (int, float)) and math.isfinite(value)


def rounded(values):
    return {key: round(value, 6) for key, value in values.items()}


def state(result, key):
    source = result.get(key) or {}
    return {name: source[name] for name in STATE_KEYS if name in source}


def summarize_run(path):
    raw = path.read_bytes()
    record = json.loads(raw)
    result = record.get("result") if isinstance(record, dict) else None
    if not isinstance(result, dict) or not isinstance(result.get("steps"), list):
        raise ValueError("Expected a final {id, ok, result} sequence record with steps")
    steps = result["steps"]
    sections, problems = {}, []
    if result.get("withinRunRepositions") != 0:
        problems.append("Zero test repositions within the run must be recorded")
    sums = dict.fromkeys(METRICS, 0.0)
    failed_steps, unknown_steps, intentional_misses = [], [], []
    for index, step in enumerate(steps):
        if not isinstance(step, dict):
            problems.append(f"Step {index + 1} is not an object")
            continue
        step_id = step.get("id", f"step-{index + 1}")
        if step.get("passed") is False:
            failed_steps.append({"id": step_id, "reason": step.get("reason")})
        elif step.get("passed") is not True:
            unknown_steps.append(step_id)
        section = step.get("section") or "unassigned"
        bucket = sections.setdefault(section, {"steps": 0, "passedSteps": 0,
                                                **dict.fromkeys(METRICS, 0.0)})
        bucket["steps"] += 1
        bucket["passedSteps"] += step.get("passed") is True
        for metric in METRICS:
            value = step.get(metric)
            if not number(value) or value < 0:
                problems.append(f"{step_id}: missing or invalid {metric}")
                continue
            bucket[metric] += value
            sums[metric] += value
        recovery = step.get("recovery") or {}
        if step.get("reason") == "expected-recovery" and recovery.get("passed") is True:
            intentional_misses.append(step_id)

    totals = {}
    for metric in METRICS:
        value = result.get(metric)
        if not number(value) or value < 0:
            problems.append(f"Run has missing or invalid {metric}")
        else:
            totals[metric] = value
            if metric != "elapsed" and abs(value - sums[metric]) > .01:
                problems.append(f"Run {metric} differs from recorded step sum")
    if "elapsed" in totals:
        totals["stepElapsed"] = sums["elapsed"]
        totals["orchestration"] = totals["elapsed"] - sums["elapsed"]
        totals["unallocated"] = totals["elapsed"] - sum(sums[k] for k in ("travel", "wait", "replay"))
        if totals["orchestration"] < -.01 or totals["unallocated"] < -.01:
            problems.append("Timing categories overlap or exceed run elapsed time")
    for bucket in sections.values():
        bucket["unallocated"] = bucket["elapsed"] - bucket["travel"] - bucket["wait"] - bucket["replay"]
        bucket.update(rounded({k: v for k, v in bucket.items() if k not in ("steps", "passedSteps")}))

    complete = result.get("completedSteps") == result.get("requestedSteps") == len(steps)
    if record.get("ok") is False or result.get("passed") is False or failed_steps:
        status = "failed"
    elif record.get("ok") is True and result.get("passed") is True and complete and steps and not unknown_steps and not problems:
        status = "passed"
    else:
        status = "incomplete"
    before_diag = (result.get("before") or {}).get("diagnostics") or {}
    after_diag = (result.get("after") or {}).get("diagnostics") or {}
    deltas = {key: after_diag[key] - before_diag[key] for key in ("hits", "releases", "acknowledgements", "cancels")
              if number(before_diag.get(key)) and number(after_diag.get(key))}
    return {
        "status": status, "file": path.name, "sha256": hashlib.sha256(raw).hexdigest(),
        "id": record.get("id"), "outerOk": record.get("ok"), "resultPassed": result.get("passed"),
        "completedSteps": result.get("completedSteps"), "requestedSteps": result.get("requestedSteps"),
        "recordedSteps": len(steps), "totals": rounded(totals), "sections": sections,
        "failedSteps": failed_steps, "unknownSteps": unknown_steps, "problems": problems,
        "before": state(result, "before"), "after": state(result, "after"), "diagnosticDelta": deltas,
        "initialRepositions": result.get("initialRepositions"),
        "withinRunRepositions": result.get("withinRunRepositions"),
        "intentionalMissSteps": intentional_misses, "recordedScope": result.get("scope"),
    }


def matched_state_differences(main, shortcut):
    differences = []
    for key in ("checkpoint", "status", "official", "speed", "jumpHeight", "useJumpPower"):
        a, b = main["before"].get(key), shortcut["before"].get(key)
        if a is None or b is None or (abs(a - b) > 1e-5 if number(a) and number(b) else a != b):
            differences.append(key)
    positions = [run["before"].get("position") for run in (main, shortcut)]
    if not all(isinstance(p, list) and len(p) == 3 and all(number(v) for v in p) for p in positions):
        differences.append("position")
    elif math.dist(*positions) > .1:
        differences.append("position")
    for key in ("checkpoint", "status"):
        if main["after"].get(key) != shortcut["after"].get(key):
            differences.append("final " + key)
    return differences


def compare(runs, name):
    main, shortcut = (runs[f"matched_{name}_{suffix}"] for suffix in ("main", "shortcut"))
    result = {"status": "pending", "main": main.get("file"), "shortcut": shortcut.get("file")}
    if any(run["status"] in ("failed", "invalid", "ambiguous") for run in (main, shortcut)):
        result["status"] = "failed-input"
    if main["status"] != "passed" or shortcut["status"] != "passed":
        result["reason"] = "Both matched runs must pass before calculating savings"
        return result
    differences = matched_state_differences(main, shortcut)
    if differences:
        return {**result, "status": "not-comparable", "reason": "Different or missing matched states", "differences": differences}
    result.update(status="ready", scope="One matched scripted attempt per branch; not human savings or expected success-adjusted savings",
                  savings=rounded({k: main["totals"][k] - shortcut["totals"][k] for k in METRICS}))
    return result


def build_summary(directory):
    files = {kind: [] for kind in KINDS}
    for path in sorted(directory.glob(f"*{BUILD}.json")):
        kind = path.stem.removesuffix("-" + BUILD).removesuffix("_" + BUILD).replace("-", "_")
        if kind in files:
            files[kind].append(path)
    runs = {}
    for kind, candidates in files.items():
        if not candidates:
            runs[kind] = {"status": "pending", "reason": "Final raw run file is not present"}
        elif len(candidates) > 1:
            runs[kind] = {"status": "ambiguous", "files": [p.name for p in candidates]}
        else:
            try:
                runs[kind] = summarize_run(candidates[0])
            except (OSError, ValueError, TypeError, KeyError) as error:
                runs[kind] = {"status": "invalid", "file": candidates[0].name, "reason": str(error)}
    comparisons = {name.upper(): compare(runs, name) for name in ("x01", "x02")}
    failed, clean = runs["failed_x02_and_replay"], runs["matched_x02_shortcut"]
    miss = {"status": "pending", "scope": "One authored miss and recovery/retry; not an expected retry cost or success-rate estimate"}
    if failed["status"] == clean["status"] == "passed":
        differences = matched_state_differences(failed, clean)
        if differences:
            miss.update(status="not-comparable", reason="Different or missing replay/clean matched states", differences=differences)
        elif not failed["intentionalMissSteps"]:
            miss.update(status="unverified-miss", reason="No passed expected-recovery step is recorded")
        else:
            miss.update(status="ready", missSteps=failed["intentionalMissSteps"],
                        recoveryAndReplay=failed["totals"]["replay"],
                        additionalElapsedVsCleanShortcut=round(failed["totals"]["elapsed"] - clean["totals"]["elapsed"], 6),
                        failedAttemptAndReplayElapsed=failed["totals"]["elapsed"],
                        cleanShortcutElapsed=clean["totals"]["elapsed"])
    elif failed["status"] in ("failed", "invalid", "ambiguous"):
        miss.update(status="failed-input", reason="Intentional-miss replay run has not passed")
    ready = all(run["status"] == "passed" for run in runs.values()) and all(c["status"] == "ready" for c in comparisons.values()) and miss["status"] == "ready"
    bad = any(run["status"] in ("failed", "invalid", "ambiguous") for run in runs.values())
    return {"schemaVersion": 1, "build": BUILD, "generatedAt": datetime.now(timezone.utc).isoformat(),
            "status": "complete" if ready else "has-failures" if bad else "partial",
            "units": "seconds", "scope": SCOPE, "humanPacingTargetsValidated": False,
            "categoryRules": "Replay-tagged steps contribute their entire elapsed time to replay. Travel and wait exclude those steps. Replay also includes recorded recovery-settle time. Orchestration is run elapsed minus step elapsed.",
            "runs": runs, "matchedComparisons": comparisons, "intentionalMissCost": miss}


def main():
    directory = Path(__file__).resolve().parents[1] / "docs/artifacts/heartwood-ascent/v1"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=directory)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    output = args.output or args.input_dir / f"route-timing-{BUILD}.json"
    summary = build_summary(args.input_dir)
    output.write_text(json.dumps(summary, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    print(json.dumps({"file": str(output), "status": summary["status"],
                      "runs": {k: v["status"] for k, v in summary["runs"].items()}}))


if __name__ == "__main__":
    main()
