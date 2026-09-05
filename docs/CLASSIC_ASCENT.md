# Classic Ascent Point to Point

## Current status: passed for manual fine-tuning

September 6, 2026: the accepted course is builder version 7, `AltitudeRevision = 2`. See the [current v7 handoff](CLASSIC_ASCENT_V7.md), [level-design guide](LEVEL_DESIGN_GUIDE.md) and [reusable chat brief](LEVEL_DESIGN_CHAT_STARTER.md). Preserve accepted geometry and manual edits; do not regenerate this course without a new request.

## Historical version 4 reference

The following records an earlier build. Use the v7 handoff for current implementation and verification limits.

Classic Ascent has three parallel paths that reconnect at 19 shared checkpoints,
with wider forest and snow clearings for a 20-player race. The mountain rises to
about Y425 above the route's Y64–244 climb. Sloped mountain faces, planted islands,
overhead canopy, rock galleries and snow cornices surround the paths.

The user's version 3 run took almost six minutes with several falls and was fun.
That is the current human pacing evidence. Version 4 has not been timed by a
human or tested with 20 players. Nine minutes remains the race timeout; finishing
or losing all official racers ends it early. Targets are tuning intentions only.

## Sections

| Section | Central transitions | Design |
| --- | ---: | --- |
| Trailhead | 10 | Broad forest floor, three dirt trails, low fallen trunks, supported camp shelter |
| Stepping Gardens | 14 | River crossings on moving log bundles, shared banks, trees and gorge walls |
| Switchback Climb | 24 | Smaller stone footholds on three lines; no lava |
| Ridge Bridges | 16 | Three bridges, individually collapsing boards, shared stone refuges |
| Pillar Yard | 18 | Basalt routes above lava, warned rising vents |
| Broken Causeway | 12 | Three ruined spans, varied falling rocks concealed by overhead rock pockets |
| Cliffside Traverse | 16 | Exposed outer rockfall route, central ledges, sheltered inner rock steps |
| Summit Steps | 18 | Snow clearings, intermittent snowball volleys, solid rock cover |
| Skyline | 20 | Small low-friction ice footholds, snowy checkpoint islands, ice arches |
| Summit Run | 10 | Broad snowy approach, staggered giant rolling snowballs, side alcoves |

There are 158 central transitions and 159 map-specific recovery volumes.
Branches are offset roughly 20 studs from the middle line; 66-stud checkpoint
clearings let racers change paths. The central route is about 2,157 studs long.
Scenery and collision remain separate where necessary to preserve jump gaps.
The opening, snowy steps and summit use shared walkable ground between the paths.

## Runtime mechanics

- River logs travel four studs sideways and carry grounded official racers. They
  reverse smoothly; visual timber follows the moving collision platform.
- Bridge boards disappear 0.45 seconds after contact and restore after 1.8 seconds.
  Stone refuges remain solid. Parallel lines give following racers alternatives.
- Lava vents warn for 1.4 seconds, rise for 0.75, remain up for 1.4, then sink.
- Rockfall uses the existing amber warning and falling-rock cycle, with 13 sources
  and varied diameters. Overhead pockets conceal the authored spawn positions.
- Six snowball emitters fire staggered volleys. A hit deals 35 damage; a lethal
  hit recovers the racer instead of killing their character. Solid cover stops a
  snowball, and the projectile is consumed on its first player hit.
- Six avalanche emitters send 12-stud snowballs down the final approach. Side
  alcoves sit outside the intended rolling lines. Hits recover the racer.
- Skyline has Ice material and friction 0.025; checkpoints remain grippy.
- Hazards only affect official Racing players. No new client gameplay remotes.
- Successful recovery preserves the character, zeroes velocity, heals, records one
  fall and returns directly to the saved checkpoint. The 1.5-second duplicate
  cooldown remains, with one second of motion-hazard immunity.
- Unexpected real character death/reset still uses Roblox's respawn fallback.
- The start pen is 66 by 36 studs with a full-width gate and a 5-column formation.
  Intermission staging and gate opening keep the prior no-second-teleport behavior.
  Lobby/intermission flow remains deferred until the planned lobby rebuild.

## Source and manual editing

- `ClassicAscentPointToPoint.luau`: section geometry, branching routes, checkpoints.
- `AscentEnvironment.luau`: mountain, ground, canopy, galleries and camp.
- `AscentObstacles.luau`: log bundles, boards, vents, covers and projectile sources.
- `AscentDetails.luau`: signs, checkpoint milestones and start pen.
- `AscentSignAdjustments.luau`: user's captured sign rotation/height adjustments.
- `CourseHazardService.luau`: recovery surfaces, rockfall and crumbling boards.
- `CourseMotionService.luau` and `AscentMotionConfig.luau`: moving hazards/platforms.
- `RespawnService.luau`: authoritative instant checkpoint recovery.
- `ClassicAscentAmbience.client.luau`: course sky and lighting, unchanged in v4.

Paths are under `src/ServerStorage/CourseBuilders`, `src/ServerScriptService/Services`,
`src/ReplicatedStorage/Config` and `src/StarterPlayer/StarterPlayerScripts`.

The durable authored model in Studio is
`ServerStorage.CourseLibrary.Course_ClassicAscentPointToPoint`.
`Workspace.RaceCourse` is an edit preview and is replaced when a race spawns.
For manual geometry work, copy the library model into Workspace, edit it, then
copy the finished model back into CourseLibrary before Play. Preserve an archive
before replacing either copy. Existing version 4 models are retained by Ensure;
editing the builder scripts alone does not regenerate an existing version 4 model.

The user's original visible v3 model is preserved as
`ServerStorage.CourseBuildArchive.ClassicAscent_v3_UserSignEdits_20260905`.
Exact sign snapshots are in `docs/artifacts/classic-ascent-v3-manual-signs.json`.
Their relative rotation/height adjustments carry into new mounted signs, whose
wording now describes the actual mechanics. New absolute locations follow v4 paths.

All scenery is reproducible native geometry. A Creator Store pine search was
attempted, but the selected model could not be loaded due to asset access. No
third-party scripts, uploaded assets, DataStore changes, economy changes or place
publishing are part of this build. Use Rojo 7.7.0 on localhost:34872.

## Verification

One focused Studio run passed 11 checks: startup, checkpoint registration,
same-character recovery/healing, direct checkpoint destination, duplicate recovery
suppression, moving logs/attached timber, snowball and avalanche cycle activation,
and visible lava contact recovery. Evidence:
`docs/artifacts/classic-ascent-v4-quick-check.json`.
The runner is `tests/studio/ClassicAscentV4QuickCheck.luau`, outside Rojo's mapping.

Visual review covered the mountain, forest canopy and river crossing. A geometry
check identified and shortened unintended long outside-lane jumps. No full-course
robot runs were performed for v4. Old traversal runners describe v3 and should not
be treated as v4 acceptance evidence.

Manual acceptance remains with the user: route choice, fun, icy movement, projectile
cover, bridge crowd flow and completion times. Twenty-player performance and touch
controls remain unverified. Course ambience still has no music or ambient audio.
