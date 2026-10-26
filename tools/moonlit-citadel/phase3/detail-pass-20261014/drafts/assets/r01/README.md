# DT01 R01 detail kit

Eight reusable units, 26 material meshes, 9,574 library triangles. Source52 and the original uploaded DT01 are preserved. R01 corrects only the crescent tip joins in `MC_DT_HeraldicBanner__Brass`. All other 25 material geometries, all 26 measured part rows and all eight whole-unit bounds remain exact.

Final files are in `assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01`: editable `MC_DETAIL_KIT_DT01.blend`, selected-material-only `MC_DETAIL_KIT_DT01.fbx`, `manifest.json`, actual cleaned vertices/triangles in `authored-geometry.json`, component boxes in `occupied-geometry.json`, `DetailGeometry.luau`, build receipt and three original 1440×960 PNG previews.

| Unit | Parts | Triangles |
| --- | ---: | ---: |
| MC_DT_FacadeNiche | 3 | 1056 |
| MC_DT_QuoinCornice | 3 | 376 |
| MC_DT_SlateDormer | 3 | 468 |
| MC_DT_ChimneyVent | 4 | 476 |
| MC_DT_HeraldicBanner | 3 | 588 |
| MC_DT_IvyCluster | 3 | 1832 |
| MC_DT_HerbShrub | 4 | 3122 |
| MC_DT_YardWinch | 3 | 1656 |

`DetailRecipes.build_recipes(a,e)` returns `(name, mesh, mounting_notes)` records using the existing architecture module `a` and exporter `e`. Each mesh also has conservative primitive boxes in `.occupied`. Importing the recipe module causes no scene edits. The palette reuses Source52 material keys/RGB; banners use SlateBand, foliage uses Leaf/Foliage, and herb blossoms use Flower.

Units use zero base pivots, Roblox +Y up and intended facade/front +Z, with Blender +Z up/front -Y. The ER01 convention is `Roblox=(X,Z,-Y)`. Material parts retain stable `asset__Material` names and zero Blender object transforms. Manifest `center/size` are Blender axes; `roblox_center/roblox_size` are the intended Roblox axes. Root must verify the real native imported vertex set and necessary import rotation; this offline FBX roundtrip does not substitute for that proof.

`occupied-geometry.json` exposes `metadata.assets[name].occupied`, with low/high XYZ arrays, plus bounds, mesh cost and notes. Niche capital rear reaches -0.21845 in Z, so a pivot offset +0.08 outside the final face limits wall penetration to about0.14. Quoin rear is -0.10 and banner rear -0.14. Ivy spans Z0.0478..0.67; its stem bottom is about-0.015. Ground/roof pieces have near-zero closed bottoms. Use the measured boxes, including the one corrected crescent component box, rather than nominal dimensions.

All 26 material parts and their FBX roundtrip are closed/manifold, have positive island volume/outward winding and no zero-area triangles. The corrected contour has zero proper crossings. Roundtrip vertex matching uses a measured 0.00001 tolerance because import transforms introduce small float differences; arbitrary decimal-rounded equality is not a reliable substitute. `r01-readonly-roundtrip.json` and `kit-freeze.json` bind the exact files and checks.

Run the builder only in a new isolated background Blender process, with an empty new output directory:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/BuildDetailKit.py -- --output <new-output-folder>
```

The authored/export collections are hidden in the saved preview file so the eight zero-origin library units do not overlap visibly. Enable the authored collection to edit a unit. The separate preview copies and mounting walls are excluded from FBX. Root owns upload, native import, assembly, clearance and the final map review; this author has not touched Studio or live Blender.
