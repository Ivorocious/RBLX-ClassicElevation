# Source57 physical finishing recipe

`SurfaceFinishingPlan.luau` implements exactly `neighbors/FINAL_POSE136.json`, SHA256 `0f5c0e39cccfc4135ea4217ab82f40681db3136220325c774df7089ffba771b9`: 29 world MeshParts and 107 route MeshParts. It follows the Source56 recipe and does not replace the existing 200-part `SurfaceSeparation` pass.

Each target checks an exact relative path, unique child identity, original MeshId, source asset/material/triangle attributes, original appearance and inert visual flags. It also checks the current Source56-relative CFrame and native Size before preparing any writes. Route targets all preflight before the first assignment; world targets preflight each newly assembled edit unit. A repeated application rejects the changed poses. Only manifest-changed Size or CFrame properties are assigned. Unchanged fields, flags, attributes, contact geometry, arrows, original floor and veil are preserved.

The operation frames are relative to the course Origin, not fixed world coordinates. The current data is bound to the approved Source56 map; it is not an arbitrary legacy migration.

Hook order:

1. `VisualAssembly.Apply`: existing floor inset, existing route cosmetics, existing deterministic `flatFloorLayers`, new `Finishing.ApplyRoute`, existing `visualTop`.
2. `WorldAssembly.Apply`: existing per-unit scaling/placement and `Separation.ApplyWorldUnit`, existing appearance, new `Finishing.ApplyWorldUnit` on that newly created unit.
3. `WorldAssembly.AddDetails`: the same world finishing hook runs only on a newly appended detail unit. Existing units are untouched.

`WorldAssembly.Apply` also verifies 29 targets for a complete world; representative partial builds preserve their existing behavior. `WorldPlan.Candidate` comes from the new module. Fresh `RouteBuilder.Build` writes SourceRevision57 and BuildRevision51 from the same module.

The separate cleaned mesh substitution must run after these original-MeshId guards. It is not included in this implementation lane.

Five production files were touched: new `SurfaceFinishingPlan.luau`, plus `WorldAssembly.luau`, `VisualAssembly.luau`, `RouteBuilder.luau` and `WorldPlan.luau`. New require dependency: `SurfaceFinishingPlan`, used by those four existing modules.

`CheckSurfaceFinishing.luau` passed on both actual saved Source55 model copies with the exact original Source54 floor restored, matching all non-veil Source56 geometry. Each fixture retains 2,742 instances, 1,763 BaseParts and 1,469 MeshParts. Exactly 136 target parts produce 138 permitted Size/CFrame property changes, with no unexpected record, attribute, flag or property change. Route preflight atomicity and repeated-call refusal pass; all 35 current builder modules compile. Lune lacks the serialized MeshId alias for MeshContent, so each fixture supplements the 136 original IDs from its exact native snapshot before taking the baseline. Twelve unchanged transparent mist anchors are omitted from this offline fixture. No native Studio edit or full fresh-builder/native acceptance is claimed by this test.
