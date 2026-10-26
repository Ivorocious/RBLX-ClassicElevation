# Option A: east turn and north final rail

Scoped author proposal for the confirmed Source23 late Arch Expert shortcut. No production, Studio, Normal geometry or reviewer files were changed. Native `rw10_short_arch_r13.json` records actual expected FinalRiseRail support after the ReturnTurn edge jump despite the surrounding focus trial later failing its recovery expectation; the successful landing is a real shortcut finding.

Use `ExpertRoutes_OPTION_A.luau` plus this single Layout line replacement:

```luau
local expertMergeNeedle = surface("ArchExpert", "MergeNeedle", v(-114, 51, 31), v(3.6, 1, 8), "ExpertPerch")
```

| Contact | Proposed position | Proposed X/Y/Z size |
| --- | --- | --- |
| ReturnTurn | -106,44,-4 | 7,1,10 |
| ReturnBeam | -121,46,1 | 14,1,3.2 |
| MergeTurn | -123,48,12 | unchanged 7,1,10 |
| FinalRiseRail | -114,50,22 | 3.6,1,8 |
| MergeNeedle | -114,51,31 | 3.6,1,8 |

The beam keeps its existing transverse hurdle; no extra hazard or barrier is added. The beam's intended landing remains before the hurdle, and the next transfer departs from the cleared far side. The final rail covers z18–26; the needle covers z27–35, leaving a real one-stud gap. The needle touches the intended shared merge edge at z35 without overlapping its footprint. Shared ArchMerge remains -122,52,44 at 18×18.

## Explicit supported goals

All goals reserve a 1.05-stud square half-footprint inside the floor. These values are already in the draft; do not substitute generic diagonal lips for the three changed corner commitments.

| Intended transfer | Departure | Arrival | Flight | Rise | Ideal reach spare |
| --- | --- | --- | ---: | ---: | ---: |
| OffsetCorbel → ReturnTurn | -110.25,42,-10.05 | -108.45,44,-7.95 | 2.766 | 2 | 5.252 |
| ReturnTurn → ReturnBeam | -108.45,44,-0.5 | -115.05,46,0.5 | 6.675 | 2 | 1.343 |
| Cleared ReturnBeam → MergeTurn | -124.6,46,1.55 | -125.45,48,8.05 | 6.555 | 2 | 1.463 |
| MergeTurn → FinalRiseRail | -120.55,48,15.95 | -114.75,50,19.05 | 6.576 | 2 | 1.442 |
| FinalRiseRail → MergeNeedle | generic aligned lips | generic aligned lips | 3.100 | 1 | 5.257 |

The hurdle approach and landing are x-117.4 and x-124.6 on the beam's z1 centerline. The return turn cannot land directly on its cleared far side: the corresponding horizontal x separation from the turn's western raw edge is 15.1 studs before avatar edge allowance.

## Raw rectangle separation

Using actual contact rectangles, not center distances:

| Attempted bypass | Raw closest-edge distance | After 2.121-stud total edge allowance | Spare above flat ideal reach 8.669 |
| --- | ---: | ---: | ---: |
| ReturnTurn → MergeTurn | 11.662 | 9.541 | 0.872 |
| ReturnTurn → FinalRiseRail | 17.213 | 15.092 | 6.423 |
| ReturnTurn → MergeNeedle | 26.140 | 24.019 | 15.350 |
| ReturnBeam → FinalRiseRail | 15.400 | 13.279 | 4.610 |

The allowance uses twice the observed avatar's 1.060341-stud half-root width as a conservative simple edge model. It is not proof against Roblox step-up, collision shape or momentum behavior; actual adversarial jumps remain required. Positive-rise bypasses receive the more generous flat reach in this screen.

`CheckRectangles.py` uses rotated native Normal rectangles from `rw10_final_r12_layout.json`. The five proposed Expert footprints have no overlap with other Normal contacts; only the intended shared-merge boundary touch remains. MergeTurn's existing proximity to Normal Causeway_4_1 is unchanged. FinalRiseRail is 10.609 studs from Normal Causeway_4_2 and 7.332 studs from SouthCloister Causeway_1_1, so it may jump directly to the shared cloister after the retained hurdle. MergeNeedle is already adjacent to that cloister (1.736 studs). Test those rejoin cuts; this proposal does not establish compulsory traversal of every final merge contact.

## Checks and physical test

`CheckOptionA.luau` compiled and loaded the candidate against current production Layout and dependencies, applying the needle change only in memory. All eight choice combinations retain supported Arch Expert goals. The two JSON reports contain the measured static values. These are author checks, not a final grade or native movement proof.

Lead should test the intended five transfers, the existing hurdle crossing, ReturnTurn→MergeTurn, ReturnTurn→FinalRiseRail, ReturnTurn→cleared beam, ReturnBeam→FinalRiseRail, and nearby Normal contacts with ordinary R15 speed16/JumpHeight7.2/gravity196.2. Preserve the earlier native success as historical evidence and require fresh blocked-bypass plus legitimate-route results before claiming closure.
