# Studio testing controls

During Play, press **F6 → UI PREVIEWS → Voting UI (10-map preview)**. It opens the shared voting screen with the ten illustrated sample maps from the visual reference. These placeholders do not add playable courses. Search, select up to five maps, remove picks, and test Confirm; confirmation stays local. Hide closes it, and reopening keeps the draft and search. The 00:42 timer is a fixed display sample. This Studio-only screen never submits votes, changes rounds, or saves data.

Press Play, then press **F** or click **Fly [F]** to toggle character flight.

- **WASD:** move relative to the camera, including its up/down viewing angle.
- **Space:** move straight up.
- **Left Ctrl:** move straight down.
- **Left Shift:** fly faster.
- Release movement keys to hover. Toggle off to resume normal walking and gravity.

Flight starts off and turns off on death, respawn, or character anchoring. It pauses movement while typing, while the game menu is open, or when the window loses focus. Collisions, hazards, checkpoint checks, and race rules remain active. Flight is unavailable while seated or anchored by staging.

The entry script and controller both require `RunService:IsStudio()`. The controller also requires a client context. This testing control creates no RemoteEvent and does not run in published game sessions.

Tune speed and keys in `src/ReplicatedStorage/Config/StudioFlightConfig.luau`. The controller lives in `src/StarterPlayer/StarterPlayerScripts/Controllers/StudioFlightController.luau` and is started by `StudioFlight.client.luau`. Rojo includes all three through the existing folder mappings.

## Verification — September 11, 2026

The normal client smoke check passed ten cases, including zero-drift hovering, restoring default/nondefault humanoid flags, resuming gravity, removing all flight constraints, refusing anchored activation, and preserving character collision flags. Studio input checks passed F on/off, Space ascent, W movement, Ctrl descent, Shift boost, textbox focus exclusion, and the on-screen button. Respawn left flight off with one GUI and no constraints on the new character. The server context refused activation.

Rojo build and native Luau loading passed. Studio returned to Edit; temporary test objects were discarded. City Run retained its 3,961 descendants. These checks cover one keyboard-controlled Studio client; full races and touch/gamepad flight were not tested.

[Test evidence](artifacts/studio-flight-checks.json), [client smoke check](../tests/studio/StudioFlightSmoke.client.luau).

The controller uses Roblox's [LinearVelocity](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity) and [AlignOrientation](https://create.roblox.com/docs/reference/engine/classes/AlignOrientation) constraints, with [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService) to suspend normal movement keys during flight.
