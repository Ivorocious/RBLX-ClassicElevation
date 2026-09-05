# Classic Ascent — restart checkpoint

Updated 2026-09-05 after the alpine environment rebuild and Studio tests.

## Current state

- Branch: `codex/classic-ascent-environment`. This file belongs to the local
  checkpoint commit containing the implemented environment review build.
- Placeholder rollback: `85b8dea` on the pushed branch
  `origin/codex/barebones-placeholder-classic-ascent`.
- Earlier restart checkpoint: `fafc8d4`.
- Remote: https://github.com/Ivorocious/RBLX-ClassicElevation.git.
- `main` remains the May baseline; rebuild is not merged or pushed.
- User rejected the initial rectangular blocks as a proof of concept. Do not
  describe that placeholder, or this unapproved review build, as a finished game.
- User asked us to handle Rojo/Git, minimize Computer Use, and keep restart points.
  They reconnected Rojo successfully after upgrading their plan.

## Implemented and verified

`ClassicAscentPointToPoint.luau` builds version 2: ten named environments, a rising
480-degree spiral, 146 transitions, 19 checkpoints, 147 fall volumes, about 2,175
studs. `AscentEnvironment.luau` supplies mountain rock, shelves, camp, pines,
water, basalt, ruins, snowy vegetation, and summit flags. The scene contains
1,296 BaseParts. Client-local lighting/haze activates near the course and restores
in the lobby. There are no imported sound/music assets.

All 18 solo Studio checks passed on this geometry. Physical traversal: 138.09
seconds (2:18), no unexpected falls. Checked checkpoint order, early-finish rejection,
all splits, early round end, locked results, next-round reset, arbitrary nested
fall zones, repeated binding, and respawn orientation. Rojo build passed. Read
`docs/PLAYTEST_NOTES.md` for details and boundaries.

This does not establish human pacing, retention, touch usability, multiplayer
crowding, device performance, or aesthetic acceptance. The original targets are
2:30–3:15 familiar, 4–6 typical, 6–8 beginner, with a nine-minute maximum. Do not
add artificial waiting to lengthen the clean run.

## Studio and Rojo

- Place: Project Classic Elevation, place ID 85558151074819.
- Last Studio mode: Edit. Rediscover the MCP studio ID after a restart.
- ServerStorage.CourseLibrary.Course_ClassicAscentPointToPoint is version 2.
- Workspace.RaceCourse is a copy of that new model for visible Edit inspection.
- Prior models/review previews are preserved in ServerStorage.CourseBuildArchive;
  the original legacy courses and lobby are preserved.
- CourseService archives the Edit RaceCourse at Play startup and spawns a runtime
  copy from the selected library model. No extra preview duplicates remain in Workspace.
- Temporary test runners/reports were discarded by stopping Play.
- Matching CLI: `./.tools/rojo-7.7.0/rojo.exe` (ignored local tool); port 34872.
  The global `rojo` may still resolve to incompatible 7.6.1.
- Restart command: `./.tools/rojo-7.7.0/rojo.exe serve default.project.json`.
  Check for an existing listener before starting another. Ask the user to reconnect
  the plugin when needed instead of using Computer Use.
- Build: `./.tools/rojo-7.7.0/rojo.exe build default.project.json -o .tools/classic-ascent-validation.rbxlx`.

## Next useful action

Have the user inspect/play the new version and give concrete visual/difficulty
feedback. Tune only that scoped feedback. Human acceptance remains open in TASKS.
The separate Classic Ascent circuit and unofficial recovery remain future work.
Do not publish Roblox or merge the branch automatically.

For further geometry edits, Ensure preserves an existing version 2 model. Archive
that generated model explicitly before rebuilding from a fresh module require;
MCP require caches can otherwise return stale code. Preserve authored assets.
Keep every durable code/geometry change in repository files.

Studio tests must run as temporary server Scripts containing the exact repository
test text with the final module return replaced by `.Run()`. Requiring service
modules from MCP directly can expose a different cached state from the live server
Script environment. Read report attributes through MCP instead. Stop Play afterward.
