# Guardian sweep tail variant

October21,2026. Current output **candidate_c03 / ER_GUARDIAN_SWEEP_C03**. This separate asset leaves Phase1 candidate_c04 and world candidate_c03, K04/K05 imports, route, mechanism clocks and existing contact source unchanged.

The lead reconciled the final tail to an8-stud maximum depth rather than stretching the earlier decorative tail into a29.25×5×3 beam. The existing root, rest yaw25degrees, axis-Y and50-degree sweep remain integration inputs. Fresh native contact, complete-cycle refuge and required traversal checks are mandatory; older beam/contact proof does not cover this shape.

## Output and placement

- `build_tail.py`: saved Blender5.2.1 builder using the unchanged Phase1 geometry/export helper.
- `candidate_c03/ER_GuardianSweepTail.fbx`: one asset, four material parts,290 triangles.
- `candidate_c03/GuardianSweepTail.blend`: editable material meshes and two preview cameras/render state.
- `candidate_c03/GuardianSweepTail_oblique.png` and `GuardianSweepTail_plan.png`: inspected renders.
- `candidate_c03/manifest.json`: exact bounds, source/output hashes, shape checks and successful FBX roundtrip.
- `candidate_c03/upload_receipt_network.json`: completed network-enabled upload; asset84469813238228.
- `candidate_c03/upload_receipt.json`: preserved original default-sandbox DNS attempt, still recorded as submitting without an operation.
- `candidate_c03/transport-retry.json`: links both receipts and the two matching read-only DNS checks that justified the lead's single intentional network-enabled retry.

Asset name **GuardianSweepTail**, parts `ER_GuardianSweepTail__Shell`, `__Mint`, `__Coral`, `__Lilac`. Atlas offset0. Place its common root directly at the existing GuardianTail mechanism pivot, **scale1 with no additional local rotation**. Local Roblox+X points outward along the sweep; local+Y points up. Blender/native conversion remains RobloxXYZ=(BlenderX,BlenderZ,-BlenderY), one unit per intended stud.

Exact native-local bounds: **X0..29.25,Y-1.5..3.5,Z-4..4**. Four connected branches share a broad stepped root and have different chunky heights/tip lengths; one central feather extends farther. Sparse mint/coral/lilac face patches use the existing palette. The exported surface comes from the union of15 broad boxes, with internal faces removed and coplanar surface rectangles merged. It contains no opaque placeholder beam.

Each vertex obeys the lead's north-side constraint:

```text
-sin(25deg)*X + cos(25deg)*Z >= -13.65
```

Actual minimum is **-13.6304150578**, static margin **0.0195849422**. This is a vertex-bound check, not native full-cycle clearance proof.

The source cell union has3,145 occupied cells and one connected component. All145 exported quads were checked by probing immediately inside/outside the complete solid; the new builder corrects open patch normals after the generic helper's normal operation. FBX reimport retained four parts, one material per part, and bounds within0.0000005 studs. A final build took about8.6seconds, including two24-sample1600×900 renders. An optional OS thumbnail-cache write failed outside the workspace; requested blend/renders saved successfully and were opened.

Material seams and greedy surface T-junctions are not a universal watertight-solid claim for every individual material mesh. Prepare native precise mesh contacts and inspect face/contact coverage. Keep actual visible art queryable and lethal; do not hide a large old lethal box behind this asset or reuse old hazard-clearance conclusions.

Rebuild to a fresh directory:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/egg_rush_circuit/guardian_sweep/build_tail.py -- --out assets/egg_rush_circuit/guardian_sweep/candidate_next
```

## Upload outcome

Dry-run validated **owner86069177**, model name `EggRushGuardianSweepTailC03`, and FBX SHA256:

```text
d4b3ce2df8cbdac46914fc33fb98e516e337dd7efe194d3a0a2f2d5c6a866d73
```

**Upload completed:** the lead performed one intentional network-enabled upload using the same hash, owner and model name. `upload_receipt_network.json` records statecomplete, operation`311fbc11-cb77-4fac-9384-6fac752bc034`, **asset84469813238228**. The lead also verified the asset's name and creator86069177 through native Marketplace inspection. Reuse this completed receipt; no further upload retry is needed.

The original helper attempt used the default sandbox and returned `Request failed or returned invalid data; no automatic upload retry.` Its unchanged `upload_receipt.json` remains statesubmitting without an operationID. Independent keyless read-only requests by both helper and lead failed DNS resolution (`gaierror11001`) in the default sandbox. The lead recorded that transport evidence and the deliberate network-enabled retry decision in `transport-retry.json`. Preserve all three records rather than rewriting the original attempt as a successful receipt.

One official `insert_asset` attempt under `game.ServerStorage.AssetImports` returned `Failed to load package asset:Request Failed`, creating no instance. The lead then imported through `AssetService:LoadAssetAsync`, inspected all four meshes, prepared precise contacts and admitted them into `EggRush_ER_K06`. Original imports and earlier kits remain retained.

Fresh C13 native resting, sweeping and returning contacts each recovered the actual racer once at CP3. Refuge center plus four usable edge positions each observed all six states for more than12.5seconds with zero recovery/drift ([receipt](../../../docs/artifacts/egg-rush-circuit/phase3/native-c13-contacts.json)). C14 confirmed surface contacts and empty bounding-box corners; the shaft interior probe is observational and did not hit ([probe](../../../docs/artifacts/egg-rush-circuit/phase3/native-c14-surface-corner-probe.json)). These are scoped native results, not a universal solid-volume or crowd/device/FPS claim. Final-course traversal remains separate.

Original command, recorded for investigation rather than blind replay:

```powershell
python tools/upload_roblox_model.py assets/egg_rush_circuit/guardian_sweep/candidate_c03/ER_GuardianSweepTail.fbx --user-id 86069177 --name EggRushGuardianSweepTailC03 --receipt assets/egg_rush_circuit/guardian_sweep/candidate_c03/upload_receipt.json --upload
```
