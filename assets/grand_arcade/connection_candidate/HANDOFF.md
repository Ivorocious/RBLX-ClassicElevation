# C01 connection candidate

This isolated candidate was prepared from the measured Edit lobby and stage. It has **not** been installed or tested in native Play.

The current stage pivot stays `(1552, 374.2, -942)`. The lobby floor is at Y 370, with its front edge at Z -893. The replacement approach has a lower landing from Z -890 to -894, a 16-stud ramp from Z -894 to -910 that rises 4.2 studs, and a level upper landing from Z -910 to -920. Its 18-stud visible floor has 17.8 studs between the parapets and narrows slightly at the posts. The central front rail opening is 20 studs. The original outer rail shapes and bevels are clipped from the saved B10 meshes, preserving both outside spans.

`GrandArcadeConnection_C01.fbx` contains 38 meshes / 5,168 triangles, including four hidden calibration markers. Its `.blend` and builder are isolated from the owner's scene. `build-report.json` and the three preview views document geometry only.

## Installation

1. Reconfirm the intended place is 85558151074819 and Studio is in Edit mode. Recheck the lobby floor, front rail and stage pivot against `current-geometry-inventory.json`; C01 refuses changed measurements.
2. Upload/import only `GrandArcadeConnection_C01.fbx` using the existing model workflow. Keep the import in the controlled AssetImports folder; do not rerun the full lobby or stage builder.
3. Call the new standalone `ServerStorage.CourseBuilders.LobbyBuilders.GrandArcadeConnection` module's `Ensure(lobby, stage, importModel, explicitRecoveryFolder)` from the lead's Edit installer. The recovery folder must be under ServerStorage, preferably within the existing developer archive namespace.
4. The module archives four original front-rail material meshes, its two crossing colliders, three old Approach material meshes, six old Approach colliders, and the twenty original parts of lamps 2/3/5/6. The two original outer rail-post colliders stay in place. Thirty-five original instances retain their exact properties, parent references, original paths, and names in a C01 recovery folder. The new model is `Lobby.GrandArcadeConnection`; it does not alter practice, the stage pivot, presentation data, global lighting, or courses.
5. The module's `Restore(lobby, recoveryFolder)` restores those original instances and parks its own candidate in recovery. It does not delete owner geometry.

Before the live installation, the optional `check_recovery.native.luau` fixture can call `Test.Run(connection, lobby, stage, importModel)` in Edit. It recursively creates empty Models/Folders and copies geometry under its own ServerStorage fixture, retaining pivots and names while omitting scripts and Humanoids. It verifies thirty-five untouched archived originals, all twenty exact lamp offsets, two non-colliding supports, repeated installation, full restoration, and rejection of an incomplete lamp set before any original move. It removes only its own geometry copies afterward. This worker has compiled the fixture but has not executed it in Studio. The lead's initial whole-model-copy attempt was rejected for Animate-script capabilities before live mutation; that copy method has been removed.

The four lamps previously obstructing near-edge paths are copied intact into `RepositionedLamps`: lamps 2/3 at Z -925 move outward from X 1543/1561 to 1541.6/1562.4. Lamps 5/6 at Z -900 receive the same outward move and a +.175-stud rise to meet the ramp. All twenty parts are checked against the live stage pivot before any original is archived; each visible mesh and matching collider uses the same offset. The original parts remain recoverable and unchanged. Repeated `Ensure` returns the installed C01 without moving the lamps again.

Two small native cream footing pads support lamps 5/6 at X 1541.6/1562.4 and Z -900. Each is 3 × .6 × 2.3 studs, with its top at Y 371.575, and reaches inward past the walkway plinth edge. They are visible, anchored, and non-colliding; they add no walking obstruction and require no FBX rebuild.

## Native checks required

- Capture before/after player-height views at the lower lobby, rail opening, ramp midpoint, stage landing, and both quarter views. Inspect the exact rail ends, the base trim, ramp normals, tile joints, old lamps, and upper stage overlap under the existing lighting.
- Confirm all 1,071 original lobby parts still exist with their saved properties. Only the six archived rail instances should have changed parent/path; practice must remain exact.
- Sample floor support every half stud along the three paths at X 1552, 1544.8, and 1559.2. There must be continuous support through the former rail and four-stud gap, no blocking cross rail, and no height seam above the designed incline. This supports diagnosis only.
- Use a normal character starting safely inside the lower lobby at approximately `(1552, 373, -886)`. Disable jumping using the existing Studio test tools, retain ordinary walking speed, and follow the exact route in `native-walk-plan.json` to Z -928 safely inside the stage, then back to Z -886. Repeat at X 1544.8 and 1559.2 near both edges. Walk sideways to the next path only after returning to the lower lobby. A single initial placement on the lobby may prepare the check, but placing onto the stairs/stage or pathfinding alone is not traversal proof.
- Record character positions and health while walking, jump-state restrictions, and successful forward/back MoveTo completions. Check no snag at both landings, no collision from the archived cross rail, and guards stop accidental side departure. Restore any temporary character/test settings.
- Inspect camera/fall-return behavior and existing stage previews afterward. The connection is permanent lobby geometry and must remain outside course replacement.

The local candidate check compiles the module and validates the exact collision profile endpoints, adjoining landings, floor overlaps, and clear width. It does not establish native collision, appearance, player walking, device performance, or a full five-course tournament.
