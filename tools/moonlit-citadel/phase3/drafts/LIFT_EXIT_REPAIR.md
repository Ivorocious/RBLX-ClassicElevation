# CP04 recovery floor repair

Implementation helper report, October 12, 2026. Source inspection and calculations only; this is not a final judge or native playtest result. No Studio access or source edits were performed by this helper. Root integrated the proposed change while the source check was being prepared.

## Diagnosis

The saved `MC_P3_NNN_continuous03_fail.json` shows a real ceiling at the lower lift. The old CP04 recovery floor was at `(112,106,-66)`, size `30x1x22`, with its top at 106 and underside at 105. Its footprint was X97..127, Z-77..-55. The lower cars occupy X96..110 and X114..128, Z-75..-63, while rising from top72 to106. The old recovery floor covered both cars' standing space.

The actual Bay1 rider remained near local X102.992/Z-64.994. At 187.834 seconds, rootY102.679 and deckTop99.372 still produced actual deck contact. By 188.035 seconds rootY barely changed to102.701, while deckTop rose to100.734. The failure snapshot at188.201 seconds shows rootY102.582, downward velocityY-6.518 and FloorMaterial Air, with no falls, deaths or replacement and official CP3 retained. Head centerY104.161 plus its approximately0.637 half-height places its top near104.798, immediately beneath the floor underside105. This agrees with a rider blocked by the recovery floor while the car continues upward.

The ordinary standing root height is approximately3.181 above support. Approximately4.76 is feet-to-Head center, not the head's top; the latter is approximately5.40. The source check below reserves7 studs above each recovery slot and4.5 studs across its full body envelope.

`TestClient.luau:455` requires `contact() == deck` on every ride sample. `contact()` first rejects FloorMaterial Air, so a transient floor-state delay could fail this strict harness in another situation. Here the fixed ceiling overlap and stalled body position independently explain the failure. Keep the exact-support requirement unchanged; do not mask this by accepting a different floor, carrying the avatar, adding an exit teleport or changing the ride height.

## Exact patch

Only `src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/Layout.luau` requires this change:

```diff
-local cp04 = checkpoint("Lifts", "CP04", v(112, 106, -86), v(48, 2, 18), 4, v(112, 106, -66))
+local cp04 = checkpoint("Lifts", "CP04", v(112, 106, -86), v(48, 2, 18), 4, v(112, 106, -86))
 for index = 1, 4 do
  local name = string.format("CP%02d", index)
  local data = Layout[name]
- data.pocketSupport = surface("RecoveryPockets", name .. "Pocket", data.pocket, v(30, 1, 22), "SafeRefuge").path
- data.respawnArea = v(30, 0, 22)
+ local depth = if index == 4 then 14 else 22
+ data.pocketSupport = surface("RecoveryPockets", name .. "Pocket", data.pocket, v(30, 1, depth), "SafeRefuge").path
+ data.respawnArea = v(30, 0, depth)
 end
```

The new CP04 recovery floor occupies X97..127, Y105..106, Z-93..-79. It is wholly contained inside the unchanged CP04 terrace, X88..136, Y104..106, Z-95..-77. Therefore it adds no new collision volume, shortcut or connector. The full48x18 terrace remains available for waiting, passing and branch decisions. The lower and upper deck footprints are each4 studs away in Z from the recovery floor. The UpperFrontWall's nearest edge is1.75 studs north of the recovery floor; the actual spawn bodies have more room than this floor-edge measurement.

Changing depth alone would leave the old pocket over the lift. Moving the full22-depth pocket onto CP04 would extend through the UpperFrontWall. Both relocation and CP04-only depth14 are required. A west-side30x22 relocation was rejected because it overlaps either the mirrored first raised brace or the lower outboard counterweight, and its connection would need more geometry.

## Source verification

`LIFT_EXIT_REPAIR_CHECK.luau` loads the actual production modules and evaluates the old and repaired recipes in memory. When run after root integrated the repair, it reconstructs only these exact old pocket statements in memory. It never writes production source, edits Studio or starts a game.

Checked integrated Layout SHA-256: `3d3107dcca3f593445dd2152119caae52cc3ac14af7d0de52c0345e8f630f4cd`.

- Only `RecoveryPockets/CP04Pocket` differs among generated surfaces.
- All16 route/bay variants and both catch routes are unchanged, including the existing Normal corner commitment and mirrored Expert upper rides/exits.
- All167 WorldPlan placements and their counts are unchanged. The new pocket is inside already-protected CP04 floor space; no new scenery footprint is introduced.
- The existing Coverage and CheckpointService formula yields `7 columns x 3 rows = 21` supported respawn positions, retaining at least20 positions. Other pockets keep their existing30x22 areas.
- Slot centers occupy X98.5..125.5, Z-90.5..-81.5. With2.25 studs of body allowance on every horizontal side and7 studs upward, their combined body bounds are X96.25..127.75, Y106..113, Z-92.75..-79.25.
- All29 checks against the UpperFrontWall, both lower and upper deck-body sweeps, all four outboard weight reserves, and every original/mirrored upper brace and exit floor are clear.
- Lift origins,14-second cycles,2-second dwells,7-second second-bay offset and34-stud vertical travel are unchanged. No ride or checkpoint signatures were changed.

The existing generic clearance checker skips RecoveryPockets in its floor/body comparisons (`clearance_check.luau:125`), and its lift sweep volumes are checked against art rather than fixed floor contacts. This explains the missed case; the narrow check above covers the repaired pocket directly without weakening that checker or the native ride harness.

## Focused native validation for root

1. Rebuild the candidate from this source and confirm the installed CP04 recovery floor is30x1x14 at local `(112,106,-86)`, with `RespawnAreaSize=(30,0,14)` and all four lift signatures unchanged.
2. Run one focused actual Lower Bay1 ride from CP03 through the same boarding and exit path. Require real deck support through local top103.6 or above, then the ordinary jump to CP04 and official CP4. Confirm the rider's root continues rising through the old stall height near102.7, with no falls, deaths, recovery, character replacement or carry blocker. Preserve the strict support assertion.
3. Run the already-planned uninterrupted NNN and EEE proofs to cover both required lift stages and ordered official checkpoints. A failure in a different section should be diagnosed separately.
4. Confirm an actual CP04 recovery lands on the repaired supported grid and can walk across the existing terrace to either branch. The21-position source capacity is not proof of actual20-player traffic or comfort.

Native physics,20-player throughput, human pacing and owner acceptance remain unverified by this source-only report.
