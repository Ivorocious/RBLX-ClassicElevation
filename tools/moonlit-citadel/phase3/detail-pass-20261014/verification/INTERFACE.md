# Additive detail verification

These helpers preserve Source52 and inspect only the owner-approved DT01 additions. They do not install scenery, edit production, run gameplay or touch live Studio/Blender.

## Fresh recovery

Root already captured `FreshBaseline52` under `ServerStorage.MoonlitP3ReworkRecovery.DetailPass20261014`. It contains 17,875,424 bytes in 100 chunks, SHA256 `3eda16621db02dcfc6235f8e90ce698d7c2d5dab4f5e1957610fa41dee4dcc7a`. Do not recapture it. Each course has 2,431 objects including its root, 243 world units, 639 world meshes, 19 arrows, 147 colliders, 135 walkables and 55 hazard contacts.

`CaptureSnapshot53` captures all existing course/world objects, readable reflected properties, unavailable-property presence, attributes and tags. It retains owner lighting descendants and the current camera. The embedded schema explicitly omits derived motion readings and engine-generated identities. The native baseline captured 140,366 readable properties per course; saved Lune reads differ, so native and saved comparisons are separate.

Root uses `CaptureSession({editable=...,stored=...})` then `SaveChunks(recovery,name,state)`, receiving a compact receipt plus raw JSON for its sink. The capture yields every 250 records and caching yields every 20 chunks. `ReadChunks` verifies the full cached content.

`ExtractSnapshotCache53.luau` takes the exported cache Folder `.rbxm` and reconstructs/checks the full snapshot JSON locally. The second optional argument is an output filename prefix. It preserves the native SHA/byte receipt rather than rebuilding the snapshot from saved model properties.

## Native comparison

`CompareSnapshots53.Run(before,after,context)` needs the final plan and exact `expected={source,build,packet,candidate,units,meshes,triangles}`. Optional `detailAttributes` binds the exact new root/world detail attributes. Existing object paths, classes, properties, tags and attributes compare exactly, including all Source52 scenery and signs.

The only default changes are the four course identity attributes and three world count attributes. New paths must belong to actual DT01 plan units, their descendants or required district Folders. Added meshes must be anchored with collision, query and touch disabled. Both saved/native comparisons enforce unchanged collider, walkable, hazard and arrow counts.

`AuditNative53.Run(context)` wraps the snapshot/comparison and unchanged `GeometryAudit52` plus `PartAdjustmentOracle52`. Required context fields are `snapshot`, `compare`, `geometry52`, `adjustment52`, `before`, `plan`, `expected`, `editable`, `stored`, `libraries`, `recovery`, `dtManifest`, `sourceGuard`, `otherMaps` and `clearance`. Optional fields are `detailAttributes`, `approvedER01Metadata`, `afterSnapshotSink` and `afterSnapshotName`.

Pass the verified native DT01 library as `libraries.DT01`. The existing geometry oracle already supports that keyed library; no frozen Source52 helper edit is needed. Final expected counts include `architecture`, which must stay at or below 260. Combined limits remain 350 units, 900 meshes and 420,000 triangles.

`CompareSourceGuard53.Compare` accepts fresh native source rows `{path,sha256,class?}` before and after plus four exact expected full path/hash pairs for WorldPlan, WorldAssembly, DetailPlan and DetailGeometry. It allows exactly two changed and two new builders outside this pass's owned recovery. `CompareOtherMaps` compares the root's fresh six path/hash rows. Root captures these sources/maps separately; the full course snapshots do not replace them.

## Focused occupied geometry

`CheckDetailClearance53.luau <actualPlanJson> [fresh52ModelsRbxm] [outputJson] [occupiedMetadataJson]` uses the measured DT01 asset-local occupied boxes. It scans 32 route choices, mechanism envelopes, follow-camera spaces, landing sight, actual stored sign faces and three accepted crown/arrival view corridors. It checks only new details and allows intended scenery attachment to existing walls. Select the actual corrected R01 metadata through the fourth argument.

The measured geometry uses `metadata.assets[asset].occupied={{low={x,y,z},high={x,y,z}},...}`. Root's import calibration must establish that the native DT01 basis matches these authored Roblox axes before the static proof becomes a native placement proof.

## Saved reopen

`PrepareBindings53.py` binds the actual final packet/plan, verified DT01 library and saved candidate files. Required arguments are `--plan`, `--packet`, `--dt-library`, `--dt-library-name` and `--architecture`. Select the actual corrected R01 manifest through `--dt-manifest`. Optional `--detail-candidate` binds a distinct component marker. The default candidate files are `final/source53-models.rbxm` and `final/source53-modules.rbxm`; optional arguments can select another exact file or staged durable source root.

`CheckSavedDetail53.luau [bindingsJson]` reopens both fresh52 models and both candidate53 models, checks all existing object/property arrays, actual added counts and measured triangles, the exact packet/module source text and durable parity. Only WorldPlan/WorldAssembly may differ among old modules; only DetailPlan/DetailGeometry may be added. It also applies the unchanged Source52 part-depth oracle and actual verified native template frames/sizes to the full final plan.

Static/saved checks do not establish rendered detail quality or native temporal stability. Root performs the serial native review and restores the fresh owner camera/lighting before the final snapshot comparison.
