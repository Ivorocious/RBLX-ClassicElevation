# Classic Ascent v5 — Blender scenery and traversal pass

Built September 6, 2026. Builder version 5. The mountain functions and three bridge routes are preserved; this is ready for the owner's next playtest, not a claim that 20-player difficulty is validated.

## Changes

- Fifteen authored Blender props: three pines, three angular rocks, two ruined pillars, two ice formations, grass, wildflowers, a rooted log, a snowman, and snow-covered rock cover. Seeded clusters vary spacing, size, orientation, and density. No trees on the cliff-jump section.
- Removed repeated ellipsoid supports, oval arches, and unnecessary under-platform columns. The generated course has 2,478 BaseParts, down from 4,708 in v4. This is an object-count reduction, not a measured frame-rate improvement.
- Trailhead: six jumpable rolling-log hazards, travelling downhill, disappearing and resetting.
- River: 28 rows with resting banks and 60 individual narrow logs. Logs flow across each current in one direction, disappear at the boundary, and reset while hidden. Grounded riders move with the logs; reset movement never carries riders back.
- Smoothed the old short bends and widened jump gaps across all three routes. Reduced the skyline to 18 rows to provide meaningful gaps without tiny ice landing surfaces. Ice friction is 0.005; snow checkpoints remain grippy.
- Added eight small stone refuges between bridge lanes, preserving the full-width stone rest areas and collapsing boards.
- All 44 hazard warning circles are red. Pillars and connected cliff overhangs replace repetitive arches. Four boulder lanes roll from the hillside with variable pauses; refuge pockets sit off their travel lines.
- Six static snowmen shoot damaging snowballs at variable intervals. Rocky cover blocks snowballs. Avalanche traversal remains, with fewer props and an open final approach.
- Instant checkpoint recovery and the Studio-only Skip checkpoint button remain available.

## Durable files and assets

`assets/ascent/AscentProps.blend`, its FBX export, generator, manifest, and preview are committed. Uploaded model asset **89332142209949** belongs to creator **86069177**, with explicit upload approval. No place was published.

`AscentProps` loads the approved asset once, accepts only the expected named meshes, restores colors, normalizes height, and caches reusable templates in `ServerStorage.AscentMeshLibraryV5`. The cache is rebuilt from the asset when absent. This avoids silently substituting primitive props if meshes cannot load.

The imported raw model remains in `ServerStorage.AscentPropsImportV5`. Previous Studio course copies are preserved in `ServerStorage.CourseBuildArchive`; the old authored v4 model is also retained, disabled, in `CourseLibrary`. `Builder.Ensure` preserves existing v5 models, allowing manual edits without automatic regeneration.

## Checks and limits

- Rojo 7.7.0 build passed; Studio compiled all builder, service, and config ModuleScripts without syntax errors.
- Structural check: version 5, 19 checkpoints, eight bridge refuges, all warning circles red, and no named legacy oval support/arch objects.
- Representative edit views inspected: trailhead, ruins, snow section, and finish. All 15 prop templates loaded successfully.
- Brief motion check confirmed travel, warning/cooldown, hiding, and resetting for the new rolling logs, river logs, boulders, and existing lava/avalanche. River logs did not reverse while travelling.
- The first check caught mountain wedge bounding boxes swallowing snowballs. Snowballs now use exact initial-overlap geometry; the follow-up observed all six lanes travelling 29–54 studs and cycling.
- No full-course run, timing validation, or 20-player load test. Jump feel, slippery landing difficulty, damage balance, crowding, and performance need the owner's playtest.

## Quick owner validation

Press Play, use the DEV panel to start the race, and use **Skip checkpoint** to jump between sections. Check jump clearance over rolling logs, riding a river log through a wrap, bridge refuge access, cover during snowball volleys, ice stopping distance, and the final reveal. Stop Play before manual course edits; save the Studio place to retain them.

Motion attributes remain server-authored. New attributes are `MotionStart` (optional CFrame), `InitialProgress` (0–1), `PauseMin`, and `PauseMax`. No new remotes, purchases, DataStore changes, or reward changes were introduced.
