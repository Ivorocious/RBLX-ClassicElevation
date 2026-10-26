# Moonlit Citadel BL02 kit usage

The majority Phase 1 kit contains 29 editable source units, exported as 55 material meshes. Use `MC_BL02_sample.blend` for art edits and the checked `MC_BL02_library.fbx` for import. `architecture.py`, `mechanisms.py` and `build_sample.py` reproduce the package in a separate Blender process. The upload receipt identifies Model 138009529483104, creator User 86069177, and the exact FBX hash. This completed upload must not be repeated.

Native library: `ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library`. Durable placement helper: `src/ServerStorage/CourseBuilders/MoonlitCitadel/MeshKit.luau`. The three-area sample is `Workspace.MoonlitCitadelPhase1_BL02`, final candidate `MC_P1_BL02_R04`. The old BL01 and C01 studies are preserved. None is a production race map.

## Placement

Blender uses X right, Z up and front -Y. Native conversion is X right, Y up and front -Z. Every source unit has origin zero. Native origin models preserve that mounting point through whole-model moves and rotation. The table reports the evaluated unit's bounds in native X width, Y height and Z depth; these are useful starting bounds, not contact dimensions or approved dimensions for a finished course.

Keep matched window frame/tracery/panels, turret/body/glazing/spire, car/ironwork, weight/ironwork and pulley/trim at the same mounting frame and scale. Window and turret units mount at their base; the floor mounts at its walking top; car stone mounts at the deck top; weights and pulley wheels use their body center; the lantern cage/core use the hazard body center. The spire mounts at the shaft top. Corbels mount immediately below an independently authored contact. The sample builder gives tested frame/scale combinations.

Use the existing `MeshKit.Place(parent, name, assetName, frame, scale)` with a positive Vector3 scale. Whole-assembly rotation is supported. The sample tests selected turret/roof scale 0.65, pulley scale 0.7, varied rectangular floor skins, and guide/header lengths. Other scales remain untested. Keep windows, spires, lanterns and pulley wheels proportional. Resize floors/straight guides independently only when their skin still matches the simple contact. Rebuild a differently shaped arch in Blender instead of stretching its rise, width and trim independently. After art or hazard-size changes, recheck visible contact and waiting clearance.

All imported art is anchored and noncolliding. Ordinary decoration has query/touch disabled. The visible moving cage/core meshes are queryable for exact hazard overlap; their light is safe. Walking floors, blockers, checkpoint triggers and hazardous red contact volumes are separate native parts. The closed amber window panels use Glass material with zero transparency, preserving the colored pattern without layered transparency. Procedural grain in Blender renders is not an exported texture; native limestone/slate/metal materials supply the current surface response.

| Edit unit | Native bounds, studs (X x Y x Z) | Library triangles |
| --- | --- | --- |
| MC_WindowFrame | 24.00 x 57.98 x 2.74 | 3852 |
| MC_WindowTracery | 18.95 x 53.55 x 0.50 | 1312 |
| MC_WindowGlass | 19.25 x 53.65 x 0.18 | 216 |
| MC_StoneArch | 24.00 x 17.00 x 4.24 | 2100 |
| MC_TurretStone | 7.28 x 28.00 x 7.28 | 3212 |
| MC_SlateSpire | 8.00 x 18.00 x 8.00 | 860 |
| MC_BalustradeStone | 18.00 x 3.00 x 1.02 | 440 |
| MC_BalustradeIron | 16.50 x 2.38 x 0.23 | 1268 |
| MC_CarStone | 14.00 x 1.00 x 12.00 | 1292 |
| MC_CarIronBrass | 13.99 x 3.72 x 11.99 | 936 |
| MC_WeightStone | 4.00 x 8.00 x 2.50 | 92 |
| MC_WeightIron | 4.00 x 7.94 x 0.23 | 168 |
| MC_PulleyIron | 6.80 x 6.80 x 1.49 | 496 |
| MC_PulleyBrass | 6.62 x 6.62 x 1.74 | 836 |
| MC_LanternCage | 4.00 x 7.00 x 4.00 | 1220 |
| MC_LanternCore | 2.90 x 3.33 x 2.90 | 60 |
| MC_KillCasing | 13.99 x 2.00 x 11.99 | 1364 |
| MC_KillRed | 13.92 x 0.05 x 11.92 | 88 |
| MC_KeepShell | 66.70 x 66.00 x 3.95 | 4488 |
| MC_PierStone | 5.20 x 60.00 x 5.80 | 380 |
| MC_FloorStone | 18.00 x 0.95 x 12.00 | 132 |
| MC_GuideIron | 1.45 x 52.00 x 1.59 | 352 |
| MC_CableReturnIron | 11.77 x 2.20 x 0.15 | 308 |
| MC_TurretAmber | 1.86 x 10.49 x 0.06 | 352 |
| MC_Banner | 3.80 x 10.77 x 0.46 | 712 |
| MC_Ivy | 2.44 x 10.47 x 0.28 | 304 |
| MC_ExpertCorbel | 5.80 x 1.90 x 5.00 | 44 |
| MC_RouteArrow | 4.00 x 2.50 x 0.35 | 36 |
| MC_CrownEmblem | 6.80 x 4.80 x 0.53 | 36 |

## Use while developing

Keep the main pointed window, spires, major arch outlines, open car ends and readable landings. Reuse source mesh IDs and the small shared palette. Avoid additional lights or separate geometry for every brick, roof tile, leaf or chain link. The kit deliberately omits individually simulated chains and final night lighting. Distant trees and other map scenery are later discoveries, outside this Phase 1 package.

Before adding many copies, record placed mesh triangles, mesh instances, shared mesh IDs, collider counts, visible shadows and lights. Check a representative player's view and actual contacts. Remove unneeded detail or idle work early; preserve route width, catching surfaces and hazard checks. Record resource reductions separately from measured frame-time gains. The owner's latest direction sets no target device or FPS number.

The BL02 library has 26,956 triangles versus BL01's 79,444. The final three-area assembly has 79,208 placed-mesh triangles versus 272,368, and 273 MeshParts versus 315. Native rough parts add rendering cost. Final counts are in `docs/artifacts/moonlit-citadel/phase1/MC_BL02_R04_geometry_evidence.json`; the open catch return adds six contacts while the corrected Expert chain uses one fewer contact. These counts do not prove device performance, real 20-player racing, human difficulty or final sound suitability.
