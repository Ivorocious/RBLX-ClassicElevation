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
