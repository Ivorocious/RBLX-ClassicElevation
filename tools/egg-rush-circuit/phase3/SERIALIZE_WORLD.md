# Scoped Phase3 native recovery

`SerializeWorld.luau` returns a ModuleScript with `Run(expectedCandidate)`. Its default candidate guard is `ER_P3_W02_C01`; pass a different explicit Phase3 candidate only when the lead has verified that actual revision. It requires the owned place/creator in Studio Edit mode, Phase3, R03 route identity and an installed `Decoration.HatcheryWorld`.

Stage only this temporary module through the lead's existing tooling, then call its `Run()` in Edit mode. No Studio or native serialization was run by the helper. The script does not use HTTP, change HTTP settings, run gameplay modules, publish, move live inputs or delete originals.

## Exact contents

Six serialized roots:

1. `Workspace.Course_EggRush` at the explicit current candidate.
2. `Workspace.ER_P1_R01_AssetGallery` with exactly 26 direct Models.
3. `ServerStorage.CourseAssetKits.EggRush_P1_R01_K01` with exactly 26 direct Models.
4. `ServerStorage.CourseAssetKits.EggRush_P2_R01_K01` with exactly 27 direct Models.
5. `ServerStorage.EggRushPhase3Meshes`.
6. Detached `EggRush_Phase3_SourceRestore`, containing exactly 25 allowlisted current sources with individual `RestorePath` attributes.

The gallery/kit paths and counts come from the existing `backup_phase2_candidate.luau`; native existence, class and counts are asserted again at execution. No broad archive or unrelated course/system is included.

The source restore set is the four current Phase3 modules (`World`, `WorldPlan`, `WorldKit`, `PerchFoundations`); nine current RestartP2 build dependencies (`Builder`, `Presentation`, `RevisionR02`, `LayoutR02`, `HazardKit`, `RevisionR03`, `ReadableKit`, `ChickenKit`, `ChickenR04`); three RestartR01 build dependencies (`Builder`, `Study`, `Sample`); current `Runtime`, `GuardianPeck`, `ChickenMotion`, `ChickenPeck`, `NativeTraversal`, `ImportKit`; `ServerScriptService.Services.EggRushService`; `StarterPlayer.StarterPlayerScripts.EggRushAmbience`; and `ReplicatedStorage.Config.EggRushAmbienceConfig`. Existing shared race, checkpoint, camera and other project systems remain outside this scoped backup. Restore into the existing project rather than treating the payload as a standalone place.

## Native verification and transport

The script adapts `SerializeChickenR05.luau`: snapshot hierarchy, names/classes, attributes, selected geometry/mesh/GUI/sound properties, normalized Source and internal ObjectValue/PrimaryPart references; native `SerializeInstancesAsync`; detached `DeserializeInstancesAsync`; compare read-back contents; then compare live inputs and source originals again for object identity, unchanged parent, properties, attributes and Source. Numeric tolerance is 0.0005 and Source line endings are normalized to LF. PointLight color, brightness, enabled/shadows and range are also compared. A property outside this explicit coverage is not independently verified by the comparison.

Live geometry is serialized directly. Only the 25 small source containers are cloned into the detached restore tree; the native read-back remains detached and is destroyed after comparison. Original geometry and sources are never deleted, moved or overwritten. Instance, part, model, light and source counts are measured from the actual guarded candidate rather than assumed from an earlier W01 count.

On success, the owned folder `ServerStorage.EggRushPhase3_20261026.WorldRecoveryPayload` contains `Manifest` plus ordered `Chunk_0001`, `Chunk_0002`, … StringValues holding base64 text in chunks of at most 45,000 characters. The manifest records candidate, six roots/counts, restore paths, exact bytes/base64 length/chunk count, native read-back comparison, source paths/normalized sizes, unchanged originals and Adler32. Stored chunk text is checked against the encoded native buffer before exposing the folder. An existing folder is preserved and causes an explicit stop; this is not an overwrite tool.

The lead must fetch every numbered chunk exactly once, concatenate in numeric order, base64-decode to the intended `.rbxm`, and verify decoded byte length and Adler32 against the manifest. Compute SHA256 of the written filesystem file and save that hash with the native manifest/read-back receipt. A tool reporting export success by itself does not satisfy read-back/file verification. The eight Phase3 meshes remain asset-ID references; original `.blend`/FBX files, receipts and generators remain in the repository rather than being embedded in this model.

Only the owned detached verification roots are destroyed by the serializer. Preserve the completed payload until the external file/hash check succeeds; the lead may then remove its own temporary serializer/payload as scoped cleanup. Restore geometry to the manifest's exact paths only after reviewing the target state; merge source containers individually by `RestorePath`, never replace service folders wholesale.

This is a **scoped model/source recovery**, not a whole-place save, publication, final world acceptance or proof that every referenced asset will load on another device. The separate verified native whole-place save remains required.
