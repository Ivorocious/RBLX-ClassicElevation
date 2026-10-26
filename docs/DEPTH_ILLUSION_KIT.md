# Floor and horizon depth kit

Find `Workspace.DepthIllusionKit.CopyThese` beside the obstacle palette. Select the kit in Explorer and press **F** to focus it.

- **01_FloorDepthFade:** horizontal layers fade from a clear top to an opaque bottom, 44 studs below. Use under a drop or open floor edge.
- **02_HorizonDepthFade:** vertical layers fade from a clear front to an opaque back, 44 studs away. Use beyond the playable area to soften or conceal distant scenery.

Each template contains 12 numbered layers. `Layer_01_Near_Clear` is fully transparent and `Layer_12_Far_Opaque` is opaque. Intermediate layers become progressively less transparent. These are stationary layers, not an animated fade or a change to global lighting.

## Placement

1. In Edit, duplicate one model from `CopyThese` with **Ctrl+D**.
2. Move the duplicate into `Workspace.Course_CityRun.Decoration`.
3. Move, rotate and scale the whole model. Keep the clear side toward the player: floor down along local -Y; horizon away along local -Z, viewed from +Z.
4. Select individual layers in Explorer to change Color, Transparency or spacing. Use the same color across all layers for an even haze; keep the far layer opaque when you want a fully concealed background.

All layers are anchored, non-colliding, non-touchable, excluded from queries, and cast no shadows. They do not function as floors or kill parts. Put separate collision or red traps where gameplay needs them. Copy only the numbered model, not the display labels.

Check from normal player height after placement. The edges of the layers are visible from the side, as in the supplied reference; hide those edges behind scenery or extend the model beyond the sightline. The floor prototype is 72 by 72 studs; the horizon prototype is 80 wide by 56 high. The 12 overlapping transparent faces should be checked on target devices after you choose their final coverage and quantity.

## Source and verification

`src/ServerStorage/CourseBuilders/DepthIllusionKit.luau` recreates the kit through `.Build(workspace)` when the existing kit is absent. It never replaces an existing edited kit and requires no upload or runtime script.

Installation verified both models, all 24 layers, decreasing transparency through each stack, opaque far layers, and non-colliding/non-shadowing settings. Actual Studio views were inspected. Existing City Run geometry was preserved. See [kit evidence](artifacts/manual-kit-v2-checks.json). This does not establish performance or appearance at your final placements.
