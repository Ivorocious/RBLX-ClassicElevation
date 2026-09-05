# Classic Ascent Point to Point

## Current build

The alpine environment rebuild is implemented on `codex/classic-ascent-environment`.
It replaces the rectangular placeholder with a rising spiral around a rock mountain,
with camp and pines, garden streams, timber bridges, basalt columns, ruined stone
architecture, cliff ledges, snow, and summit banners. This is an environment review
build. Human visual acceptance, pacing, touch controls, and multiplayer tests remain
outstanding; automated movement tests cannot establish enjoyable pacing or retention.

The rejected placeholder is preserved at commit `85b8dea` on
`codex/barebones-placeholder-classic-ascent`. The original point-to-point course,
circuit, and template are preserved.

## Source and authoring

- `src/ServerStorage/CourseBuilders/ClassicAscentPointToPoint.luau`: playable route,
  checkpoints, recovery volumes, signs, and obstacle details.
- `src/ServerStorage/CourseBuilders/AscentEnvironment.luau`: deterministic mountain
  geometry and scenery; no imported assets or global Terrain edits.
- `src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau`: local
  warm lighting and atmospheric haze near the active course, restored in the lobby.

`Ensure(library)` creates the course before discovery. Builder version 1 is retained
under a disabled `_Placeholder` name when upgrading to version 2. Existing version 2
models are retained, including manual edits. Further builder changes require explicit
reconciliation: archive the prior generated model before rebuilding. Do not delete
Studio-authored courses. Requiring a module alone does not create the course.

Rojo owns the builder scripts, not CourseLibrary, Workspace terrain, or the lobby.
The builder reproduces this course from Git; keep a Studio place backup for the
existing authored assets. Git commits and Rojo sync do not publish the place.
Use the matching Rojo 7.7.0 executable and plugin on localhost:34872.

## Route

The course rises from Y=64 to Y=244 across roughly 2,175 studs, wrapping 480 degrees
around the mountain. There are 146 route transitions after Start: 126 obstacle
platforms, nineteen checkpoints, and Finish. Every section has a midpoint checkpoint
and an end checkpoint, with the final endpoint replaced by Finish. Gold inlays,
lanterns, checkpoint numbers, section signs, and a finish gate identify progress.

| Section | Transitions | Play and setting |
| --- | ---: | --- |
| Trailhead | 10 | Wide ascending stone approach, expedition camp and pines |
| Stepping Gardens | 14 | Staggered stone jumps beside turquoise pools |
| Switchback Climb | 16 | Side-to-side rising rock steps and forest shelves |
| Ridge Bridges | 16 | Narrow timber decks, planks, rope rails, broad recovery islands |
| Pillar Yard | 18 | Staggered basalt tops and tall column clusters |
| Broken Causeway | 12 | Wider gaps between ruined limestone spans and piers |
| Cliffside Traverse | 16 | Narrow offset ledges below rock faces |
| Summit Steps | 18 | Closely spaced snow steps and snowy pines |
| Skyline | 16 | Narrow ice platforms along the exposed upper ridge |
| Summit Run | 10 | Broad final ascent, expedition flags and stone finish gate |

Everything is anchored. Scenery is noncolliding and separated from the playable
ribbon; checkpoint pads remain wide. Decoration must not hide the intended landing
or look like a required traversable path. The build uses native Roblox materials
and geometry; visual ambience currently has no music or ambient sound asset.

## Pacing targets

- Familiar good player: 2:30-3:15; clean target budget 2:40.
- Typical player: 4-6 minutes including mistakes.
- Less experienced player: 6-8 minutes.
- These remain targets, not measured human completion times or retention gains.
- Shared maximum: nine minutes, including older courses when manually selected.
- All official racers finishing or leaving ends Racing early. A remaining official
  racer retains the deadline; the first finisher does not shorten it.
- Ghost and late racers do not hold the official round open.

Frequent checkpoints limit lost progress. Section landmarks provide visible goals,
and wide islands offer pauses without enforced waiting. Tune frustrating sections
before increasing the timeout. Do not add waiting solely to enforce run duration.

## Fall recovery

Each route transition has a local `Recovery_###` volume twelve studs below it, plus
`FallZone_Main` beneath the mountain. There are 147 volumes in total.
`CourseService.GetFallZones()` accepts every BasePart descendant of FallZones,
regardless of name or nesting. RespawnService disconnects old bindings before
rebinding. The existing Y=4 fallback remains. Recovery applies to official active
racers; separate unofficial checkpoint and respawn tracking remains backlog work.

## Verification and human acceptance

See `PLAYTEST_NOTES.md` for actual results and limitations. During Studio Play,
run `tests/studio/ClassicAscentSmoke.luau` as a temporary server Script, replacing
`return Smoke` with `Smoke.Run()`. It requires one player and tests checkpoint
ordering, rejected early finish, recovery, then physical movement across every node.
Read `ServerStorage.ClassicAscentTestReport`. Movement uses Humanoid input; it does
not teleport through the timed traversal. Stop Play to discard the runner.

Run `ClassicAscentRecovery.luau` similarly, replacing `return Recovery` with
`Recovery.Run()`, in the next fresh solo race. It checks progress reset, elevated,
nested and general recovery, rebind behavior, and respawn orientation.
Tests are outside the Rojo mapping and are never shipped as gameplay scripts.

Human acceptance: complete first and repeat runs on keyboard and touch, then test
with 2-6 players. Record completion time, checkpoint splits, falls, timeouts, exits,
and willingness to replay. Check camera room, path clarity beside scenery, platform
edges at section boundaries, and finish readability. Human approval is still needed
before calling the course a finished player experience.
