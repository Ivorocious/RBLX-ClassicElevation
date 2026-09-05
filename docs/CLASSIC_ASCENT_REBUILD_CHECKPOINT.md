# Classic Ascent rebuild — restart checkpoint

Updated: 2026-09-05. Read this first when resuming after usage limits reset.

## User request and acceptance boundary

The user rejected the first course as a barebones proof of concept: uniform
floating platforms, ten names without ten distinct environments, missing mountain
ambience and decoration. Do not call that version a completed experience.
They explicitly requested implementing the complete environment rebuild.
They also requested durable checkpoints because their five-hour limit is near.
Minimize Computer Use; ask the user for easy UI actions instead.

## Git and tools

- Current rebuild branch: `codex/classic-ascent-environment`.
- Starting commit: `85b8dea`, pushed on
  `origin/codex/barebones-placeholder-classic-ascent`.
- `main` remains at `cc78937` (May implementation).
- Remote: https://github.com/Ivorocious/RBLX-ClassicElevation.git.
- User authorized pushing the placeholder. Keep the rebuild locally committed;
  do not assume a new unfinished rebuild should be published or merged.
- Rojo executable: `./.tools/rojo-7.7.0/rojo.exe`; server port 34872.
  Global `rojo` is still 7.6.1 and incompatible with the updated plugin.
- Studio place: Project Classic Elevation, place ID 85558151074819.
  Rediscover its MCP studio ID; IDs change after Studio restarts.
- Last inspection: Edit mode; CourseLibrary has the original template,
  point-to-point, and circuit. The placeholder authoring model was absent.

## Accepted mechanics already implemented

Nine-minute timeout, early ending when all officials finish/leave, arbitrary nested
map-specific fall zones, checkpoint orientation preserved, existing course IDs
kept distinct. Eighteen solo checks passed on the PLACEHOLDER geometry, including
physical traversal at 148.43 seconds. These results do not validate rebuilt geometry.
No human pacing, touch, retention, or multi-client acceptance evidence exists.

## Rebuild direction

Replace rectangular rows with a winding alpine ascent around a mountain: green
trailhead and camp, garden water crossing, switchback steps, timber gorge bridge,
basalt pillars, ruined aqueduct, cliff traverse, snow steps, exposed skyline,
and summit plaza. Sections must differ in obstacle composition AND environment.
Use purposeful geology, vegetation, water, architecture, signage, and local
lighting effects. Inspect real Studio screenshots from player height.

Target familiar skilled run 2:30-3:15, typical 4-6 min, beginner 6-8 min; unvalidated
until playtesting. Preserve nineteen checkpoints and nine-minute maximum.

## Work at this checkpoint

- Initial Studio/repo inspection complete; rebuild branch created.
- Parent is redesigning `ClassicAscentPointToPoint.luau` route geometry.
- A bounded cheaper subagent is writing ONLY `AscentEnvironment.luau` in
  `src/ServerStorage/CourseBuilders`. Check whether it exists and read it.
  Do not assume an old agent remains alive across a restart.
- Module contract: `Build(model, nodes, center)`, with ordered BaseParts carrying
  SectionIndex/SectionName; scenery only, no collision, no global Lighting edits.
- No rebuilt geometry has been synced, created, or tested yet.

## Next steps

1. Inspect git status and this checkpoint; review any new environment module.
2. Complete curved route with genuinely distinct obstacle types and safe geometry.
3. Integrate scenery and course-scoped ambience, preserving existing place assets.
4. Reconcile existing authoring model explicitly; builder Ensure deliberately
   does not overwrite models. Archive prior generated versions rather than delete.
5. Rojo build/sync; create new authoring model; inspect overview AND player views.
6. Update the repository smoke tests for the rebuilt route; physically traverse,
   verify fall zones/ordering/early finish, then record actual limits honestly.
7. Commit milestones and update this checkpoint before yielding.

Never publish the Roblox place automatically. Do not expand into economy,
persistence, monetization, circuit implementation, or unrelated UI work.
