# Strict integration wrapper

This module preserves the complete proposal03 geometry and five retirements. It changes only how its required units are split between the two existing generators. The historical proposal03 freeze is unchanged.

In `WorldPlan.Get`, after all architecture/details are assembled and before recounting:

```luau
plan = ArtRepairPlan.Apply(plan, "Architecture")
counts.plantingMounts = ArtRepairPlan.RevisePlantingMounts(counts.plantingMounts)
```

Pass these revised mounts into `Environment.Get` as usual. It builds both plants, `counts.groundedPockets` and the occupied rows from the final basin frames. Before `Environment.Get` returns its plan:

```luau
plan = ArtRepairPlan.Apply(plan, "Environment")
```

Architecture requires all44 applicable replacement names and all five retirements. Environment requires all12 applicable plant names. `Apply(plan)` retains the original strict56-replacement/five-retirement combined check. Unknown scope, missing required unit or changed asset/library identity fails. There is no `allowMissing` path.

`RevisePlantingMounts` requires all six named gallery mounts, checks their existing shelf identities, clones those six records and updates only their frames. Unrelated mounts retain their original records. Missing gallery mounts, duplicate mount names or altered shelf identities fail.

`integration-check.json` passes the full/split comparison and uses the frozen Source54 `Environment.Get` to verify all12 generated plants, all12 occupied rows and all six grounded pocket frames against the final proposal. It also verifies missing-name/scope guards and an unrelated mount. No geometry, production source, Studio or frozen history was edited.
