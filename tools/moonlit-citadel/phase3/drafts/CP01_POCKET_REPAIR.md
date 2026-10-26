# CP01 recovery pocket repair proposal

Source-only implementation helper analysis, October 12, 2026. No production source or Studio edits were made by this helper.

Change only the final argument of CP01's checkpoint declaration in `Layout.luau`:

```diff
-local cp01 = checkpoint("SharedArches", "CP01", v(-144, 28, -112), v(32, 2, 24), 1, v(-144, 28, -131))
+local cp01 = checkpoint("SharedArches", "CP01", v(-144, 28, -112), v(32, 2, 24), 1, v(-144, 28, -112))
```

The current filesystem recipe has recovery Z-131. Root's suspected installed Z-140 must be checked against the actual runtime contact before applying the equivalent runtime repair. Either location puts a floor with top28/underside27 above the final catch-return ramp.

The generated `Tread_5_1` is centered at `(-144,25,-140.125)` and `Tread_5_2` at `(-144,27,-129.375)`, each approximately `7x1x11.0145`. The current source recovery pocket spans X-159..-129 and Z-142..-120. It intrudes into both treads' supported torso/head space, matching the reported failure at `Tread_5_1ActualLanding`. Actual blocker identity and native physics still belong to root's focused check.

The proposed pocket keeps its full `30x1x22` size and `30x0x22` respawn area. At `(-144,28,-112)`, its entire solid is X-159..-129, Y27..28, Z-123..-101. The existing unchanged CP01 terrace is X-160..-128, Y26..28, Z-124..-100. Thus the relocated floor is wholly inside an existing collider: it creates no new playable footprint, approach, shortcut or jump bypass. The trigger and both branch routes stay in their original positions.

The existing CheckpointService/Coverage formula gives 7 columns and 5 rows, preserving **35 supported respawn positions** at the original 4.5-stud spacing. The original 32x24 terrace remains available for passing and waiting. This source capacity does not prove actual 20-player flow.

`CP01_POCKET_REPAIR_CHECK.luau` passed against current source SHA-256 `389db5edb93e39b65faa16dd803b9f2032f1f17c554abfa709752d18b62423bb`. It applies the proposal in memory; only CP01Pocket changes among generated surfaces, both catch routes are identical, and all 167 WorldPlan placements/counts remain identical. Oriented torso/head prisms from 2..7 studs above each catch support with a 2.25-stud horizontal body allowance flag the old pocket on both final treads and find **zero intersections with the proposed pocket**. This checks torso/head clearance; it is not a substitute for native movement across the existing final floor seam.

Proposed Layout SHA-256: `50ff1ee55d83446c7e9a9503bc95355a9ae714e7b89bf681fa76176557db79f7`.

For root's focused runtime check, preserve the original failure and a reversible pocket/respawn-frame backup, then place the actual CP01 pocket top at local `(-144,28,-112)` and keep its trigger respawn frame at that point plus `(0,4,0)`. Confirm the unchanged `30x0x22` respawn area. Retry the actual committed Arch catch from the same official CP1 state; require an ordinary catch drop, return across both final treads, real CP01 support, and no falls, deaths, character replacement or checkpoint advance. Do not relax actual support assertions or move the avatar during traversal. Mirror the single coordinate in durable source and rebuild the final candidate after the focused native result.
