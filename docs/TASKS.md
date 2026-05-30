# Tasks

Track scoped implementation work for ProjectClassicElevation here.

## Backlog

- Confirm Rojo sync from filesystem into the open Roblox Studio place.
- Implement LapBased race validation and lap result data.
- Create two shippable graybox courses.
- Add separate unofficial checkpoint and respawn tracking for LateRacing and GhostRacing.
- Add test tooling when the first pure logic modules exist.
- Optional: polish MVP UI after playtesting.

## In Progress

- None.

## Done

- 2026-05-20: Initialized ProjectClassicElevation from the Roblox baseline template.
- 2026-05-20: Added Phase 1 MVP race architecture foundation.
- 2026-05-21: Implemented Phase 2 server-authoritative round state machine and basic player race statuses.
- 2026-05-21: Built the first MVP point-to-point graybox Studio course.
- 2026-05-21: Implemented server-side checkpoint and finish validation.
- 2026-05-22: Implemented server-side fall detection and latest-checkpoint respawn.
- 2026-05-23: Implemented late join and finished-player options.
- 2026-05-23: Implemented MVP race HUD, results UI, and personal summary UI.
- 2026-05-24: Implemented round staging and lobby/start positioning.
- 2026-05-25: Implemented ghost racer non-collision behavior.
- 2026-05-25: Performed MVP hardening pass.
- 2026-05-25: Expanded the MVP graybox course and improved course difficulty after playtesting.
- 2026-05-27: Added CourseService foundation and reusable course template.
- 2026-05-29: Migrated active course references to CourseService.
- 2026-05-30: Implemented active course spawning and fixed CourseService selection.
