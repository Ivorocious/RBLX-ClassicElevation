# Classic Ascent — restart checkpoint

Updated 2026-09-05: version 4 adventure and instant-recovery pass.

## Git and Rojo

- Branch: `codex/classic-ascent-environment`. The commit containing this file is
  the v4 checkpoint. No new push, merge or Roblox publish.
- Previous v3: `6cd21d6`; v2: `eed69b9`; original placeholder: `85b8dea`.
- Remote: https://github.com/Ivorocious/RBLX-ClassicElevation.git.
- Main remains the May baseline. User delegates Rojo and version control.
- Run `.tools/rojo-7.7.0/rojo.exe serve default.project.json` on localhost:34872.
  Global Rojo 7.6.1 is incompatible with the updated plugin.
- Rojo was restarted in this pass; source sync was confirmed through Studio MCP.
  Prefer MCP/repo tools and minimize Computer Use.

## Current state

Library model and Workspace preview are builder version 4. The user's manually
edited v3 preview is retained under
`ServerStorage.CourseBuildArchive.ClassicAscent_v3_UserSignEdits_20260905`.
Exact sign snapshots and source-backed relative presentation overrides are saved.
Generated iteration archives are retained; do not delete them blindly.

Three paths connect through shared clearings and 19 ordered checkpoints. There
are 158 central transitions, 159 recovery volumes, roughly 2,157 central route
studs and about 4,700 BaseParts. All ten sections are described in CLASSIC_ASCENT.md.

Implemented: dominant taller mountain and rising sides; coherent camp roof;
forest canopy and overhead rock/snow formations; moving river log bundles;
smaller dry/icy cliffs; three collapsing bridges and stone refuges; lava spurts;
concealed varied rockfall; snowy volley cover; giant summit snowballs. Normal
hazards now recover the same character immediately, heal and count one fall.
Unexpected actual death still has the legacy respawn fallback.

CourseMotionService is registered in Main and observes active-course replacement.
Authored part attributes configure MotionKind, MotionEnd, timings and damage.
CourseHazardService handles existing hazards through RespawnService.RecoverPlayer.
No new gameplay remotes, economy, DataStore, publishing or circuit work.

## Evidence and remaining work

- User's v3 playtest: almost six minutes, several deaths, enjoyable, still wanted
  more immersion. This supersedes the old robot's 2:57 as human pacing evidence.
- V4: one short Studio run, 11 checks passed; no full-course automated traversal.
  Report: docs/artifacts/classic-ascent-v4-quick-check.json.
- Build and source checks pass. Final small geometry changes join bridge ropes
  and move avalanche alcoves outside the rolling lanes.
- Human timing, difficulty, ice feel, projectile cover and 20-player crowd/performance
  remain user playtest work. Nine-minute timeout retained. Do not claim retention
  gains or a 2–3 minute experienced-player completion time.
- Intermission/lobby behavior is deliberately deferred to the planned lobby rebuild.
- Studio is back in Edit mode, ready for manual review.

## Manual fine-tuning

Studio's DEV RACE panel includes **Skip checkpoint**. During Racing it moves the
local official racer to the next checkpoint (then Finish), using normal touch
registration. It is guarded on both client and server and unavailable in live games.

The library model is used for races; Workspace.RaceCourse is only a preview.
Capture Workspace edits back into the library before Play, preserving an archive.
Ensure preserves existing v4 models. Further generator edits need deliberate
regeneration/reconciliation. Keep a Studio place backup for manual geometry and
original lobby/course assets; Git and Rojo do not save or publish the entire place.

No repeated course testing: the user specifically wants to own full playtests.
