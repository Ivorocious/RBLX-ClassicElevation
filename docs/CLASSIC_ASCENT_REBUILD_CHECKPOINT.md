# Classic Ascent — restart checkpoint

Updated 2026-09-05 after version 3 gameplay and environment feedback.

## Durable state

- Current branch: `codex/classic-ascent-environment`. The local commit containing
  this file is the version 3 checkpoint. No rebuild push, merge, or Roblox publish.
- Previous alpine version: `eed69b9` (version 2, before hazards/integration fixes).
- Original placeholder: `85b8dea` on pushed
  `origin/codex/barebones-placeholder-classic-ascent`.
- Remote: https://github.com/Ivorocious/RBLX-ClassicElevation.git.
- Main remains the May baseline. User delegates Rojo/Git handling to us.
- Minimize Computer Use; ask the user for easy UI actions when needed.

## User's latest requirements and implementation

1. Join scenery to the trail: connected banks, shoulders, embedded cliff supports.
2. Replace catwalk pacing: 44 lethal surfaces, 9 collapsing platforms, 8 rockfalls.
3. Integrate signage/checkpoints: supported waymarkers and material-matched milestones.
4. Connect the track and mountain: terrain banks reach into the mountain mass.
5. Clean summit/railings: paired rock/snow slopes and connected rope spans.
6. Stage once during Intermission; protected start pen, closed exit through
   Countdown, no second Racing teleport. Permanent gate wings guide the exit onto
   the first trail. Queued respawns and actual escapes recover into the pen.
7. Course-specific cloud sky and lighting, restoring original values on exit.

Geometry: builder version 3; 146 transitions, 19 checkpoints, 147 fall volumes,
about 2,175 route studs and 1,481 BaseParts. Route geometry source is split between
ClassicAscentPointToPoint, AscentEnvironment and AscentDetails. CourseHazardService
owns runtime hazards. HazardConfig owns timings. Client sky settings live in
ClassicAscentAmbienceConfig. No external uploads or music/audio were added.

## Verification

34 gameplay assertions passed: traversal 10, staging 9, hazards 7, recovery 8.
Full hazard-enabled physical traversal: 176.76 seconds (2:57), no unexpected falls
and all nineteen checkpoint splits. This is an automated informed route, not
human first/repeat timing or retention evidence. The preflight fall is intentional.

Six sky textures loaded successfully. Client course-ID switch restored the original
SkyboxBk and ClockTime 14.5, then reactivated the course sky and ClockTime 15.2.
Sampled route-body terrain intersections returned none after corrections. Real
player-height bridge/snow views and overview/start views inspected. Rojo build
and git diff checks passed. Final cosmetic cleanup places ice strata under their
crumbling pads, removes their loose corbels, and uses round warning footprints.

Not yet established: human fun/difficulty acceptance, keyboard/touch pacing,
multiplayer crowding, device performance or retention. Keep nine-minute maximum;
no waiting was added solely to enforce a run length. Human tuning targets remain
roughly 2:30–3:15 familiar, 4–6 typical, 6–8 beginner. Follow the user's next feedback.

## Studio / restart

- Place: Project Classic Elevation, place ID 85558151074819.
- Last mode: Edit; final model visible as Workspace.RaceCourse. The matching
  authoring model is ServerStorage.CourseLibrary.Course_ClassicAscentPointToPoint.
- Prior versions/reviews remain in ServerStorage.CourseBuildArchive. Legacy
  courses and lobby are preserved. No extra preview model remains in Workspace.
- Stop Play discarded temporary test runners, reports and test-only nested zone.
- Use `.tools/rojo-7.7.0/rojo.exe serve default.project.json`, localhost:34872.
  Check for an existing process/listener first. Global rojo may still be 7.6.1.
- Build: `.tools/rojo-7.7.0/rojo.exe build default.project.json -o .tools/classic-ascent-validation.rbxlx`.
- Builder preserves version 3 models. To refresh changed geometry, explicitly
  archive the prior generated model and use a fresh cloned module require; MCP
  require caches can otherwise expose stale code. Keep durable changes in files.
- CourseService archives the Edit RaceCourse at runtime and spawns the library copy.
- Git reconstructs generated course/scripts; keep a Studio backup for old authored
  lobby/assets. Publishing requires an explicit user request.

## Test execution notes

Use exact `tests/studio/*.luau` text in temporary Play-only server Scripts, replacing
ONLY the final module return with its `.Run()` call. Service modules required from
MCP itself may have separate state from the live server Script environment.
Read report Folder attributes through MCP. Start the staging test immediately after
Play (one sequential tool call avoids missing its twenty-second Intermission).

Traversal waits for rockfall cooldown and jumps center fissures. Do not backtrack
to a takeoff marker after clearing a fissure. Crumble warning is 1.25 seconds; the
original 0.65 seconds was too short for a normal-speed crossing. Hazard tests can
follow staging in the same race; recovery requires the following fresh race.
Stop Play after tests. See PLAYTEST_NOTES.md for exact findings.
