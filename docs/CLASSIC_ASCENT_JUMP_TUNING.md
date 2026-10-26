# Classic Ascent jump restoration

**Archived:** the owner rejected this course after exhaustive visual review on September 7 and requested V7 back. These results describe the rejected V8 jump candidate. See [V7 editing](CLASSIC_ASCENT_EDITING.md) for the current course.

September 7, 2026. Jump revision 1, candidate 11.

The owner accepted the recovery pass's visual direction and requested one remaining change before manual fine-tuning: restore real, uneven jump sequences in Sections 03, 05, 06, 07, and 09, with 03/09 hardest, then 06, then 05/07.

## Result

| Section | Average obstacle gap | Furthest gap |
| --- | ---: | ---: |
| 03 Switchback Climb | 6.37 studs | 7.80 studs |
| 09 Skyline | 6.35 studs | 7.73 studs |
| 06 Broken Causeway | 5.69 studs | 6.50 studs |
| 05 Pillar Yard | 4.23 studs | 5.79 studs |
| 07 Cliffside Traverse | 4.35 studs | 5.25 studs |

These are measured edge-to-edge gaps between ordinary footholds. Broad checkpoint approaches are rest areas and are excluded from the difficulty averages. All 204 ordinary foothold connections now have a gap; platform widths, depths, side offsets, and the existing uneven heights vary.

The widest early trial gaps were beyond the character's actual jump range and failed live tests. The final tuning uses the normal WalkSpeed 16, JumpHeight 7.2, and gravity. It preserves that movement setup rather than increasing the character's power.

## Changes

- Restored 36 hidden landing meshes and retired all continuous walking links in the five requested sections.
- Lowered the connecting ground and low supports beneath the jumps. The tall uphill walls, trees, river, landmarks, hazard placement, and checkpoint positions remain.
- Fitted gaps using the actual convex landing outlines, with a rise-dependent limit based on normal jump physics.
- Added predictable, seeded size and side-to-side variation. Section 05's outer lines stay separated from the central landings.
- `JumpRevision = 1` prevents the pass from applying again to an already tuned course. Manual edits to that model are retained when the existing model is reused.

Tuning values live in [AscentJumpConfig](../src/ReplicatedStorage/Config/AscentJumpConfig.luau). The pass is [AscentJumpTuning](../src/ServerStorage/CourseBuilders/AscentJumpTuning.luau); [AscentJumpProfiles](../src/ServerStorage/CourseBuilders/AscentJumpProfiles.luau) records the current landing assets' upper collision outlines. Config changes should be tested on a fresh build, not by clearing the revision on an already modified model.

## Verification

- Fresh source build passed the authored geometry and difficulty checks.
- 747 landing-top rays, 228 snow-path samples, and preservation of all 80 accepted river pads passed.
- All 204 gap centres and their two nearby side samples were checked: 612 samples total. One side sample immediately after checkpoint 5 touches the broad checkpoint edge; every centre sample remains clear. No unexpected scenery bridges a tested gap.
- There are zero remaining continuous-route connections in these five sections.
- Mesh count remains 1,644. This count does not establish device performance.
- All **231 tested connections** were reached with normal character movement: 204 ordinary foothold connections and 27 longer checkpoint approaches. The initial combined run passed 229 cases and flagged two walking-only checks. Both flagged cases then blocked walking and passed their jumps in three isolated repeats each, without geometry changes. The artifact retains the initial failures and every rerun.
- Nine distinct shortest-gap walking checks successfully rejected walking across; the two flagged initial attempts above remain a reason to include these spots in the human fine-tuning pass.
- All **19 checkpoint contacts and splits** passed in a fresh live race using teleported approaches. This confirms contact/order, not full route traversal.
- **3,386 unrelated parts** retained their position, size, orientation, and color. Reapplying the jump pass changed no part a second time.
- Rojo build and whitespace checks passed. Studio returned to Edit mode; temporary runtime fixtures and UI changes were discarded.

[Geometry results](artifacts/jump-tuning-geometry.json) · [Difficulty results](artifacts/jump-tuning-difficulty.json)

[Character tests and reruns](artifacts/jump-tuning-character-tests.json) · [Checkpoint contacts](artifacts/jump-tuning-checkpoints.json) · [Preservation](artifacts/jump-tuning-preservation.json)

The character tests use isolated copies of the real collision meshes, with normal movement and airborne steering. They establish reachability of the tested connections, not a complete human course run, fun, multiplayer flow, or actual phone/PC performance. Final difficulty feel and fine-tuning remain with the owner.

## Preservation

The accepted pre-jump course is retained in Studio at `ServerStorage.AscentJumpCandidate01.Course_ClassicAscentPointToPoint`. The older V7 archive also remains. No place publication or Git commit is included.
