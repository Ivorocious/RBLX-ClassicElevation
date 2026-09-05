# Tasks

Track scoped implementation work for ProjectClassicElevation here.

## Backlog

- Review and approve the Classic Ascent alpine environment build for a complete
  environment: ten distinct sections, mountain setting, ambience, and decoration.

- Human-test Classic Ascent on keyboard/touch and with 2-6 racers; tune the
  2:30-3:15 skilled and 4-6 minute typical completion targets.
- Build the separate Classic Ascent circuit after the point-to-point route is accepted.

- Preserve the existing Studio-authored lobby and old courses in a saved place backup.
- Create two shippable graybox courses.
- Add separate unofficial checkpoint and respawn tracking for LateRacing and GhostRacing.
- Add test tooling when the first pure logic modules exist.
- Optional: polish MVP UI after playtesting.

## In Progress

- Human review of Classic Ascent version 3: integrated terrain, active hazards, safe staging and course sky. Automated hazard-enabled traversal: 2:57; keyboard/touch and multiplayer tuning remain.

## Done

- 2026-09-05: Implemented version 3 feedback: joined terrain, mounted signs and milestones, cleaner summit and rope spans, lethal/collapsing/rockfall hazards, protected intermission staging without a second teleport, and restoring course sky.

- 2026-09-05: Implemented a reproducible barebones Classic Ascent placeholder,
  multiple map-specific fall zones, nine-minute maximum, and early race completion.

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
- 2026-05-30: Implemented LapBased race validation and lap result data.
## Classic Ascent v4 handoff — 2026-09-05

- [x] Three paths, shared clearings and wider staging for 20 racers.
- [x] Taller mountain, canopy, supported camp and overhead rock/snow scenery.
- [x] River logs, mini-cliffs, three collapsing bridges, vents, concealed rockfall,
  snowball cover, slippery Skyline and summit avalanche.
- [x] Preserve manual sign presentation and replace confusing sign text.
- [x] Instant checkpoint recovery and one focused Studio verification session.
- [ ] User manual fine-tuning and full playtest, including 20-player behavior.
- [ ] Revisit intermission/lobby flow with the planned lobby rebuild.
