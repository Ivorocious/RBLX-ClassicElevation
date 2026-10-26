# Entrance repair candidate

The isolated builder is `../build_entrance.py`. The FBX and editable Blender scene are `GrandArcade_R01_Entrance.fbx` and `GrandArcade_R01_Entrance.blend`. This worker did not upload, install, edit Studio, or change Luau. After the lead installed and reviewed the candidate, the authorized follow-up carried the entrance geometry into the existing Blender builders.

## Alignment and replacements

All twelve exported meshes use **C01 coordinates**, including the six stage rail meshes. One unit is one stud; X right, Y toward the stage, Z up. Align the four calibration markers to world origin **(1552, 370, -892.5)** using the existing marker workflow. The expected stage pivot is (1552, 374.2, -942). Use the aligned import positions when replacing artwork; the old MeshPart centers are unsuitable because the repaired bounds changed.

| Imported mesh | Existing target |
| --- | --- |
| UpperLanding__FloorA | Workspace.Lobby.GrandArcadeConnection.Architecture.UpperLanding__FloorA |
| UpperLanding__FloorB | Workspace.Lobby.GrandArcadeConnection.Architecture.UpperLanding__FloorB |
| FrontWing-1__Ivory | Workspace.GrandArcade.FrontWing-1__Ivory |
| FrontWing-1__Pale | Workspace.GrandArcade.FrontWing-1__Pale |
| FrontWing-1__Gold | Workspace.GrandArcade.FrontWing-1__Gold |
| FrontWing1__Ivory | Workspace.GrandArcade.FrontWing1__Ivory |
| FrontWing1__Pale | Workspace.GrandArcade.FrontWing1__Pale |
| FrontWing1__Gold | Workspace.GrandArcade.FrontWing1__Gold |

Archive exactly these eight originals, preserving parent references and properties, before changing their presentation. Keep every other material mesh in place. In particular, **UpperLanding__Cream merges its base floor and both guard bodies**; it must stay intact. All three merged PortalPosts meshes, both FrontWing Navy meshes, all lower/ramp materials, the stage floor, lamps, trees, and collision parts are untouched by this candidate. The Blender scene's `Context__` objects are review context and are excluded from the FBX.

## Floor ownership

The stage's actual 96-edge walking-surface polygon owns the floor inside its boundary. The last row's four C01 tiles ends at that boundary with a 0.0001-stud numerical setback. The original eight preceding tiles retain their exact vertices. This changes only the two merged FloorA/B meshes, whose separate tiles have equal broad bounds in the original asset.

At center, the seam is C01 depth 25.2, world Z -917.7. It curves stageward near the usable edges, following the exported polygon rather than an approximate straight cut. The C01 Cream base remains 0.027 studs below its walking tiles, so this tiny joint does not expose water. No cover plate was added. Native floor collision remains the original 18-stud width; the 16-stud ramp still rises 4.2 studs, and the landing top stays Y 374.2.

## Rail joints

The original 41 rings of each curved beam retain their exact vertices. Six additional rings extend each closed tip from stage local (±12.09609478, -21.34650598) into the existing terminal post at **(±9.45, -22.3)**. Those coordinates are C01 (±9.45, 27.2), world X **1542.55 / 1561.45**, world Z **-919.7**. The post body center is Y 375.8 and its size remains 1.42 × 3.2 × 1.42.

The Ivory foot tapers from width 1.7 to 1.3 over the new span; the pale handrail stays 1.3 wide and the gold strip stays 1.12. Every closed tip corner lies within the post body. The curved pale cap remains at stage heights 2.53–2.87 and gold at 2.85–2.95. The bridge cap stays 2.8–3.03 / 3.03–3.10. The existing post head at 3.13–3.40 provides the deliberate height transition. The new tips do not reduce the existing opening or the 17.8-stud parapet clearance; the existing wider terminal posts already determine their local opening.

The source collision footprint has an approximately **0.63749-stud horizontal gap** between each last WingCollision box and its C01 GuardPost. This is a measured existing gap, not a demonstrated player escape. All current colliders remain unchanged. During installation, inspect this exact contact area. If the extended guard needs continuous native blocking, a narrow dependent connector can bridge it without changing route collision: right center (1562.77304739, 375.9, -920.17674701), left center (1541.22695261, 375.9, -920.17674701), size about 2.82 × 3.0 × 1.1, with long-axis Y rotation ±0.34585 radians. Recheck against current native geometry before adding it; both existing endpoint colliders should remain intact.

## Geometry proof and remaining native checks

`entrance-manifest.json` records source/output hashes, every replacement, component volumes, triangle counts, exact boundary points, join dimensions and output checks. The package contains twelve meshes including four markers and 2,440 triangles. All source candidate and reimported FBX components are closed and outward, with no degenerate triangles. Each original curved-beam signed volume was negative; the corrected result is positive. Maximum FBX roundtrip vertex difference is 0.00000763 studs. Landing top triangles have **zero area overlapping the stage footprint** both before export and after FBX reimport.

The inspected left/right joint previews show each curved cap terminating into its post. The floor preview shows one owner on each side of the curved boundary. These are Blender views. The lead still needs single-sided imported front/back/inside/outside views, shallow native seam views, guard/collider agreement at both corners, and normal-speed R15 walking across the seam both ways at center and both usable edges with jumping disabled. No device, FPS, multiplayer, or native walking result is claimed here.

FBX SHA-256: `c2548bfd1a696df38b4c7b8ffa0929ccad6fe6915f11cf1464c1b98eef2c6778`.

## Durable source follow-up

`assets/grand_arcade/build_stage.py` now extends only the FrontWing entrance ends through `extend_entrance_terminal`. It retains all 41 original rings and the lead's explicit outward-normal calculation. The extrusion, bay assembly, face-winding repair and prop placement were not changed by this follow-up.

`assets/grand_arcade/connection_candidate/build_connection.py` now reads the saved A01 walking surface's actual 96-edge boundary and trims only upper-landing tile geometry through `upper_landing_tile`. Lower/ramp tiles, all other upper-landing materials, posts and collision dimensions retain their existing paths.

`../check_entrance_source.py` executes only extracted helper definitions in a separate Blender process. It compares the resulting eight meshes against this saved candidate, checks every original rail ring and unaffected landing tile, verifies closed outward solids, and measures zero floor overlap. `durable-source-checks.json` records the successful result and current source hashes. Neither whole production builder was executed and no existing `.blend`, FBX or generated Luau output was overwritten.
