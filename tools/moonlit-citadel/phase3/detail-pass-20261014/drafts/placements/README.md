# DT01 detail placement draft

The final measured plan adds 78 details to the exact frozen Source52 composition. It targets the owner's bare gate-wall photo, then west-climb jamb walls and roof ends, gallery fronts and planters, lift-wing walls and machinery, keep-window flanks, and one low crown-carrier vine.

`DetailPlan.luau` exposes `Get()` returning the additive units and `{units, meshParts, triangles}`. Every unit uses library `DT01`, exact course-local `localCF`, scale, district and name. Use the corrected kit at `assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01`. Root alone integrates the module and performs native import and appearance validation.

| Template | Units | Mesh parts | Known triangles |
| --- | ---: | ---: | ---: |
| Facade niche | 18 | 54 | 19,008 |
| Quoin/cornice | 14 | 42 | 5,264 |
| Slate dormer | 8 | 24 | 3,744 |
| Chimney vent | 6 | 24 | 2,856 |
| Heraldic banner | 8 | 24 | 4,704 |
| Ivy cluster | 12 | 36 | 21,984 |
| Herb shrub | 10 | 40 | 31,220 |
| Yard winch | 2 | 6 | 3,312 |
| Additive total | 78 | 250 | 92,092 |

The combined world is 321 units, 889 mesh parts and 290,814 known triangles; the WorldPlan portion has 254 units. All additions are anchored decorative art with collision, query and touch disabled. Accepted route geometry, arrows, signs, windows, terrain, crown floor and fall plane are unchanged.

`detail-placement-plan.json` records the exact frames and actual Source52 support faces. `support-measurements.json` records wall probes, roof/ground roots and source object/face indices. The two west-cliff shrubs follow their actual sloped face normals. Gallery shrubs are rooted on the existing soil material, excluding existing leaves from the root measurement. `detail-occupied-rows.json` provides 2,624 occupied component boxes derived from the final R01 geometry. The independent bounded clearance proof is owned by the verification helper.

The first integrated render exposed weak dormer visibility behind vertical gable ends and overlapping new gallery banners/niches. One finite correction moved three west dormers toward their supported edge, two gallery dormers toward the route-facing roof edge, and two gallery banners to separate jamb positions. Counts and existing geometry stayed exact. `render01` preserves the original candidate and its exact plan snapshot; `render02` is the final candidate.

Final original images in `render02` show the gate, west climb, gallery standing view, natural crown standing view and overall composition. The baseline gate image is `render01/01-source52-gate-before.png`. The gate camera is a photo-like course-local view at (-144, 5.5, 138), aimed at (-144, 25, 30); it does not claim the owner's exact native camera. The final scene and assembly mapping are `render02/MC_DETAIL53_CANDIDATE.blend` and `render02/detail-composition-report.json`.

These are unretouched isolated Blender outputs with approximate inspection night lighting. They complement native art inspection and do not establish Roblox import, live appearance, gameplay, performance or owner acceptance. No Studio, live Blender, Rojo, production source or external upload was touched by this draft.
