# Floating lobby

A separate [Blender comparison lobby](BLENDER_LOBBY_COMPARISON.md) now sits beside this original build, connected by a middle-floor bridge. Its architecture and review evidence are documented separately.

The lobby has three main floors and a rooftop podium. Cream stone, blue banners, gold rails, warm lanterns and planted terraces follow the owner's September 7 reference images.

- **Middle / arrival:** central spawn terrace and one connected jumping practice loop inside the building. Missed jumps land on the room floor.
- **Upper / shops:** three furnished shop spaces. Their labels and counters are placeholders; there are no purchases or shop interactions.
- **Lower / overlook:** quiet seating and placeholder wins/time boards, with open balconies facing the race area below.
- **Roof:** the first three finishers from the last completed race, with names, times and avatar displays. The display remains during the next race and updates when that race completes. It is local to the running server and is not saved between server sessions.

Automatic race participation uses the existing race flow. An opt-out control is deferred. This build adds no remotes, economy, DataStore changes or combat.

For the current lobby inspection, `RaceConfig.StudioLobbyPreview = true` pauses race startup in Studio. Press Play to explore the lobby without automatic course entry. Set it to `false` and restart Play to resume races. This setting does not pause published servers.

## Source and Studio editing

`src/ServerStorage/CourseBuilders/LobbyBuilders/SkyLobby.luau` builds the architecture. `LobbyParts.luau` contains local building helpers; `LobbyProps.luau` prepares the imported prop templates. Palette and origin are in `src/ReplicatedStorage/Config/LobbyConfig.luau`.

`LobbyService` loads before the race services. It preserves an existing `Workspace.Lobby`; it builds only when that model is absent. This lets Studio edits survive Play. Its fall-return plane brings lobby visitors back to the spawn; active official racers remain under the existing race logic.

Keep these names when editing the model:

- `LobbySpawnPadMarker`, `LobbyPlatform`, `SpawnLocation`, `SpectatorPadMarker`, `LobbyFallReturn`.
- `Podium/Slots/First`, `Second`, `Third`, each with `DisplayMarker`, `WinnerName` and `TimeLabel` descendants.

Architecture is grouped under `Architecture/01_Overlook`, `02_Arrival`, `03_Shops` and `04_Rooftop`. Stairs, gardens, lanterns, banners and podium have separate groups. The model is about 112 studs wide, with floor heights 370, 388, 410 and 428 in the current scene.

Rojo synchronizes scripts; the built geometry and imported mesh templates are Studio content. Save the place locally to retain manual geometry edits. Rebuilding replaces manual geometry, so preserve a copy first. Previous lobby candidates and the original simple lobby are kept in `ServerStorage/LobbyArchive`.

## Blender props

`assets/lobby/create_lobby_props.py` produces the original trophy, crystal and hanging banner kit. The `.blend`, `.fbx`, manifest and preview live beside the script. Model asset **102619480125450** is inserted as `ServerStorage.LobbyPropsImport`; normalized templates live in `LobbyMeshLibrary`. The upload receipt is `.tools/uploads/lobby-props.json`.

The lobby also reuses the existing V7 cedar template where available. If that template is absent, planters use simple foliage. Import the lobby prop asset into `ServerStorage.LobbyPropsImport` before building in a fresh place.

## Validation

`tests/studio/LobbyPodiumService.luau` checks result selection and display updates on an isolated fixture. `LobbyTraversal.luau` checks all five stairs in both directions and all eight practice jumps; `LobbyConnections.luau` checks four stair-landing routes into the shops and podium. Candidate04 passed all 22 movement cases with grounded starts. The main movement fixture copied the live player's WalkSpeed 16 and JumpHeight 7.2 (`UseJumpPower = false`).

Live checks also passed the lobby fall return and all three real avatar loads on a separate podium fixture. See `docs/artifacts/lobby-traversal-04.json`, `lobby-connections-04.json`, `lobby-live-services-04.json` and `lobby-podium-tests.json` for methods and limits.

Visual reviews are recorded separately in `docs/artifacts/lobby-review-*` and `PLAYTEST_NOTES.md`. Generated images, mesh uploads and architecture scores do not establish multiplayer performance or a full human traversal.

All three independent Terra High reviewers passed the same Candidate04: player-scale **8.1/10**, rooftop **8.1/10**, and overall architecture **8.35/10** (front 8.4, three-quarter 8.3). Read the [player](artifacts/lobby-review-player-04.md), [roof](artifacts/lobby-review-roof-04.md), and [architecture](artifacts/lobby-review-front-04.md) reports for screenshots and limits.
