# Bugs

## Egg Rush open-sky correction — W06 C02, October27

Resolved the demonstrated grey-basin composition: omit seven bedplates, 27 deep extensions and nine broad lowland groups; shorten building/garden bases without moving their top seats. Finish Start/CPs and correct checkpoint numeral orientation. An Egg Rush-only staging filter fixes the permanent Start/lap lintel disappearing during countdown cleanup; the gate and barrier behavior remain unchanged. [Current evidence](artifacts/egg-rush-circuit/phase3/sky-pass/STATUS.md).

All three bounded visual reviews are 8.7/10. Final native QA has 907 scenery parts, 2,824 queries and no hits/unresolved warnings. Original geometry/physics/respawns/links remain intact across 626 parts / 1,185 instances, with 25 + 15 explicit appearance exceptions and zero other differences. Actual Countdown→Racing→Lobby and 108 scenery mesh fetches pass. The first lifecycle observer read partial client loading too early; its preparation error remains separate from the successful corrected observer and is not a production missing-course finding. Occupied 3D horizon, full current traversal, arbitrary falls, crowd/device/FPS, whole-place save and owner acceptance remain open.

## Previous Egg Rush quality control — W05 C05, October27

Corrected demonstrated scenery faults: detached facade supports, awnings cutting neighboring sheds, overlapping workshop roofs, exposed same-plane trim joins, an unsupported curved-roof garden, Tray/Rookery building overlap, two Sorting sheds cutting the retained chutes and doubled old/new facade art. The final course-local assembly passes the bounded visual reviews and 3,554 native scenery queries. The original 626 parts / 1,185 instances retain geometry/physics/references; 25 expressly allowed old-art transparency changes are recorded separately from zero other differences. [Current evidence](artifacts/egg-rush-circuit/phase3/qc-pass/QC_STATUS.md).

Open: actual Racing horizon has no usable 3D screenshot. Chrrxs reports no rendered frame during Play even after the owner restored Studio; the alternate Proxy capture shows current race HUD over a blank dark scene. This does not alone establish a production renderer failure. Actual initialized client checks confirm all 196 scenery MeshPart fetch callbacks succeed, ordinary C05 Start support and active/exit atmosphere behavior. A raw-string Edit preload probe produced asset-type mismatch messages; do not treat that probe as an authentication or live MeshPart failure. Full current Normal, arbitrary falling paths, crowd/device performance, whole-place save and Phase3 acceptance remain unverified.

## Historical Egg Rush Phase3 — W03 C02 findings, October26

Phase2 R03/R05 is owner-accepted; Phase3 remains active and unaccepted. Canonical and native `ER_P3_W03_C02` match through Rojo, with 976 new scenery parts, six lights and eight reused A03 mesh templates. Earlier Egg Rush bug entries below retain their original candidate/evidence limits and no longer impose Phase2 approval gates. See the [current course brief](artifacts/egg-rush-circuit/COURSE_BRIEF.md).

Corrected: the rejected W02 C02 composition now has inward fronts, vaulted/setback masses and broad gardens. Review then demonstrated a reachable noncolliding gallery-floor illusion; W03 C02 adds 17 matching solid walls and one floor, with floor/collar/stem below the real Fall top. Current 4,064-query native QA has zero standing/jump/tray/camera/neighbor hits or unresolved ledges, and exact 626-part / 1,185-instance gameplay preservation. Source-shape/native collision checks, rectangle envelopes and blocked raw fall centerlines are bounded evidence, not universal visible-triangle or sideways-fall proof. [Current QA](artifacts/egg-rush-circuit/phase3/current-w03/world-check-w03-c02-final.json).

Still open: final W03 Full Normal R05 and corrected gallery R03 native results are **PENDING**. Normal R04 did not start; its preparation error is not a production race failure. Gallery R02 passed geometry preflight but walked into the existing ReturnHotGrate before jumping, so corrected-driver R03 is pending without another production edit. Focused Nest R03 / Egg Band1 R04 passes and pre-world actual peck R02 do not close full-route proof; the Egg Band1 raw receipt still names W02 C02 and carries an obsolete Nest-method string.

W02 C02's actual-LocalScript atmosphere activation/real Break-lobby exit passes with unchanged global Lighting; W03 repeat is pending. The cold plugin-require flow snapshot error was a test-context failure, not a demonstrated production defect. W02 C02's matched occupied medians (16.4304 / 16.5692 ms) are stationary same-session evidence only. Longer startup stalls, human/crowd/device behavior and FPS gains remain unproved. Final W03 reviews, recovery and verified whole-place save remain **PENDING**.

## Historical Egg Rush chicken R05 — October26

The owner rejected R04's repeated return to one home pose. ER_P2_R05_C01 now keeps the gained target-facing stance, lifts after the strike and leads into the next target with head-led turns and separate foot steps. Current A02 art has a shaped breast/belly, layered wedge feathers, clearer cheeks/eyes and pointed beak. Initial authored foot pose now matches time zero. Focused native contact/clearance/support/restoration checks pass; owner movement/appearance judgment and moving-racer recovery remain pending. [Current handoff](artifacts/egg-rush-circuit/phase2/chicken-r05/FINAL_HANDOFF.md).

## Historical Egg Rush chicken-only R04 — October26

`ER_P2_R04_C02` replaces the swan-like long neck with a fuller short-necked chicken and body-led peck. C01's neighboring-head contacts are corrected by a narrow underside trim and lifted recovery; C02 native art checks record no unintended standing-space overlap across2,646 queries. Foot rays record no missing support, with a disclosed0.01-stud visual tolerance and0.002045-stud maximum gap. All564 non-chicken Part properties/attributes and route references match the prior course, excluding explicit roost support. Human camera/feel and moving-racer recovery remain unproved. [Current chicken handoff](artifacts/egg-rush-circuit/phase2/chicken-r04/FINAL_HANDOFF.md).

## Historical Egg Rush R03 C04 fixes and open proof — October26

Current `ER_P2_R03_C04` replaces the tail with a three-target peck, gives hazards broad red contact silhouettes, moves the Incubator backdrop off the sampled jump corridor and separates the feather swing from peck target1. A separate lap HUD chip and explicit Start recovery frame clarify existing server lap rules. Native C04 passes all15 placed-start progression cases, including two actual Start recoveries, and records visible laps1/2/3. The 607 sampled decor queries are clear; current mechanism waits and fixed-box peck contact checks pass. Moving-racer peck recovery, continuous races and native appearance remain unproved. The reported long Play stall was not reproduced in one warm sample; its cause is still open. [Current handoff](artifacts/egg-rush-circuit/phase2/revision-r03/FINAL_HANDOFF.md).

## Historical Egg Rush R02 critique fixes — October26

Installed `ER_P2_R02_C07` answers the owner's six-image critique. Explicit layouts remove the observed Normal/Expert/checkpoint clashes and redundant tray approach; CP2's outgoing chain no longer offers the identified near-touching bypass. Misleading grass ledges are retired, low nest rims have grounded banks, and the shared shell exit moves clear of the closing-crown intersection found by the native cycle test. C07 geometry/standing checks and the corrected 23-mechanism sample report no corresponding overlap. All four independent reviewers find no remaining demonstrated blocker in scope. Full revised Normal play, natural tray boarding/exits, new hit/recovery and human Expert feel remain open evidence, not old C05 passes. [Current handoff](artifacts/egg-rush-circuit/phase2/revision-r02/FINAL_HANDOFF.md).

## UI live-play findings — October 26

Fixed in the UI overhaul (client display only): results never showed in events (the Next course ticket exists from the start of loading and the results screen treated that as a handover); results then held over the 10 s Event end window; "Race 6 of 5" and the wrong "Next" course once the server had moved on; the last race's ticket sat over the next countdown and over a new vote; long course names cut off on the countdown card; "1 races entered"; dark fringes on the scaled sunburst and plate stripes (black pixels under the images' transparency); a three-stop dark sky gradient drew visible bands on the arrival screen.

Open, not UI (left unchanged): `RaceConfig.ResultsDuration` is 2 s, so the server's Results phase ends during the 3 s finish moment and the results screen relies on its own hold through loading. The Event end window is `GrandArcadeConfig.FinaleSeconds` (10 s) before the next round. In one run the lobby reported "Course or camera delivery was not ready" after a Studio camera override used for inspection; it did not recur in later runs. The loading line "Course loaded · waiting for safe delivery" and "Optional target: Reach checkpoint 1 of 4" after a 1st-place finish come from the race flow, not the views. [UI log](artifacts/ui-overhaul-concepts-2026-10-13/CURRENT_STATE.md).

## Historical Egg Rush C05 arrival resolved — October22

The owner restored Studio asset fetching by signing back in. Current native checks confirm511/511 lobby mesh IDs, fresh structural/hazard loading, actual ordinary lobby/course readiness and complete finish/Break/rejoin flow. The corrected gate requires visible structure despite invisible collision parts; the missing ArrivalAssets dependency is restored. Final Normal/Expert finish three laps with zero falls. [Final closeout](artifacts/egg-rush-circuit/phase2/restart-r01/FINAL_CLOSEOUT.md). Authentication was restored by the owner; no permission, credential or account change was performed by the agent. Owner visual/game-feel review remains pending.

Historical failed attempt before restoration: fresh ordinary Play reached the saved Custom racer's Entering state, then production lobby preload failed. Logs include lobby asset fetch failures and an animation request rejected with authentication required. No ordinary race admission occurred in this attempt. Keep the earlier C03 supported-flow pass separate. Final C05 movement checks use the existing temporary Studio preset/start fixture; they do not clear this entry failure. No authentication or global arrival code was changed. [Current evidence](artifacts/egg-rush-circuit/phase2/restart-r01/STATUS.md).

## Historical Egg Rush concurrent tray exit — October21

Follow-up: Native19 and21 pass conservative role-swapped two-body Receive and full tray-ride/exit sequences using one actual client and a fitted physical clone. NativeTraversal now stops stale steering immediately after recovery. S4 geometry is unchanged; the original primary miss is unexplained/unreproduced. This is bounded physical exit clearance, not20-client/network proof. [Evidence](artifacts/egg-rush-circuit/phase2/restart-r01/EXIT_CLOSEOUT.md). Original failed case follows.

Historical Native11 failure, superseded only within the bounded fixture above: TraySplit completed both actual supported21-stud carries, then failed at receiving-to-first-climb and climb003-to004. Later isolated S4 side lanes pass; there is no corrected concurrent receiving/exit pass. Keep this unresolved rather than treating successful rides or final solo races as traffic clearance. [Retained case](artifacts/egg-rush-circuit/phase2/restart-r01/native-11-c04-focused-derived.json).

## Historical Egg Rush R03 closed-shell contact — October21

The observed R02/R03 head/torso clipping is fixed in the tested standard R15 movement: full visible shell solids plus a course-scoped fitted collider with forward jump-animation clearance. Final native29 closed attempts and native30/31 open laps reported zero Head/torso overlaps. Four bounded closed attempts found no crossing; this is not exhaustive route or all-avatar proof. The conservative unrestricted-turning geometry bound remains inconclusive. The Phase1 T01 timing decision now has actual scripted three-lap finishes174.511sec Expert /306.537sec Normal. The failed Normal late-takeoff trial remains preserved; its exact triggering body part was not captured. An earlier test-only red-hop takeoff completed the retry without changing the hazard/contact rules. Human/crowd pacing remains unverified. [Evidence and limits](artifacts/egg-rush-circuit/phase1/restart-r01/PHASE1_REVIEW.md).

## Historical Egg Rush C14 findings — October21

Actual C14 walking reached four of five selected targets without jumping; C15's larger gaps pass five fresh native samples. Independent review closes the nearby-world composition finding after connected rooms/pipes and grouped banks. C15 Normal finishes5:31.004; Expert3:00.560 remains0.560sec over the strict target. The Studio client Arrival lobby-load error is unresolved evidence for human entry: server presets enabled tests. Human/crowd/device/performance and whole-place Save remain open boundaries. [Final handoff and retained findings](artifacts/egg-rush-circuit/phase3/FINAL_HANDOFF_C15.md).

## Moonlit Citadel closed by owner — October20

The owner accepted Source57 / Build51 and directed that Moonlit Citadel is done. Earlier Moonlit open/pending entries below are historical evidence, not outstanding map work. The missing final moving-render verification remains an evidence limit; no further repair pass is planned without a new request. [Acceptance record](artifacts/moonlit-citadel/phase3/final-surfaces-20261020/OWNER_ACCEPTANCE57.md).

## Moonlit final surface pass — Source57, October20

Both native map copies now contain 138 guarded visual adjustments and 139 Blender mesh substitutions across195 distinct visual parts. The full-scene scan reports zero supported exact overlaps; actual imported faces and fresh full-build/detail-append checks pass. Contacts, hazards,19 arrow shapes, Finish, original floor and12 mist emitters remain exact. Three queryable lantern reliefs and125 nonzero-depth same-part relief cases remain classified. Background Edit and Play captures are blank, so moving-camera visual verification remains open; no blanket no-flashing or fresh art approval is claimed. [Current handoff](artifacts/moonlit-citadel/phase3/final-surfaces-20261020/HANDOFF57.md).

## Moonlit depth interpretation corrected — October20

The owner rejected Source55 removing the floor. Source56 restores the three exact original ER01 meshes in both maps and adds a low feathered horizontal mist veil. The DP01 substitution is removed from future builds. All other1,760 parts per map and the finish fix remain exact. The native Play preview shows the veil over retained ground; construction/source/fresh-assembly checks pass. [Current evidence](artifacts/moonlit-citadel/phase3/veil-20261020/HANDOFF56.md).

## Current Moonlit repair status — Source55, October20

The missed finish is reproduced: a normal root-height160.488 crossing was above the old gate, and a supported edge arrival could be outside its width. Both now finish on their first crossing using a28x12x24 trigger, with the same plane/base/direction. Missing-checkpoint and backward probes remain Racing; the backward fixture does not independently establish checkpoint eligibility. The unchanged ForwardGate source separately preserves its direction guard. Race/checkpoint service source is unchanged.

The measured flashing families now have physical separation across200 decorative parts/184 visible witnesses. The pictured gallery bracket no longer covers the pointed window; the crown's loose foot blocks form a joined apron. Shallow bedrock is replaced by an actual open chasm with deep banks. This supersedes older Moonlit open-status entries below for these specific defects; it is not every-frame/every-camera or performance proof. [Evidence](artifacts/moonlit-citadel/phase3/repair-20261019/REVIEW_PACKET55.md).

## Open — Moonlit Citadel Source 49 covered gallery glass — October 14, 2026

The new `GalleryRearGreatHall` obscures an existing gallery glass window. A fixed-camera visibility test reveals its lower panes when only the new hall is hidden; the upper portion remains masked by other foreground architecture. Restored immediately. Inspect all three similarly placed gallery windows when correcting the final art. This is a confirmed visibility defect for the first window, not a claim that all three were separately isolated. [Original and diagnostic views](artifacts/moonlit-citadel/phase3/closeout-review-20261014/REVIEW.md).

## Moonlit Citadel render verification remains open — October 14, 2026

The former Source 48 triangular cap flashing is absent from Ideation's fresh Source 49 settled crown comparisons, with shadows both on and off. The separate broad floor colour change reported by the original reviewers was not reproduced in these four images, but their requested moving-render check remains unresolved. Static A/B images do not close that temporal concern. [Current evidence and limits](artifacts/moonlit-citadel/phase3/closeout-review-20261014/REVIEW.md).

## Historical — Moonlit Citadel Source 48 surface flashing — October 13, 2026

Source 48 / Build 42 visibly flashes at crown masonry joins after a 0.15-stud camera move, including with GlobalShadows disabled. Two shared assets, `MC_AR_MasonryMass` and `MC_AR_FoundationBay46`, retain coincident top faces in their main stone and differently colored trim. Live measurements identify 41 assemblies with this construction; this is not a claim of 41 separately reproduced visible flashes. All 717 scenery parts have player collision disabled, so changing physics collision settings will not fix these rendered faces.

Correct the shared geometry and inspect its placements, then repeat the saved camera comparison with shadows on and off. No repair was made during this review. [Reproduction, source locations and evidence](artifacts/moonlit-citadel/phase3/enclosure-review-20261013/REVIEW.md).

## Shipwreck Cove missing from Dev Tools — October 9, 2026

Resolved: Model-only discovery skipped the editable Shipwreck Folder in CourseLibrary because its startup conversion only checked Workspace. The loader now accepts the stored Folder and protects its converted template from being archived as its own predecessor. The current editable map stays in `ServerStorage.CourseLibrary`; actual F6 listing, map selection and restart pass. All 1,952 descendants, 1,585 parts, editing groups and interaction properties were preserved.

## 2026-10-03 — Heartwood findings frozen on hold

Heartwood has been archived and removed from the game at the owner's request. Round 2 upper-path completion, free-camera review, foreground performance and device/multiplayer checks were unfinished. These are historical follow-up items, not active tasks or acceptance claims. [Stopped state](../archives/heartwood-ascent/hold-2026-10-03/README.md).

## 2026-10-03 - Heartwood Ascent HA04 completion

The final form pass resolves the repeated receiver bowls, small exposed-top crown and sparse gardens surroundings in reviewed views. Current art is 246,536 triangles. The calm finish passes four zero-jump legs. The real Catch-edge jump returns to Catch without reaching J3 in this one attempt.

Retained failures distinguish physical misses from fixture errors. Wide needs supported edge preparation before the ordinary jump; aiming B1 directly at that edge missed, so its successful centre aim stays. Real Finish contact freezes the avatar before the old three-stud root-centre assertion, and SanctuaryArtwork is legitimate support. The final narrow fixture accepts four studs with exact grounded finish support, Finished and checkpoint 3; no flower geometry or movement change was made.

Human pace/difficulty, owner style, full-route performance, touch controls, devices, networking and multiplayer remain unverified. The compact authored route and efficient scripted steering do not establish target human timing. Current focus-paired stationary samples supply one background and one foreground observation without a matched HA03 foreground baseline.

[Final HA04 evidence](artifacts/heartwood-ascent/v1/FINAL_REPORT.md).

## 2026-10-03 — Heartwood HA03 acceptance limits

The initial colliding sanctuary blocked its finish entrance; corrected entrance petals now pass the full main/shortcut runs. The old XB test aim missed J4; a nearer aim passed without changing gameplay. A Catch-return test expected only the ramp even though the avatar stood on the adjoining Fork_3; its support list was corrected and the physical return passed. All attempts remain in the evidence folder.

Remaining review items: straight bark seams, simpler/sparser crowns, some apparently detached greenery and incomplete surrounding forest compared with A3. Placed art exceeds the working triangle target. Current stationary desktop samples average about 66.7 ms with foreground focus unverified; no 60 FPS or device performance claim is supported. Human shortcut difficulty, touch controls and real multiple occupants remain unverified. [Current limits](artifacts/heartwood-ascent/v1/FINAL_REPORT_HA03_HISTORY.md).

## 2026-10-01 — Long lobby course title clipping resolved

The reference's larger course title clipped Classic Point-to-Point in actual Play. Titles now use the reference size when it fits and shrink longer names inside the available space. All four current course names passed text-fit and format non-overlap checks with larger text at three UI container sizes. See [current HUD verification](artifacts/hud-reference-2026-10-01/final/verification.json).

Track known bugs and regressions here.

## Open

- 2026-09-22: A second automated Play launch stalled in official MCP after a successful first session. Further lifecycle requests reported the start was unfinished; the alternate Chrrxs start remained queued/not_executed. Stop was issued through RunService and Edit mode verified. Save the Studio place before restarting Studio if manual Play also stalls. This prevented extra control checks, not the completed V3 sync/map-switch checks.

No remaining blocker from the 2026-09-08 pre-phase review. Earlier manual-validation items below retain their own status.

## Fixed

- 2026-09-24: Shipwreck Cove SC_MAP_25's `FallZone_Main` had moved from its authored center (-1500, 79, 0) to (-1459.586, 95.063, -23), causing normal jumps to trigger recovery. Restored the editable map's plane relative to `Bounds.CourseOrigin` and locked it against viewport selection; the builder now locks future planes too. In the actual race, a jump peaked at Y=98.53 without recovery, the first dock jump landed, and a deliberate fall caused exactly one recovery. [Evidence](artifacts/shipwreck-cove/fall-zone-fix-2026-09-24.json).

- 2026-09-22 follow-up: removed 112,640 retired map/archive instances from the saved Edit model after verified offline exports. Disabled unconditional Classic Ascent rebuilding. Official MCP Play and Stop then succeeded; the earlier launch stall did not recur in this test, but a specific loading-time improvement was not benchmarked.

- 2026-09-22: Play hid edited V3 and loaded an old inspection snapshot. Retired that startup and promoted visible V3 to the authoritative editable source. A temporary geometry change survived Play and City Run → Classic Ascent → City Run.
- 2026-09-22: Ending an unlimited Studio race could fail to advance the round. Explicit phase termination now breaks the timer loop; verified live.

### Pre-phase review findings — 2026-09-08

Eight tree trunks now have checked solid collision. Removed the identical duplicate Classic Ascent and added rejection of ambiguous course IDs. Exported, verified and removed four historical containers; warm Play acknowledgement improved from 14.433 to 4.644 seconds in one sample per condition. See [cleanup checks and limits](PRE_PHASE_CLEANUP_2026-09-08.md).

### Racers could leave staging, then be teleported back at the starting signal

**Status:** Fixed in Classic Ascent version 3.

Staging now occurs once during Intermission. A protected start pen and exit gate keep racers safe before Racing. The gate opens without moving healthy staged characters again. Verified with free movement, forward collision, escape recovery, queued respawn and transition checks.


### Active racer respawns in lobby after falling

**Status:** Fixed

**Steps to Reproduce:** During `Racing`, fall through `FallZone_Main` far enough for Roblox to kill
the character.

**Expected:** The official racer returns to `RaceCourse.Start` or the latest completed checkpoint.

**Actual:** The character could respawn at the lobby spawn while the race was still active.

**Notes:** Fixed by making `RespawnService` only consume fall cooldown after an actual pivot and by
adding a `Humanoid.Died`/`CharacterAdded` fallback that returns active official racers to their
checkpoint respawn after a void death.

## Template

### Bug Title

**Status:** Open

**Steps to Reproduce:** TBD.

**Expected:** TBD.

**Actual:** TBD.

**Notes:** TBD.
## Classic Ascent v4 — 2026-09-05

- Fixed normal hazard death delays/default-spawn flash by recovering the existing
  live character directly. Unexpected reset/real death still uses Roblox respawn.
- Fixed malformed camp roof, preserved manual sign angles/heights, removed the
  Switchback lava and Skyline red seams, and concealed falling-rock sources.
- Intermission uses the prior on-course staging flow. Lobby return expectations are
  deferred to the upcoming lobby rebuild at the user's request.
- Open validation: human v4 timing, slippery-floor feel, cover effectiveness and
  20-player crowd/performance. No full-course v4 automation was run.

## Classic Ascent v6 - 2026-09-06

- Open: river log idle carry needs manual acceptance. Native physics replaced forced rider teleports, and walking/jumping are possible, but focused automated idle samples showed about 4.6 studs of relative drift for 4.6 studs of log travel. Do not mark the river movement issue fully resolved until standing, walking, jumping and wrap behavior pass in Studio. See [v6 handoff](CLASSIC_ASCENT_V6.md).

## Classic Ascent v7 - 2026-09-06

- Fixed late-arriving river foam discovery after course replacement; moving foam was observed on the client.
- River bank overlap and log density were revised. All 40 logs moved in a server sample. Rider carry remains open: the short automated placement triggered recovery and did not establish standing/walking/jumping acceptance. See [v7 handoff](CLASSIC_ASCENT_V7.md).

## City Run C15 fixes - 2026-09-15

Removed the hidden final post beneath CP09 from the active replacement route, adjusted its finish rise, and separated corner endpoints from the wooden deck surfaces. Originals remain archived. Passing evidence is in [the C15 handoff](artifacts/city-run/c15/C15_HANDOFF.md).

## Shipwreck cave checkpoint SC_CAVE_26 - September 24, 2026

Final shortened cave jumps remain unverified after earlier uphill misses. Studio Play-start timed out and remained in Edit. Side routes, camera clearance and real recovery also need checks. Visual review still flags boxy facets and slab-like wave crests. See [checkpoint](artifacts/shipwreck-cove/revision/review26/HANDOFF.md).

## Shipwreck SC29_CANDIDATE_05 verification gaps

Later C29 evidence supersedes the C26 route/capture limitations above: five R15 geometry chains and ten focused hazard groups pass. C05's grove-entry probe was hit by a coconut before completing the beach. This is not proof of unfairness, but human readability/avoidance and full-course production recovery still need a playtest. Wave server playback is confirmed; client audibility is not. Multiplayer/mobile performance remains separate from any synthetic server-cost profile. See [current review evidence](artifacts/shipwreck-cove/review29/EVIDENCE.md).

## Shipwreck SC31_CANDIDATE_08 — September 27, 2026

Coconut start exclusion and visible shoreline support now have exact-build Studio evidence. The rapid teleported lap probe repeatedly missed Checkpoint 2 on lap three; separate physical re-entry registered it and continuation finished. Normal-play reproduction remains open. Shared crumble fairness with two clients, human expert difficulty, target-device and 20-player performance are unverified. Visual route clutter and pale rock separation remain below the requested polish standard. Three-reviewer 9/10 gate not met. See [handoff](artifacts/shipwreck-cove/review31/HANDOFF.md).

### C09–C10 follow-up

The rapid-drop CP2 miss produced no physics contact event. Normal-speed CP2 approaches passed on all three laps, with all 12 grouped race/recovery checks passing; no production checkpoint change was needed. Two connected clients now verify the shared expert-cap drop/reset and replication. A follower arriving 0.9 seconds later finds the cap absent, so human race fairness remains open. C10 clears 25 extra wreck supports and raises the sails/yards; C09 corrected textured hull/cave separation. Human difficulty and target-device/20-racer performance remain unverified. [Current evidence](artifacts/shipwreck-cove/review31/UPDATE10.md).

## Shipwreck C11 acceptance boundary

Final same-build scores are visual9.0/gameplay8.4/technical8.6. No confirmed C11 collision or gameplay defect was found; the shared disappearing expert cap can disadvantage a follower and requires a continuous human race to judge fairness. Target-device/20-racer profiling and human route/difficulty acceptance remain unavailable. See review31/HANDOFF.md and ACCEPTANCE.md.


## Fixed: Shipwreck ambience hides players' lobby (September 29, 2026)

Reproduced with the real Studio Map/Teleport controls. Shipwreck is now at Start (1417,88,-1066), about 395 studs from LobbySpawnPadMarker. ClassicAscentAmbience activates Shipwreck inside a 750-stud sphere and ShipwreckAmbienceConfig hides Workspace.Lobby. After teleporting back to the lobby (8.61 studs from its marker), all 1,153 lobby parts still have LocalTransparencyModifier=1; the lobby remains intact on the server. This is a visual activation bug, not deletion or missing archives.

Fixed: course ambience now excludes players inside the actual lobby bounding box, padded by 8 studs horizontally and 12 vertically. Arrival screens also suppress course effects. Existing restoration restores visibility, lights, sky and post-effects on return. Eighteen live checks passed across Shipwreck -> lobby -> Shipwreck -> lobby, and all 14 existing ambience transitions passed away from the lobby. The lobby remained visible while the Shipwreck race was active. Separate simultaneous-client verification is not claimed.

## Fixed: lobby panel overlap and unanswered choice guard — October 1, 2026

The old personal race summary could appear underneath the new lobby rail after returning to Lobby during a race. It now yields whenever LobbyUI is visible; the final source passed native client fixture and visual checks.

An unanswered late-choice request could leave the local guard set for the rest of a race. A six-second status/race/request-version check now permits retry if the server never changes the player status. Explicit server return to Lobby also clears the guard. Mock failure/stale-callback checks passed; real network failure behavior remains unverified.

## Grand Arcade follow-up — October 2, 2026

- Completed Ready preparations could reopen the stage presentation after result rebroadcast or arrival attribute changes. The actual controller's native replay/readiness fixture now passes; a false course-readiness gate can still resume delivery.
- The blocked rail/stepped approach is replaced by the approved recoverable C01 connection. Three continuous native center/edge round trips passed with jumping disabled and no intermediate teleports.
- Corrected the imported Style/Gear counter binding, stair sign/bench obstruction and inset plaque/records-frame alignment. Normal E interaction at the corrected Style counter and Keep current look restoration pass. Four sign faces pass native review. LowerJunction Back and StyleStairs Front remain unaccepted because benches obscure the selected camera positions; this does not establish a defect on normal walking routes.
- Podium finisher text exists and fits its measured native canvas, but Edit captures did not show the names reliably. Do not treat that as a confirmed font or clipping defect. Native Play visual verification remains open.
- The misspelled ShoulderAccessory property forced every podium avatar into its fallback. Corrected to ShouldersAccessory; a native exact-service fixture now creates genuine models, retains safe invalid-user fallbacks and excludes stale appearance results.
- Interrupted presentation cleanup could retain an abandoned Scriptable camera. Inside the existing arrival/camera ownership guards, saved Scriptable now returns to Custom. Ten fresh-module cleanup checks and13 full fresh-controller lifecycle/input checks now pass; actual death/respawn, pending resumption and terminal cleanup restore current camera, HUD and normal movement. Synthetic preparation does not prove real map delivery or multiplayer.

### Grand Arcade scoped geometry repair — October 3, 2026

R01–R06 from the explicit repair brief are locally fixed and verified: exposed entrance floor overlap, rail-intersecting planters, tree-engulfed lamps, inward mesh faces, arch/casing/keystone mismatch and unfinished rail terminal joints. Near-stage lantern obstruction was also cleared. Six no-jump crossings and one labelled miniature fallback display passed. Original instances remain recoverable; broader old lobby backlog stays stopped. [Repair evidence and limits](artifacts/grand-arcade-repair-2026-10-03/FINAL_REPAIR_REPORT.md).

## Stud Garden — crowd and performance acceptance open, October 4, 2026

The final bounded20-avatar opening proxy completed14, with3 falls,3 unfinished and3 stalled. Two opening turns are24×24 and the first incoming jump gap is retained; a separate solo opening run passes. The remaining crowd failures are unresolved, and proxy steering/collision pressure are not separated. Confirm with actual20-player opening and whole-route tests before accepting capacity.

Two fixed ten-second solo Quality10 views measured about15FPS, with no NPCs and no camera drift. Hardware and foreground state were not verified; no cause is assigned to Stud Garden and no mobile/lower-end readiness is claimed. [Actual evidence and limits](artifacts/stud-garden/FINAL_BUILD_REPORT.md).

## Stud Garden V2 — open verification, October 4, 2026

K13 fixes the reviewed fork gap, buried bunny, misleading unsupported leaves, root bevel and shop-sign issues. New-family movement and H2 runtime behavior remain unverified because automatic approval review requires explicit permission for temporary Studio test mutations; the owner question is pending. Supported planting may create unintended route shortcuts when integrated and must be checked against actual course progress. Full course/map, twenty-racer flow and device acceptance are still outstanding. [Current state](artifacts/stud-garden-v2/CURRENT_STATE.md).

R305 now supplies the full revised disabled course preview. The original R303 basket-to-finish shortcut candidate and seed-tray rim walkaround were corrected in geometry and re-screened; this is not recorded avatar proof. Grove root recognition remains unresolved in the final visual review and lead judgment: the forms still resemble platforms on stepped supports. Final whole-course scores are 8.3 clarity, 8.4 challenge and 8.6 contact/construction; the requested 8.5 gate is not met. Required real-race integration, normal-control route/contact/hazard/recovery checks, expert reward, twenty-player flow and device performance are still open. The eleven-script native race-controls application remains blocked by its earlier approval rejection; it was not installed or bypassed. [Final quality-pass evidence](artifacts/stud-garden-v2/phase2/round3/ROUND3_REPORT.md).

## Keyboard Circuit Phase 1 — open verification, October 7, 2026

C06 supplies clear Normal/Expert signs and ordinary third-person evidence for the sample. The prior source duplicates are preserved in the approved archive; current Rojo/snapshots are unique and match all thirteen sources. The feedback module bounds preload recovery to one alternate request after failure; fresh C06 canonical loading and playback passed.

The isolated Play capture showed the existing lobby loader's failure overlay. Its cause was not diagnosed, so this is not attributed to Keyboard Circuit or recorded as a whole-game regression. Native playback does not establish the four tonal families; owner listening, normal whole-game arrival, simultaneous followers, twenty racers, touch-device comfort and device performance remain open. [Current evidence and raw overlay](artifacts/keyboard-circuit/phase1/EVIDENCE.md).

### C07 verification follow-up

Larger-key contact, held presses, two-client shared occupancy, new down/up playback and repeated-walking scheduling now have fresh C07 native receipts. The first head fixture was mislabeled accessory-only contact; its raw result is retained and a corrected actual Head/CollisionPart recovery passes. No related gameplay-source defect was found. Existing duplicated client feedback/preview copies remain intact; a controller guard was verified to produce one eight-voice mix.

Owner sound satisfaction, first-time lift edge use, simultaneous mechanism followers/riders, twenty-racer flow, avatar-scale/touch-device comfort and device performance remain open. Current overview/kit images use the live sky and include distant unrelated geometry; they are construction views, not clean final presentation sheets. The unrelated lobby-loader overlay remains undiagnosed. [C07 evidence limits](artifacts/keyboard-circuit/phase1/C07-REVIEW-BRIEF.md).

R3 notes that stopping the runtime leaves the warning plate/frame's last color until a new runtime updates it; stopped geometry and contact motion are reset. This is nonblocking display polish. R5 records a .000122-stud separate-export decode difference on one noncolliding angled decorative bank; playable bank checks hold and no meaningful route shift is indicated. All five C07 reviews pass with no unresolved Phase 1 blocker; these optional findings remain owner-visible in their reports.

## Keyboard Circuit C08 follow-up — October 7, 2026

Fixed the owner's circled doubled legend: original SurfaceGui remained enabled underneath the depressed clone. C08 hides it while held and restores its prior value on release, camera replacement and Stop. Each key now has one character. Native held, warning, camera and cleanup checks passed.

Initial stepping before asynchronous audio preload finishes can be silent: each fresh multiplayer client recorded five misses, followed by warmed playback with zero additional misses/steals. C07 used the same preload/skip pattern; this is not proof of unchanged cold-load speed. Human tonal comfort, all-avatar/device/crowd performance and the earlier unrelated lobby overlay remain open. The installed Stop fixture was corrected because participant diagnostic records intentionally persist; its raw assertion failure is retained and no gameplay source change was made. [Exact evidence and limits](artifacts/keyboard-circuit/phase1/C08-REVIEW-BRIEF.md).


### Keyboard Circuit C08 readiness - October 7, 2026

C08 initial unloaded-hit gap fixed by bounded entry readiness. Fresh solo startup and five actual voices record zero misses; a stalled-clip fixture verifies held visuals, movement restoration and cleanup. Earlier startup misses remain archived; physical devices, network cold-cache and fresh multiplayer readiness are not verified.

## Keyboard Circuit Phase 2 — October 8, 2026

Fixed the CP1-to-O03 departure gap by translating O03 2.5 studs; all twenty-one ordinary joins now pass with verified support. Fixed stopped Leave leaving stale replicated participant diagnostics. Fixed lobby cards covering the isolated course preview, with native Begin/Stop/Restart/Leave restoration checks and phone simulator views.

Two actual local clients now pass simultaneous startup, last-occupant shared-key hold, fallaway following, shared shuttle carry/exit, concurrent respawn and moving-rider restart. These replace the earlier missing two-client evidence for this candidate only. Human difficulty, shortcut savings, three-lap duration, twenty-racer capacity, physical devices and cold network cache remain unmeasured. Five fresh Phase 2 reviews remain pending. [Exact evidence and limits](artifacts/keyboard-circuit/phase2/P2-C01-REVIEW-BRIEF.md).

**Fixed captured H08 foot-clearance defect in I05:** the I04 supported exit approach and grounded RightFoot contact remain recorded. After the owner approved the exact handoff, the -3.25 hinge repair was installed and mirrored into the actual two-client test. Three varied arrivals, four separate clear-window bank holds, a full refuge cycle and a complete continuous normal lap pass without recovery inside those checks. The unchanged bank now has 2.05 studs of clearance above the flat panel. A mixed relocation test contact and two later outside-fixture falls remain unassigned; a subsequent separate 120-second stationary observation passes. [Current evidence and limits](artifacts/keyboard-circuit/phase2/P2-C01-REVIEW-BRIEF.md).

**Open I05 review blockers:** O07 has rectangular turn banks rather than arrow-key forms; O05 bracket marks fall through to default legends. R1/R2/R5 score 8.3 with one blocker each; R3 passes at 8.7. The owner's current full-race targets are normal 240–360 / Expert 120–180 seconds. Efficient normal traversal passes one lap in 139.088 seconds; the Expert attempt fails at H08→H01 with SupportLanding after 122.547 continuous seconds. Both precision branches are slower than their normal alternatives in the unpaired recorded arrivals. A still-rising connector landing was accepted by the fixture, but the exact server blocking hit was not captured. Preserve the failures; ground-readiness fixture and copied-layout repairs require native verification. [Normal receipt](artifacts/keyboard-circuit/phase2/P2-C01-efficient-normal-08.json) · [Expert receipt](artifacts/keyboard-circuit/phase2/P2-C01-efficient-expert-09.json).

**Separate compact prototype, not installed:** Expert12 completes one lap in 129.882 seconds, with both 10/7-cap branches, all required gates and zero recovery. X01/X02 intervals show unpaired savings of 7.134/3.462 seconds, but the 40–60-second Expert share is still missed. Normal12 fails before H01/O08/finish after 117.693 seconds when the test driver loses its expected H08 departure ray support while settling from nearly 16 studs/second; no authoritative recovery appears in that run or the subsequent server capture. The earlier cap-4 readiness latch is reproduced/fixed in the fixture; the earlier H04Contact remains preserved without an exact struck-part attribution. Broader Expert routing awaits the owner's [scope choice](artifacts/keyboard-circuit/phase2/I06-EXPERT-SCOPE-PROPOSAL.md). [Native notes](artifacts/keyboard-circuit/phase2/research/COMPACT-PACING-NATIVE.md).

## Keyboard Circuit I07 corrections — October 8, 2026

The four large circled side recovery banks were optional and visually read as unused route parts. The current isolated candidate omits them and recovers on the marked permanent checkpoints. All 80 recovery positions pass 720 native support rays after correcting the old grid's unsupported/downstream slots. Four actual Fall recoveries on06 pass separately, preserving ordered progress and supported upstream placement.

The opaque Shift parking blocks in Image 5 are replaced with open trays below the walking surface. Big special keys have beveled caps and one visible legend; the shared Enter return arm has no second glyph. The smaller circled O07 entry remains necessary to bridge an approximately 15-stud direct gap.

Full automated timing is corrected on06: Normal5:35 and Expert2:16 across all three laps, with0recoveries/15ordered gates each. Revision02/03's7:01/6:11 failures remain;04 passed time but had an unmarked skip. Revision05 passed both timings but an actual H08-refuge jump reached the finish. Revision06 raises the finish five more studs and all four focused ordinary bypass attempts reject after legitimate checkpoint prerequisites. The interrupted returning-avatar entrance and distant pre-enrollment streaming setup errors remain disclosed; no unrelated onboarding or streaming setting changed. Typical human timing and human-discovered shortcuts remain owner playtest work.

## Keyboard Circuit I08 installation and evidence corrections — October 8, 2026

Native construction moved new geometry after the build call, leaving authored recovery positions unchanged. The first startup failed before valid timing began. A separate post-call alignment now restores the intended origin; fresh startup, both full two-lap races and final Edit placement agree. `work-i08/AlignCandidate.luau` preserves the reproducible correction.

The expanded node spacing exposed the old connector-count formula's insufficient gap allowance. The builder now generates enough necessary banks and checks every gap within 1–4.5 studs. A focused bypass fixture lost its movement binding after a preceding held-press test; reinstalling that fixture yields four actual rejected attempts. These failures remain distinct from the successful continuous races.

R5 caught the I08 motion check writing to an I07 report filename. Its one output-path line is fixed; 14412 samples pass under the I08 filename and the historical I07 receipt is regenerated by its unchanged historical check. Prior freeze/reviews are preserved; final freeze02 records one test-only delta and zero game-source or geometry changes. [Correction receipt](artifacts/keyboard-circuit/phase2/P2-I08-receipt-path-correction-01.json). Human shortcuts, pacing, audio satisfaction and crowd/device/FPS limits remain open for playtesting.

## Keyboard Circuit I09 fixture and evidence boundaries — October 8, 2026

The initial precision fixture used a .9-stud departure inset that exceeded the new small-cap half-width. Its adaptive inset now stays inside the actual contact. A first experience-preserving draft offered too little observed local reward and is retained as rejected history; the current two cuts each bypass two encounters while keeping six moving mechanisms. A subsequent automated Domino run arrived near the front edge of a permanent wait bank. The current fixture waits for the visible opening and centers on permanent passage banks; the final arrival stop radius is smaller than its tolerance. These fixture corrections do not change main-route geometry, hazard tuning or movement settings. Failed attempts are preserved separately from passing race evidence.

Fresh rendered screenshots cannot be obtained while Studio is minimized. Native properties, contact/support rays, current source and an authored-coordinate route schematic remain available. No focus, camera, keyboard or mouse automation is authorized. Human difficulty, typical pace, subjective audio, exhaustive shortcuts, twenty-racer and device/FPS proof remain open.

## Keyboard Circuit I09 candidate03 resolved sign failures — October 8, 2026

Candidate02 R1/R4 sign blockers are resolved in03:24 native label contrast checks have minimum5.216:1, and80 bank-center/recovery-position target records ×5 text-region points show zero sign-to-sign occlusion. This does not prove full scenery visibility or human camera readability. Previous failed judgments remain in history.

The initial03 source-byte agreement did not match two global Rojo rows. Current source readback matches durable text after newline normalization; both files are normalized to LF without gameplay text changes. Initial failed/stale agreements are retained; fresh Edit inspection matches all19 current sources against41 frozen inputs. Native serialization/reopening and fresh-source rebuilding compare text ink as well as geometry, typed attributes, internal references and source bytes. Human difficulty/pacing/audio, exhaustive shortcuts,20-racer/mobile/FPS checks remain open.

## Keyboard Circuit Phase 3 M01 placement and artwork checks — October 8, 2026

Resolved stale absolute recovery/traversal attributes after the owner moved the accepted course by `(-20278,0,442)`. M01 retains the owner's physical placement and every gameplay part pose exactly, while correcting only documented world attributes/markers. Rebuilding directly at the smaller origin initially changed tangent precision orientations; canonical generation followed by translation resolves that drift. Both original and moved P2 recovery files remain available.

During artwork preparation, five planned underside plates entered lower-level headroom and were omitted. The Creamy rack and Thocky magazine were moved outward to clear route/camera space; drawer fronts were lowered to expose the inventory, and both district-case sides were finished. Final621-part scenery passes body, complete authored motion and geometric visibility checks. Early artwork receipts remain history.

Close native Client capture timed out on the connected Edit peer with not_executed status. Final views are labeled offline reconstructions; native GUI/material response, human readability/audio/difficulty, typical pace, exhaustive shortcut resistance and real crowd/device/FPS outcomes remain unverified. [Current evidence](artifacts/keyboard-circuit/phase3/P3-M01-REVIEW-BRIEF-01.md).

Resolved an audit coverage error found by R3 during Phase3 review: EnterTurn selected O02 instead of actual O04 and produced a zero-point row. The corrected native audit explicitly checks both O04/O08, both tops with five targets each, and rejects empty/missing turns. All20 real Enter rays pass; total visibility2163rays. Freeze02 supersedes01 for every final review; map/gameplay/global source, native geometry and race/focused evidence are unchanged. Old frozen inputs and the provisional R1 report are recoverable in history. [Correction and exact prior hashes](artifacts/keyboard-circuit/phase3/P3-M01-enter-coverage-correction-02.json).


## Keyboard Circuit M02 visual corrections — October 9, 2026

Resolved: malformed lap HUD separator; two-line ASCII progress fits native 205/320px panels. Resolved: O05 arm banks duplicated sixteen cap positions over main grids; two-cell aligned extensions have zero cap intersections and native supported walking/held release. Resolved: lift/shuttle warnings could retain a phase during Stop; reset now refreshes after stopped/window attributes, and all seventeen native displays stop/resume correctly.

Native Play startup and teardown reported timeouts; the running session subsequently completed the focused lift test, and final status confirms Edit only. No underlying unrelated shutdown-hook repair was added. Smaller secondary sign text and human mobile/world readability remain nonblocking playtest limits. [Frozen M02 packet](artifacts/keyboard-circuit/phase3/P3-M02-REVIEW-BRIEF-01.md).

## Keyboard Circuit M04 sky and effects — October 9, 2026

The physical Archive enclosure was an incorrect interpretation of the selected skybox. M04 uses six actual Sky textures; M03 and its sources/native export remain recoverable and inactive.

Bare asset-string preloading failed. Preloading an owned, unparented Sky now reports six successful loads before applying the actual face properties, with no remaining task or probe. Lighting ownership and preview refresh guards prevent an obsolete run from applying or restoring the current profile. An earlier mixed hot-swapped runtime failure remains preserved; its writer was not conclusively identified. All eight lifecycle cases and actual death/respawn pass in the final clean saved-source session.

Late-streamed scenery originally left only 75 of 101 client decorations after returning from another map. Bounded reconciliation of 97 named anchors now fills the pool without duplicates, and trace targets resolve when used. A real City Run ambience handoff and fresh F6 return prove the full 101-part pool. Native visible sky seams/camera directions remain unverified because passive capture is unavailable while Studio is minimized. [Final M04 review evidence](artifacts/keyboard-circuit/phase3/P3-M04-REVIEW-BRIEF-01.md).
# Keyboard Circuit M05 — October 9, 2026

Resolved: moving the native M04 model had left world-position attributes at the old location. The standard-course adapter now aligns route/recovery/motion metadata to the actual F00 bank without moving existing parts. All nine start/checkpoint poses are supported, and eight staged native falls recover correctly.

Resolved: the active map used separate prototype race logic/UI and seven-checkpoint signs. M05 uses shared progression/HUD and eight-checkpoint signs. Passive native screenshot capture remains unavailable while Studio is minimized; final visible brightness/sky acceptance is an owner playtest observation.

# Keyboard Circuit M06 — October 9, 2026

Resolved: the M05 shared-course handoff made R1/R3 mandatory, but Expert precision routes could bypass the narrow bank triggers and prevent completion. Twenty-five standard alternate triggers now cover the actual Expert pads, use the same ordered checkpoint, and copy permanent-bank recovery metadata. Core shared validation and physical routes are unchanged.

Both original misses reproduce in the regression test; Normal, Expert and mixed routes each finish two laps after repair. Native Expert contact/jump testing registers both midpoints and reaches the shared Finished status. [Current evidence](artifacts/keyboard-circuit/phase3/P3-M06-REVIEW-BRIEF-01.md).

## Moonlit Citadel R05 sample findings — October 10, 2026

Resolved in the saved sample: repeated character positioning prevented ordinary car exit; floor velocity now supports normal walking. The folded upper catch return blocked headroom and is replaced by an open side route. Reversed rough lantern orientation, a CP03 wait under the rising ramp and an early receiving-landing obstruction are corrected. Original/replaced geometry and failed evidence remain recoverable.

Open: native stone/window finish is flatter than selected references; pale Expert steps need owner critique. Directed Normal rough completion in73.895 seconds is a concrete warning against the4–6/2–3-minute targets. Original Studio Play automation stalled; the separate local fixture works, without claiming an unrelated automation repair. Full rough branches/catches, avatars, human audio/navigation and device/20-player acceptance remain unverified. A temporary saved-file attribute override replaced embedded candidate attributes; it was removed, and the final file readback passes. [Review and handoff](artifacts/moonlit-citadel/phase1/MC_BL01_R05_FINAL_REPORT.md).

## Moonlit Citadel BL02 R04 findings — October 10, 2026

Resolved: rough E1 rising contacts obstructed gallery headroom/rest pads. Seventeen finite flat contacts and clear landings now pass complete Expert/mixed traversal. Both actual catches and continuous returns pass. Historical failed geometry/probes remain. Two narrow support-expectation corrections accept only the receiving GalleryJoin or same-segment rest landing within the expected footprint/height; grounded and zero-recovery guards remain.

Resolved: standalone daylight could start before its Controllers folder copied. Bounded WaitForChild is durable in isolated.project.json; fresh startup console is empty and saved source matches.

Improved: broader dark window lead/amber regions, structural joins and supported Expert corbels/cues. Native surfaces remain flatter/coarser than references. Human appearance/audio/navigation, avatar range and actual20-player performance are unverified. Directed73–84s runs warn against race-duration goals. Original Play automation's prior stall is not claimed repaired. [Current report](artifacts/moonlit-citadel/phase1/MC_BL02_R04_FINAL_REPORT.md).

## Moonlit Citadel Phase 2 FinalB — October 11, 2026

Resolved: collidable racers/accessories could become false carry obstacles or hazard padding. Focused server carry/body-contact handling passes adjacent-rider cycles and genuine wall/ceiling/hazard checks. Exact server/client support disagreements remain recorded; strict actual owning-client observations are checked separately.

Resolved: counterweight contacts could supply unintended support. All four weights are visual/noncolliding; physical native observations record no weight support. Accepted art, deck/rail geometry and all 432 walkable contacts are unchanged.

Retained failures: first fresh Expert run hits a real LanternCage after CP1/2; a distinct arrival-phase completion does not erase it. Earlier racer collision, observer/setup failures and Reset01's one-stud idle server/client mismatch remain failed evidence. Reset02 completes the full cycle with both strict client traces and all 252 paired comparisons within bounds; the mismatch does not recur.

Remaining human checks: pacing/branch reward, edge-strafe difficulty, camera/audio comfort, avatar range, physical-device controls/FPS and actual twenty-racer boarding/traffic. Native tests use two actual clients; static twenty-body occupancy is separate. Future Phase 3 walls must retain the upper catch-return opening overlapping the keep reserve's east edge. No unresolved concrete Creator technical review blocker. [Evidence and limits](artifacts/moonlit-citadel/phase2/MC_P2_C01_R04_FINAL_REPORT.md).

## Moonlit Citadel R05 visual repairs — October11,2026

Ideation's V01 competing red/casing faces, V02 coplanar floor joins and V03 eleven intrusive decorative pier placements reopened FinalB. R05 retains all gameplay contacts and shared Runtime/Layout while separating decorative floor faces, insetting red rendering and trimming only the intrusive pier art. Final native checks reproduce prior18 intrusion pairs then find zero; all286 flat skins remain with zero coplanar horizontal face pairs and maximum0.072004408stud art/contact offset. Native daylight crown/catch/boarding/red/join views are saved; the same three Creator judges PASS independently with zero concrete blockers.

Retained setup failures: server wait for client-local ArrivalOpen, a client reading the previous failure before replication cleared it, and RedBody01 after automatic next-race transition. None started its intended traversal/body contact. Fresh EEE03 finishes the real shared race with zero falls; RedBody02 produces one actual shared recovery. Original failed diagnostics and the temporary test-source final-LF extraction mismatch remain preserved.

Preservation precision is explicit:486 physical/query/touch and432 walkable properties are canonically equal, with44 raw near-axis rotation normalizations at most8.742277657e-8, two inherited stored-pivot materializations and11 additional codec-equivalent raw pivot representations. All raw observations remain. Ideation also accepts the technical scope; human/crowd/device/ownerPhase2 checks remain separate. [Exact repairs and evidence](artifacts/moonlit-citadel/phase2/MC_P2_C01_R05_FINAL_REPORT.md).

## Moonlit Citadel R06 owner revision — October 11, 2026

Owner rejected R05: supporting sections were short/easy, Expert choices and Image4 direction were unclear, and scenery obstructed jumps/camera space. Preserve the praised signatures and accepted Phase1 assets. R06 adds real gaps, precision branches and58 red contacts; three combined choice boards remain. All eight current native route combinations, both catch returns and focused reset/contact checks pass; the three independent scores are8.6/10. Owner acceptance remains pending.

Retain failed raw runs. First SharedArches approach hit an overhead original red contact; the current approach moves away. A later crown recovery with old±2.4 hurdle goals was intermittent; current±3.6 goals add body clearance while hazard footprints remain unchanged. Do not recast failures as passes.

Root opened too many diagnostic Studio copies. The owner showed memory pressure and required Obby Tournament only. Six root-created copies are closed; no new Studio copies. R06 is installed in Original and owner R05 is archived intact.

Historical Original setup failed during client lobby preload and first-frame Finish replication; failed originals remain preserved. After the owner restart/re-login, the cue09 actual client is Ready with ArrivalOpen=false. No production arrival code changed.

Resolved: Play retained the editable Moonlit course beside RaceCourse, producing duplicate colliders. The reviewed CourseService editing handoff follows the existing authoring pattern and leaves Edit geometry intact on Stop. Fresh strict floor checks pass. CP4 direction now has three nonphysical common-landing arrows, with no new board/caption/light. Full current course-focused results and all three final8.6/10 scores are complete; all owned native test windows are closed. [Current target](artifacts/moonlit-citadel/phase2/revision06/REVIEW_TARGET.md).

Later owner feedback rejects cue09's86arrows. Guidance11 resolves the clutter with seven meaningful fork arrows and zero floor captions, retaining three boards. Independent saved-property checks clear all84arrow corners and292trim corners inside their playable pads, with physics/pivots/reference preservation. Current1503parts/sixGUIs removes244decorativeParts/sevenGUIs.

Cue09 EEN failed after six completed routes: Crown Step_2_3 hurdle launch had backward test-input momentum and landed close to red. Exact contacted red/limb was not retained. Failed native/Suite/Trial/Airborne are preserved; bounded supported braking is added only to diagnostic tools04. Fresh guidance11 full-eight/catch/two-client/cleanup evidence and scores remain pending; no geometry or hazard/profile/finish guard was relaxed for this failure.

## Moonlit Citadel R06 artificial overhead protection limitation — October 11, 2026

A temporary test ceiling stopped one actual R15 rider, caused ejection and ordinary shared fall recovery; the other rider remained unaffected. The lift recorded no blocked-carry detection. Its clearance box includes the root and currently collidable body parts, while this avatar had all fifteen visible body parts noncollidable. This failed protection case remains open and deducted from the runtime score. No authored route ceiling failure is established; production runtime code and failed evidence remain unchanged. [Independent diagnosis](artifacts/moonlit-citadel/phase2/revision06/review_runtime/FOCUSED_NATIVE2_FAILURE01_REVIEW.md).

## Moonlit Citadel R07 owner correction — October12,2026

R06 was owner-rejected; earlier technical scores do not establish acceptance. R07 resolves its red under-gap/shaft collectors, broad supporting-island pattern, misleading E1/E3 arrows, first-landing sign occlusion and easy direct CP4 boarding cut. Existing invisible falling recovery is retained and separately proven. Final brace tiers are staggered, with actual supported traversal in both bays resolving the roof/contact failure.

Remaining limits: pale purple arrows have modest contrast; two local Normal gallery corner cuts and a skilled moving-rail phase cut remain possible. No continuous final Expert finish, human navigation/difficulty/pacing, real20-player or device FPS proof. Historical artificial overhead-protection failure remains open and Runtime unchanged. All three current scoped scores exceed8.5; owner acceptance is open. [R07 evidence](artifacts/moonlit-citadel/phase2/MC_P2_C01_R07_FINAL_HANDOFF.md).


## Moonlit Citadel P3 repairs and remaining limits — October12,2026

[Final evidence](artifacts/moonlit-citadel/phase3/drafts/FINAL_REVIEW_PACKET.md): repaired lower-lift/CP04 pocket interference, gate contact, upper equal-height crossing/red intrusion/walking bypass and CP01 return-pocket interference. Upper catch contact/skins are60×12; final whole directed routes and focused catch returns pass. Original invisible falling recovery stays separate from21 on-course reds. Actual night restoration/reentry/death/respawn and cleanup are saved.

Remaining review/owner checks: finite south/diagonal Arch catch coverage; source-only possible small opening shortcut across several supports; tight Expert landing margins; repetitive Normal gap stretches; unrendered return/merge/lift marker metadata and competing remote silhouettes. Directed Expert3:14.681 exceeds the nominal three-minute target by14.681s. These are not reported as human pacing, difficulty or camera results. Real20-racer boarding/merges, avatar/device/FPS and owner acceptance remain open. Retained failed/prototype records are not overwritten or relabelled as final passes.


## Moonlit P3 revision08 unresolved assembly — October12,2026

Same art judge identifies one material blocker: Cloister gables/vault ribs are offset14studs from a single frontage and their opposite ends appear unsupported in native day/night views. Grounded supports currently end at the deck. A bounded join/support repair is in progress; Crown destination and Gate/West context findings are closed by actual08 geometry.

The approach08 fixture selection was invalid for its ending assertion: it uses the no-progress focus guard across two real checkpoints. Preserve raw FAILED; it is completed physical traversal evidence only. No production bug or passing test is inferred. Human catch fairness, crowd/device/FPS and owner acceptance remain open.

## Moonlit P3 Source09 assembly closure — October12,2026

The prior08 unsupported Cloister roof/rib finding is resolved by twelve connected native support axes; eight accepted piers were added and seven existing units adjusted outside unchanged route/view guards. Six real09 day/night views show the joins. The same art judge closes at8.7; allfive final scores exceed8.5 with no material blockers. Earlier7.4/8.2 rejections and failed traces remain preserved.

Human first-time navigation, repetitive Normal rhythm/long final interval, Expert directed3:14.681, small opening cut, finite south/diagonal catch coverage and tight receiving margins remain disclosed. Owner acceptance,20-racer behavior,avatar/device/FPS remain open. [Handoff09](artifacts/moonlit-citadel/phase3/MC_P3_M01_R01_FINAL_HANDOFF09.md).

## Moonlit Citadel Source30 owner-rework closure — October 13, 2026

The owner rejected Source09/Build8; its preceding review claims are historical. Source30/Build24 closes the five pictured gate/shared/machinery/upper relationships through layout, exposes Normal, retires the rejected wall and completes the world/night. The same five current High judges identify no material blocker in their respective scopes.

Resolved during this rework: mirrored opposite-face direction glyphs, upper arrival board occlusion, detached foundation feet, late Expert near-neighbor shortcuts, and the real Shared3-to-early-Normal connection. Source29's Failed shortcut record actually reached the target/centre before later recovery; it remains a confirmed cut. Moving Step3 two studs outward/half a stud down makes the repeated30 trajectory reset without target support; legal fulls still pass. Source28 accessory-touch early anchoring is resolved using the existing directed finish gate, retaining strict actual-body guards and negative order/direction checks.

Remaining nonblocking deductions/limits: possible untested FinalRiseRail/MergeNeedle-to-SouthCloister merge cuts; Bay1's partly clipped board; Step2's limited landing-top view; repeated tall piers, sparse outward views, faint/unestablished night ridge and plain crown floor. The historical artificial overhead-protection failure is unchanged and disclosed; no authored current ceiling failure is established. Earlier inconclusive probes, failed captures and failed exports remain historical rather than passing proof.

Directed gallery Expert movement after removing waits is0.034s slower in current fulls and0.116s slower in the controlled historical pair, despite15.1% total timed-encounter saving at that near-matched initial phase. Full8.68% saving includes unequal lift waits. Human near-impossible difficulty/fun,4–6/2–3-minute targets, camera/audio, avatars, actual20-racer traffic and device/FPS remain unvalidated. [Current handoff and bounded evidence](artifacts/moonlit-citadel/phase3/rework-20261012/FINAL_HANDOFF_SOURCE30.md).


## Race-flow integration findings — October 14, 2026

Resolved: City Run client readiness ray selected a noncolliding start marker; lobby readiness blocked My Racer; early results publication consumed automatic finish choices; resolved inactivity retained a keep-racing prompt; distant streamed racers could not be watched; inactive watching sent an unintended withdrawal during character reset. Focused checks and native follow/death regression are recorded in the [race-flow report](artifacts/game-flow-study-2026-10-02/REPORT.md).

Open verification: continuous human sessions, physical device/controller/touch and native keyboard panel navigation. Studio VirtualInput blocks Tab/Escape; emulator checks prove containment only. Current catalog has four eligible courses, so the five-course native gate is pending. Earlier failed probes remain diagnostics. Practice course authoring is deferred by the owner.

## Fixed: blank next-course ticket — October 20, 2026

The old course-delivery ticket drew its panel over its own labels (global layering in a new ScreenGui), so it looked blank. The rebuilt ticket (`NextCourseView`) uses sibling layering. Not yet re-checked in Play.
