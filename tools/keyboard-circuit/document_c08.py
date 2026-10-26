import shutil
from pathlib import Path

root = Path.cwd()
base = root / "docs/artifacts/keyboard-circuit"
phase = base / "phase1"
history = phase / "history/C07-final-docs"
history.mkdir(parents=True, exist_ok=True)
for path in [base / "COURSE_BRIEF.md", phase / "EVIDENCE.md", phase / "ASSET_CATALOG.md", phase / "reviews/INDEX.md", phase / "audio/README.md"]:
    relative = path.relative_to(base)
    destination = history / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists():
        shutil.copyfile(path, destination)

path = base / "COURSE_BRIEF.md"
text = path.read_text(encoding="utf-8")
records = {
    "- **Status:**": "C08 implements one-character key legends, fixes the duplicated pressed legend, adds a decisive/smooth held stroke, tunes the existing sound pairs with quiet releases and short body effects, and removes repeated runtime work. Source/rebuild/native recovery, Normal traversal, lift/shuttle, hazard/warning, lifecycle, actual two-client holds and installed bootstrap checks passed. C07 and its kit are preserved. The requested three specialist implementation/research reports are complete. C07's five High scores remain historical; a fresh C08 release gate and owner sound/feel acceptance remain open.",
    "- **Current candidate / live target:**": "`Workspace.KeyboardCircuit_P1_C08` and `ServerStorage.CourseAssetKits.KeyboardCircuit_EditableKit_K01` (`KC_KIT_C08_01`) are installed in Obby Tournament, place `85558151074819`, universe `10191126818`. Sample origin `(2300,330,-1300)` and study origin `(2300,330,-1850)` remain isolated. Rojo has ten unique builders and one client Feedback/Preview pair. Each model has fourteen unique snapshot sources, including Audio, Feedback and Preview. C07/kit and earlier candidates remain in `ServerStorage.DeveloperArchives.KeyboardCircuitP1_Archives`. Four fresh native exports and exact source/test boundaries are in [C08 review brief](phase1/C08-REVIEW-BRIEF.md). Unrelated course counts and all C07 geometry/collisions were retained.",
    "- **Next action:**": "Obtain the owner's hands-on critique of the current [whole-route study](phase1/KC_C08_study_owner_view.jpg), [sample](phase1/KC_C08_sample_owner_view.jpg) and [pressed-key view](phase1/KC_C08_press.png). Compare all four sound families at a fixed listening volume. The paired checkpoint and fresh same-five-judge C08 release gate remain open; C07 scores cannot transfer. Phase 2/3 production requires separate authorization.",
    "- **Operations / reviews in flight:**": "No Play, source edit, upload or specialist operation remains active. C08 source/native/regression checks and guarded handoff are complete; Studio is back in Edit with the owner's exact Scriptable camera/Focus/FOV restored. The earlier five C07 judge scores apply only to that historical package. [C08 evidence](phase1/C08-REVIEW-BRIEF.md) and [review index](phase1/reviews/INDEX.md) distinguish implementation checks from release/owner acceptance. The warmed sound checks passed; five initial unloaded-hit misses on each multiplayer client remain recorded. No CPU/FPS gain, full-race/device result, whole-place save or publication is claimed.",
}
lines = text.splitlines()
for prefix, value in records.items():
    indices = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    assert len(indices) == 1, prefix
    lines[indices[0]] = prefix + " " + value
text = "\n".join(lines) + "\n"
text = text.replace("Typical C07 cap:", "Typical C08 cap:")
text = text.replace("C07 uses typical 2.42-stud caps", "C08 retains typical 2.42-stud caps")
text = text.replace("with authentic editable characters/symbols.", "with one authentic editable character or symbol per key.")
text = text.replace("| C07 down/up", "| C08 retains down/up")
text = text.replace("Current native source pairs, Creynex attribution, short playback regions and family tuning", "Current C08 source pairs, Creynex attribution, short playback regions, quieter releases and family tuning")
text = text.replace("All eight loaded; repeated-walking scheduling and all four native prompt auditions passed.", "All eight loaded; four native prompt auditions and warmed two-client playback passed. Initial preload misses remain recorded separately.")
path.write_text(text, encoding="utf-8", newline="\n")

path = phase / "ASSET_CATALOG.md"
text = path.read_text(encoding="utf-8")
text = text.replace("Editable legends include QWERTY characters and paired symbols.", "Each editable legend contains one QWERTY character or keyboard symbol.")
text = text.replace("Short playback regions, per-family tuning and repeat limits prevent cutoffs in the final walking fixture.", "C08 adds softer releases, small stable per-key variation and two short local body effects. Native warmed fixtures recorded no missing clips or voice steals; initial preload misses are retained.")
text = text.replace("Construction sources are under", "Current revision: `KC_KIT_C08_01`. Geometry, edit units, collision/query/touch settings and shared K02 mesh are unchanged from C07. Both sample and kit carry 14 snapshot sources, including Audio, Feedback and Preview. The kit stays inactive. [C08 source/native evidence](C08-REVIEW-BRIEF.md).\n\nConstruction sources are under", 1)
path.write_text(text, encoding="utf-8", newline="\n")

path = phase / "EVIDENCE.md"
text = path.read_text(encoding="utf-8")
intro = """# Keyboard Circuit Phase 1 evidence

C08 is the current installed revision. It gives each key one symbol, hides the original legend during a press, keeps the .45-stud shared hold with faster attack and smooth release, improves the existing sound mix, and avoids duplicate stationary checks and repeated writes. Sample and kit geometry/collisions are unchanged from C07; each has 14 saved sources.

[C08 review brief](C08-REVIEW-BRIEF.md) links the exact native tests, performance counts, limitations and recovery exports. Normal traversal, lift/shuttle, held warnings, actual head recovery, camera/cleanup, two-client 2 → 1 → 0 holds and installed preview passed. Warm audio played all four families without extra misses or steals; five early preload misses on each multiplayer client remain recorded. Native frame captures did not show a measurable CPU/FPS gain. Human sound/feel judgment and the fresh five-judge release gate remain open.

Current owner pair: [study](KC_C08_study_owner_view.jpg) and [sample](KC_C08_sample_owner_view.jpg); [clean pressed legend](KC_C08_press.png). Four native current/recovery files have hashes in [export verification](C08-export-verification.json). No Phase 2/3 production, full-race/device result, whole-place save or publication is claimed. Live state belongs in `../COURSE_BRIEF.md`.

## Historical C07 record

The following record and scores describe C07 at its original gate. Original current-state documents are preserved in `history/C07-final-docs/`; sources before C08 are in `history/C07-source-before-C08/`. C07 source paths in its old manifest have since changed for C08; do not treat that manifest as a current source check.
"""
path.write_text(intro + text.split("\n", 1)[1], encoding="utf-8", newline="\n")

path = phase / "reviews/INDEX.md"
text = path.read_text(encoding="utf-8")
intro = """# Keyboard Circuit Phase 1 reviews

Current candidate: `KC_P1_C08`, kit `KC_KIT_C08_01`. The requested Sol 6.1 Sound ExtraHigh, Stepping ExtraHigh and Optimization Max specialists implemented their scopes and supplied reports under `../research/`. The lead completed source, native recovery and focused regression checks; [C08 brief](../C08-REVIEW-BRIEF.md) states exact boundaries.

C08 does not inherit any C07 score. A fresh review by the same five High judges and the separate owner study/sample checkpoint remain open before production expansion. The three specialist reports are implementation/research reports, not substitute judge scores.

## Historical C07 gate

The following scores and final package identifiers apply only to C07. Original index: `../history/C07-final-docs/phase1/reviews/INDEX.md`.
"""
text = text.split("\n", 1)[1].replace("The current candidate is KC_P1_C07", "The historical candidate was KC_P1_C07", 1)
path.write_text(intro + text, encoding="utf-8", newline="\n")

path = phase / "audio/README.md"
text = path.read_text(encoding="utf-8")
intro = """# Keyboard Circuit audio audition

C08 retains the eight Creynex recordings listed below and improves their mix: softer high frequencies on releases, quieter up hits, a short local Creamy/Thocky body treatment and small stable per-key pitch/gain variation. The four down, two up and two nearby voices remain bounded; standing still does not retrigger sound. Both body groups and their settings were read back natively. Audible ASMR quality, family distinction and repeated comfort require human listening.

All eight clips loaded in the native experience. Four actual prompt auditions passed. Each real simulated multiplayer client then played eight warmed family hits without additional missing clips or voice steals. Each also retains five initial skipped hits before asynchronous preload finished. C07 used the same preload/skip pattern; cold-load duration was not compared, and missed steps are not queued later. [C08 evidence](../C08-REVIEW-BRIEF.md).

Approach the four audition banks beside C08, press E once, and walk across their keys at one fixed listening volume. Compare body, clarity, release balance and comfort through headphones and speakers. `C08/SingleKeys` is the separately attributed CC0 Cherry KC1000 research comparison; it has not been uploaded, selected or substituted for the four paired families. [Specialist research](../research/C08-SOUND-XHIGH.md).

## Historical C07 recording selection

The following recording/access receipts and walking result describe C07. The same asset IDs continue in C08 with new tuning.
"""
path.write_text(intro + text.split("\n", 1)[1], encoding="utf-8", newline="\n")

notes = {
    "DECISIONS.md": """\n\n## Keyboard Circuit C08 asset refinement — October 7, 2026

Keep C07 key size, fixed support, geometry and authoritative hazard/carrying behavior. Use one character per key and hide/restore the original legend together with the cosmetic mesh during a press. Apply decisive attack/smooth release, preserving shared last-occupant holds and grouped Enter. Keep the eight existing recordings and bounded voices; add softer release/body treatment and modest stable variation rather than replacing all four families with one unreviewed pack.

Remove duplicate stationary overlap checks and change-only pose/state/warning writes; retain the exact moving sweep. Publish diagnostics about ten times per second and promptly on important changes/Stop. Both native assets carry 14 self-contained snapshot sources. Preserve C07/kit before the guarded C08 handoff. Focused checks do not establish FPS gain or human sound preference; C07 judge scores cannot endorse C08. [Current evidence](artifacts/keyboard-circuit/phase1/C08-REVIEW-BRIEF.md).
""",
    "BUGS.md": """\n\n## Keyboard Circuit C08 follow-up — October 7, 2026

Fixed the owner's circled doubled legend: original SurfaceGui remained enabled underneath the depressed clone. C08 hides it while held and restores its prior value on release, camera replacement and Stop. Each key now has one character. Native held, warning, camera and cleanup checks passed.

Initial stepping before asynchronous audio preload finishes can be silent: each fresh multiplayer client recorded five misses, followed by warmed playback with zero additional misses/steals. C07 used the same preload/skip pattern; this is not proof of unchanged cold-load speed. Human tonal comfort, all-avatar/device/crowd performance and the earlier unrelated lobby overlay remain open. The installed Stop fixture was corrected because participant diagnostic records intentionally persist; its raw assertion failure is retained and no gameplay source change was made. [Exact evidence and limits](artifacts/keyboard-circuit/phase1/C08-REVIEW-BRIEF.md).
""",
    "TASKS.md": """\n\n## Keyboard Circuit C08 owner refinement — October 7, 2026

- [x] Use the requested Sound ExtraHigh, Stepping ExtraHigh and Optimization Max specialists for research and implementation.
- [x] Enforce one-character legends, fix original/clone label overlap, improve held attack/release and tune the bounded sound mix.
- [x] Avoid repeated runtime/visual/diagnostic work while preserving geometry and gameplay behavior.
- [x] Complete focused native route, lift/shuttle, hazard/warning, lifecycle, two-client hold/audio and installed-bootstrap checks.
- [x] Match 14 Rojo/snapshot sources, rebuild both assets, reopen four native exports and preserve C07/kit before C08 installation.
- [ ] Obtain owner key-feel/sound critique and paired study/sample checkpoint decision.
- [ ] Complete the fresh same-five-judge C08 release gate before production expansion; do not inherit C07 scores.

No Phase 2/3 production, full-race/device certification or publication is complete. [Current state](artifacts/keyboard-circuit/COURSE_BRIEF.md).
""",
    "PLAYTEST_NOTES.md": """\n\n## Keyboard Circuit Phase 1 C08 — October 7, 2026

Native C08 checks passed one/two-key contact, static holds without repeat writes/sound, jump/cell transfer, camera replacement and exact prior GUI restoration. Two actual simulated clients held the same key through occupants 2, 1 and 0; the cap stayed down until the last departure. Installed automatic preview produced one controller, eight audible voices, clean held legends and complete client cleanup. Stop publishes the inactive runtime while retaining participant diagnostic records; the initial overly strict fixture and corrected evaluation are both saved.

Normal traversal passed all 34 staged movements in 21.50 seconds with 7.89 studs of lift carrying and Enter turn. Lift/shuttle boarding and receiver checks passed. Return-phase actual Head/CollisionPart contact recovered the participant; grounded held warning border/arrow passed with explicit float tolerance. C07 full Expert traversal remains historical, with unchanged C08 geometry/gameplay tuning.

All eight recordings loaded; four native prompts played their down/up pairs. Warmed two-client family auditions added eight plays each without additional unavailable clips or voice steals. Each client's five earlier preload misses are retained. C08's local cycle recorded 3,126 queries versus C07's 4,950 over similar roughly 6.6-second windows, but two 128-frame captures did not show a meaningful CPU/FPS gain. Shape/collision signatures and editable units match C07. Four native files reopened and 14 sources rebuilt/matched.

Manual owner check: Studio Play, stage the C08 sample using its existing Begin hook, then stand, walk diagonally, jump/re-enter and try both Enter arms. Compare the four E-key sound banks at a fixed listening level through headphones/speakers. Native operation does not prove satisfying or ASMR tone. No all-avatar, touch-device, 20-racer, full-race, whole-place-save or publication result is claimed. [Current packet](artifacts/keyboard-circuit/phase1/C08-REVIEW-BRIEF.md).
""",
}
for name, note in notes.items():
    path = root / "docs" / name
    text = path.read_text(encoding="utf-8")
    assert "## Keyboard Circuit C08 asset refinement" not in text if name == "DECISIONS.md" else note.splitlines()[2] not in text
    path.write_text(text.rstrip() + note + "\n", encoding="utf-8", newline="\n")
print("Updated C08 current state, preserved prior documents and appended scoped project notes")
