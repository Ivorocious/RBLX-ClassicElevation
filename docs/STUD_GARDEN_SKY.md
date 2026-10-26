# Stud Garden - Giant's Backyard

The owner-selected Giant's Backyard sky is installed for Stud Garden. Giant clover leaves and dandelions surround the course, with warm daylight, open patches of sky and a softly blurred garden floor below. [Current course and runtime locations](STUD_GARDEN_EDITING.md).

![Native Studio overview](artifacts/stud-garden-v2/giants-backyard-20261006/overview.jpg)

## Implementation

- `src/ReplicatedStorage/Config/StudGardenAmbienceConfig.luau` holds the six uploaded image IDs, lighting and color settings.
- `src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau` selects the profile for `stud_garden_v2` within 500 studs of Start. All nine current checkpoints are within 397 studs. The existing lobby exclusion and the new optional `ExcludeWorkspaceRoots` setting keep the nearby Grand Arcade on the baseline sky.
- Leaving the course area, entering the lobby/stage, unloading the course or selecting another map restores the saved environment before applying the next profile.
- `default.project.json` keeps the lobby environment as the global Edit baseline. The garden sky appears when playing Stud Garden.

Atmosphere density and haze are zero because the first preview produced a flat band across the image's lower hemisphere. Warmth comes from the artwork, daylight and light color correction. The panorama's lower section was revised with ImageGen to avoid a pinched garden-floor texture.

This adds background artwork only. The native course, hazards, scenery and collision settings are unchanged. [Artwork, conversion script, receipts and recovery](../assets/sky/stud-garden-giants-backyard/README.md) are saved locally. The 1774 x 887 source limits actual detail despite the six 1024-pixel output faces.

## Verification - October 6, 2026

- All twelve shared cube edges match with zero channel error. Native overview, player-height, overhead and downward views were inspected.
- All six final textures loaded successfully through the Sky object in Studio Play.
- The actual developer map selector loaded Stud Garden; its real client applied all six IDs, ClockTime 11.4 and course color correction. [Actual Play state](artifacts/stud-garden-v2/giants-backyard-20261006/actual-play.json) and [Play screenshot](artifacts/stud-garden-v2/giants-backyard-20261006/play.jpg).
- All 24 client checks passed, including City Run, Shipwreck, Classic Ascent, Stud Garden, range exits, lobby/Grand Arcade exclusion, unknown map and unload. These checks use a temporary client course fixture while the installed controller runs; cleanup restores the actual course and character. [Results](artifacts/stud-garden-v2/giants-backyard-20261006/transitions.json).
- The real developer teleport back to the lobby restored the cloud-sea sky, ClockTime 14.5 and disabled course color correction while Stud Garden remained loaded. [Lobby result](artifacts/stud-garden-v2/giants-backyard-20261006/actual-lobby.json).
- Final source matches/compiles, test compilation, Rojo build and scoped whitespace checks passed. All 26 recorded baseline environment properties were restored. Stud Garden remains 8,015 parts / 3,751 colliders, with identical content and geometry hashes. Lobby and Grand Arcade also match their starting hashes. [Final Edit verification](artifacts/stud-garden-v2/giants-backyard-20261006/final-edit-check.json).

Studio is back in Edit with the original camera/FOV, no active preview, HTTP access false and the temporary upload server stopped. Public course selection remains disabled; the place was not published. Save the Studio place to retain the current native installation. Multiplayer, physical-device performance and a full race were not tested for this visual change.

## Viewing and future edits

In Studio Play, enter the lobby, open F6 developer controls and choose **Stud Garden — start race**. Look around and overhead, then use **Teleport: Lobby** to confirm the normal sky returns.

`tools/stud_garden_sky_preview.luau` offers `Preview.Apply()` and `Preview.Restore()` for temporary Edit-mode viewing. Run the file through Edit MCP with its final `return Preview` replaced by the desired call. It saves touched properties under `ServerStorage.__StudGardenSkyPreviewBackup`. Always restore before Play or saving, so the garden does not become the global baseline. This helper is outside the Rojo runtime tree.

The focused client test is `tests/studio/CourseAmbience.luau`; run its `RunClient()` in Studio Play with a real course and character loaded outside the lobby/stage. It temporarily anchors and restores the character.
