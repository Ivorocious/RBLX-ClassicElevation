# Art-only environment draft

The current commission and Source38 Ideation review govern this draft. The accepted Phase2 course stays fixed. The eight review images opened here were original day views01/02/03/06 and night views07/09/13/16. A03 and environment v04 were also inspected in the continuing task. No live Studio, Blender, import/upload, accepted gameplay source or production file was changed by this helper.

## Foundation and district planting

`EnvironmentPlan.Get(layout, architectureMounts)` replaces the nearly flat display base with ten20–30-stud-deep upper rock bodies, six12–16-stud-deep lower shelves and24 staggered faceted skirt groups. Small rotations and varied widths break the straight base outline while retaining a restrained connected footing. Five plant compositions sit around the gate, west cloister, gallery, machinery court and keep. Each uses a weathered knoll and three fern patches; three groups have a cypress and four have a short carved lantern foot. It uses existing verified RW01 and BL02/P3 assets.

The highest rock top is-27.54 and the lowest foundation bottom is-62, local to course origin. Foundation tops remain below the existing fall/reset height-23. These are decorative, noncolliding structures; falling behavior is preserved. Plant leaves rise above some ground rocks but use the accepted route/lantern/lift clearance reserves. No trees, pillars or new colliders are inserted into the race.

Raised planting now consumes explicit actual architectural ledge frames. The world author supplies six gallery mounts via `planned.plantingMounts`, each containing `name`, `frame` and `supportName`. The mounts come from joined gallery body side ledges at localX±16, localY4, localZ1.4; the environment places a0.65-scale carved basin and0.8-scale fern on each. It creates no freestanding78–140-stud plant pedestal. Keep/crown mounts may be supplied by the world author if they have actual supporting ledges. Up to ten clusters fit the180-mesh environment ceiling.

The added fern roots seat on the basin's actual soil top:0.96×0.65=0.624 stud above its base, verified against the accepted plant-pocket recipe. Ground stems use only0.02 stud of seating allowance above the rock terrace.

Integration must call `Environment.Get(layout, planned.plantingMounts)`. `plantingMountsMissing` and `omittedPlanting` are explicit unfinished conditions; do not silently accept them. Each planting frame must also be compared against the actual rendered ledge and architecture after integration.

## Palette and night proposal

The draft carries restrained `color`/`material` fields for rocks. WorldAssembly must honor these fields on scenery clones. The leaf/flower palette is per imported material mesh; tinting the entire two-material fern model would erase its intended distinction. `NIGHT_PALETTE.luau` supplies suggested roles for the world author's new architecture. Apply them to new Phase3 scenery clones, preserving accepted course objects, arrow colours and library templates.

Rock reference sRGB luminance rises from0.0776 for the old(64,79,108) to0.1483 for upper stone(102,108,117),0.1093 for depth stone(83,94,108), and0.1919 for small weathered accents(116,122,128). These are source-colour calculations, not rendered brightness measurements. The palette remains quieter than pale stone and warm focal windows.

The current gallery night image09 crop(x620–1700,y0–230) has99.62% of pixels below12 in all RGB channels. This crop is evidence of the saved upper background's darkness, not a general visibility score. The proposed profile keeps21.3 clock time and all six existing valid sky IDs, raises ambient values modestly, lowers contrast from0.06 to0.015, and uses a lighter atmosphere colour/decay with modest0.55 haze. Exposure0.65 and brightness2.2 are a preview starting point. Four existing outer light positions become grouped ground accents with brightness0.5/range22; the light count stays four.

The primary keep window remains the strongest warm feature. Secondary windows should use subdued SmoothPlastic, avoiding the existing unconditional Neon treatment on every glass placement. Decorative iron receives a lighter value and more environment specular response; accepted machinery materials are untouched. The lead must judge the actual profile from gate/gallery/machinery/crown, then preserve the existing course-local restoration flow. This helper does not claim the night issue is closed from source numbers.

## Focused checks and integration limits

A read-only Lune fixture loaded the accepted current Layout and proposed six actual-body ledge frames. `Environment.Get` returned87 units,146 mesh parts,37,130 placed triangles, four lights, six mounted planting groups, zero omitted groups and zero clashes against fixed-contact, pendulum and lift reserves. This is planning geometry, not native visual or moving-camera evidence.

The full `placeTemplate`/`PlaceSolidArrow` tail is byte-identical to production, SHA256 `2140851d700baa4ec954509de19ea948516a6f1b2792b967c0e4869f1b68da6e`. All19 selected arrows remain governed by the existing selection; this draft adds none. The six sky textures and activation/restoration identity fields are unchanged.

Check native scenery contact flags, support joins, planter seating, foundation silhouette and contrast from the same original views. Combine environment counts with the joined architecture before applying overall resource limits. None of these counts prove device FPS, multiplayer behavior or owner Phase3 acceptance.
