# Technical Architecture

## Source of Truth

Git stores scripts, documentation, configuration, and development history.

Rojo syncs filesystem source into Roblox Studio. Durable script changes should be made in the repository first unless a task explicitly calls for a temporary Studio-only edit.

## Roblox Service Layout

- `ReplicatedStorage/Shared`: shared modules used by both server and client.
- `ReplicatedStorage/Config`: shared configuration and tuning values.
- `ReplicatedStorage/Remotes`: RemoteEvents and RemoteFunctions.
- `ServerScriptService/Services`: server-authoritative gameplay services.
- `StarterPlayer/StarterPlayerScripts`: client runtime scripts.
- `StarterGui`: player UI.

## Server Authority

Gameplay-critical systems must be validated and owned by the server, including:

- race state
- race start time
- player race status
- checkpoint progress
- fall respawn position
- finish validation
- finish time
- placement
- race result data
- currency
- inventory
- rewards
- progression
- damage
- purchases
- unlocks
- matchmaking

## Networking

All client-to-server remote payloads are untrusted. New remotes should document:

- purpose
- client payload
- server validation
- server response or side effect

MVP race remotes live under `ReplicatedStorage/Remotes`. Server-to-client remotes broadcast
race state, player status, timers, results, and personal summaries. Client request remotes
(`RequestSpectate`, `RequestRaceLate`, and `RequestGhostRace`) are only requests. The server
validates the player, current race state, current player status, and eligibility before changing
authoritative state.

## Data Persistence

DataStore is intentionally excluded from the MVP. Personal bests may be tracked in memory for the
current server session only. Persistent PBs, historical race results, global leaderboards, ranked
points, seasons, rewards, economy, and monetization require explicit approval before implementation.

DataStore-related systems require explicit approval before implementation.

## MVP Race Architecture

Phase 1 establishes the filesystem/Rojo foundation only:

- `ReplicatedStorage/Shared/RaceTypes`: typed race states, player statuses, formats, and result
  payload shapes.
- `ReplicatedStorage/Shared/RaceConstants`: shared state/status/format/remote names and defaults.
- `ReplicatedStorage/Shared/FormatTime`: display formatting for elapsed race times.
- `ReplicatedStorage/Config/RaceConfig`: MVP point-to-point race tuning.
- `ReplicatedStorage/Config/CheckpointConfig`: expected Workspace course naming conventions.
- `ServerScriptService/Services`: service skeletons for race, player status, checkpoint, respawn,
  results, and ghost-race responsibilities.

MVP uses `RaceFormat = "PointToPoint"`. `LapBased` exists only as a type/config possibility so the
checkpoint model can later add lap-aware validation without rewriting the result payloads.

Phase 1 does not implement the round loop, checkpoint touch handling, finish placement, UI,
ghost collision, course selection, DataStore, economy, monetization, ranked systems, seasons,
global leaderboards, or practice mode.

## MVP Round State Machine

Phase 2 implements the server-authoritative round loop in `RaceService`:

- `WaitingForPlayers`: waits until `RaceConfig.MinPlayers` eligible players are present.
- `Intermission`: queues eligible players for the next official race.
- `Countdown`: keeps queued players eligible before the race starts.
- `Racing`: starts queued players as official racers and ends by timer only for Phase 2.
- `RaceEnding`: marks unfinished official racers as DNF after the race timer expires.
- `Results`: broadcasts the minimal current race result payload.
- `Resetting`: returns players to `Lobby` for the next round.

`RaceService` owns race state, race id, state deadlines, and timer broadcasts. It uses
`Workspace:GetServerTimeNow()` and never accepts client timing. `PlayerRaceService` owns per-player
statuses and broadcasts status changes. `ResultsService` owns the minimal in-memory race result
record and records DNFs only. Placement, checkpoint splits, personal bests, fall respawns, late
join choices, ghost collision, and UI remain later phases.

## MVP Checkpoint and Finish Validation

Phase 3B started with the Studio course at `Workspace/RaceCourse`. Phase 8D keeps
`Workspace/RaceCourse` as the current active/fallback course, but `CheckpointService` now reads the
active Start, ordered checkpoints, and Finish through `CourseService`.

The official MVP checkpoint naming convention is `Checkpoint_###`, for example `Checkpoint_001`,
under the active course's `Checkpoints` folder.

`CheckpointService` asks `CourseService` for ordered checkpoint parts, preserves numeric ordering,
and connects server-side `Touched` handlers to checkpoint parts and the active course Finish.
Only official players whose `PlayerRaceService` status is `Racing` can progress. Lobby, Queued,
Spectating, Finished, GhostRacing, LateRacing, and DNF players do not advance official results.

Checkpoint order is enforced on the server. A racer cannot skip checkpoints, overwrite a completed
split, finish before all checkpoints are complete, or overwrite a locked finish. `RaceService`
remains the only owner of race timing, and `ResultsService` records splits, finish time, placement
order, and timer-ended DNFs in memory only.

## MVP Fall Detection and Respawn

Phase 4 implements server-authoritative fall handling in `RespawnService`. Phase 8D migrates its
fall-zone lookup through `CourseService`, so it binds the active course's `FallZone_Main` and also
checks `RaceConfig.FallYThreshold` on a small server heartbeat interval so falls can be detected
even when a fall-zone touch does not fire cleanly.

Only official racers with `PlayerRaceService` status `Racing` can trigger official fall respawns.
Lobby, Queued, Spectating, Finished, GhostRacing, LateRacing, and DNF players are ignored. The
client cannot report falls, respawn position, or fall counts.

`CheckpointService` owns checkpoint progress and exposes the latest checkpoint respawn CFrame using
the active course parts from `CourseService`. If a racer has not reached any checkpoint, respawn
falls back to the active course Start. Characters are repositioned with a vertical offset using
server-side pivot logic instead of being killed/reset.
`ResultsService` owns fall counts in the current in-memory race result payload and preserves those
counts when players finish or DNF.

If Roblox kills an official racer before `RespawnService` can pivot their current character, the
service records the active race id on `Humanoid.Died` and moves the next loaded character back to
the latest checkpoint or Start. This prevents active racers from staying at the lobby spawn after a
void death during `Racing`.

## Late Join and Finished-Player Options

Phase 5 implements server-authoritative handling for `RequestSpectate`, `RequestRaceLate`, and
`RequestGhostRace` in `PlayerRaceService`. The client creates minimal `LateJoinUI` and
`FinishedOptionsUI` request panels, but those panels never set authoritative status locally.

Players who join while the race is already in `Racing` are left in `Lobby` and are not official
racers for that race. During the active race, a `Lobby` player may request `Spectating` or
`LateRacing`. `Spectating` players cannot trigger official checkpoints, finish, placement, fall
counts, or result data. `LateRacing` players can physically run the course, but they remain
unofficial and cannot place, win, overwrite results, or become official DNFs.

When an official racer finishes, `CheckpointService` locks their official result through
`ResultsService` and sets their player status to `Finished`. During the active race, a `Finished`
player may request `GhostRacing`; they can run again physically, but checkpoint, finish, placement,
fall count, personal best, and result overwrite logic remains blocked because official validation
only accepts official `Racing` players. A `Finished` player may also request `Spectating` without
changing the locked race result.

Known Phase 5 limitations:

- LateRacing and GhostRacing do not yet maintain separate unofficial checkpoint progress.
- LateRacing and GhostRacing do not yet use latest-checkpoint respawn; official fall counts remain
  limited to official `Racing` players.

## MVP Race UI

Phase 6 adds client display UI under `StarterPlayer/StarterPlayerScripts`. `Client.client.luau`
keeps the remote listeners and debug output, while `Controllers/RaceUiController` owns the runtime
player-facing UI:

- `RaceHUD`: visible during Intermission, Countdown, Racing, RaceEnding, and Results. It displays
  active course metadata, race state, local player status, timer, checkpoint split count when
  available, fall count when available, and placement when the authoritative result payload includes
  it.
- `RaceResultsUI`: visible around RaceEnding and Results. It displays official placements, finish
  times, fall counts, and DNF rows from `RaceResultsUpdated`.
- `PersonalSummaryUI`: appears after the local player has a result or during Results. It displays
  the local player status, official placement and finish time when available, falls, checkpoint
  splits, DNF reason when available through the result row, and a simple note such as `Clean Run`,
  `Finished with Falls`, `DNF`, or `Unofficial Run`.

The client UI is display-only. It does not decide official finish time, placement, falls,
checkpoint completion, or result validity. `ResultsService` remains the authoritative source for
official race result data. For UI freshness, `ResultsService` now registers official active racers
at race start and broadcasts `RaceResultsUpdated` after active racer registration, checkpoint
splits, falls, finishes, DNFs, and the Results state broadcast. This does not add persistence,
personal bests, economy, ranked systems, course selection, rewards, or DataStore usage.

## MVP Round Staging and Player Positioning

Phase 7A adds server-authoritative physical staging through `StagingService`. Lobby staging
configuration lives in `RaceConfig` and points at the Studio-authored `Workspace/Lobby` object. The
MVP lobby target is `LobbySpawnPadMarker`, with `LobbyPlatform` as a safe fallback. Phase 8D
migrates race start lookup through `CourseService`; the current fallback start target remains
`Workspace/RaceCourse/Start`.

`StagingService` only moves characters on the server. It finds each player's character, humanoid,
and `HumanoidRootPart`, clears linear/angular velocity, and uses `Model:PivotTo()` with a small
vertical offset. Multiple players receive small formation offsets around the target part to reduce
spawn overlap. Clients cannot request or choose authoritative teleport locations.

`RaceService` uses staging at round boundaries:

- `WaitingForPlayers`: returns current players to the lobby target when the round loop enters the
  waiting state.
- `Countdown`: moves queued official racers to the active course Start when Countdown begins.
- Race start: stages queued racers again immediately before official `Racing` status starts, so
  players who joined during Countdown are also at the start.
- `Resetting`: returns all players to the lobby target before resetting statuses to `Lobby`.

Staging is separate from fall respawn. During `Racing`, players are not repeatedly teleported by
staging; official fall recovery remains owned by `RespawnService`, which still respawns racers at
the active course Start before their first checkpoint or at their latest official checkpoint
afterward.

## GhostRacing Non-Collision

Phase 7B implements server-authoritative non-collision for `GhostRacing` through `GhostService`.
`GhostService` creates or ensures two character collision groups:

- `RaceCharacter`: normal player character parts for Lobby, Queued, Racing, Finished, Spectating,
  LateRacing, and DNF players.
- `GhostCharacter`: character parts for players whose authoritative status is `GhostRacing`.

`GhostCharacter` does not collide with `RaceCharacter` or other `GhostCharacter` parts, so ghost
racers cannot physically block official racers or each other. `GhostCharacter` still collides with
`Default`, so ghost racers can run on the course and lobby parts normally. `RaceCharacter` keeps
normal collision against the world and other non-ghost characters.

`PlayerRaceService` remains the owner of status authority. When it changes a player into
`GhostRacing`, it asks `GhostService` to apply ghost collision and a small reversible transparency
change to that player's character parts. When the player leaves `GhostRacing`, including during
round reset, `GhostService` restores the character to `RaceCharacter` collision and restores stored
part transparency. `PlayerRaceService` also re-syncs ghost mode on status assignments so Lobby,
Queued, and Racing transitions restore normal character collision if a prior reset missed a
character. `GhostService` also handles character respawns and newly added character parts, including
accessories, while avoiding anchored course or lobby objects.

Ghost racers remain unofficial. They still cannot trigger official checkpoints, finish officially,
overwrite placement, change finish time, change fall count, or affect race result data. LateRacing
and GhostRacing still do not yet have separate unofficial checkpoint progress or checkpoint respawn
tracking.

## MVP Hardening Pass

Phase 8A keeps the existing playable loop intact and focuses on cleanup around edge cases. Official
race results remain in memory only and continue to be server-authoritative.

Runtime-only per-player state is cleaned when players leave: checkpoint progress is removed from
`CheckpointService`, fall respawn cooldown state is removed from `RespawnService`, and ghost visual
transparency bookkeeping uses weak part keys so destroyed character parts do not keep stale
references alive.

If an official active racer leaves during the current race before finishing, `ResultsService` marks
that racer as DNF with the reason `Left race`, removes them from active racers, and broadcasts the
updated result payload. Finished results remain locked and are not overwritten by disconnect or DNF
handling. LateRacing, GhostRacing, and Spectating players remain unofficial and cannot create or
modify official results.

## MVP Course Expansion

Phase 8B expands the Studio-authored `Workspace/RaceCourse` point-to-point graybox course into a
longer six-checkpoint route. The course still uses the `Checkpoint_###` naming convention under
`Workspace/RaceCourse/Checkpoints`, so `CheckpointService` discovers `Checkpoint_001` through
`Checkpoint_006` without code changes.

`RaceConfig.RaceDuration` is now 300 seconds for the MVP course target. The route is intended to
give new players enough time for a roughly 2:30-3:00 completion and practiced players enough room
for roughly 1:00-1:30 runs. The Studio course remains a static graybox: no moving platforms, kill
bricks, course selection, persistence, rewards, or DataStore behavior are introduced.

`FallZone_Main` remains the single fall detection volume for the MVP course and has been resized in
Studio to cover the expanded route bounds. Fall respawn behavior is unchanged: official racers
respawn at Start before their first checkpoint or at their latest completed official checkpoint.

## Course Template and CourseService Foundation

Phase 8C adds `CourseService` as the foundation for future multi-course support. It discovers
`ServerStorage/CourseLibrary` when present, reads `CourseInfo` attributes, validates course
hierarchy, and exposes helper methods for the active course model, Start, Finish, Checkpoints, and
`FallZone_Main`.

For compatibility, the active runtime course remains `Workspace/RaceCourse`. Phase 8C does not
spawn, rotate, or replace courses and does not change checkpoint, fall, staging, result, or lap
gameplay. If `ServerStorage/CourseLibrary` is missing, `CourseService` falls back to the existing
`Workspace/RaceCourse` so the current point-to-point flow continues to work.

Phase 8D makes `CourseService` the active course reference provider for gameplay services.
`CheckpointService`, `RespawnService`, and `StagingService` no longer own direct course model lookup;
they ask `CourseService` for ordered checkpoints, Finish, Start, and `FallZone_Main`. `RaceService`
can rebind checkpoint and fall-zone touch handlers for the current active course at round start and
broadcasts course id, display name, race format, and lap count in race state/timer payloads.
`ResultsService` stores the same course metadata in the in-memory result payload.

LapBased gameplay is still not implemented. The active course abstraction is only a compatibility
step for future course spawning, course rotation, and lap-aware validation.

Studio now contains `ServerStorage/CourseLibrary/CourseTemplate`, a reusable authoring model with
`CourseInfo`, Start, Checkpoints, Finish, Obstacles, FallZones, RouteMarkers, Decoration, and Bounds.
`CourseInfo` attributes define CourseId, DisplayName, RaceFormat, LapCount, Enabled, Difficulty,
target completion times, and CheckpointCount. The template uses the graybox color convention for
manual course creation.

## Studio-Only Development Controls

For faster local iteration, the client creates a `DevRaceControls` ScreenGui only when
`RunService:IsStudio()` is true. The buttons send requests to `RequestDevRaceState`, and
`RaceService` only honors those requests in Studio. Current actions are `Start Race`, `Skip State`,
and `End Race`; they are development shortcuts and are not part of live gameplay.

## Current Tooling Baseline

- Rojo: verified with version 7.6.1.
- StyLua: configuration added in `stylua.toml`; executable availability not yet verified.
- Selene: configuration added in `selene.toml`; executable availability not yet verified.
- Package management: `packages/` exists as a placeholder; no package manager is active yet.

## Testing Strategy

- Use Studio playtesting for gameplay behavior.
- Use focused tests for pure logic modules when practical.
- Record manual verification steps in implementation summaries.
