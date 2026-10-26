# Classic Ascent V8 journey rebuild

**Archived, September 7:** the owner rejected V8 and requested V7 back. See the [current V7 editing guide](CLASSIC_ASCENT_EDITING.md). All V8/recovery references below are historical.

This records the earlier V8 candidate. The owner requested a further visual recovery pass after reviewing it; see [CLASSIC_ASCENT_RECOVERY_VERIFICATION.md](CLASSIC_ASCENT_RECOVERY_VERIFICATION.md) for current changes and evidence. Earlier counts and Skyline preservation statements below describe candidate 06, not the current course.

September 6, 2026. Approved scope: the ten-section mountain journey, protected river quality, clearer section identities and finish, bounded hazard additions, and irregular jump platforms. No place publication.

## Implemented

- New Blender scenery: basalt columns, ruined road abutments, cliff buttresses, glacial forms, snow ridges, and a simpler cedar variant. Source kits, FBX exports, previews, and triangle manifests are in `assets/ascent/v8/`. Uploaded model assets: `119809824049796` and `122018596414278`.
- Trailhead has a central trail cue. Switchback, bridge, lava, causeway, cliff, and alpine sections have distinct mountain framing. Skyline has a pale central landing edge. The summit has a centered hanging sign, terrace, flag, and an open distant view.
- Sections 03, 05, 06, and 07 use 186 convex chipped-stone landings with matching Hull collision. Each has an attached noninteractive rock root. Deterministic position, width, yaw, and height variation keeps the route irregular while bounding adjacent changes. Two tight switchback approaches have extended back edges.
- Section 04 retains its collapsing boards with fewer repeated rail/post elements. Section 09 retains its accepted platform geometry and variation.
- Rolling boulders increase from 4 to 5, snowballs from 6 to 8, and giant snowballs from 6 to 8. The added hazards use staggered phases; warning duration, damage/recovery behavior, speed, and existing pause ranges remain. Existing moving river logs, rolling trunks, and lava vents keep their counts.
- Explicit refuge cover is included in rolling-boulder and avalanche collision checks. A single swept sphere query resolves a racer or cover along the movement path; initial overlaps are also checked. Runtime outcomes remain a verification gate below.
- Noninteractive scenery meshes use regenerated Box collision data; playable stone keeps Hull collision and the 42 query-enabled river meshes retain their geometry. This establishes authored collision settings, not a measured FPS or memory saving.
- Route length metadata now reflects the central route after layout changes. Existing V8 models must carry the journey and scenery-collision revisions before reuse.

## Verified evidence

`tests/studio/ClassicAscentJourney.luau` passed against candidate 06 in Studio Edit mode. Full output: [journey-geometry.json](artifacts/journey-geometry.json).

- 170 central route nodes and 19 checkpoints remain.
- All 80 river route pads and all 50 Skyline route pads retain their accepted position, size, and orientation.
- 558 downward rays hit the expected physical stone tops: three checks on each of 186 new landings. Horizontal collision-edge rays measured 264 route connections.
- The widest measured connection in rebuilt stone sections is approximately 6.697 studs. This is a geometric clearance, not proof of a successful jump. The accepted Skyline still contains an approximately 8.079-stud gap.
- Sections 03, 05, 06, 07, and 09 retain more than one stud of authored height-offset variation. These are reproducible authored variations, not layouts randomized every race.
- Motion roots: 100 moving river logs, 6 rolling logs, 12 lava vents, 5 rolling boulders, 8 snowballs, and 8 avalanches. All authored warnings remain at least 1.4 seconds.
- Candidate 06 has 4,293 BaseParts and 1,505 MeshParts, including 1,277 Box, 186 Hull, and 42 Default collision meshes. The earlier V7 inventory was 4,732 BaseParts and 1,297 MeshParts. Counts alone do not establish performance.
- A normal Studio Play startup selected BuilderVersion 8 with JourneyRevision 1. The subsequent scripted traversal and cover tests have not yet run successfully; see the gate below.

## Independent rechecks

Six Terra High critics completed one bounded second pass. Five section-pair reviewers used four grounded views each, and the performance reviewer inspected source and live authored counts. They confirmed stronger section identities, the retained dense river bank, a clearer Skyline line, and a readable summit arrival. Reports remain independent evidence; they are not gameplay or performance certification.

[01–02](artifacts/recheck-01-02.md), [03–04](artifacts/recheck-03-04.md), [05–06](artifacts/recheck-05-06.md), [07–08](artifacts/recheck-07-08.md), [09–10](artifacts/recheck-09-10.md), [performance](artifacts/recheck-performance.md).

Coordinator reconciliation:

- The start gate is intentionally closed in Edit/countdown state. `StagingService.openStartGate` hides its visual rails and removes collision at race start; the closed preview is not evidence that it obstructs the running race.
- River platform repetition and its hillside wedge are inherited observations. Keep the owner's accepted dense river-bank composition; do not reopen its geometry based on those opinions alone.
- The sign subtitle was shortened and enlarged after the recheck. The V8 reuse path now rejects missing journey/collision revisions.
- The Blender JSON manifest includes source triangle totals. CedarLite has 1,974 triangles versus the older cedar's 5,574; the protected river keeps its older cedar. The Luau upload manifest does not contain triangle totals. Source triangles are not rendered-frame measurements.
- Remaining visual refinements include repeated bridge/pedestal rhythms, some sharply exposed cliff faces, uniform lava, and arranged snow-hazard scenery. These are recorded honestly rather than treating a bounded pass as a perfect art result.

## Runtime gate and manual checks

Automated character-jump and cover tests are prepared in `tests/studio/ClassicAscentJourneyJump.client.luau` and `tests/studio/ClassicAscentCover.server.luau`. They require an active Studio race and temporary fixtures. Automatic approval review blocked fixture creation, character movement, and moving a duplicate authored course; explicit test authorization was requested. No successful runtime result is claimed while this gate is pending.

After authorization, test selected widest/highest jumps with a real client-owned character, then exposed/front-of-cover/behind-cover/radius-edge cases for all three projectile kinds over two cycles. Recheck river motion and recovery in the running services. Temporary Play changes must disappear when Play stops.

Human checks still required: run all three lanes, confirm readable warnings and cover at normal camera distances, check checkpoint recovery after falls, and test passing/queuing with other racers. Measure on an actual budget phone and PC with 20 racers before accepting the 30/60 FPS targets. Desktop Studio and device emulation do not establish those targets.

## Source and scene state

Filesystem scripts are the durable source and Rojo supplies them to Studio. The authored V8 course is in `Workspace.Course_ClassicAscentPointToPoint`; the previous accepted V7 is retained in `ServerStorage.CourseBuildArchive.ClassicAscent_V7_BeforeJourney_20260906`. The build can generate the V8 runtime library from source. No place has been published.
