# Classic Ascent — shelved 2026-10-27

The owner shelved Classic Ascent. Its source was removed from `src` and `tests`; this folder keeps it outside the Rojo mapping, so nothing here enters the Roblox place.

| File | Contents |
| --- | --- |
| `source.zip` | The 27 removed files, plus the eight edited shared files as they were **before** the shelving edits |
| `manifest.json` | Each file's path, size, SHA-256, whether it was removed or edited, and its Git state at archive time |

Many of these files were never committed (`git` = `untracked` or `modified` in the manifest), so this zip is their only copy. The zip was read back and every file matched its recorded hash.

## What was removed

- Builders: `ServerStorage/CourseBuilders/Ascent*.luau` and `ClassicAscentPointToPoint.luau`
- `ServerScriptService/Services/CourseMotionService.luau` (snowballs, avalanches, lava spurts, rolling/moving logs, rolling boulders) and its `Main` entry
- `ReplicatedStorage/Config/AscentMotionConfig.luau`, `ClassicAscentAmbienceConfig.luau`
- `StarterPlayerScripts/AscentWater.client.luau`
- `tests/studio/ClassicAscent*`

Edited, not removed: `CourseConfig` (editable-course and auto-build settings dropped; the course ID stays in `RetiredCourseIds`), `CourseService` (editable Classic Ascent and auto-build steps), `RaceConfig` (time limit), `VotingArtwork` (row and thumbnail), `ClassicAscentAmbience.client.luau` (profile list), and the `CourseAmbience` / `CourseLifecycle` Studio tests. `CityRunInspectionService` also lost the `"CourseMotionService"` name from one list; that one-word edit is not in the zip.

Not yet done: Studio models (any library copy, the manual preview and the mesh libraries `AscentProps` used) remain in the place. Export each to an `.rbxm` in this folder before removing it. The authored V7 model is already in [retired-maps-2026-09-22](../retired-maps-2026-09-22/README.md).

## Restore

1. Extract `source.zip` to a separate folder. Do not extract it over current work.
2. Copy back the removed files, then compare each edited file with its archived copy and re-apply only the Classic Ascent parts.
3. Remove `classic_ascent_point_to_point` from `CourseConfig.RetiredCourseIds` and put the course model back in `ServerStorage > CourseLibrary`.
