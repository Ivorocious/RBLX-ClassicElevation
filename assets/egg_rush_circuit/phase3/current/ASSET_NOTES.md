# Egg Rush Phase 3 world kit

`build_world_kit.py` is the durable Blender source for `ER_P3_WORLD_KIT_A03`. It targets the accepted R05 course, six eggs, two orthogonal trays, and the pecking chicken. The five selected Phase 3 views govern appearance; the current brief and accepted native layout govern placement and gameplay.

The kit contains 15 complete reusable units and eight reusable custom meshes. Buildings have floor/underside, rear and side walls, roof/ceiling, cornice, recessed windows, and real arched door openings. Foundations and foliage use broad closed forms. The tank contains a stepped block egg. No geometry is a gameplay contact by default.

The lead owns Blender, uploads, and native Studio assembly. Build in an isolated two-thread process:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --threads 2 --python 'C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\egg_rush_circuit\phase3\current\build_world_kit.py' -- --out 'C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\egg_rush_circuit\phase3\current\candidate_a03'
```

Then verify the exact exported file:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --threads 2 --python 'C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\egg_rush_circuit\phase3\current\verify_world_kit.py' -- --out 'C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\assets\egg_rush_circuit\phase3\current\candidate_a03'
```

Each build uses a fresh folder. The failed A01 source, export, checks, and log remain preserved: its 151 solids passed saved geometry checks, but preview rendering stopped after a Blender file reopen invalidated the previous scene reference. A02 reacquires scene and root references and also closes the tall hall's small upper sidewall gap. A02 completed its geometry checks and all three previews. Visual inspection then found coplanar grass/rock tops on two terrace units and hidden rookery soil. A03 separates these layers while preserving the unit bounds and the eight mesh geometries.

The single upload package is `ER_WorldMeshLibrary.fbx`. Its eight exact object names are `ERW_ArchBand`, `ERW_ArchSpandrels`, `ERW_VaultRoof`, `ERW_TankDome`, `ERW_TankDrum`, `ERW_RockLobe`, `ERW_PipeElbow`, and `ERW_LeafCrown`. All mesh origins are geometric centers. Roblox XYZ maps to Blender X,-Z,Y; FBX exports forward -Z/up Y at one Blender unit per intended stud. The manifest stores exact template dimensions and material roles. Native size checks passed. The asymmetric native probe identified a Y180 mesh import rotation; the module now compensates for it after each mesh definition's own rotation. Corrected native appearance remains a separate check.

`WorldKit.setMeshLibrary(importedFolder)` binds exact named imported MeshParts. `WorldKit.getSize(type)` returns the unit size. `WorldKit.build(parent, type, frame, scale, options)` places a bottom-centered unit whose front faces local -Z. `options.Name` and `options.Role` identify the placement. `options.Accent` recolors coral/mint materials while retaining cream, honey, rock, glass, and greenery. The optional scale is a `Vector3`; the planner converts requested size divided by the base size.

Every generated art part is anchored, visible, noncolliding, untouchable, and excluded from queries. Roles distinguish unreachable architecture, foundations below the course, distant landscape, and landmarks. Green caps require actual unreachable placement; they must never masquerade as landings. Native gameplay contacts stay separate and unchanged. There is no bounding-box substitute for missing custom meshes: assembly stops with the exact missing template name.

The build writes three source previews, the saved `.blend`, a geometry manifest, file hashes, and saved-readback checks of dimensions, frames, outward faces, closed geometry, positive volume, and nonzero face area. The verifier compares FBX vertex positions, axes, names, and material slots after importing into an empty Blender scene. These are source/export checks; native appearance, route clearance, human play, crowd traffic, and performance remain separate evidence.


## Completed A03 evidence

The lead completed the A03 Blender build in 28.653 seconds with Blender 5.2.1. All 151 saved pieces passed actual dimension/frame, closed-solid, outward-face, positive-volume and nonzero-face checks. Three source previews were generated. The exact exported eight-mesh library contains 928 triangles. Independent FBX readback passed all eight names, material slots and vertex positions; its largest vertex error was 0.00000384 stud.

The lead uploaded this package once to creator `86069177`: Roblox model asset `80825818781490`. `candidate_a03/upload-receipt.json` records the completed operation and FBX SHA256 `39f0633130f71e05f1282f59280940a39772ba386ec074a8a6d6fac5baf0b69e`. Reuse this completed package; a fresh upload is unnecessary.

The lead imported exactly eight MeshParts into `game.ServerStorage.EggRushPhase3Meshes` and checked their source dimensions within floating-point tolerance. Their shared package frame came from the insertion location; it is not an authored placement. Matching dimensions and a common frame do not prove the mesh's local orientation. First native architectural/foundation appearance and asymmetric orientation remain separate checks; neither native visual acceptance nor gameplay clearance is claimed here.

## Focused native orientation probe

`check_native_orientation.luau` returns a table with `run(library, safeProbeCenter, options)`. The lead can load it as a temporary module or with the existing trusted source loader, then call it with `game.ServerStorage.EggRushPhase3Meshes` and an explicitly chosen isolated `CFrame`. It creates only an owned temporary folder containing two clones, separated by 60 studs: `PipeElbow` and `RockLobe`. The originals, package frame, production world, mesh permissions and collision settings remain unchanged. `options.KeepVisuals = true` retains these clones for inspection; otherwise it removes its own newly created folder after measurement. A pre-existing folder with the same name stops the check instead of being replaced.

The probe embeds the exact frozen A03 source vertices and triangles for those two asymmetric meshes. It casts 75 rays per mesh and compares measured surfaces with source geometry and the X/Y/Z 180-degree alternatives. Optional `options.ShowExpectedMarkers = true` places small blue markers at exact source contour vertices. These let the lead compare the actual rendered silhouette with the proposed source frame in the same view. The result records the original imported frame, tested clone frame, individual rays, candidate errors, collision fidelity and evidence limit.

Raycasts use Roblox's collision shape, which can simplify the visible mesh. Box collision or a weak/ambiguous fit reports an inconclusive result. A source-compatible result only distinguishes the tested flips; it does not claim arbitrary-transform proof or replace the first native visual inspection. This probe does not use EditableMesh or change account/asset permissions.

## Measured import rotation and source correction

The lead's `docs/artifacts/egg-rush-circuit/phase3/current-w01/native-orientation.json` found the same concrete Y180 mesh rotation on both asymmetric examples. RockLobe's Y180 fit had zero hit/miss disagreements and mean normalized error 0.0000287; the uncorrected Source alternative had four disagreements and error 0.10074. PipeElbow's Y180 fit had zero disagreements and error 0.00417; Source had 18 disagreements and error 0.5433. The first native front view showed all meshes after settling. This supports the measured import correction, while final native visual acceptance remains separate.

The durable builder's module emitter and generated `Phase3/WorldKit.luau` now use `frame * position * definitionRotation * CFrame.Angles(0, math.pi, 0)` for imported mesh definitions. Native Blocks and Wedges retain their existing frame calculation. This is an import assembly correction: the completed FBX, Blender geometry, package asset `80825818781490` and its upload receipt remain unchanged. The saved build manifest's original module hash describes the pre-correction generated file; the lead must freeze the current emitter/module source hash separately rather than rebuild or reupload the valid mesh package.

The clone-only probe accepts `options.Correction = CFrame.Angles(0, math.pi, 0)`. It applies that transform to each clone after its expected placement frame, while rays, source triangles and blue markers remain in the original expected frame. Its report records expected frame, corrected clone frame and correction separately. Corrected source compatibility and native appearance still require the lead's execution; this documentation does not claim that follow-up result.
