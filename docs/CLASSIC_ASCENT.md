# Classic Ascent Point to Point — Barebones Placeholder

## Current build

**Status: mechanics proof of concept, not the completed Classic Ascent experience.**
The user reviewed this build on 2026-09-05 and rejected its visual completeness.
The ten named groups do not yet provide ten meaningfully distinct sections.
The mountain setting, terrain composition, ambience, and substantial decoration
remain unimplemented. Passing movement and race tests does not establish visual
quality, enjoyable pacing, or acceptance of the course.

`Course_ClassicAscentPointToPoint` / `classic_ascent_point_to_point` is a static
graybox built from `src/ServerStorage/CourseBuilders/ClassicAscentPointToPoint.luau`.
The original point-to-point course, circuit, and template are preserved.

The builder runs before course discovery and only creates a missing model in
`ServerStorage.CourseLibrary`. Requiring the module alone does not build anything.
`Ensure(library)` can also be called in Studio Edit mode to create the authoring
model. Existing models are never overwritten, including after a builder edit.
Builder changes therefore need an explicit reconciliation with an existing
authoring model before they take effect. Keep durable geometry changes in the
builder; Studio-only adjustments are not backed up by Git.

Rojo maps only `ServerStorage.CourseBuilders`; it preserves unknown ServerStorage
instances and does not own the existing CourseLibrary or lobby. A clean checkout
recreates this course, but the existing Studio-authored lobby still needs its place
backup. Publishing is not part of this implementation.

## Route

The route has ten sections, 100 obstacle platforms, nineteen checkpoint landings,
and a separate finish. Each section has a midpoint recovery landing and ends on a
wide landing; the last endpoint is Finish. Broad checkpoint pads connect the
right-angle bends. Section names are shown on signs and stored on route parts.
The generated route measures about 2,360 studs between successive platform centers.
Checkpoint respawns preserve the pad orientation; bend pads face the outgoing leg.

| Section | Character | Skilled budget |
| --- | --- | --- |
| Trailhead | Broad warm-up jumps | 12 seconds |
| Stepping Gardens | Staggered landings | 15 seconds |
| Switchback Climb | Short rising platform sequence | 18 seconds |
| Ridge Bridges | Narrow platforms with passing islands | 14 seconds |
| Pillar Yard | Staggered, rising precision landings | 20 seconds |
| Broken Causeway | Wide flowing jumps | 14 seconds |
| Cliffside Traverse | Offset ledges | 20 seconds |
| Summit Steps | Second sustained climb | 17 seconds |
| Skyline | Mixed widths, offsets, and rises | 18 seconds |
| Summit Run | Broad final approach and finish arch | 12 seconds |

All geometry is anchored. Required jumps use four-stud forward gaps and at most
two-stud rises. Side offsets provide variation without requiring wall hops or
camera tricks. Noncolliding cliffs provide visual context without allowing
scenery shortcuts. Gold marks checkpoint landings and the finish.

## Pacing and retention targets

- Familiar good player: 2:30-3:15; clean route budget 2:40.
- Typical player: 4-6 minutes including mistakes.
- Less experienced player: 6-8 minutes.
- These are unvalidated targets, not measured completion times or retention gains.
- The current shared race timeout is nine minutes (540 seconds), including the
  older courses when manually selected. It is a maximum, not a minimum run length.
- Racing ends early when all official racers have finished or left. A remaining
  official racer retains the deadline; the first finisher does not shorten it.
- Ghost and late racers do not hold the official round open.

## Fall recovery

Twenty local volumes cover the two halves of each section, with a lower general
catch volume. `CourseService.GetFallZones()` discovers all BasePart descendants
of FallZones, regardless of name or nesting. RespawnService disconnects the old
set before binding the new one. The pre-existing global Y=4 fallback remains.
All playable route surfaces are above it.

Recovery still applies only to official active racers. Separate unofficial
checkpoint/respawn tracking remains a backlog item.

## Human acceptance checks

Test the full route on keyboard and touch, and test crowding with 2-6 players.
Record first and repeat attempts separately: completion time, checkpoint splits,
falls, timeouts, exits, and whether players choose another run. Do not treat a
teleported checkpoint smoke test as a timing or jump-reachability test.

Verify immediate start/finish clarity, both turns between terraces, camera space
around signs and cliffs, fall recovery near section boundaries, and a smooth final
approach. Tune slow or frustrating sections before extending the timeout to ten
minutes. Never add waiting solely to enforce the skilled completion target.

`tests/studio/ClassicAscentSmoke.luau` contains the repeatable solo physics smoke
test. During Studio Play, run its contents as a temporary server Script, replacing
the final `return Smoke` with `Smoke.Run()`. Do not save this runner in the place.
It takes control of one character, tests rejected checkpoint/finish shortcuts,
checks local fall recovery and rebinds, then physically walks/jumps all route parts.
Its results appear in `ServerStorage.ClassicAscentTestReport` in the server model.
Stop Play to discard the temporary runner and report. The tests folder is not
mapped into the shipped place.

`tests/studio/ClassicAscentRecovery.luau` similarly runs as a temporary server
Script (replace `return Recovery` with `Recovery.Run()`) in the following fresh
solo race. It checks reset state, elevated/nested/general recovery, and checkpoint
orientation. It adds one runtime-only nested test volume. Stop Play afterward.
