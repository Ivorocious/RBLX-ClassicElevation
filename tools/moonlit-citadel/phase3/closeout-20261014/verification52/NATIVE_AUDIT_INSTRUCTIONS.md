# Final Source 52 native audit

Use only this helper for `MC_P3_CLOSEOUT_FC03`, Source 52 / Build 46. It expects 243 scenery units, 639 mesh parts and 198,722 known triangles in each course. Source 50 and 51 helpers and evidence stay historical.

## Exact inputs

| Input | SHA256 |
| --- | --- |
| Final `before/closeout_source52_packet.json` | `80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617` |
| Final `combined-plan52.json` | `3b0e592a6695e70a881d30daaa7bfb27915a60bec6acce75e685358b7a7266c2` |
| `approved-templates52.json` | `2f0720835f0afea95de194bd14e40bb83bb0b0cfa2f1e8a12232735fa7293da9` |
| `source-specs52.json` | `301b855cb00fb016b5edb6bf5cc1965a09a8cfe23a7afeb989ab0e3e9481d1cd` |
| Fresh `before/closeout_protected_baseline49.json` | `2a0cd5a394f1b042311a9b137a97b612cacf5eddcaaafc9e5c2f7dd2e929479d` |
| Approved ER01 template metadata | `e3c10a2ccb037eca569b2377634056eeb1a11524e1ebbcbb9efa37efed898dde` |
| Final LF `WorldAssembly` source | `816d5e4cdeeabbdc3fc5e9fc62758afa5a5eca3aa7737ccd9ee087725b845a4d` |
| Native `helperpacket52.json`, five modules, 42,268 bytes | `e925ce14f0c6d8f65cc3f826309700aaee697c3c434e39c36075c954a9b71918` |

Artifact paths are relative to `docs/artifacts/moonlit-citadel/phase3/closeout-20261014/`. Helper metadata is in this verification52 folder. ER01 metadata stays at `tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json`.

## Native execution

Root alone loads the helper packet into a new owned recovery folder. Create its five sibling ModuleScripts: `GeometryAudit52`, `PartAdjustmentOracle52`, `ExpectedAppearance52`, `AuditNative52` and `RunAudit52`. Packet records contain LF source and exact SHA256 per module. Preserve prior helpers and production modules.

After installation, restore Edit mode, the original camera/lighting and sample visibility. Call:

```lua
local report = require(ownedVerification52.RunAudit52).Check({
    planRaw = combinedPlan52Raw,
    templatesRaw = approvedTemplates52Raw,
    sourcesRaw = sourceSpecs52Raw,
    protectedBeforeRaw = freshProtectedBaseline49Raw,
    erMetadataRaw = approvedER01Metadata49Raw,
    protector = require(ownedCloseoutRecovery.ProtectedCourse),
})
```

Require `report.pass`, `geometryPass`, `sourceGuard.pass`, `protected.pass`, `otherMaps.pass` and `partAdjustment.pass`. Save the report through the owned receiver. The helper performs the full protected-record comparison internally and returns a compact `protectedAfterReceipt`; it avoids duplicating the large snapshot. An optional `protectedAfterSink(raw, receipt)` callback can cache that full snapshot in root's owned recovery. `includeProtectedAfter=true` explicitly returns it if needed. Transport and any cache write remain root responsibilities.

The entry checks the intended Obby Tournament place, exact raw input hashes, all 1,278 planned clone parts across both courses, every unit pivot, and 36 templates containing 101 approved material parts. Pose, size, mesh identity, material, color, texture, transparency, material variant, shadows, double-sided setting, render fidelity and saved source attributes are checked. All scenery contact flags stay off. Collision fidelity is compared against current native templates when readable; the offline saved reader cannot independently expose that property.

Only `GrandRearCentralPinnacle / MC_TL_GrandPinnacle__StoneLight`, in TL01 asset `MC_TL_GrandPinnacle`, may use `partLocalScaleOverrides` equal to `[1,1,float32(1.04)]`. Its native Size.Z changes after author scaling. Its centre, CFrame, unit AuthorScale and appearance remain exact. Any second override, another unit/part, a 1.02 factor or additional position/frame/size override is rejected. The adjusted material's complete bounding row clears all 1,586 existing reserve volumes from the 32 route combinations.

Protected records compare the fresh Source 49 recovery: accepted nonworld geometry, mechanism records, hazards, checkpoints, recovery, finish, owner edits, signs and all 19 arrows; frozen Phase 1, accepted BL02 library and both arrow templates; and existing world lights. The helper also compares exactly **four CourseLibrary models** to their fresh serialization hashes. Root's separate Workspace Lobby and Grand Arcade proof remains required and is not counted as two more CourseLibrary rows.

The 1,035 LF source expectations merge the fresh 1,031 post-Race-Flow native source records with all 30 final packet records. Only SceneryRevisions, WorldAssembly and WorldPlan change from Source 51. Current Race Flow source remains the baseline; no old Source 48 common-script hashes are used. Raw-byte filesystem preservation is a separate proof.

## Saved reopen and exact delta

After root exports both final courses to `final/source52-models.rbxm` and the 30 sources to `final/source52-modules.rbxm`, run from the repository root:

```powershell
.\.tools\lune-0.10.5\lune.exe run tools/moonlit-citadel/phase3/closeout-20261014/verification52/CheckSavedReopen52.luau
.\.tools\lune-0.10.5\lune.exe run tools/moonlit-citadel/phase3/closeout-20261014/verification52/CompareSavedWorld51To52.luau
```

The reopen helper binds the final plan and packet, reopens both models and all 30 saved sources, verifies source parity with current durable files, measured triangle counts, contacts/arrows, root pivots and all saved part transforms/sizes against the approved libraries and one override. It writes `final/source52-reopen-report.json`. Full protected native records are still verified by the native helper, not inferred from saved counts.

The delta helper reads the existing `final/source51-models.rbxm` and new Source 52 models. Each course must retain all 243 unit identities, pivots, AuthorScale and local frames, and 638 of 639 part poses, sizes and static appearances exactly. The sole adjusted part must preserve every compared property except Size.Z, which must equal the old depth multiplied by 1.04 within 0.00001 for native float rounding. It writes `final/saved-world-delta51-to52.json`. Both input model hashes are recorded. Optional first and second arguments can supply explicit saved paths.

Saved comparisons do not establish identical rendered shadows or every rendered frame. Source 51 gallery/floor samples retain Source 51 labels; final Source 52 standing/arrival/floor/day views and focused keep movement remain root's fresh evidence. Sampled JPEG sequences do not establish video, every rendered frame, FPS, gameplay or multiplayer performance.

## Focused offline checks

`part-override52-focused-check.json` binds the actual final plan and approved saved template, validates the exact override and checks one corrected whole-part bounding row. `geometry-override52-fixtures.json` tests only the three-part pinnacle unit: correct relief passes; absent relief, 1.02, position movement and another part resize fail. Seven helper/reopen scripts compile. These are prepared audit checks, not live installation, render stability or independent reviewer judgment.
