# Exact exposed-plane cleanup proposal

Kit01 is superseded by `proposal02`: the new pose scan revealed other exposed faces on the same assets. Kit02 closes every exact same-facing overlap plane on the seven affected material meshes. See `proposal02/README.md`. Uploaded kit01 remains unused.

The seven material meshes in `proposal01/MC_EXPOSED_PLANAR_UNION01.fbx` remove duplicate area from eight proven exposed, same-facing source planes. The editable `.blend` opens a separate scene containing those seven replacement objects and retains the original composition in its other scene for comparison. Original input files were read only; their before/after hashes match.

| Replacement | Source triangles | Replacement triangles | Source overlap pairs on selected planes | Guarded existing instances |
| --- | ---: | ---: | ---: | ---: |
| MC_AR_GalleryBody46__Stone | 72 | 74 | 7 | 3 |
| MC_AR_GalleryBody46__StoneLight | 324 | 328 | 12 | 3 |
| MC_ER_LanternBracket__Stone | 24 | 32 | 3 | 7 |
| MC_GuideIron__Iron | 132 | 146 | 6 | 106 |
| MC_P3_SlateGable__StoneLight | 144 | 147 | 4 | 5 |
| MC_WeightIron__Iron | 48 | 68 | 24 | 4 |
| MC_WindowTracery__Lead | 1312 | 1320 | 8 | 11 |

Forty placements supplied the exposed overlap witnesses. The same seven original MeshIds occur in 139 existing instances whose Anchored flag is true and CanCollide, CanQuery and CanTouch are false. The full explicit path list, current frame/size/flags and original MeshIds are in `cleanup-proof.json` under each mesh's `allGuardedMatchingInstances`. No matching instances failed these guards. Recheck the guards against live state before applying a replacement.

Only planes containing a supported-visible exact self-overlap witness were changed. The operation subtracts already retained source triangle area from later triangles on the same oriented plane, then keeps every remaining fragment. This preserves the planar surface union, including holes and exterior edges. Other source polygons are copied with their coordinates, material index and loop UVs. It does not move a whole part, union different materials, flatten close relief, remove opposite-facing surfaces, alter leaves, or touch the route, arrows, ravine floor or dark veil.

`saved-geometry-verification.json` verifies the actual saved float coordinates, rather than only the construction's double-precision coordinates:

- No positive-area overlaps above 0.00001 local square units remain on the selected planes. The largest remaining float sliver is 0.0000001133 square units.
- Bidirectional planar coverage has at most 0.0000008653 missing square units and 0.0000000160 added square units from float rounding. All referenced mesh bounds match exactly.
- Original meshes use flat faces and have no custom normals or unapplied modifiers. Flat-normal vector error is below 0.000000055.
- Gallery, bracket, gable and tracery UV layers survive with linear interpolation inside each retained source triangle; the earlier original face supplies the UV on duplicate area. Maximum saved UV interpolation error is 0.0000001193. GuideIron and WeightIron have no source UV layer.
- All seven individual FBXs roundtrip through Blender with a maximum referenced-vertex distance of 0.0000043661 local units. The combined FBX imports seven mesh objects with the expected polygon counts.

## Import and geometry profile

FBX uses forward `-Z`, up `Y`, unit scaling enabled, `FBX_SCALE_UNITS`, no baked space transform, no modifiers and face smoothing. Each object has an identity transform and material-part-centered local geometry. One Blender unit is one intended unscaled stud. Actual native readback of both the original installed meshes and imported kit01 proves mesh-local mapping `(-X, Z, Y)` from Blender, superseding the preimport `(X, Z, -Y)` assumption. Preserve the installed part's CFrame, Size, color, material, flags and attributes when applying its new mesh. Check each imported library's axes and bounds first. A template CFrame rotation does not change the mesh geometry copied by ApplyMesh.

`cleanup-local-geometry.npz` provides each canonical `Asset__Material` key with these suffixes:

- `__trianglesBlenderLocal`: saved replacement triangles in original centered Blender local space.
- `__sourceFaces`: original source polygon index for each replacement triangle.
- `__polygonIndices`: replacement polygon index for each replacement triangle.
- `__originalTrianglesBlenderLocal` and `__originalSourceFaces`: original source geometry for comparison.

For a complete course rescan, convert to Roblox local coordinates, divide by the original local mesh extent and multiply by the installed native Size, then apply the installed CFrame. Preserve the original center; all source and replacement local bounds are identical. Use actual new triangle/polygon indices for self-overlap diagnostics and retain source polygon indices as provenance only.

## Boundary

No Studio changes, uploads, asset transfer, production script edits, publishing or whole-place saves were performed by this proposal. Blender roundtrip proof does not establish Roblox import, live camera stability or gameplay proof. The lead must verify the new native library and integrated candidate before claiming the flashing issue is fixed.
