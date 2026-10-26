from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[4]
FOLDER = ROOT / "docs/artifacts/keyboard-circuit/phase3"
CANDIDATE = "KeyboardCircuit_P3_M04_01"
REVISION = "KC_P3_M04_01"
FILES = {
    "hud": "native-hud-01",
    "heldPress": "native-held-press-01",
    "brackets": "native-bracket-01",
    "warningCycle": "native-warning-cycle-01",
    "liftRide": "native-lift-ride-01",
    "fallRecovery": "native-focused-recovery-01",
    "cleanSessionSources": "native-clean-session-sources-02",
    "lifecycle": "effects-lifecycle-03",
    "deathRespawn": "effects-death-03",
    "sky": "native-sky-load-03",
    "otherMapHandoff": "effects-other-map-handoff-01",
    "normal": "normal-two-lap-01",
    "expert": "expert-two-lap-01",
    "normalEffects": "normal-race-effects-01",
    "expertEffects": "expert-race-effects-01",
}
components = {}
for name, stem in FILES.items():
    path = FOLDER / ("P3-M04-" + stem + ".json")
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    assert data.get("candidate") in (CANDIDATE, "Workspace." + CANDIDATE), (name, "wrong candidate")
    assert data.get("passed") is True and not data.get("failures") and not data.get("error"), (name, "failed component")
    assert data.get("active") is not True and data.get("running") is not True, (name, "still running")
    for key in ("revision", "prototypeRevision"):
        if key in data:
            assert data[key] == REVISION, (name, key)
    components[name] = {
        "candidate": CANDIDATE, "revision": REVISION, "passed": True,
        "path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    if name in ("normal", "expert"):
        components[name].update({key: data[key] for key in ("continuousSeconds", "fixtureHoldSeconds", "setupCalls", "movement")})
        components[name].update(gateCrossings=len(data["gates"]), midpointSaves=len(data["midpointReceipts"]),
                                completedLaps=data["serverState"]["completedLaps"], recoveries=data["finalState"]["recoveries"])
    elif name.endswith("Effects"):
        components[name].update(waves=data["waves"], lapSweeps=data["lapSweeps"],
                                maxSweepContactLevel=data["maxSweepContactLevel"], diagnostics=data["finalDiagnostics"])
result = {
    "candidate": CANDIDATE, "revision": REVISION, "passed": True, "failures": [],
    **components,
    "boundary": "Identity-bound aggregate of passing native checks. Focused HUD/contact/warning/recovery cases preceded the final source-only cosmetic guards and streaming repair; accepted gameplay and warning geometry are preserved. Clean saved-source lifecycle, death, actual Sky, other-map restoration and both complete races/effect observations ran after the final repair. Referenced raw receipts retain their exact fixture conditions. No native camera seam inspection, typical-human pacing/audio, crowd/device/FPS or publication claim.",
}
path = FOLDER / "P3-M04-native-play-checks-01.json"
with path.open("x", encoding="utf-8", newline="\n") as output:
    output.write(json.dumps(result, indent=2) + "\n")
print(json.dumps({"passed": True, "candidate": CANDIDATE, "components": len(components), "path": path.relative_to(ROOT).as_posix()}))
