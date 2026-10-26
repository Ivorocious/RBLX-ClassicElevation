# Physical surface separation, October 19 repair

The frozen proposal changes 200 decorative parts: 135 floor meshes, 51 world meshes and 14 route cosmetics. On both actual saved model copies, the helper retained all 2,759 records and changed only 201 expected Size/CFrame properties. Attributes, flags, colliders, contacts, arrows, signs, services and model identities stayed exact. Production and live Studio were not edited by this work.

`SurfaceSeparation.proposed.luau` is the implementation. `remaining-family-closure.proposed.json` lists every operation after the exact Art03 plan, including native before/after Size, native rotation and course-local position delta. Size uses the placed MeshPart's own XYZ axes, after author scaling. Position deltas use course XYZ. `expected-native-patch-manifest.json` supplies the actual saved-model final CFrame and Size.

| Function | Parts | Placement in the existing build |
| --- | ---: | --- |
| `ApplyFloorSkins(course)` | 135 | Before `flatFloorLayers` in `VisualAssembly.Apply`. Keep the existing 0.012 layer step and layer assignments. |
| `ApplyWorldUnit(model, data)` | 51 total | After placing/scaling each unit and before appearance, in both `Apply` and `AddDetails`. |
| `ApplyRouteCosmetics(course)` | 14 | After route cosmetics exist. Only their decorative material parts move. |

Each function checks measured source sizes, material identities and visual-only flags before its writes. Floor and route functions preflight the complete target set. A repeated floor/window/route application is rejected. Unit counts are bound to this candidate; this is not an unrestricted future-map rule.

| Physical rule | Copies |
| --- | ---: |
| Floor native Size X/Z minus 0.08 | 135 |
| Window Stone native Size X/Y minus 0.12 | 11 |
| Masonry Stone native Size X/Z minus 0.08 | 25 |
| Wheel-support Iron course Z plus 0.06 | 4 |
| Upper machinery bay Stone course X plus 0.08, also counted in masonry | 1 |
| Crown StoneLight course Z plus 0.08; StoneDark native Size X plus 0.12 | 2 |
| Northwest court StoneLight course Z plus 0.06 | 1 |
| Chimney StoneLight course Y plus 0.06 | 6 |
| Two seated-roof SlateBand parts course X plus 0.06 | 2 |
| Weight Iron course X plus 0.06 | 4 |
| Car/weight Brass course Z plus 0.06 | 8 |
| Two specified Red40 guide-post Brass parts course Y minus 0.06 | 2 |

Art03 separately moves WestArchMiddleWing and its eight attachments by course X minus 0.08. Do not apply that move twice. Art03 is bound by SHA256 `3b21f8f113b5daa8ab7489cdd1d00f4fee1d0b66642d45c4b6cdfecc06420117`.

The original geometry diagnosis used 1,598 visible objects, 374,804 actual triangles and fresh native poses. Native bounds agreed within 0.0004272 stud. Same-facing triangle overlap within 0.02 stud produced 635 pairs. Rays from 677 supported player-height eyes found 363 visible pairs; 184 have different native appearances. The final finite check transforms those exact 184 measured witnesses through Art03 and the physical corrections: all have at least 0.025 stud separation. No measured different-appearance family remains held. The two adjacent gallery-rejoin witnesses improve from 0.00733 to 0.047064/0.047065 stud through the floor's lateral inset; their existing layer heights remain unchanged.

The check does not rescan every new neighbour or prove all possible camera views free of flashing. The original scan also found 179 visible pairs with the same appearance and 272 pairs without a sampled visible witness. Those are not a claim of invisibility or complete clearance. Maximum per-axis Size adjustment is 0.12 stud and maximum translation is 0.08 stud. Native motion and the final combined visual assembly remain root's integration checks.

`surface-separation-unit-tests.json` records the two saved-model checks. Lune did not expose saved Model.WorldPivot consistently, so the test supplements each copy from the exact native snapshot before taking its baseline. It simulates Art03's 50 same-asset pose/scale changes; six banner asset replacements and five retirements remain the art author's separate assembly. The tests then check all 200 expected parts, all other model records, and repeat-call refusal.

Earlier `physical-separation-proposal.json` is historical. The frozen final implementation and finite closure are the files named above; `surface-separation-freeze.json` records their hashes. No renderer depth bias or approved asset-library edit is used.
