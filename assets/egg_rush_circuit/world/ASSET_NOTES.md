# Egg Rush world support kit

October21,2026. Current reusable output **candidate_c03 / ER_WORLD_KIT_C03**. Selected P3 A05, B02, C02, D02 and E03 PNGs were inspected for broad gray/green supports, grouped greenery, cream/coral rooms, mint arches and incubation housing. Course layout, jumps and contact remain the lead's work. Phase1 candidate_c04 is unchanged.

## Contents

- `build_environment.py`: saved Blender5.2.1 builder; imports geometry/export helpers from the unchanged `../phase1/build_kit.py`.
- `candidate_c03/ER_Supports.fbx`: three support heights and one bare rock.
- `candidate_c03/ER_Nature.fbx`: one broad shrub group.
- `candidate_c03/ER_Buildings.fbx`: nursery wall bay, mint pipe arch and blue arched window.
- `candidate_c03/ER_Landmarks.fbx`: incubator housing and gate lintel.
- `candidate_c03/ER_world_kit.blend`: editable originals and shared-mesh preview copies.
- `candidate_c03/ER_world_kit_sheet.png`: inspected final overview.
- `candidate_c03/manifest.json`: exact bounds, colors, material parts, atlas offsets, hashes and actual FBX roundtrip checks.

The whole unique kit contains **10 assets,21 material parts,1,460 triangles**. No external textures, small studs, tile grids or noisy surface markings. All art is intended to be noncollidable; native cream pads and intentional gameplay contacts remain separate.

## Build

Run from the repository root in a fresh output directory:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/egg_rush_circuit/world/build_environment.py -- --out assets/egg_rush_circuit/world/candidate_next --render
```

Optional dimensions use `--support-width 10 --support-depth 6 --support-height 20`, for example `--support-height 24`. Height variants are0.5×,1× and1.6× the requested standard height. Width/depth/height must each be at least3 studs. Omit `--render` for exports alone. Existing completed manifests prevent accidental candidate overwrites.

Earlier C01/C02 candidates are retained but superseded. C01 established shape, C02 improved preview framing, and C03 removed overlapping coplanar wall/gate faces that appeared black in the preview. The four export packages in C03 are the handoff; do not mix manifests or hashes across candidates.

## Placement and pivots

Use the established upload workflow only when the lead performs authorized uploads. This builder performs no network, upload, live Blender, Studio, place-save or publishing action.

Units and axes match Phase1: **one Blender unit=one intended stud**, FBX forward-Z, upY, `FBX_SCALE_UNITS`. Coordinate conversion is **RobloxXYZ=(BlenderX,BlenderZ,-BlenderY)**. Names are `ER_<Asset>__<Role>` with one material per part. Parts of an asset share one authored origin.

Each package is a spaced atlas. Preserve imported relative part positions and subtract that asset's `packageOffsetRoblox` from its manifest when assembling a local model. Explicitly restore the authored model pivot; automatic bounding-box pivots differ from top-center support pivots. Editable originals are hidden in `AUTHOR_<Asset>` collections; unhide a collection's objects when editing it. Visible preview copies share mesh data.

Sizes below are rounded **Roblox width×height×depth**, studs:

| Asset | Size | Pivot and intended use |
| --- | --- | --- |
| RockSupportLow | 10×10×6 | **Top center0**, extending downward. |
| RockSupportStandard | 10×20×6 | **Top center0**; normal isolated10×6 pad support. Atlas offsetRoblox28,0,0. |
| RockSupportTall | 10×32×6 | **Top center0**; tall isolated support. |
| BareRock | 7×7×5.4 | Top center0; low outer scenery, without green cap. |
| ShrubGroup | 8.85×6.6×4.35 | Bottom center; three major connected crowns, six broad blocks. |
| NurseryWallBay | 14.8×10.45×3.1 | Bottom center; cream facade faces Blender-Y /Roblox+Z; actual arched opening and coral cornice. |
| MintPipeArch | 10×10×3 | Bottom center; opening7.2 wide and inner arch peak8.6 high. |
| MintArchWindow | 8×8×1.2 | Bottom center; broad opaque blue window with mint frame and cream sill. |
| IncubatorHousing | 14×17.7×14.25 | Bottom center; open chamber3..12 high, diameter about9. Put an existing square-stepped egg inside. |
| GateLintel | 24×3.2×4 | Beam center0; place at the intended gate clearance. Native posts/trigger stay separate. |

Supports taper from their full10×6 bottom footprint to a rock crown8.2×4.62. The flat green cap is **8.6×4.98**, narrower in both directions than a10×6 cream pad. Place the top pivot at the underside of that pad. Vary height by scaling local RobloxY around the top pivot; maintain a sensible cap thickness when authoring large height changes. Width/depth scale independently with their corresponding pad, while preserving the green inset. One support belongs under one pad: never stretch it across a jump gap or link successive crowns with grass/rock shelves. Keep all scenery collision disabled and inspect the visible gap from player height.

The incubator deliberately exports housing only: four cream supports, mint base/dome and coral cap. Its chamber remains open so the prior egg family stays visible; optional native transparent glazing is a separate integration choice. The window exports opaque flat color to avoid relying on FBX transparency behavior.

## Checks and remaining limits

Final build exited0 in Blender5.2.1, about7.9 seconds including the24-sample1900×1100 preview. All four FBXs reimported successfully: exact21 total parts, one material slot per part, positive-area finite geometry and bounds within0.000006 studs. The final overview was inspected and the earlier coplanar-face dark bands are absent. Output hashes, builder hash and unchanged helper hash were rechecked successfully.

The optional Windows thumbnail cache write failed outside the workspace; the requested blend and PNG saved and were opened/inspected successfully. No active editor scene was reset. These are offline authoring checks. Roblox import scale/colors, actual native mesh face coverage, pad joins, scenery shortcuts, player-camera views, native contact, crowd clearance and performance remain unverified.
