# City Run V3 - Stage 1 asset kit

**Stage 1 asset creation is complete.** The final kit has 69 editable Blender assets, 22,746 triangles across one copy of the library, and one shared opaque atlas. Both packages are imported into the isolated Studio review gallery. V1 Original, V2 Optimized and the course were not changed. Stage 2 map assembly has not started.

## Deliverables

- [Editable combined Blender library](../assets/city_run/v3/CityRun_V3_Stage1.blend)
- [69-asset manifest and export paths](../assets/city_run/v3/stage1-manifest.json)
- [Catalog and rebuild instructions](../assets/city_run/v3/README.md)
- [Mounting guide](../assets/city_run/v3/MOUNTING.md)
- [Native evidence index](artifacts/city-run/v3/studio10/README.md)
- [Native import audit](artifacts/city-run/v3/studio10/import-audit.json)
- [Editable source/export audit](../assets/city_run/v3/stage1-package-audit.json)

| Metric | Final asset library |
|---|---:|
| Unique meshes | 69 |
| Triangles, one copy of every asset | 22,746 |
| Largest asset | 1,904 triangles |
| Referenced materials / texture images | 1 / 1 |
| Shared opaque atlas | 2048 x 1024 |
| Roblox packages | 2 |
| Native dimension / pivot / visual flag errors | 0 / 0 / 0 |

These are asset-library metrics, not assembled-map cost, draw calls, measured memory or FPS improvements. The atlas's estimated 10.67 MiB RGBA8/full mip chain is an uncompressed estimate, not measured Roblox memory.

## Art and resource approach

Painted window artwork replaces individual window assemblies. Closed building shells, broad color blocks, reusable roofs, storefronts, foliage and skyline clusters supply density without tiny realistic detail. The workshop breaks the residential window pattern; five loading/worksite accents distinguish service and construction areas. All reuse the same atlas. Vehicles, a crane and wrecking-ball skin are visual assets; existing gameplay controllers and collision remain authoritative.

Named Blender collections, individual FBX exports, source generators and mounting metadata allow fine edits. The combined .blend includes all 69 assets. The two uploaded packages remain immutable; clone their normalized canonical meshes for assembly rather than reimporting individual exports and potentially duplicating texture IDs.

## Native Studio verification

Final build: `V3_KIT_05+V3_DISTRICT_ADDON_01`; presentation: `FINAL_STUDIES_10`.

- Base package: asset 113491549212344, 64 meshes / 21,390 triangles.
- District add-on: asset 94105724616140, 5 meshes / 1,356 triangles.
- All 69 use texture `rbxassetid://117032649495568`.
- All 69 match manifest dimensions and source pivots; anchored, non-colliding, non-touching, non-querying, single-sided.
- Original/Optimized inspection templates retain 7,150 / 6,853 descendants. No course edits were made during this pass.
- Local source/FBX checks passed. The final combined Blender library passed collection, triangle, dimension, shared material/image, individual export and uploaded-package hash checks.
- Eleven frozen native overview/forward/reverse images plus six contact closeups cover market, courtyard, construction, terminal, service and workshop studies. These are isolated assembly fixtures, not a playable map.

Find the canonical assets under `Workspace.CityRunV3AssetReview.CityRunV3PaintedAssetKit05` and `CityRunV3DistrictAddon01`. Final market/service studies are under `FinalStudies10`; retained construction is `DistrictStudies09.Construction`, with courtyard/terminal/workshop evidence from studio07. Old review fixtures are preserved inspection overhead, not shipping content. This pass did not publish or automatically save the place; local source and import/fixture scripts are durable.

## Independent final reviews

All four reviewed the same uploaded geometry and final presentation independently. The grounding follow-up adds contact evidence and documentation without changing geometry or scenes.

| Reviewer | Score | Report |
|---|---:|---|
| Luna Max - grounding and mounting | 8.4/10 | [Report](artifacts/city-run/v3/review_luna_ground_10b.md) |
| Luna Max - readability and variation | 8.8/10 | [Report](artifacts/city-run/v3/review_luna_read_10.md) |
| Terra High - composition and cohesion | 8.1/10 | [Report](artifacts/city-run/v3/review_terra_10.md) |
| Sol Low - resource use and editability | 8.5/10 | [Report](artifacts/city-run/v3/review_sol_10.md) |

**All four are strictly above 8.** Earlier lower reviews remain in the evidence folder as history; local render scores were not substituted for native acceptance. Remaining observations concern repetition if clusters are overused, sightline placement, some low-contrast detail, and scene-specific mounting. Address these during assembly using the existing kit.

![Final native market study](artifacts/city-run/v3/studio10/market_reverse.jpg)

![Final native service study](artifacts/city-run/v3/studio10/service_inside.jpg)

## Stage 2 boundary

Assemble V3 scenery around identical course geometry, checkpoints, hazards and timings. Check normal traversal and falling views, real moving-actor attachment, avatar clearance and route visibility. Measure mobile frame time and memory with 20 racers on representative devices before claiming a performance gain. Stage 1 acceptance does not establish these results.
