# Final Source 51 native audit

The helper is rebound to `MC_P3_CLOSEOUT_FC02`, Source 51 / Build 45. It expects 243 scenery units, 639 mesh parts and 198,722 known triangles in each of the two native courses. Source 50's helper and reports remain historical and unchanged.

## Exact inputs

| Input | SHA256 |
| --- | --- |
| Final packet `before/closeout_source51_packet.json` | `016c10fdcc4d70a75af996216a2cef4687b773a3a42bc7ea389b4608273e62c4` |
| Final plan `combined-plan51.json` | `95352d0a83b16c50acb3c6e6e6c99a4d1deffb19cac81105783b1bea9e240f03` |
| `approved-templates51.json` | `6cc817f61cb7174403dd6ec4ed67dcb900ecf61e6fc89434a1b3c28db11fc9e8` |
| `source-specs51.json` | `06fa96497d51bb7c5a2ef568218757929ecb2c9c13c63681aacf762d49940f13` |
| Fresh `before/closeout_protected_baseline49.json` | `2a0cd5a394f1b042311a9b137a97b612cacf5eddcaaafc9e5c2f7dd2e929479d` |
| Approved ER01 template metadata from the Source 49 geometry folder | `e3c10a2ccb037eca569b2377634056eeb1a11524e1ebbcbb9efa37efed898dde` |
| Current LF `WorldAssembly` source | `545ed7ddeac6205559f775d81548e290ff5d8070dff87365325c1ab34932cd8e` |

Plan and baseline paths above are relative to `docs/artifacts/moonlit-citadel/phase3/closeout-20261014/`. The two new metadata files are in this verification51 folder. ER01 metadata remains `tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json`.

## Native execution

Root alone loads `helperpacket51.json` into a new owned recovery folder, creating its four sibling ModuleScripts. Its records contain exact code and per-module hashes. Names are `GeometryAudit49`, `ExpectedAppearance51`, `AuditNative51` and `RunAudit51`. Do not replace the Source 50 helpers or production modules.

After final installation, restore Edit mode, the original camera/lighting and all sample visibility, then call:

```lua
local report = require(ownedVerification51.RunAudit51).Check({
    planRaw = combinedPlan51Raw,
    templatesRaw = approvedTemplates51Raw,
    sourcesRaw = sourceSpecs51Raw,
    protectedBeforeRaw = freshProtectedBaseline49Raw,
    erMetadataRaw = approvedER01Metadata49Raw,
    protector = require(ownedCloseoutRecovery.ProtectedCourse),
})
```

The entry verifies raw input hashes, resolves the current native instances, captures current protected records, and compares the six other saved map models with their fresh pre-install serialization hashes. Root should save the complete report and its `protectedAfter` evidence through the owned receiver. Require `report.pass`, `geometryPass`, `sourceGuard.pass`, `protected.pass` and `otherMaps.pass`. Preserve findings if any fail.

HTTP transport and restoration stay outside the helper. It performs no camera, lighting, script, geometry or physics mutations. A duplicate native source path stops verification rather than guessing an instance.

## What is checked

All 1,278 scenery clone parts are checked for native pose, size, MeshId, color, material, shadow settings, texture identity, source material/asset attributes, inherited transparency/material variant, double-sided setting, render fidelity and each unit pivot. Every part stays anchored and unable to collide, query or touch. All 36 used templates are bound to 101 approved saved native mesh-part identities. The existing actual-vertex proof for ER01 stays bound to its approved asset.

The full nonworld comparison covers accepted contacts and skins, mechanism records, hazards, checkpoints, recovery, finish, owner edits, signs and all 19 arrows. Phase 1, the accepted BL02 library, both arrow templates and existing world lights remain exact. These compare the fresh protected Source 49 baseline; no course physics is rewritten by this helper.

The 1,035 source expectations merge the fresh post-Race-Flow native inventory with the 30 final Source 51 packet records. Only `SceneryRevisions` and `WorldPlan` differ from Source 50. SHA checks normalize native source CRLF to LF. No Source 48 common-script hashes are consulted, and Race Flow's legitimate current text remains the baseline. Root's exact raw-byte filesystem preservation check remains separate.

The saved Lune reader cannot expose collision fidelity. Native clone/template collision fidelity is compared if script-readable, but this is not claimed as an independently frozen saved-property comparison.

## Test boundary

`audit-fixtures51.json` records the same meaningful offline positive and fault checks, updated for the new placements and counts. Synthetic saved-template models are used only to test the audit. No live/native installation, renderer stability, gameplay, multiplayer, device performance or reviewer judgment is established by those fixtures. Root must still run the actual native helper, current day/night route-height views, focused continuous movement evidence and the original independent final gate.
