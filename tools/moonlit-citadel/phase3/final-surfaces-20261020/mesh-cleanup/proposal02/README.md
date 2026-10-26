# Kit02: full exact plane closure

This supersedes kit01, which cleaned only the planes visible from the initial witness set. The proposed new poses exposed further exact cofaces on those same meshes. Kit02 removes duplicate area on all 21 exact same-facing overlapping source planes in the seven affected material meshes. It does not merge nearby relief surfaces.

| Mesh | Original triangles | Kit02 triangles | Exact overlapping triangle pairs removed | Planes |
| --- | ---: | ---: | ---: | ---: |
| MC_AR_GalleryBody46__Stone | 72 | 85 | 55 | 6 |
| MC_AR_GalleryBody46__StoneLight | 324 | 332 | 24 | 2 |
| MC_ER_LanternBracket__Stone | 24 | 32 | 3 | 1 |
| MC_GuideIron__Iron | 132 | 160 | 12 | 2 |
| MC_P3_SlateGable__StoneLight | 144 | 156 | 16 | 4 |
| MC_WeightIron__Iron | 48 | 72 | 36 | 4 |
| MC_WindowTracery__Lead | 1312 | 1340 | 41 | 2 |

Total: 187 exact overlapping triangle pairs removed, 2177 replacement triangles, seven unchanged material slots, 139 explicitly guarded existing instances. Original files remain unchanged. Referenced bounds match exactly. Flat normals and source UV interpolation pass verification. Both the combined FBX and all seven individual FBXs pass Blender roundtrip checks.

Actual saved float geometry has zero overlap pairs above 0.00001 local square units on these planes. The largest float sliver is 0.0000001133 square units. Bidirectional planar coverage has at most 0.0000008653 missing square units and 0.0000000160 added square units from float rounding. See `saved-geometry-verification.json` for per-plane measurements and `cleanup-proof.json` for exact path/MeshId guards.

`cleanup-local-geometry.npz` uses the same per-asset keys and fields documented in the parent README. Actual kit01 native readback and original installed mesh readback independently prove mesh-local conversion from Blender as `(-X, Z, Y)`. ApplyMesh to the old CFrame/Size requires no template CFrame rotation. Kit02 still requires its own actual native geometry readback before production integration.

No Studio change or upload was performed by the mesh-cleanup agent. The lead owns native import and integration. Keep kit01 unused. Require the fresh whole-candidate self-overlap scan and live verification before reporting completion.

## Actual native SR02 readback

The lead uploaded asset `99796608028640` and supplied actual native EditableMesh vertices/faces in `native-import-sr02-57.json`. Independent offline checks passed for all seven meshes and 2177 actual native triangles:

- `native-axes-proof-sr02-57.json`: both old and new geometry use `(-Blender X, Blender Z, Blender Y)`. Direct ApplyMesh preserving the existing CFrame/Size passes. No template rotation is required. Maximum new actual surface distance is 0.000008363 studs; comparison to original installed geometry at the maximum existing size envelope is below 0.000140 studs. Every source triangle vertex, midpoint and center was checked in both directions against oriented target surfaces.
- `native-self-overlap-sr02-57.json`: all actual native triangle planes inspected; zero exact same-facing overlaps above 0.00001 square studs, using maximum plane gap 0.00003 studs and normal dot above 0.999999.
- `native-union-proof-sr02-57.json`: analytic triangle subtraction verifies surface coverage in both directions on every oriented plane. The largest uncovered fragment is below 0.000214 square studs, consistent with the measured native float edge shifts. This does not assume matching triangle diagonals.
- Stored normals have minimum dot 0.9999998808 and no invalid native UV coordinates were reported. `native-actual-geometry-sr02-57.npz` preserves the actual native local triangles for final candidate scans.

These checks verify the imported mesh geometry. Native installation, whole-candidate visibility and live camera checks remain the lead's responsibility.
