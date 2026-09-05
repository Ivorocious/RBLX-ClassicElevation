# Playtest Notes

Record manual Studio playtest findings here.

## MVP Manual Checklist

Use this checklist for the current MVP race loop before moving into larger feature phases.

- [X] One-player race loop: join, queue, countdown, start, finish, results, reset.
- [X] Two-player race loop: both players queue, start together, finish order is correct.
- [X] Checkpoint order enforcement: touching a later checkpoint early does not advance progress.
- [X] Early finish blocked: finish cannot be recorded before all checkpoints are complete.
- [X] Finish result locking: repeated finish touches and post-finish status changes do not overwrite placement or finish time.
- [X] Fall before checkpoint: official racer respawns at `RaceCourse.Start` and fall count increments once per cooldown.
- [X] Fall after checkpoint: official racer respawns at latest completed checkpoint and fall count increments once per cooldown.
- [X] DNF on timer end: unfinished official racers are marked DNF without overwriting finished racers.
- [X] Late join spectate: player joining during Racing can choose Spectate and remains unofficial.
- [X] Late join race late: player joining during Racing can choose Race Late and cannot affect official results.
- [X] Finished player spectate: finished result stays locked after choosing Spectate.
- [X] Finished player ghost race: finished result stays locked after choosing Ghost Race.
- [X] Ghost non-collision: GhostRacing player does not block official racers or other ghosts.
- [X] Ghost world collision: GhostRacing player still collides with course/platform parts.
- [X] Reset to lobby: Finished, DNF, Spectating, LateRacing, GhostRacing, and Lobby players return to lobby during reset.
- [X] UI visibility: RaceHUD, ResultsUI, PersonalSummaryUI, LateJoinUI, and FinishedOptionsUI appear only in expected states.
- [X] Dev controls Studio-only: `DevRaceControls` appears only in Studio and `RequestDevRaceState` is ignored outside Studio.
- [X] Player leaving mid-race: active official racer who leaves is marked DNF with reason `Left race`.
- [X] Player joining mid-race: new player remains unofficial unless they choose Race Late, and still cannot affect official results.

## Phase 8B Course Expansion Checklist

Use this checklist to tune the expanded six-checkpoint MVP graybox course.

- [X] New player completion time: target 2:30-3:00; does not matter right now.
- [X] Practiced player completion time: target 1:00-1:30; 57 seconds (I am highly experienced).
- [X] Average falls per run: 1
- [X] Checkpoint_001 spacing and warm-up section feedback: Was impossible, Manually Adjusted
- [X] Checkpoint_002 staggered platform section feedback: Was impossible, Manually Adjusted
- [X] Checkpoint_003 narrow bridge / precision section feedback: Was impossible, Manually Adjusted
- [X] Checkpoint_004 elevation climb section feedback: Was impossible, Manually Adjusted
- [X] Checkpoint_005 rhythm/gap section feedback: Was impossible, Manually Adjusted
- [X] Checkpoint_006 final mixed challenge feedback: Was impossible, Manually Adjusted
- [X] Confusing sections: None
- [X] Too easy sections: Everything is too easy but it does not matter since the purpose is to visualize a 1 minute map
- [X] Too hard sections: It was literally impossible before I manually adjusted the course
- [X] Checkpoint spacing feedback: Excellent, honestly.
- [X] 2-6 player crowding feedback: Not done yet, but it does not matter yet (I will only do this once I create a shippable course)
- [X] FallZone_Main coverage after expansion: Great
- [X] Finish readability and final approach feedback: Fine, could be better

## Sessions

### 2026-09-05 Classic Ascent Point-to-Point

**Build:** codex/classic-ascent-point-to-point; Rojo CLI/plugin 7.7.0.

**Verified:** New course hierarchy has ten sections, 100 obstacle platforms,
nineteen checkpoints, twenty local fall zones, and one general catch. CourseService
validation returned no warnings. All three older library models remain present.

**Solo physics smoke:** `tests/studio/ClassicAscentSmoke.luau` passed ten checks.
Out-of-order checkpoints and an early Finish touch were rejected. A local fall
returned the player to Start and counted once after two handler rebinds. A
server-controlled Humanoid then physically walked and jumped all 120 route
transitions in 148.43 seconds without an additional fall, recorded nineteen
checkpoint splits, and finished officially. The solo round ended early and kept
the finish time locked. The intentional pre-run fall is not part of the route
traversal measurement.

**Next-round recovery smoke:** `tests/studio/ClassicAscentRecovery.luau` passed
eight checks: progress/falls reset; checkpoints recorded once; elevated recovery
returned to checkpoint 8 facing the outgoing leg; nested arbitrary zone names
were discovered and recovered once after repeated rebind; general catch/Y fallback
recovered once; and a remaining official racer kept the round active. Runtime
test scripts and the extra test zone were discarded by stopping Play.

**Evidence boundary:** This is an automated traversal, not a human timing or
retention test. The 2:30-3:15 skilled, 4-6 minute typical, and 6-8 minute beginner
targets remain unvalidated. Touch controls, 2-6 player crowding, and actual
multi-client first-finisher/last-departure behavior still require playtesting.

**Tooling:** Rojo 7.7.0 build and Git whitespace checks pass. Global Rojo remains
7.6.1; use the project-local command documented in README. No publishing performed.

### 2026-05-30 LapBased Race Validation

**Build/Commit:** TBD.

**What Was Tested:** Repository implementation and Studio hierarchy inspection for the first
LapBased validation pass. A simple technical `Course_ClassicCircuit` model was created in
`ServerStorage.CourseLibrary` for smoke testing.

**Findings:** LapBased races now track current lap, required laps, current-lap checkpoint progress,
lap times, and lap-aware checkpoint splits in server-owned result data. PointToPoint behavior is
intended to remain unchanged. The default configured active course is still
`classic_point_to_point`; switch `CourseConfig.ActiveCourseId` to `classic_circuit` manually when
testing the circuit.

**Phase 8F Smoke Checklist:**

- [X] PointToPoint course still stages, checkpoints, finishes, shows results, and resets.
- [X] `Course_ClassicCircuit` spawns when `CourseConfig.ActiveCourseId` is set to
  `classic_circuit`.
- [X] LapBased Finish touch before current-lap checkpoints are complete does not finish or advance
  the lap.
- [X] Completing all checkpoints then touching Finish increments lap until the final lap.
- [X] Final lap Finish locks placement and total finish time.
- [X] RaceHUD shows course, format, lap progress, current-lap checkpoint progress, falls, and
  placement.
- [X] PersonalSummaryUI shows lap times and lap-labeled checkpoint splits.
- [X] Fall before any current-lap checkpoint returns to Start.
- [X] Fall after a current-lap checkpoint returns to that latest checkpoint.
- [X] Ghost Race after a LapBased finish remains non-colliding and unofficial.
- [X] Reset returns Finished, DNF, Spectating, LateRacing, GhostRacing, and Lobby players to Lobby.
- [X] Repeated touches and multiple rounds do not create duplicate checkpoint/fall connections.

**Bugs Found:** None in repository or Studio hierarchy inspection.

**Follow-up Tasks:** Manual Studio Play/Test of both course formats, then build better shippable
graybox courses on top of the template.

### 2026-05-30 Active Course Spawning

**Build/Commit:** TBD.

**What Was Tested:** Studio MCP inspection and repository verification for fixed CourseService
selection/spawning. A persistent `Course_ClassicPointToPoint` library model was created from the
current `Workspace.RaceCourse`.

**Findings:** `ServerStorage.CourseLibrary` contains `CourseTemplate` and
`Course_ClassicPointToPoint`. The playable course has CourseId `classic_point_to_point`, display
name `Classic Point-to-Point`, PointToPoint format, LapCount `1`, Enabled `true`, and six
checkpoints. Existing `Workspace.RaceCourse` and `Workspace.Lobby` remained present after the
library copy was created.

**Bugs Found:** None in repository verification or Studio hierarchy inspection.

**Follow-up Tasks:** Run manual Studio Play/Test for CourseService startup spawn, round-start
rebinds, checkpoint order, fall respawn, finish/results, Ghost Race, reset to Lobby, and duplicate
touch-trigger checks across rounds.

### 2026-05-29 CourseService Reference Migration

**Build/Commit:** TBD.

**What Was Tested:** Repository verification for the CourseService reference migration. Studio MCP
inspection was attempted, but the connected Studio target was unreachable during this pass.

**Findings:** Source maps include the migrated services. `CheckpointService`, `RespawnService`, and
`StagingService` now use `CourseService` for active course references while keeping
`Workspace.RaceCourse` as the active fallback/current course.

**Bugs Found:** None in repository verification.

**Follow-up Tasks:** Run manual Studio Play/Test once Studio reconnects: staging to Start,
checkpoint order, fall respawn before and after checkpoints, finish/results, ghost race, and reset
to Lobby.

### 2026-05-27 Course Template Foundation

**Build/Commit:** TBD.

**What Was Tested:** Studio inspection for `ServerStorage.CourseLibrary.CourseTemplate`, repo
source-map verification for the CourseService foundation, and a short Studio Play startup smoke
test.

**Findings:** Course template exists with the required hierarchy and `CourseInfo` attributes.
Existing `Workspace.RaceCourse` and `Workspace.Lobby` remain present. Studio Play started with
`RaceHUD` present, confirming the service bootstrap still loads.

**Bugs Found:** None in inspection.

**Follow-up Tasks:** Implement active-course reference migration before adding course rotation or
lap-based gameplay.

### 2026-05-27 Fall Respawn Regression

**Build/Commit:** TBD.

**What Was Tested:** Falling through `FallZone_Main` during `Racing`. Post-fix MCP smoke also
moved an official racer below the fall threshold during `Racing`.

**Findings:** An official racer could pass through the red fall zone, die, and respawn at the lobby
spawn instead of returning to the latest checkpoint or Start. After the fix, moving the official
racer to `Y=1` during `Racing` returned them to Start and updated the HUD to `Falls: 1`.

**Bugs Found:**
- Fall recovery did not have a character-death fallback when Roblox killed the character before the
  normal fall-zone or Y-threshold pivot completed. FIXED

**Follow-up Tasks:** Manually retest a full red-box/void death before Checkpoint_001 and after a
later checkpoint during an active race.

### 2026-05-25 Phase 8B Smoke Test

**Build/Commit:** TBD.

**What Was Tested:** Studio Play single-player smoke test after the course expansion. Used MCP
character pivoting through `Checkpoint_001` through `Checkpoint_006` and `Finish` to verify server
checkpoint order, finish recording, RaceHUD, and PersonalSummaryUI payload display.

**Findings:** RaceHUD showed the 5:00 timer and all six checkpoints completed. Finish recorded
placement `#1` and PersonalSummaryUI displayed six checkpoint splits. This was not a human timing
pass, so actual new-player/practiced-player completion time still needs manual playtesting.

**Bugs Found:** None in this smoke test. Studio output still shows unrelated Roblox style warnings
for `RoundedCorner8 ::UICorner`.

**Follow-up Tasks:** Run full human playtests for course timing, falls, two-player crowding, and
ghost racer non-collision on the expanded course.

### 2026-5-25

**Build/Commit:** TBD.

**What Was Tested:** TBD.

**Findings:** Ghost mode can leave a player visually transparent into the next round if normal
collision/visual state is not re-synced after reset.

**Bugs Found:**
- Player remains transparent after the new round starts after choosing Ghost Race. Checkpoints still
  count because their next-round status is Racing, and they can finish the race. FIXED

**Follow-up Tasks:** Retest finished-player Ghost Race through reset into the next official race.

## 2026-09-05 — Alpine environment review build

Branch: `codex/classic-ascent-environment`; builder version 2.

- Rojo 7.7.0 reconnected on localhost:34872; project build passed.
- Studio generated 1,296 BaseParts, 146 route transitions, 19 checkpoints,
  147 fall volumes, and approximately 2,175 studs of route.
- Inspected real overview and player-height views of the trailhead, bridges,
  ruined causeway, and snow section. Fixed buried scenery and unsupported snow caps
  during review. Native geometry still needs the user's aesthetic acceptance.
- Sampled the route centerline at platform centers and transition midpoints,
  at body/head heights. No opaque decoration intersected those sampled points.
  This is a limited geometric check, not a full swept character/camera test.
- `ClassicAscentSmoke`: all 10 checks passed. Physical Humanoid traversal of every
  node took 138.09 seconds (2:18), with no unexpected falls; all nineteen splits
  recorded, early completion and finish lock verified.
- The first traversal stopped at route 25 because MoveTo settled outside the test's
  one-stud center tolerance despite landing safely. The runner now uses directional
  Humanoid input to reach its targets. Full rerun passed.
- `ClassicAscentRecovery`: all 8 checks passed in the next round. Verified reset,
  elevated/local/nested/general recovery, orientation, and single fall counts after
  repeated binding. A remaining official racer kept the round open.
- Client ambience activated near the course (ClockTime 15.2, Atmosphere density 0.2)
  and disabled after lobby return, restoring ClockTime 14.5.
- No new script errors found in Studio output. No standalone Luau analyzer, StyLua,
  or Selene executable was available; live Studio execution and Rojo build were used.
- Stopped Play after tests, discarding temporary runners and test-only fall volume.
  Preserved old generated models in ServerStorage.CourseBuildArchive and placed a
  version 2 copy in Workspace.RaceCourse for immediate Edit inspection.

Limits: 2:18 is an automated clean-run measurement, below the aspirational 2:30
familiar-player budget but within the user's broad 2–3 minute skilled-run range.
No human first/repeat timing, touch control, 2–6 player, device performance, retention,
or audio acceptance evidence exists. Do not describe this as a finished/approved
player experience or claim typical players currently need 4–6 minutes.

## 2026-09-05 — Version 3 integrated terrain and active obby hazards

User feedback: separated scenery/track/mountain; bland catwalk pacing; floating
signs and generic checkpoints; noisy summit and broken rail spans; double staging
teleport; unsafe start edges; course-specific sky requested.

Implemented native terrain banks, trail shoulders, embedded cliff supports, mounted
waymarkers, material-matched milestone checkpoints, paired summit slopes, connected
rope spans, a protected start terrace and timed hazards. Version 3 has 146 route
transitions, 19 checkpoints, 147 fall volumes, 44 lethal surfaces, 9 collapsing
platforms and 8 rockfall locations. Final geometry has approximately 1,481 BaseParts.

Verified results:
- Full hazard-enabled Humanoid traversal passed all 10 assertions, all 19 splits,
  zero unexpected traversal falls, 176.76 seconds (2:57). The intentional preflight
  fall is separate. Timing includes the runner reading hazard phases and waiting
  for safe rockfall windows, so it is not a human first-attempt measurement.
- Final 20-stud start opening passed 9 staging assertions, including actual forward
  movement against the closed collision gate, free movement retention, escape
  fallback, queued death/respawn recovery, visual opening and no second teleport.
- All six bundled sky textures loaded successfully in the client. A temporary
  client course-ID switch restored the original SkyboxBk and ClockTime (14.5),
  then reactivated the course sky and ClockTime (15.2). The original course ID was
  restored immediately; the test did not change the server course.
- Sampled terrain centerline intersections at route centers/midpoints; fixed bank
  intrusion near basalt/cliff offsets, then the sample returned no intersections.
- Inspected real Play-mode bridge/snow views with the new sky and Edit-mode
  start/overview views. This is visual review, not the user's aesthetic acceptance.

Tuning and test corrections:
- Increased crumble warning from 0.65 to 1.25 seconds after physical traversal
  showed the shorter time could collapse a board before normal-speed crossing.
- The test now approaches a center fissure before jumping, rather than attempting
  to clear an entire long platform in one jump. It also avoids walking backward
  onto a fissure after clearing it. Isolated basalt traversal verified the cause.
- Moved signs outside narrow lanes and extended their supports into the ground.
- Added permanent gate wings so opening the exit does not expose start corners
  wider than the first trail. Falling rocks hide until their warning phase.

Runtime test scripts and diagnostic reports are Play-only and discarded on Stop.
One temporary test runner had a source-string substitution error; the corrected
runner was used. It is not part of shipped source. No standalone Luau analyzer,
StyLua or Selene executable is installed. Rojo build and Studio execution are the
available verification tools.

Still requires human keyboard/touch runs, multiplayer crowding checks, device
performance checks and retention/pacing feedback. Nine-minute timeout remains.

Final version 3 verification: all 7 hazard assertions and all 8 recovery assertions
passed after the complete traversal and final 9 staging assertions (34 gameplay
assertions total). Hazard rebinds did not duplicate deaths/falls; recovery was tested
in the next fresh race through the existing Studio-only EndRace control. Final
source built successfully. Final cosmetic-only cleanup uses circular warnings and
hides a fragile snow pad's ice strata with the pad; unused corbels under those
fragile pads were omitted. Final generated count: 1,481 BaseParts. Play stopped;
temporary runners/reports are gone and version 3 remains visible in Edit mode.