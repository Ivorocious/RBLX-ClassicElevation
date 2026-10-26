# City Run V3 final polish

**V3_FINAL_03C is installed and accepted by all three independent Terra Medium reviewers: 8.4, 8.2 and 8.2/10.** This supersedes the Stage 2 build02 scenery. V1, V2 and the original editor course remain preserved.

## What changed

- Rebuilt stretched city shells to their actual dimensions, with consistent window and floor proportions.
- Added four grounded backdrop buildings to close the reported sky gap. Some secondary courtyard/perimeter openness remains in the reviewers' optional notes.
- Replaced the malformed CP06 roof with a correctly joined building and roof.
- Restored the original terminal's cream arches, dark warm roofs, gabled main hall and clock-tower composition. Consolidated 1,111 original terminal MeshParts into 35 visual building meshes.
- Used stronger coral, teal, ochre and blue city colors, navy glass and cream trim. Removed the washed-out, streaked roof treatment.
- Added limited shared roof props, a courtyard mural, terminal plinths, bronze edges, six emissive lanterns and two finish planters. No new dynamic lights.
- Excluded two unused distant depth sample groups from V3 only; retained the active horizon fade and archived earlier V3 versions.

All changes are scenery-only. The existing course, checkpoints, expert routes, hazards, wrecking balls, vehicles and race scripts retain their source configuration.

## Measured inventory

These are Studio hierarchy counts, not estimates.

| Metric | V1 Original | V2 Optimized | V3 Final03C |
|---|---:|---:|---:|
| Descendant instances | 7,150 | 6,853 | 4,178 |
| BaseParts | 5,411 | 5,209 | 3,178 |
| MeshParts | 3,857 | 3,857 | 1,837 |
| Unique mesh IDs | 2,807 | 2,406 | 1,305 |
| Colliding parts | 617 | 498 | 498 |
| Touch-enabled parts | 502 | 361 | 361 |
| Query-enabled parts | 3,461 | 1,044 | 1,044 |

Final V3 uses **39.0% fewer parts, 39.0% fewer instances, 52.4% fewer MeshParts and 45.8% fewer unique mesh IDs than V2**.

The quality tradeoff is deliberate: final replacement scenery contains 196 MeshPart placements and 27 native accent parts, totaling **206,542 placed triangles**, versus 137,672 for the previous Stage2 build02 scenery. Final03C has fewer overall parts than build02, but more scenery triangles and unique mesh IDs. This is not the triangle total for the entire map. The new opaque 128 x 128 palette is 65,536 bytes as raw RGBA8 pixels, excluding mipmaps and engine overhead; this is not measured texture memory.

No mobile FPS, draw-call, memory, loading-time or 20-player performance result was measured. All three templates and archives remain in this inspection place, which adds storage overhead relative to a V3-only shipping place.

## Verification

- Compared 2,896 gameplay instances, including 2,192 parts outside Decoration: zero differences in the properties covered by the audit.
- New visual placements and accents are anchored with collision, touch and query disabled.
- Checked 282 floor centers against new scenery bounds. Two large consolidated terminal bounding boxes overlapped head-center samples; Blender mesh-level checks found actual surfaces 2.539 and 3.442 studs away. Those boxes cover empty space around the original detailed geometry. Reviewed native route screenshots show clear headroom.
- This clearance check is not a full swept-avatar, jump-arc or moving-hazard playtest.
- Blender audit: 196 placements, 27 native accents, 427 course reference boxes, all 1,111 source terminal meshes matched, zero reported errors.
- Native recovery model round-tripped in Studio with the same 4,178 descendants. Local export: 1,517,068 bytes; SHA-256: `034116081c93d816764d94ce9fea7d0546e864b4086efb61a480e09ac57914e3`.
- Final live check confirmed V1/V2 still have 7,150/6,853 descendants and source plus preview both identify as V3_FINAL_03C.
- Re-running the final dressing and installer-generation scripts produced byte-identical accepted layout and installer.
- No gameplay scripts changed in this polish pass. No place publication or automatic shipping promotion occurred.

## Review evidence

Three Terra Medium agents independently reviewed actual Roblox Studio screenshots of the same final build. Earlier grounding feedback scored base03 at 7.8; the final revision addressed that feedback before all three re-reviewed. Scores were not shared between reviewers.

| Reviewer | Score | Remaining non-blocking observation |
|---|---:|---|
| Architecture and arrival | 8.4 | Outer roofs repeat from high aerial views. |
| Grounding and visual defects | 8.2 | Mural is subtle; top-down view reveals perimeter staging. |
| Resource and visual balance | 8.2 | Secondary courtyard and roof perimeter could use optional backdrop dressing. |

[Independent review record](artifacts/city-run/v3/final03/reviews.json), [native audit](artifacts/city-run/v3/final03/audit.json), [camera list](artifacts/city-run/v3/final03/cameras.json), [Blender audit](../assets/city_run/v3/final03/blender-audit.json), and [mesh clearance checks](../assets/city_run/v3/final03/clearance-geometry.json).

Final native images: [terminal overview](artifacts/city-run/v3/final03/c_terminal_overall.png), [terminal route](artifacts/city-run/v3/final03/c_terminal_main.png), [finish](artifacts/city-run/v3/final03/c_finish.png), [courtyard](artifacts/city-run/v3/final03/c_courtyard_facade.png), [CP06 roof](artifacts/city-run/v3/final03/c_cp06_roof.png), [roof weave](artifacts/city-run/v3/final03/c_roof_weave.png), [construction](artifacts/city-run/v3/final03/c_construction_forward.png), [market](artifacts/city-run/v3/final03/c_market_forward.png).

## Inspect and preserve

Use the existing Studio Play inspection controls to select **V3 Rebuilt**. V1 Original, V2 Optimized, checkpoint jumps and unlimited race time remain available. Edit preview: `Workspace.CityRunV3Stage2Preview`, 8,000 studs east. Installed source: `ServerStorage.CityRunInspectionSources.Rebuilt`.

The prior Stage2 check confirmed the inspection UI starts, but complete manual switching and traversal are not re-certified by this scenery pass. For final gameplay confirmation, switch each variant, enable unlimited time, visit CP03/CP06/CP08 and the finish, then traverse and fall beside the corrected areas.

**Save the current Studio place locally** to retain all templates, archives and inspection settings. The native model below is a separate recovery copy of V3, not a backup of the entire place. Uploading the approved asset package did not publish the game.

## Editable deliverables

- [Native V3 recovery model](../assets/city_run/v3/final03/CityRun_V3_Final03C.rbxm).
- [Blender assembly](../assets/city_run/v3/final03/CityRun_Final03_Assembly.blend): linked scenery, accent references and wire course bounds.
- [Blender asset library](../assets/city_run/v3/final03/CityRun_Final03_Assets.blend), [FBX](../assets/city_run/v3/final03/CityRun_Final03.fbx), [layout](../assets/city_run/v3/final03/layout.json), [installer](../assets/city_run/v3/final03/install.luau), [package hashes](../assets/city_run/v3/final03/package-hashes.json).
- [Approved upload receipt](../assets/city_run/v3/final03/upload-receipt.json): model asset114559795852237, creator86069177.

Build order: `build_final03.py` creates the base asset package; `dress_final.py` applies accepted03C dressing and context exclusions; `assemble_blender.py` rebuilds the final Blender assembly; `prepare_installer.py` writes the Studio installer. The installer also needs the normalized Final03Library and the existing Stage1 kit/add-on libraries in Studio. Do not re-upload unchanged packages; retain the receipt.

The Blender assembly uses course boxes only as visual references. Roblox gameplay geometry remains the authority.
