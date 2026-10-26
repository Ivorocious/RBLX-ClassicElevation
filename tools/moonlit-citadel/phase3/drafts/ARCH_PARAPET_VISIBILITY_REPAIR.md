# Arch parapet north-end repair

Replace only ArchInsideParapet's point and size in the next fresh candidate:

```luau
{name = "ArchInsideParapet", point = v(-145,35,-43), size = v(1.5,18,74)}
```

This moves its north end from Z=-102 to Z=-80. X=-145, thickness1.5, bottomY26, topY44 and south endZ=-6 stay identical. It remains one visible solid wall, using the current normal builder and matching full-height skin. No invisible replacement collider or lowered skin is proposed. CrownInsideParapet is unchanged.

The lead's true Build04 native E1 arrival/fork views and pixel ray identified Workspace.RaceCourse.Obstacles.RouteParapets.ArchInsideParapet as the actual plain slab blocking the Expert receiving lips. This supersedes the earlier helper's arch-art attribution for that particular slab. The earlier three overly stretched arches were separate visual candidates; removing them did not fix this solid blocker. No native visual pass is claimed here.

CP01 is at (-144,28,-112). Expert RiseCorbel is (-129,32,-91), size(4,1,9); WrapTurn is (-121,36,-87), size(9,1,12). The new wall starts one stud south of WrapTurn's Z=-81 edge, so it exposes both early receiving surfaces and the existing upright red gate around Z=-88. Their floors, gate, four-stud rises and 3.2/3.6-stud rails remain unchanged. The longer wall remains beside the later climb.

## Focused shortcut check

ParapetNorthEndCheck.py reads INTEGRATED_LAYOUT.json's unchanged E1 geometry. It takes a one-stud footprint inset, clips each early route launch surface to the west side of X=-145, and computes minimum horizontal distance to the first three Expert receiving surfaces. It compares that distance with ideal ordinary jumps using WalkSpeed16, Gravity196.2 and JumpHeight7.2. The screen covers Gate, SharedArches and ArchNormal sources; it is deliberately broader than only the newly opened Z interval. It found zero reachable airborne west-to-east pairs in this subset.

| Potential shortcut | Minimum supported-foot separation | Ideal reach | Result |
| --- | ---: | ---: | --- |
| Shared Causeway4_2 Y26 to RiseCorbel Y32 | 20.29 | 6.10 | 14.18 studs beyond ideal reach |
| West half of CP01 Y28 to RiseCorbel Y32 | 16.35 | 7.22 | 9.12 studs beyond ideal reach; ordinary racers instead walk east within CP01 and take the existing authored jump |
| Any CP01 Y28 to WrapTurn Y36 | — | — | Rise8 exceeds JumpHeight7.2 |
| RiseCorbel Y32 directly to HurdleBeam Y40 | — | — | Rise8 exceeds JumpHeight7.2 |

The nearest feasible-height Normal launches to WrapTurn remain over83 studs away. The nearest feasible-height Normal launches to HurdleBeam remain over57 studs away. No platform, parapet ledge or new landing is added. Legitimate branch behavior still requires CP01, RiseCorbel, WrapTurn/gate, and the later beam commitments. This is a static ideal-reach screen, not a guarantee of native physics or every possible abuse path.

## Affected native verification only

1. Capture the same true E1Arrival and E1ExpertFork after rebuilding. Confirm the first RiseCorbel receiving lip and the red WrapTurn gate are visible; inspect the actual pixels rather than asserting that shorter geometry must look better.
2. Run the existing CP01-to-first-Expert commitments unchanged. Check the wall's new end at Z=-80 does not cover takeoff/landing, and keep the gate opening and four-stud rises intact.
3. Attempt the specific incoming Causeway4_2-to-RiseCorbel shortcut once, plus CP01-to-WrapTurn. Keep the existing driver, checkpoints, hazard count, motion and world bounds unchanged.

Run `python tools/moonlit-citadel/phase3/drafts/ParapetNorthEndCheck.py` to repeat the local screen. It completed successfully on the current exported E1 geometry. No production source, Studio, world placement, runtime or play driver was changed by this helper.
