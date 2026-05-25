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

## Sessions

### 2026-5-25

**Build/Commit:** TBD.

**What Was Tested:** TBD.

**Findings:** Ghost mode can leave a player visually transparent into the next round if normal
collision/visual state is not re-synced after reset.

**Bugs Found:**
- Player remains transparent after the new round starts after choosing Ghost Race. Checkpoints still
  count because their next-round status is Racing, and they can finish the race. FIXED

**Follow-up Tasks:** Retest finished-player Ghost Race through reset into the next official race.
