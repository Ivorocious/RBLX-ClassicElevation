# Moonlit Citadel Phase 3 world kit

October 12, 2026. Implementation source only; no Blender build, upload or Studio installation has been run by this helper. The lead controls both live tools. Phase 2 is still owner rejected/unaccepted. The current commission allows course changes and requires five independent final reviewers.

## Concrete source and run

`world_kit.py` adds ten editable architecture units under `MC_P3_WORLD_KIT`, in a separate Blender background process. It loads the accepted `assets/moonlit_citadel/bl02/MC_BL02_sample.blend` into that process, keeps its collections and meshes, and saves a new candidate copy. It never saves over the source. Its default output is `assets/moonlit_citadel/phase3/candidate01/`.

Run with the installed Blender executable:

```powershell
& $blender --background --python-exit-code 1 --python "C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\moonlit_citadel\phase3\drafts\world_kit.py"
```

The optional `-- --skip-render` exports without the two daylight images. The default renders a broad view and a player-height view of one gateway/gallery specimen. This specimen gives shape and scale evidence; it contains no gameplay colliders and is not a race route. The process refuses to run in the live Blender editor, refuses to reuse existing P3 collections, and refuses to overwrite an existing candidate blend, FBX or manifest. For a later rebuild, use `-- --output ...\phase3\candidate02` or another fresh numbered candidate directory.

Expected files: `MC_P3_WORLD_KIT.blend`, `MC_P3_WORLD_KIT.fbx`, `manifest.json`, `build_receipt.json` and the two `world-specimen-*.png` images. The receipt includes hashes and a source-preservation check. The FBX contains the new material units only. No accepted BL02 asset is re-exported or uploaded.

## Editable units

Dimensions below come from the raw authored shapes, before bevel evaluation. Native order is width × height × depth. The generated manifest replaces these with evaluated dimensions.

| Unit | Raw bounds, studs | Purpose |
| --- | --- | --- |
| `MC_P3_GatewayStone` | 27.4 × 23 × 5.04 | Open pointed gate; broad layered arch trim, slender engaged columns and visible stone joints. Opening is 18 wide up to the shoulder, with a 20-high apex. There is no threshold bar. |
| `MC_P3_GalleryArcadeStone` | 24 × 18.67 × 3.69 | Open gallery bay with carved columns, layered arch and high quatrefoil relief. Its opening is 20 wide at the base, with a 16.8-high apex. Use behind or alongside the course. |
| `MC_P3_VaultRibs` | 23.36 × 7.89 × 16.79 | Two pointed end ribs, two crossing diagonal ribs and a central boss. Origin is the ceiling springline, rather than the floor. |
| `MC_P3_FlyingButtress` | 18.94 × 34 × 3.88 | Curved sloping support with an open space below and a stepped outer pier reaching the foundation. |
| `MC_P3_TerraceFascia` | 24 × 7.8 × 2.03 | Shaped under-deck edge with four tapered carved corbels. All geometry is below its deck-top mounting origin. |
| `MC_P3_Parapet` | 24 × 3.59 × 2 | Low crenellated boundary with pointed relief details. Use along outer edges, outside the actual route contact. |
| `MC_P3_SlateGable` | 24.4 × 10.53 × 18.3 | Steep shaped slate roof with stone gable edges and restrained grouped seam bands. |
| `MC_P3_CrownScreen` | 24 × 12.8 × 1.74 | Three open pointed lancets with iron and brass details; crown-side framing with views through it. |
| `MC_P3_PlantPocket` | 8 × 3.1 × 5.01 | Tapered stone basin, inset soil and four grouped foliage shapes. |
| `MC_P3_Cypress` | 4.62 × 13.68 × 4.62 | Sparse, dark pointed tree, with five shaped foliage shells in one editable unit. |

The shapes use actual mesh profiles, arches, hollow contours and tubular ribs. Window and spire shapes remain the accepted BL02 assets. No individually placed bricks, leaves, roof tiles, chain links or dynamic foliage are introduced.

## Reuse and import

Keep the accepted BL02 native library intact. Reuse its window frame/tracery/glass together, turret stone/amber/spire together, banners, ivy, floor skins, balustrades, lanterns and crown emblem through the existing `MeshKit.Place` helper. Do not change the completed BL02 upload receipt or upload its FBX again.

The extension FBX follows the accepted `AssetKey__MaterialKey` naming pattern. Its manifest contains `assets`, `export_parts`, `rgb`, `center`, `size`, `roblox_center`, `roblox_size` and triangle counts. A separate verified native P3 library can hold the ten new templates. The lead must choose how the current placement helper selects that library; do not replace `MoonlitCitadel_BL02Library` or silently redirect every existing placement.

Units use X right, Z up, front −Y in Blender, with every edit-unit origin at zero. Convert points to Roblox `(X, Z, −Y)`. Use whole-model placement frames, positive scale and rotation. Keep arch width/rise proportional; rebuild an arch when a genuinely different passage is needed. Independent straight fascia or parapet length changes require checking the carved shapes and edge alignment.

All extension meshes are visual, anchored and noncolliding, with ordinary query/touch disabled. Native floor contacts, blockers, red hazards, checkpoint triggers, catches and moving mechanisms remain separate. Do not enable decorative roofs or screens as shortcuts.

## Revised course anchors and local settings

These are the route helper's early accepted anchors, in Roblox course-local X/Y/Z. The final route arrays and the lead's installed result remain authoritative. This document does not assemble the map.

| Anchor | Coordinates |
| --- | --- |
| Start | `(−144, 0, 146)` |
| CP01 | `(−144, 28, −112)` |
| CP02 / gallery entrance | `(−44, 52, 104)` |
| Gallery exit | `(132, 66, 104)` |
| CP03 | `(112, 72, −52)` |
| CP04 | `(112, 106, −86)` |
| Shared upper exit | `(112, 140, −120)` |
| Keep center | `(−8, 0, −28)` |
| Crown destination | `(−8, 150, −30)` |

The whole gallery rig moves by `(0, 0, 42)`. The complete lift/brace/catch assembly moves by `(36, 0, −69)`, with no yaw. Architecture follows the settled route, rather than moving only a skin or support away from its gameplay unit.

| Local setting | Architecture and character | Assembly boundary |
| --- | --- | --- |
| Gate court | A broad stone gateway, low court walls, banners, two planted pockets and accepted turret/spire silhouettes. | Keep the start release lane and gate opening clear. Mount the new gateway at a true walking top, with no raised sill or invisible decorative threshold. |
| West stone-arch district | Tall grounded supports, nearby turret recesses and ivy, with glimpses through outer arches to lower terraces. | Early envelope X `[−188, −88]`, Z `[−144, 140]`, Y `12–52`. Place buttresses alongside contacts; never bridge a required jump with a gallery roof or arch strip. |
| South cloister | Lower horizontal bays, ribbed ceilings at selected safe crossings, slate roofs, blue banners and repeated amber window rhythm. | Early envelope X `[−108, 136]`, Z `[126, 178]`, Y `48–52`. Put arcade openings around settled safe walks. An open facade can back a jump sequence; a complete bay must not span its holes. |
| Lantern gallery | Warm hero windows behind the route, cool open exterior edges, few cypresses and low parapets on safe boundaries. | Early envelope X `[−44, 146]`, Z `[68, 114]`, Y `52–66`. Keep the three lantern sweeps exposed, the broad waits readable and the Expert islands visibly smaller. |
| East wall walk | Narrower fortified scenery, more crenellations and fewer windows, with visible machinery ahead. | Early envelope X `[156, 200]`, Z `[−126, 154]`, Y `66–72`. Keep shared contacts at least 12 wide, and open deliberate passing/turning terraces. The wall must frame the route without becoming a second lane. |
| Northeast machinery | Accepted paired lift cars, outside weights and guides, with buttresses and narrow windows behind them. | Early envelope X `[82, 142]`, Z `[−135, −30]`, Y `72–140`. Architecture must clear the complete platform/weight cycle and the exact Expert brace. Do not wrap a solid facade around the bays. |
| Keep and crown | Dominant pointed window, strong slate-spire silhouette and a restrained open crown screen, with a clear look back toward the start. | The crown arrival remains open, without props or lamps between the final landing, finish trigger and continuing racers. Place screen and spires beside/behind arrival, with lower castle layers visible through them. |

Only repeat a kit bay after inspecting one finished segment at player height. Pair visible load-bearing piers with a foundation or the top of a real lower structure. For a terrace at Y52, a 34-high buttress must either mount at Y18 on a real lower wall/terrace or use a verified grounded support below it. Do not float its base at an arbitrary height. Use accepted pier lengths where a taller uninterrupted foundation is needed.

Keep the dominant hero window readable from the gallery and crown approaches. Repeated small windows, banners and foliage belong at secondary supports. Give each district its own proportions and prop mix; do not cover every wall with identical windows or scatter spires through every landing view.

## Clearance rules for the lead's assembly

Use the route helper's final contacts and the clearance helper's final report, including their unresolved internal overlaps. The early clearance findings are material: `GalleryNormalExit/Causeway_2_1` under `ExpertAfter3`, `UpperNormalGateTakeoff` under `BraceStep1`, and a catch return under shared arch landing 5. A rigid group translation alone does not resolve those within-group conflicts. Do not place close roofs until those contacts are repaired.

- Keep the body volume from walking top to +7 studs clear; retain at least 12 studs of ordinary headroom.
- For jumps, clear the space to 15 studs above the higher endpoint. Behind the avatar, reserve camera depth 11, width 8 and height to +18.2. Put vault springlines at least +18.2 above the relevant top; ribs and roofs rise above that.
- A lantern with radius-14 suspension, 4×7×4 cage and ±32-degree sweep occupies about ±11.3 studs locally. Reserve at least ±13.3 with the preliminary 2-stud margin and verify the full moving model, chain and header, rather than only its still pose.
- For the translated lower and upper lift bays, roof undersides above passenger travel require at least Y124.2 and Y158.2 respectively. Side frames may extend lower only outside the actual passenger and weight envelopes.
- Keep walking-floor artwork within 0.35 studs of its native contact edge. Fascia and corbels sit below; avoid projecting attractive safe-looking trim beside the contact.
- Keep parapets and foliage outside takeoffs, receiving edges, catches, merges and mechanism waits. Inspect forward, reverse and landing views; leave the next destination visible.

The manifest's `occupied_boxes_blender` describe the structural pieces, including separate thin boxes around arch bands and ribs. Hollow arch passages are excluded. These are conservative visual-clash proxies, not new gameplay colliders. Transform them with the same placement frame and scale as the asset. Reused BL02 pieces need their own actual bounds; the extension proxies do not cover them.

## Checked and pending

The helper ran a raw recipe check using the accepted geometry helpers without launching Blender: finite coordinates, valid face indices, one material/smoothing entry per face, closed-edge topology and raw bounds all passed. Ten units contain 7,644 raw triangles and 30 used material groups before bevel evaluation. Each raw asset is below 1,800 triangles. These are source estimates, not final imported costs.

The builder checks evaluated finite/nondegenerate triangles, indices, material assignments, closed source islands, each island's outward winding, dimensions, origins and budgets before export. Limits are 26,000 library triangles, 7,000 per asset and 40 material meshes. It records actual counts after evaluation. No textures, new runtime lights, scripts or simulated props are added by this kit.

Pending lead checks: run the builder; inspect both daylight specimen views and source editability; confirm output hashes/new-only FBX; verify native scale/material/axis/pivot; inspect placed counts and actual reuse; assemble only against final contacts; recheck affected player/camera/mechanism spaces. Apply final night lighting last and inspect route/hazard/window readability. Geometry counts do not prove FPS, device suitability, 20-racer capacity, human pacing or owner acceptance.
