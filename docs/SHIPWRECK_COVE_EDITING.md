# Shipwreck Cove editing

The editable map is `ServerStorage.CourseLibrary.Course_ShipwreckCove`. Its Folder and editing groups are preserved in storage; Play prepares the playable Model before course discovery.

The startup loader accepts the editable Folder in CourseLibrary, keeps the converted template from archiving itself, and supports the existing Workspace editing path. For visual edits, temporarily move the Folder to Workspace, then return it to CourseLibrary. Keep one current copy. Actual Play verified **Shipwreck Cove** in F6, map selection and restart from storage.

- `EditablePlatforms`: named folders for docks, cannons, wreck, cliffs, cave, waves and expert routes. Each platform model holds its visible cap and locked collision part. Wreck piles include their support, so moving the model keeps them together.
- `Decoration`: scenery and separate palm components. Palm trunks and the five `LampShelf26_*` rocks are solid. Leaves remain decorative.
- `Checkpoints`, `FallZones`, `Bounds`, `StartPen`: gameplay volumes. Keep these names for scripts.
- `ServerStorage.AssetLibraries.ShipwreckCove`: the nine active mesh kits, `Kit04` through `Kit31` as applicable.
- `ServerStorage.CourseBuilders.ShipwreckCove`: Rojo-managed scripts and layout. Edit these in the repository.
- `ServerStorage.Archive.ShipwreckCove`: recoverable map milestones, original imports, old sources, export buffers and retired test scripts. `Before_SC33_OwnerEdits` preserves the map before this pass. Archived scripts are historical and may reference old asset paths.

The hand-edited map is the current visual source. Running the full Installer replaces manual choices with the generated layout; do not rebuild the whole map just to change one object. The generated layout has 33 trunks; the current map has 32 because the owner's removed tree stays removed.

SC33 changed the wreck shortcut to 15 narrow caps on piles, with alternating 12-degree tilt and 18.9% less landing area. Studio R15 traversed all 16 links at speed 16 and jump height 7.2. This proves the tested route is reachable, not its subjective difficulty.

SC33_CANDIDATE_03 installs the repaired mountain mesh on all 38 ridges after explicit owner approval. Studio confirms the new mesh loads; all placements and sizes are preserved. The Blender assembly uses the same corrected geometry. Corrected source asset: `docs/artifacts/shipwreck-cove/review33/SC_R_Horizon28_NormalFix33.fbx`.

Camera remains Fixed. The Roblox place was not published. A new whole-map visual score is not claimed; the Studio screenshot connector disconnected during this pass.
