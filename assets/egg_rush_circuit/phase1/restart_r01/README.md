# Egg Rush Phase 1 R01 source

`build_restart_kit.py` is the fresh **ER_P1_R01_K01** shell/chicken builder. It imports geometry/export helpers from the preserved `../build_kit.py` without calling its main. It performs no upload and accesses no live editor. Only the lead should run Blender, inspect the outputs and decide what enters the new native kit.

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/egg_rush_circuit/phase1/restart_r01/build_restart_kit.py -- --out assets/egg_rush_circuit/phase1/restart_r01/candidate_k01 --render
```

The output directory must be empty or absent; partial and historical outputs are preserved. The helper exports two material-separated atlases: `ER_R01Shells.fbx` and `ER_R01Guardian.fbx`, an editable blend and a manifest with bounds, pivots, atlas offsets, contacts, hashes and FBX roundtrip results. Asset records use Roblox XYZ = Blender X,Z,-Y. Subtract each manifest atlas offset while preserving every material part's common origin.

- `ShellFragment`: 10 sideways ×4.5 forward, squared stepped body, flat top0. Suggested contact is the solid central8×4.5 top.
- `ShellLeafWide`: 12 sideways ×8 forward; solid front strip X−5..5,Y4.5..8,top0. Suggested native contact center `[0,-.3,-6.25]`, size `[10,.6,3.5]`.
- `ShellLeafCrown`: explicitly authored8×8; front strip X−3..3,Y4.5..8,top0. Suggested contact center `[0,-.3,-6.25]`, size `[6,.6,3.5]`.
- Both leaves have an actual open rear recess, floor−2.5, broad stepped rim/walls and a squared stepped lower body. There is no blanket solid top or suggested contact over the recess.
- `ShellHingeWide/Crown`: same origin as each leaf, localX hinge through0. Exposed journals are outside the shell width; the center fixed bridge sits below/behind the root and does not cross the front landing strip. The logical axis is at Z0; a full exposed shaft above the leaf is deliberately absent.
- Fresh `GuardianBody/GuardianTail`: D02-inspired block proportions, broad violet wing areas, a stepped closed eye and an attached upright-tail preview. Body socket Blender `(0,4.1,4.5)` = Roblox `(0,4.5,-4.1)`; tail root0. This pose grants no later course sweep/contact clearance.

`--render` requests seven focused PNGs: Wide open/closed, Crown open/closed, chicken front/side and a kit overview. Each assembly view includes a5.5-stud scale marker. The82-degree closed pose is an inspection view, not a mechanism-timing or gameplay recommendation. Originals remain in `AUTHOR_<Asset>` collections, hidden for isolated export/preview handling.

The shell/chicken boundary mesher removes buried box faces and merges coplanar faces of the same material. It checks patch normals against the complete solid. Those checks and FBX bounds do not prove native face coverage, absence of flashing, contact carrying, route fairness or owner acceptance. Lead inspection of one installed moving assembly must precede repetition. Phase1 still ends with owner assessment before Phase2.
