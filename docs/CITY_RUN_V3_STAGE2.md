# City Run V3 — Stage 2

> Historical build02 report. Current scenery is **V3_FINAL_03C**; see [the final handoff](CITY_RUN_V3_FINAL.md) for current metrics, reviews and recovery files.

Build **V3_STAGE2_02** is assembled and installed as the third Studio inspection template. The scenery and resource review is accepted by four independent reviewers. The inspection controls load in Play mode; manual switching, traversal, and target-device performance checks remain separate, as recorded below.

## Where to inspect

In Studio Play mode, open **City Run inspection** and cycle **V1 Original → V2 Optimized → V3 Rebuilt**. The existing checkpoint jumps and unlimited-time option remain available. Only the selected map is loaded into Workspace during inspection. The preserved templates and review archives stay in ServerStorage, so this inspection place is larger in memory than a shipping place containing only V3.

Edit-mode V3 preview: `Workspace.CityRunV3Stage2Preview`, 8,000 studs east of the original. Source: `ServerStorage.CityRunInspectionSources.Rebuilt`. V1/V2 sources and the original editor course were not replaced. The preview and asset gallery are parked during Play mode and return when Play stops.

No place was published, no V3 shipping promotion was performed, and the entire Studio place was not automatically saved. The separate native V3 model is saved locally below.

## Delivered files

- [Native Rebuilt template](../assets/city_run/v3/CityRun_V3_Stage2.rbxm) — complete RaceCourse + Context; 1,013,060 bytes.
- [Editable Blender assembly](../assets/city_run/v3/CityRun_V3_Stage2.blend) — 350 linked visual placements, 31 mesh types, 427 wire reference boxes.
- [Layout](../assets/city_run/v3/stage2-layout.json) — named placements and source replacement paths.
- [Studio assembler](../assets/city_run/v3/assemble_stage2.luau) — uses preserved V2 plus the normalized Stage1 kit; archives earlier V3 candidates.
- [Blender assembler](../assets/city_run/v3/assemble_stage2_blender.py) and [Blender audit](../assets/city_run/v3/stage2-blender-audit.json).
- [Package manifest and hashes](../assets/city_run/v3/stage2-manifest.json).
- [Native geometry audit](artifacts/city-run/v3/stage2/build02/audit.json) and [17-view camera list](artifacts/city-run/v3/stage2/build02/cameras.json).

The Blender assembly is scenery-only. Wire boxes describe course reference bounds; they are not replacements for Roblox collision geometry. Blender scene origin corresponds to Roblox `(3500,0,0)`; `(x,y,z)` maps to Roblox `(x+3500,z,-y)`. Objects are grouped as Architecture, Roofs, and Props, with a layout index and asset ID. Mesh data is linked so shared edits can update multiple instances. Make an individual mesh copy before changing a single instance's vertices.

## Measured map inventory

| Metric | V1 Original | V2 Optimized | V3 Rebuilt | V3 reduction vs V2 |
|---|---:|---:|---:|---:|
| BaseParts | 5,411 | 5,209 | 3,297 | 36.7% |
| MeshParts | 3,857 | 3,857 | 1,945 | 49.6% |
| Unique mesh IDs | 2,807 | 2,406 | 1,166 | 51.5% |
| Descendant instances | 7,150 | 6,853 | 4,298 | 37.3% |
| Colliding parts | 617 | 498 | 498 | unchanged |
| Touch-enabled parts | 502 | 361 | 361 | unchanged |
| Query-enabled parts | 3,461 | 1,044 | 1,044 | unchanged |

V3 replaces 2,257 scenery parts with 350 kit instances using 31 shared mesh types and the existing opaque atlas. Those new visuals total 137,672 placed triangles. This is **not the triangle total for the whole map**: preserved obstacles, moving vehicles, landmarks, and other retained objects add geometry. The one-copy asset-library triangle count is also a different metric.

There is no measured mobile FPS, draw-call, memory, loading-time, server CCU, or 20-player capacity result. A reduction in instances and mesh IDs is a resource improvement, not proof of a particular frame-rate improvement. All three templates and previous review archives remain in this inspection place; use a deliberately prepared V3-only shipping copy for representative device measurements.

## Preservation and verification

- Compared 2,896 gameplay instances, including 2,192 BaseParts outside Decoration: **zero differences** in the tested transforms, sizes, attributes, mesh/texture IDs, pivots, and physics flags.
- V2 and V3 retain identical collision/touch/query counts.
- Checked 282 floor-center clearance boxes against every new visual: **zero overlaps**. This is a coarse landing-center check, not a swept avatar, jump-arc, or live moving-hazard test.
- All 350 new skins are anchored and have collision, touch, and query disabled.
- Blender audit: correct build, all 350 transforms/sizes, 31 shared meshes, 137,672 triangles, zero errors.
- Native export was deserialized in Studio: 4,298 descendants, matching course pivot, 350 visuals. SHA-256: `9930d5308e96daef9f73df4af9e11f92d69e9a0725a4d3b6911fb0fa30155559`.
- Rojo project build passed. Updated inspection script sources were mirrored into Studio from the repository.
- Play mode starts and the inspection UI loads. The Assistant tool cannot directly require the service or fire the inspection RemoteEvent because of Studio capability restrictions. Manual variant switching and controls therefore remain pending; do not interpret the static audits as a full playtest.

The course's existing wrecking balls, depot sliding panel, train, cars, crumbles, rotors, conveyors, checkpoints, expert jumps, and timers retain their source configuration. Some deliberately narrow walls and moving hazards obscure the next landing in particular static poses. This pass preserves those gameplay choices.

## Independent review — same final build

| Reviewer | Focus | Score |
|---|---|---:|
| [Luna Max](artifacts/city-run/v3/stage2/review_luna_ground02.md) | Grounding and clipping | 8.2/10 |
| [Luna Max](artifacts/city-run/v3/stage2/review_luna_read02.md) | Route readability and variation | 8.2/10 |
| [Terra High](artifacts/city-run/v3/stage2/review_terra02.md) | Composition, scale, atmosphere | 8.2/10 |
| [Sol Low](artifacts/city-run/v3/stage2/review_sol02.md) | Resource use, editability, visual usability | 8.6/10 |

All reviewed build02 independently. Earlier lower scores remain in the evidence folder. First-pass camera errors were corrected using the actual course colliders; build02 also lowers/narrows the hall roof, adds a court mural, and fills distant gaps with reusable skyline silhouettes. Review scores cover visual/resource acceptance, not unmeasured runtime or device performance.

Remaining observations: repeated facades, stark depot entry, tight expert corridors, the inherited head-height court member, and exposed gray ground in overhead views. Normal traversal and falling views were prioritized as requested. Changing inherited course geometry or hazards would need a separate gameplay task.

## Manual acceptance check

1. In Play, switch Original → Optimized → Rebuilt → Original. Confirm the course restarts and only one active course/context exists.
2. Select Rebuilt again. Try Next checkpoint, Jump to start, and Unlimited time. Confirm the controls match their labels and respawn follows the selected course.
3. Check a moving ball, depot sliding panel, train, crumble, conveyor, and finish/restart. Verify each still behaves like the original.
4. Save the Studio place locally to preserve all three templates and current inspection settings. Keep the native V3 export as an independent recovery copy.

![V3 market](artifacts/city-run/v3/stage2/build02/market_forward.jpg)

![V3 terminal route](artifacts/city-run/v3/stage2/build02/terminal_crumble.jpg)
