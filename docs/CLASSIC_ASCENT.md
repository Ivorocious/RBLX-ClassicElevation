# Classic Ascent Point to Point

## Current build

The alpine environment rebuild is implemented on `codex/classic-ascent-environment`.
Version 3 integrates the hiking trail with the mountain and adds active obby hazards.
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
- `src/ServerStorage/CourseBuilders/AscentDetails.luau`: supported waymarkers, checkpoint milestones, start pen, rope spans, and hazard placement.
- `src/ServerScriptService/Services/CourseHazardService.luau`: authoritative kill surfaces, falling rocks and collapsing platforms.
- `src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau`: local
  warm lighting, atmospheric haze and a course-specific sky, restored in the lobby.

`Ensure(library)` creates the course before discovery. Older generated builder versions are retained
under disabled `_Version1`/`_Version2` names when upgrading to version 3. Existing version 3
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
and an end checkpoint, with the final endpoint replaced by Finish. Material-matched milestones, sheltered lanterns, supported waymarkers, and a finish gate identify progress.

| Section | Transitions | Play and setting |
| --- | ---: | --- |
| Trailhead | 10 | Enclosed starting camp, embedded hiking trail, fallen-log warm-up |
| Stepping Gardens | 14 | Narrow stone jumps above lethal hot-spring pools |
| Switchback Climb | 16 | Rising rock steps with lethal glowing fissures |
| Ridge Bridges | 16 | Collapsing timber planks, connected rope spans, broad recovery islands |
| Pillar Yard | 18 | Narrow basalt jumps, molten pools and lethal fissures |
| Broken Causeway | 12 | Ruined limestone spans and warned falling rocks |
| Cliffside Traverse | 16 | Narrow ledges joined to cliffs, with warned rockfall |
| Summit Steps | 18 | Fragile snow ledges that collapse after a warning |
| Skyline | 16 | Narrow ice, lethal red ice seams, and falling ice rocks |
| Summit Run | 10 | Broad final ascent, expedition flags and stone finish gate |

Everything is anchored. Mountain banks and terrain shoulders join the trail. Banks and deep foundations are solid;
small props remain noncolliding. Checkpoint pads remain wide. Decoration must not hide the intended landing
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

## Hazard and staging behavior (version 3)

- 44 lethal surfaces: hot pools, molten pools, glowing fissures and red ice seams.
- 9 fragile platforms. Touch starts a 1.25-second colour warning, then the platform
  and its visual boards disappear for two seconds before restoring.
- 8 falling-rock locations. An amber footprint warns for 1.3 seconds before a
  0.7-second fall; the next cooldown is 2.5 seconds. Per-location offsets vary the
  rhythm without unexplained random instant deaths. Safe checkpoints have no hazards.
- Hazards run only while Racing and only kill official active racers. Existing
  death recovery returns them to their latest checkpoint and records one fall.
- Hazard binding restores the old course and disconnects old touch events before
  binding a new one. Server overlap checks catch moving-rock hits. No new remotes.
- Racers stage once during Intermission. They can move inside the protected start
  terrace; high safety walls and a ceiling prevent climbing out. Timber exit rails
  and an invisible collision gate stay closed through Countdown, then open at Racing.
- Healthy staged racers are not teleported again at the Racing transition.
  Queued respawns and actual escapes return to the pen. The original courses still
  use their existing start platforms, with recovery bounds when no pen exists.

The sky uses Roblox's bundled six-face cloud textures, configured in
`ClassicAscentAmbienceConfig.luau`. The client preserves the original Sky properties
and restores them in the lobby. New custom six-face artwork would require asset
upload; this version requires no external asset dependency.

Official references consulted:
[skyboxes](https://create.roblox.com/docs/environment/skybox),
[deadly lava](https://github.com/Roblox/creator-docs/blob/main/content/en-us/tutorials/use-case-tutorials/scripting/basic-scripting/deadly-lava.md),
[fading traps](https://github.com/Roblox/creator-docs/blob/main/content/en-us/tutorials/use-case-tutorials/scripting/basic-scripting/fading-trap.md).

Additional Studio tests: `ClassicAscentStaging.luau` during a fresh Intermission,
and `ClassicAscentHazards.luau` during a solo official race. Run as temporary server
Scripts replacing their final return with `Staging.Run()` / `Hazards.Run()`.
The traversal runner now waits for rockfall cooldown and jumps over center hazards;
its time is not a measurement of a new player's decision-making.