# M04 closure tooling

Prepared only. Do not run the freeze until the corrected final sources, final native receipts, native recovery export and all six offline views are ready. Do not run the gate until three fresh independent reviews and the post-review Edit checks are complete.

The scripts use only local files. They do not control Studio, the computer or the camera, publish, or implement gameplay changes. They preserve M02/M03 recovery records and refuse to overwrite freezes, agreement records, review-time brief copies or final gates.

## Final filenames

Default outputs in `docs/artifacts/keyboard-circuit/phase3`:

- `P3-M04-FREEZE-01.json`
- `P3-M04-freeze-agreement-01.json`
- `history-m04/01/COURSE_BRIEF.md`, copied from the mutable current brief at freeze time
- `P3-M04-FINAL-GATE-01.json`

Required native assets: `KC_P3_M04_01_Native.rbxm` and `KC_P3_M04_01_Offline.blend`.

Required view folder: `views-m04`, with `render-manifest.json` and all six PNGs: `start-station`, `normal-expert-choice`, `checkpoint-shuttle-exit`, `falling-key-warning`, `repaired-brackets`, `archive-skybox-overview`.

The freeze selects the highest numbered canonical receipt for each stem below. For example, `P3-M04-native-source-agreement-02.json` supersedes `...-01.json`; both remain preserved. The latest failed receipt blocks freezing even if an older one passed. Names containing `before`, `failed` or another extra word remain descriptive evidence and are not selected as final passing receipts.

```
P3-M04-native-source-agreement-NN.json
P3-M04-filesystem-agreement-NN.json
P3-M04-native-preservation-NN.json
P3-M04-native-motion-clearance-NN.json
P3-M04-native-visibility-NN.json
P3-M04-native-resource-inventory-NN.json
P3-M04-native-play-checks-NN.json
P3-M04-effects-lifecycle-NN.json
P3-M04-effects-other-map-handoff-NN.json
P3-M04-effects-death-NN.json
P3-M04-native-sky-load-NN.json
P3-M04-normal-two-lap-NN.json
P3-M04-expert-two-lap-NN.json
P3-M04-normal-race-effects-NN.json
P3-M04-expert-race-effects-NN.json
P3-M04-native-recovery-NN.json
```

Each final receipt needs `passed: true`, the M04 candidate identity, and no unresolved failures. Every present revision must be `KC_P3_M04_01`. A receipt without identity, including the initial visibility receipt, needs a new final identity-bound record; keep the original.

## Freeze requirements

The candidate is `KeyboardCircuit_P3_M04_01` / `KC_P3_M04_01` / `KC_MAP_M04_01`, owner origin `(2222,330,-1158)`, retained layout `KC_LAYOUT_P2_I09_03`, and two required laps. Required resource counts are 8,808 parts, 2,989 press targets, 282 colliders, 3,289 query parts and zero touch parts. All 97 decorative anchors must remain invisible and without shadows in Edit. No active `ArchiveBackdrop` source or scene parts are accepted.

The final Edit source agreement and filesystem agreement must prove all 28 snapshot files and four global files match exact bytes and hashes. CRLF/LF normalization does not substitute for exact final agreement. The four globals are `StudioDevService`, `ClassicAscentAmbience`, `StudioDevController`, and `KeyboardCircuitPhase2Preview`. Keep one active M04 and all 16 earlier courses inert, including M02 and M03.

The canonical Play receipt needs fifteen required identity-bound passing component references: HUD, held press, brackets, warning cycle, lift ride, Fall recovery, clean-session sources, lifecycle, death/respawn, Sky, other-map handoff, both races and both race effect observers. Each reference binds the raw receipt by path, length and SHA256; the gate reopens it and requires a pass. Retained failed attempts cannot be used as passing components. `BuildPlayReceipt.py` writes the aggregate only after all fifteen raw checks pass.

Both race effect observers must be stopped, with all four families showing actual key entries and more than .05 studs of bar movement, two lap sweeps and visible USB contact illumination. Each final diagnostic must prove the full 101 local parts, 64 underlights, 28 bars, zero pending anchors, completed streaming, one shared update connection, one entry connection and zero restoration failures. The preceding M04 native export is explicitly frozen beside the corrected recovery export.

The final `EffectLifecycle.client.luau` receipt must cover exactly eight ordinary cases: F6 entry, F6 restart, Lobby restoration, ownership-token exit ordering, preview disable/reactivation, candidate removal/restoration, audio cancellation, and supported respawn. Each case must pass. Its `skyProofs` must confirm the six actual Lighting Sky properties and successful loads. These eight cases alone cannot pass closure.

The direct existing-City-Run handoff is separate. Require the identity-bound passing canonical `P3-M04-effects-other-map-handoff-01.json` from `OtherMapHandoff.client.luau` (or a newer numbered final receipt). It must prove `realServerTeleport: true`, `directArchiveHandoff: true`, `expectedLightingAndSkyApplied: true`, and `originalLobbyRestored: true`, with `courseId: "city_run"` and no failed or `not-run` evidence. The tooling freezes both this receipt and its fixture source and records the handoff separately in the final gate.

F6 and respawn unload the existing runtime `RaceCourse` copy. The isolated owned copy used for this case is therefore prepared after F6, offset by +20,000 X to isolate the ambience zones, then tested through supported Start, Lobby and fresh F6 actions. This verifies the real ambience handoff and restoration; it does not prove other-map gameplay. The original course library and saved maps remain the source of the copy.

The native Sky load receipt may carry the actual lifecycle `skyProof`; an unparented typed Sky probe is diagnosis only and does not prove application/restoration. Required proof fields are:

```json
{
  "candidate": "KeyboardCircuit_P3_M04_01",
  "revision": "KC_P3_M04_01",
  "passed": true,
  "skyProof": {
    "passed": true,
    "skyReady": true,
    "skyApplied": true,
    "loaded": 6,
    "failed": 0,
    "orientation": [0, 0, 0],
    "faces": [
      {"property": "SkyboxBk", "configured": "rbxassetid://80816315379134", "actual": "rbxassetid://80816315379134", "fetchStatus": "Success"},
      {"property": "SkyboxDn", "configured": "rbxassetid://96062275999034", "actual": "rbxassetid://96062275999034", "fetchStatus": "Success"},
      {"property": "SkyboxFt", "configured": "rbxassetid://135284146028712", "actual": "rbxassetid://135284146028712", "fetchStatus": "Success"},
      {"property": "SkyboxLf", "configured": "rbxassetid://108685301499016", "actual": "rbxassetid://108685301499016", "fetchStatus": "Success"},
      {"property": "SkyboxRt", "configured": "rbxassetid://127191104998913", "actual": "rbxassetid://127191104998913", "fetchStatus": "Success"},
      {"property": "SkyboxUp", "configured": "rbxassetid://109248728511991", "actual": "rbxassetid://109248728511991", "fetchStatus": "Success"}
    ]
  }
}
```

The asset upload record remains authoritative for actual IDs. The tooling hashes the six uploaded face files, all raw sky assets, the panorama, texture manifest, upload record and `assets/sky/keyboard-archive/native-load-diagnosis-01.json`. The failed bare-string preload evidence remains part of that history.

The actual death fixture must prove death, exact baseline while dead, removal of old effects, automatic respawn and final Lobby restoration. Both complete native route traces must pass their original movement/support checks with two server-confirmed laps, one setup, ten natural gate crossings, eight natural midpoints, no recovery or artificial holds, and unchanged movement tuning.

Native recovery must prove both engine round-trip and fresh source rebuild, no differences/external references/source failures, exact resource counts, and exact native `.rbxm` hash and length. A native failure stops closure. Offline renders must bind the final scene, renderer and sky inputs by hash.

The freeze includes all M04 source/fixture files, both closure scripts, final and failed-attempt M04 evidence, six views, the offline `.blend`, native recovery asset, mesh inputs, brief copy, governing documents and the M02/M03 recovery records. Reviews, final gates/reports and post-review receipts are subsequent outputs and are outside the immutable input list.

## Independent review and final gate

Expected fresh review files are `P3-M04-R1-review-01.json` / `.md`, `R2`, and `R3`. Each reviewer must be `gpt-6.1-sol` with High reasoning, independent, and judge the whole frozen M04 candidate. Each individual score must be at least 8.5 with zero blockers and no required repair. The gate does not average or inherit scores.

Use the existing M02 JSON format, with these exact fields:

- `reviewer`: `R1`, `R2` or `R3`; `model`: `gpt-6.1-sol`; `reasoningEffort`: `high`
- `independent: true`; `wholeOutcomeReview: true` or `wholeCandidate: true`
- M04 candidate and map identity; exact `freezePath`, `freezeSha256`, and `nativeSha256`
- `verifiedFrozenInputs` equal to the full freeze count; `hashOrLengthMismatches: []`
- `overallScore` or `score`; `passed: true`; `blockers: []`; `blockerCount: 0`
- `inheritedScoresUsed: false`; `otherReviewerJudgmentsRead: false`; `candidateMutated: false`

If `agent` IDs are recorded, supply three distinct IDs. A changed frozen input or a newly numbered canonical check requires a new freeze and fresh reviews.

After the reviews, produce:

```
P3-M04-native-post-review-NN.json
P3-M04-native-post-review-source-agreement-NN.json
```

The first must follow the M02 post-review pattern: `passed: true`, M04 identity, `editRunning: false`, `geometryRows`, `sources: 28`, `activeCourses: ["KeyboardCircuit_P3_M04_01"]`, `inertOlderCourses: 16`, owner origin and preserved unrelated counts. Add `sourceFreezeSha256` and `nativeSha256` for the exact reviewed inputs/export. The second must freshly match all 32 exact source rows, resources, geometry count, archive list and unrelated counts from the frozen Edit source agreement.

When every requirement is ready, from the repository root:

```powershell
python tools/keyboard-circuit/phase3/work-m04/FreezeInputs.py --freeze P3-M04-FREEZE-01.json
python tools/keyboard-circuit/phase3/work-m04/FinalizeGate.py --freeze P3-M04-FREEZE-01.json --gate P3-M04-FINAL-GATE-01.json --review-id 01
```

Use fresh numbers for a changed candidate; never replace previous closure records. A local technical pass leaves owner acceptance pending and does not prove FPS, device or multiplayer performance, human pacing, subjective audio, or publication.
