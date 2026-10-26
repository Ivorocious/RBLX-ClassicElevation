# Map editing and Studio playtests

**Offline archive update, September 22:** retired City Run builds, loose assets, old lobby snapshots and Classic Ascent V7 now live in [`archive/retired-maps-2026-09-22`](../archive/retired-maps-2026-09-22/README.md), outside the game. The earlier `ServerStorage > Archive` locations below are historical. Classic Ascent is no longer an available map, and automatic rebuilding is disabled. Active V3, the lobby and reusable DeveloperAssets remain in Studio.

## Everyday workflow

For UI work without Play, open the **UI Labs** plugin and pick a story from the **Obby Tournament** storybook; it redraws when Rojo syncs a change, and **View on Viewport** shows it full size. [Preview guide](UI_PREVIEW.md).

Studio Play starts in the lobby and holds automatic rounds there. Open **F6 / DEV TOOLS → Start race now** when ready. Selecting a map or restarting a race also releases the hold. This uses `RaceConfig.StudioLobbyPreview`; published servers keep their normal round schedule.

1. Stop Play. Edit City Run V3 at `Workspace > Course_CityRun`. Its `Surroundings` folder travels with the map. Put additional owner-created objects inside the course, for example in `OwnerEdits`.
2. Save the Studio place. Keep a local `.rbxl`/`.rbxlx` copy using Studio's Save to File action before major changes.
3. Press Play. The server uses the visible editable course as its source and creates `Workspace > RaceCourse` for that session. No manual snapshot refresh is needed.
4. Press **F6** or click **DEV TOOLS** to open the testing panel. Scroll for maps and checkpoints. **F** toggles the existing flight controls.
5. Stop Play before making lasting geometry changes. Changes to `RaceCourse` during Play are temporary and disappear on Stop.

Rojo syncs repository scripts/configuration into Studio. It does **not** save Studio geometry back into this repository. Git and a Rojo build alone are not a backup of your authored maps. Save the native Studio place as well. The project mapping preserves Studio-owned Workspace and ServerStorage objects.

Do not run old City Run builder/inspection migrations over V3. The old inspection startup loaded a stored V1 snapshot and hid the edited V3; that startup is retired. `ManualEditing=true` on `Course_CityRun` must remain enabled. Map selection from the panel lasts only for that Play session.

## Playtest controls

| Control | Effect |
| --- | --- |
| Start race now | Skips waiting/intermission/countdown; releases a lobby hold |
| Restart race | Resets racers and reloads the selected map from this session's source |
| Advance to next state | Ends the current timed phase |
| End race | Ends Racing and proceeds toward results, including with unlimited time |
| Return everyone to lobby / hold rounds | Unloads the race map and pauses automatic rounds |
| Unlimited timer | Keeps Racing open until ended, or all racers finish/leave |
| Lobby / Start / Finish area | Moves your character; Finish area does not grant missing checkpoints |
| Stud Garden — start race | After arrival, selects Stud Garden and restarts the Studio race with its hazards and checkpoints |
| Checkpoint buttons | Moves your character and updates checkpoint progress for an active racer |
| Start teleport | Resets active racer checkpoint progress to zero |
| Respawn | Reloads your character using the normal respawn system |
| Map buttons | Selects an enabled map and restarts the round |

After teleporting to the lobby, use Restart race to rejoin. Start and checkpoint teleports are refused while staging is active. These controls exist only in Studio. The server checks Studio mode, the actual player, action names, map IDs, checkpoint indices, and mutation cooldowns. Clients do not provide arbitrary positions or code. `ReplicatedStorage > Remotes > StudioDevControl` is created at runtime only in Studio.

Use **F6 → ROUND CONTROLS → Stud Garden — start race**, or **MAPS → Stud Garden**, after arrival. These installed controls select and load the approved course. Public voting remains disabled. Its source model is `ServerStorage > CourseLibrary > Course_StudGarden`; [the editing guide](STUD_GARDEN_EDITING.md) lists current runtime, test and recovery locations. Earlier V1/V2 patch reports describe historical states.

## Explorer layout

| Location | Purpose |
| --- | --- |
| `Workspace > Course_CityRun` | The one editable, active City Run V3 |
| `Workspace > Lobby` | Authored lobby |
| `ServerStorage > DeveloperAssets > ObstacleKit_Palette` | Reusable obstacle palette; copy desired pieces into the course in Edit mode |
| `ServerStorage > DeveloperAssets` | Other reusable kits and course templates |
| `ServerStorage > CourseLibrary` | Runtime course sources; do not edit this instead of visible V3 |
| `ServerStorage > CourseLibrary > Course_StudGarden` | Approved native Stud Garden source; edit before Play |
| `ServerStorage > CourseBuilders` | Rojo-managed builder modules |
| `ServerStorage > AssetLibraries` | Processed mesh libraries used by builders |
| `ServerStorage > AssetImports` | Source imports used by builders |
| Repository `archive/retired-maps-2026-09-22/retired-studio-archive.rbxm` | V1/V2, old City Run/lobby snapshots, loose assets and legacy tools; absent from game |
| Repository `archive/retired-maps-2026-09-22/classic-ascent-v7.rbxm` | Retired authored Classic Ascent; absent from game |

Offline archive contents are recovery material, not active maps. Leave `__Rojo_SessionLock` alone. Moved objects retain `ArchivedFrom`; the earlier cleanup receipt is inside the native archive at `Archive > DevelopmentCleanup20260922`. A later runtime course replacement may temporarily create `Archive > CourseArchive` during Play; those runtime objects disappear on Stop.

## Recovery and verification

Before cleanup, Workspace and ServerStorage were exported to native `.rbxm` backups in `backups/pre-development-cleanup-2026-09-22/`. Both were read back and deserialized; part/script counts and fingerprints matched. The migration preserved all 3,117 V3 parts' positions and sizes. `tools/organize_development_place.luau` records the approved one-time migration and refuses a second run.

`tests/studio/DevelopmentWorkflow.server.luau` is a temporary server test runner, not mapped into the shipped game. It tests invalid requests, an Edit-mode geometry probe reaching Play, checkpoint progress, unlimited time, round transitions, lobby hold, and City Run → Classic Ascent → City Run. GUI checks run separately on the client because client-created UI does not replicate to the server. Solo checks do not replace multiplayer testing or full manual course traversal.
