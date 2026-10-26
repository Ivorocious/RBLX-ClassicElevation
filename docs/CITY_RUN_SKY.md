# City Run — Golden Hour

The approved B concept supplies City Run's warm gold clouds, blue upper sky and late-afternoon light. The six uploaded sky faces and settings are selected for `city_run`; Classic Ascent retains its existing environment and the lobby retains the cloud sea.

## Source and behavior

- `src/ReplicatedStorage/Config/CityRunAmbienceConfig.luau` contains the six texture IDs, orientation, atmosphere, light and color settings.
- `src/ReplicatedStorage/Config/ClassicAscentAmbienceConfig.luau` now also holds Ascent's existing light and color values, unchanged from its previous script constants.
- `src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau` remains the single environment-switching script. It selects a profile by `RaceCourse.CourseInfo.CourseId` when the player is within that map's activation distance. It restores the saved baseline before applying a different profile and on leaving the map. Existing mist prewarming is retained.
- `default.project.json` remains the durable lobby lighting configuration. The global Edit-mode sky is therefore the lobby sky; City Run's environment is visible in Play on that course.

City Run's activation distance is 1,250 studs from Start. The initial inspected course's farthest part center was about 952 studs from Start and the lobby pivot was about 2,123 studs away. These measurements support coverage of the current course while keeping the lobby outside its range. Recheck this distance if the route is moved or expanded substantially.

The texture is distant background artwork and does not add physical clouds or course geometry. Phone appearance and low-end-device performance have not been established by this change.

## Assets and recovery

The [asset folder](../assets/sky/city-run-golden-hour/README.md) contains the generated panorama, reproducible face projection, image hashes, completed upload receipts, full generation prompt and pre-change script/config backups. The 1774 × 887 source limits actual cloud detail even though each projected face is 1024 pixels square. All 12 source face joins match with zero channel error.

## Checks

All six textures successfully loaded through the installed Sky object in Studio Play. The actual City Run client used the new six image IDs, ClockTime 17.2 and enabled course color settings. Luau compilation, Rojo build and whitespace checks passed after correcting the first test's syntax error.

All nine client transition checks passed: the initial lobby baseline, City Run, Classic Ascent, City Run again, leaving the activation range, re-entry, an unconfigured map, re-entry and course unload. This used a temporary local course fixture while the real client script ran. The fixture was removed and the real course restored afterward. The Edit preview Apply/Restore check also restored every touched property exactly and preserved the C08 course's 3,072 descendants and lobby's 2,120 descendants.

[Check results](artifacts/city-run-sky-checks.json)

![Golden Hour on the actual City Run course in Play](artifacts/city-run-golden-hour-play.jpg)

`tests/studio/CourseAmbience.luau` provides the focused client transition test. Run `Test.RunClient()` in Studio Play after a real course and character load. It temporarily substitutes a local course fixture, checks City Run and Classic Ascent switching, distance exit, an unconfigured map and course unload, then removes its fixture and restores the actual course name.

Manual check: enter City Run, look around the full sky including overhead, finish or return to the lobby, and confirm the cloud sea returns. Enter Classic Ascent and confirm its familiar mist/sky. This change does not publish the place.

## Temporary Studio editing preview

`tools/city_run_sky_preview.luau` provides `Preview.Apply()` and `Preview.Restore()` for an approved screenshot review in Edit mode. Apply preserves exact touched values under `ServerStorage.__CityRunSkyPreviewBackup` and adds an owned preview color effect. Restore returns those values and removes only its own preview objects. To execute either action through Studio MCP, read the file and replace the final `return Preview` with `return Preview.Apply()` or `return Preview.Restore()`.

**Restore the preview before Play or saving the place.** Otherwise the temporary City Run sky would become the baseline copied into Play. This helper is outside the Rojo runtime tree; the map-specific client script is the actual game implementation.

The temporary preview was handed to Course Creator for its C08 screenshot reviews. After those captures, Course Creator confirmed that the exact restore helper returned `restored=true` in the intended Edit session before its next Play test. No additional sky test was needed.
