# Classic Ascent v7

**September 8 cleanup:** Historical Studio archives are now in verified local model backups; CourseLibrary contains one accepted Classic Ascent. See [cleanup and recovery](PRE_PHASE_CLEANUP_2026-09-08.md) for the current archive locations. The older history below is retained.

**Current, September 7:** V7 has been restored after the owner rejected V8. The visible Workspace course is now the editing source, and Play uses its edits automatically. Follow the [fine-tuning guide](CLASSIC_ASCENT_EDITING.md); it supersedes the older library/preview instructions below. The original V7 implementation history follows.

September 6, 2026. Installed in Studio after owner approval. Nothing was published.

## Changes

- River logs are 16 studs long instead of 26, with two logs per water row instead of three (40 total). Their full travel stays within the water width. Full-width rest banks replace partial bank pieces; river checkpoints are shorter so they do not extend into adjacent log rows.
- Sixty foam streaks animate locally near the player. The client tracks water parts that arrive after the course model, including replacement rounds. Foam fades at its wrap point.
- Sections 03, 05, 06, 07 and 09 have fixed seeded variations in position, width, angle and height. Lateral changes are bounded between neighboring footholds. Scenery and boundary walls retain the original route frame so scattered platforms do not drag the scenery into the course.
- Sections 03 and 04 have low ravine mist and deeper supporting strata. The bridge layout and rest refuges remain intact.
- Broken Causeway has missing gallery bays and smaller ruined remains. Six falling-rock sources retain their warning indicators and concealed origins.
- Section 07 uses varied mesh boulders with spinning, arcing paths and irregular pauses. Sections 08 and 10 use arcing snowballs with visible surface detail. Ground contacts for bounces are sampled once per launch; a missing surface removes the bounce. These are controlled server trajectories, not unrestricted physics simulations. Existing warning, cover, damage and recovery rules remain.
- Denser forest banks include 46 cedars, varied pines, ferns, roots, flowers and small rocks. Section 09 has larger grouped ice teeth. A sculpted central summit and five distant sculpted peaks complement three layers of background ridges. Atmosphere density increases from 0.29 to 0.34.

## Blender assets

The owner approved upload of `assets/ascent/v7/AscentV7Props.fbx` to creator 86069177. Asset **112260230711687** contains AlpineMassif, Cedar and Fern, totaling five MeshParts. Imported meshes were checked for expected names and absence of scripts. Existing v5 assets remain in use.

The generator, blend file, FBX, manifest and preview are stored under `assets/ascent`. The CLI used a separate headless Blender session. No existing interactive Blender scene was reset. `AscentProps` retains the v5 library and builds a combined v7 template library.

## Verification and limits

- Rojo build passed. Changed Luau entry points compiled in Studio; the complete candidate builder executed successfully.
- 4,170 authored BaseParts, 19 checkpoints, 170 route samples, 340 boundary segments. Both side-boundary rays hit at every route sample.
- Largest measured central projected jump gap in varied sections: about 6.86 studs. Maximum authored height offset: about 1.48 studs. These are geometry checks, not proof of every jump's playability.
- Visual review covered the river, cliff distribution, causeway, summit and distant landscape. Review corrected the initially exposed summit base and excessive row alignment.
- In the focused live check, all 40 logs moved over a 0.6-second server sample. Boulder, snowball and avalanche cycles were active. Client foam movement was observed after fixing late-arriving part discovery; atmosphere density was 0.34.
- The automated rider placement triggered recovery and did not reliably verify idle carry, walking or jumping. The v6 rider-carry issue remains open for owner acceptance. No full-course run, timing run or 20-player performance test was performed.

## Recovery and quick owner check

Both accepted v6 copies are retained in `ServerStorage.CourseBuildArchive`:

- `ClassicAscent_v6_Preview_1788644694`
- `ClassicAscent_v6_Authored_1788644694`

The reviewed v7 candidate remains in `ServerStorage.AscentV7FinalReview_1788644537`. The authored CourseLibrary copy and visible Workspace.RaceCourse are version 7. Preview-only offset models are stored outside Workspace.

Start a Studio race and use **Skip checkpoint** to reach each section. First check the river: walk onto a log, stand, move along it, jump to the next row, and watch a hidden wrap from a bank. Then check the scattered footholds in 03/05/06/07/09, cover against the new projectile paths, depth mist below the bridges, and the clear summit finish.

## Final altitude and scale pass

The owner requested bottomless-looking drops and much larger scenery. The initial `AscentDepthPass` was recorded as `AltitudeRevision = 1`; the final haze refinement below advances it to revision 2. The builder also applies it to future builds.

- Sections 03/04/05/06/07/09 now have their continuous rock floor about 240 studs below the route. Supporting rock columns extend down into two layers of blue-gray haze, replacing the readable shallow floor with an obscured drop.
- Sixty larger cloud emitters form two lower valley rings around the map. Together with the ravine layers there are 132 authored emitters. The client seeds marked emitters when they arrive so the effect does not require waiting for a full particle cycle.
- The 213 scenery trees now measure about 41-94 studs tall. Scenic boulders and ice teeth are also larger. Interactive cover, projectiles, logs and platform geometry were not scaled.
- Rojo build passed. The pass ran twice without duplicating objects. Both installed copies retained all 19 checkpoints and exactly preserved the position, size and collision setting of 884 route, boundary and motion parts. Edit previews covered pit depth and forest scale; a brief live camera review confirmed the loaded haze and deeper drop. No course traversal or crowd/performance test was run.
- Before-update copies are retained in `CourseBuildArchive` as `BeforeAltitude_RaceCourse_1788645754` and `BeforeAltitude_Course_ClassicAscentPointToPoint_1788645754`. Nothing was published. Existing manual rider acceptance remains open.

## Final haze and design acceptance

The owner has passed Classic Ascent Point-to-Point for manual fine-tuning after this final change. The generated design phase is complete. Preserve accepted geometry; do not initiate another rebuild or polish pass without a new request. Design acceptance does not replace the manual gameplay and performance checks listed above.

- Both installed copies now have `AltitudeRevision = 2`. Section 09 has 12 dedicated emitters across two layers, 34 and 51 studs below the route. These sit above the underlying mountain slope, measured about 65–73 studs below the sampled gaps; the previous deeper mist was partly hidden by that slope.
- Native Atmosphere and the existing distant ranges provide map-wide haze: Density 0.37, Offset 0.02, Haze 3.1. All 60 broad valley smoke emitters are disabled, cleared and excluded from prewarming. Their anchors remain in existing models for reversibility; fresh builds do not create them.
- Seventy-two local pit emitters remain, including the 12 in Skyline. Their lifetimes are 16–20 seconds. Disabled emitters are no longer seeded by the client. This reduces broad particle work, but no FPS improvement was measured.
- Rojo build passed. Both installed copies preserved all 884 checked gameplay parts' position, size and collision settings. Applying the pass again added no objects. A brief live Skyline camera check confirmed the obscured lower surface, readable platforms, 12 Skyline emitters, zero active valley emitters and the configured atmosphere values. No course traversal or crowd test was run. Studio was returned to Edit mode.
- Before-update model copies remain in `ServerStorage.CourseBuildArchive` with the prefix `BeforeHazeFinal_`. Nothing was published.

Future level-design work should start with the [reusable chat brief](LEVEL_DESIGN_CHAT_STARTER.md) and [full design guide](LEVEL_DESIGN_GUIDE.md). They record the owner's preferences, failed approaches, effective patterns, review boundaries and manual handoff rules.

## Lobby default and course loading

The visible manual preview is now preserved at `ServerStorage.CoursePreviews.ClassicAscent_ManualPreview_1788647832`. The authored course remains in `ServerStorage.CourseLibrary.Course_ClassicAscentPointToPoint`.

`CourseService.Start` prepares the library without spawning a map. The existing round-start selection step loads a runtime clone; returning players to the lobby at reset unloads that clone. Selection is still the existing fixed configuration, not a new voting screen. With `MinPlayers = 1`, one eligible player can trigger that selection automatically.

Rojo build and `tests/studio/CourseLifecycle.luau` passed in Studio Edit mode: empty startup, library discovery, selected clone, 19 checkpoints, repeated unload and unchanged authored model. No full race traversal was run. For a manual check, start Play, observe loading when the round selects its map, then end the race and confirm reset unloads it before the next selection.
