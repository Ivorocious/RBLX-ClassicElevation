# Game Design

## Core Concept

Project Classic Elevation is a live multiplayer Roblox parkour/obby racing game. Players
compete in the same main race on a repeating round cycle, with modern race data layered on top
of a classic obby format.

## Player Fantasy

Players are racing other people live, trying to finish first while improving their own times,
checkpoint splits, and clean-run consistency.

## Core Loop

1. Players join the server and queue into the current round flow.
2. The server runs intermission, countdown, race, ending, results, and reset states.
3. Official racers run the same point-to-point course.
4. Falls respawn racers at their latest checkpoint instead of permanently killing the run.
5. Results show placement, time, falls, splits, and personal summary notes.

## Main Features

- MVP point-to-point race format.
- Round-based race state machine.
- Server-authoritative player race status and result tracking.
- Checkpoint split and fall count tracking.
- Late join support through spectating or unofficial late racing.
- Finished-player support through spectating or unofficial ghost racing.

## Progression

Persistent progression is excluded from the MVP. Personal bests should be session-only and
in-memory until DataStore use is explicitly approved.

## Monetization Notes

Monetization decisions must be reviewed before implementation.

## Open Questions

- Exact MVP course layout and checkpoint count.
- Minimum player count once public playtesting begins.
- Final UI layout for HUD, results, late join, finished options, and personal summary.
