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
(`RequestSpectate`, `RequestRaceLate`, and `RequestGhostRace`) are only requests; future server
code must validate the player, current race state, current player status, and eligibility before
changing authoritative state.

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

## Current Tooling Baseline

- Rojo: verified with version 7.6.1.
- StyLua: configuration added in `stylua.toml`; executable availability not yet verified.
- Selene: configuration added in `selene.toml`; executable availability not yet verified.
- Package management: `packages/` exists as a placeholder; no package manager is active yet.

## Testing Strategy

- Use Studio playtesting for gameplay behavior.
- Use focused tests for pure logic modules when practical.
- Record manual verification steps in implementation summaries.
