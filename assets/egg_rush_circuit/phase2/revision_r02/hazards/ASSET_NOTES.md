# Hatchery hazard kit

Current candidate: `ER_P2_R02_H02`, authored in Blender 5.2.1 LTS with no external textures or add-ons required by the builder. H01 is retained as the initial export; H02 cleans native part names and exported numeric precision. The shapes are unchanged.

| Template | Parts | Red lethal parts | Shape |
| --- | ---: | ---: | --- |
| ScorchedShell | 8 | 3 | Broken cream shell around hot teeth |
| FeederPaddle | 7 | 1 | Mint feed arm and broad red paddle |
| HeatGrate | 8 | 4 | Coral and iron frame with raised hot bars |
| FeatherPinch | 9 | 4 | Opposed cream feather fingers with red inner edges |

All 32 solids are editable boxes, faithfully exported as native Roblox Block Parts. No upload is needed. Each template uses a local base pivot, Roblox Y up, and fits within roughly 7 × 3 × 3 studs. The grate is deliberately low. The saved Blender scene separates the four local roots for the preview board; exported positions are relative to each root.

`candidate_h02/` contains the `.blend`, readable render board, raw part manifest, file hashes, build timings, and verification results. The runtime module is `src/ServerStorage/CourseBuilders/EggRush/RestartP2/HazardKit.luau`.

```luau
local model = HazardKit.Create(parent, "ScorchedShell", frame)
local scaled = HazardKit.Create(parent, "FeederPaddle", frame, .8)
```

The optional scale accepts a number or `Vector3`. Vector scaling changes part dimensions and local offsets while keeping their authored angles. Every part is anchored, noncolliding, and touch-disabled. Red parts are Neon, `ERLethal=true`, and query-enabled. Housing is `ERLethal=false` and query-disabled. The kit adds no movement or `ERMechanism` attribute; course code supplies motion and lethal detection.

Build in a fresh output folder from the repository root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/egg_rush_circuit/phase2/revision_r02/hazards/build_hazard_kit.py -- --out assets/egg_rush_circuit/phase2/revision_r02/hazards/candidate_next --render
```

Run the focused offline checks:

```powershell
& .tools/lune-0.10.5/lune.exe run assets/egg_rush_circuit/phase2/revision_r02/hazards/verify_hazard_kit.luau
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background assets/egg_rush_circuit/phase2/revision_r02/hazards/candidate_h02/hazard_kit.blend --python-exit-code 1 --python assets/egg_rush_circuit/phase2/revision_r02/hazards/verify_saved_blend.py
```

H02 generated in 0.114 seconds and rendered in 7.351 seconds, excluding Blender process startup. Saved-file reload verified all 32 closed, finite solids with positive volume and matching exported transforms. Lune compiled the module and checked 16 model creations / 128 parts across default, numeric, and vector scale, with rotated and translated placement. Its geometry comparisons allow 0.0001 stud for instance property precision.

The render board was inspected. Blender could not write its optional automatic thumbnail to the user's thumbnail cache; the candidate `.blend`, render, and manifest were saved successfully and independently reloaded. The isolated background processes exited. The live Blender scene and Studio were not used. Roblox appearance, movement, lethal contact, and performance remain unverified here.
