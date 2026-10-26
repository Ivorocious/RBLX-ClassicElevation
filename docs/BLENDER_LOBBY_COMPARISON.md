# Blender lobby comparison

Historical B05 comparison record. The owner selected Blender as the main workflow; [the current B07 lobby](LOBBY.md) replaces the side-by-side layout. Both earlier models are preserved in ServerStorage.LobbyArchive.

The separate **Skycourt B05** lobby sits beside the original Candidate04 lobby. A walkable bridge connects their middle floors. The original `Workspace.Lobby` and existing courses remain in place; automatic races stay paused in Studio through `RaceConfig.StudioLobbyPreview`.

## What was built

All visible comparison architecture, stairs, floors, rails, lettering, planting, furniture, podium trophies, suspension details and the comparison bridge were modeled in Blender. Roblox supplies invisible walking surfaces, lights and fall return. The standard Roblox avatar used in review images is a scale reference, not Blender geometry.

The layout keeps the written requirements: lower boards and overlooks, central middle-floor spawn with one unified practice route, upper placeholder shops, and a rooftop podium. Reference-image text does not add combat or separate practice rooms.

This is an architectural comparison. Shops and board rows are placeholders; the comparison podium has modeled ranks and trophies. The original lobby retains its working last-race avatar/name/time display. No new purchases, race controls, data storage or publishing were added for the comparison.

The lower central stair now ends on a protected landing with room to turn toward the boards. Rear rooftop stair entrances were moved back to open a walking lane between the main stairs and the shop entrance. A return plane below the new building returns falling visitors to its middle spawn.

## Source and rebuilding

- `assets/lobby_blender/build_lobby.py` creates the geometry in a fresh background Blender scene and exports the FBX, `.blend`, previews, JSON manifest and synced `BlenderManifest.luau`.
- `assets/lobby_blender/Skycourt_B05.blend` is the editable Blender file; `Skycourt_B05.fbx` is the imported export.
- `src/ServerStorage/CourseBuilders/LobbyBuilders/BlenderComparison.luau` places the imported model, restores material colors and creates the invisible walking surfaces and lights.
- `src/ServerStorage/CourseBuilders/LobbyBuilders/BlenderManifest.luau` contains generated placement data. Change the Blender generator rather than editing this file manually.
- `tests/studio/BlenderLobbyTraversal.luau` checks connections and practice jumps with a separate R15 character using the live player's movement settings.

The model has 132 exported meshes, including four hidden import calibration markers, and 268,433 triangles. Visible stonework and decoration use mesh geometry; the 338 simple walking/collision shapes are invisible. These counts describe this asset, not measured multiplayer performance.

Asset **92270524522675** was uploaded through the existing encrypted-key uploader. Its receipt is `.tools/uploads/lobby-blender-b05.json`. The inserted source is `ServerStorage.SkycourtB05Import`.

To rebuild in the intended Studio place, first preserve any existing comparison model, insert that asset as `ServerStorage.SkycourtB05Import`, and run this in Edit mode:

```lua
local builders = game.ServerStorage.CourseBuilders.LobbyBuilders
require(builders.BlenderComparison).Install("SkycourtB05Import", require(builders.BlenderManifest))
```

The installer refuses to replace an existing `Workspace.BlenderLobbyComparison`. The four calibration markers correct import scale and orientation. Earlier comparison candidates are preserved in ServerStorage. Rojo synchronizes scripts, not manually authored Studio geometry; the Blender file, FBX and installer are the durable reconstruction path.

## Independent visual reviews

All four assessed the same B05 Studio build from six fresh screenshots. The original lobby visible in some backgrounds was excluded. The two builds share the existing sky and global lighting for a fair comparison. No desktop mouse or keyboard control was used for this task.

| Reviewer | Focus | Score |
| --- | --- | --- |
| Luna Max | Grounding and clipping | 9.0/10 |
| Luna Max | Route readability | 8.6/10 |
| Luna Max | Asset variation and reference fidelity | 8.4/10 |
| Terra High | Composition, scale, atmosphere and cohesion | 8.8/10 |

Reports and original Studio captures are under `docs/artifacts/blender-lobby/`. B02 did not pass the full gate: its reference-fidelity review was 7.6/10. B05 is the reviewed revision; scores were not averaged and no reviewer was dropped. Terra escalation was not needed.

## Play checks

The first movement pass on B04 confirmed the corrected bottom descent/turn, ascent, comparison bridge, both roof approaches and seven practice jumps. It found two cramped shop-floor turns; those were revised in B05. The B04 record is retained as `B04-movement.json` rather than presented as a clean pass.

Final B05 passed all 14 movement cases with grounded starts at WalkSpeed 16 and JumpHeight 7.2: bottom descent/turn, bottom ascent, bridge, both shop connections, both roof routes, and seven practice jumps. Results are in `docs/artifacts/blender-lobby/B05-movement.json`. Rojo build and Python compilation passed. The new fall-return hookup reuses the existing lobby handler; a live player fall was not forced during this comparison.

Automated traversal establishes the tested paths only; it does not establish multiplayer performance or a complete human playtest. The scale figure was removed from the active scene after review; no reviewed architecture changed.
