# Moonlit layout draft interface

This is an implementation draft, not an installed candidate or review judgment. All five owner images and A03/environment v04 were opened at original resolution. The parent owns native instance confirmation, native views, assembly, movement tests and final integration.

## Export and module contract

`Layout.luau` retains `Surfaces`, `ArchSkins`, `Transfers`, `CP01`–`CP04`, `StartPoint`, `FinishPoint`, `LiftOrigins`, `GalleryFrame`, `Lanterns`, `BranchCosts`, `Wayfinding`, `ReturnRoutes`, `GetRoute(choices,bays)` and `GetCatchRoute(name)`.

`ExpertRoutes(Layout,surface,archEndpoint,cp04,galleryFrame,galleryExitNode,upperExit)` receives the unshifted surface writer. Its arch endpoint is the extra `ArchExpert/MergeNeedle` at(-114,51,30),3.6×10. Layout then appends the explicit jump from that corbel to the real shared ArchMerge at(-122,52,44), before either branch takes the shared cloister. This fixes the separately authored final rail connection without changing Expert's other contacts. No shift wrapper or mirrored upper branch remains. `SupportingObstacles.Apply` records floors; it must not apply the old hardcoded positional changes. The new `RouteHazardLayout` chooses supported obstacles from actual floors, and `RouteHazardGoals` supplies their directed movement goals.

`RouteBlockers = {}`; `UpperFrontWall` is absent. RouteBuilder must retire its unconditional `UpperBoardingWall` creation. No replacement wall, collision curtain or decorative route blocker is included. Renderer assertions tied to exactly 21 old hazards need the current count. Old Wayfinding decision plaque positions/text need the new anchors.

## Current anchors

All coordinates are local to Config.Origin.

| Contact | Position | Notes |
| --- | --- | --- |
| GateCourt | -144,0,146 | Preserved 44×36 start capacity; route leaves north-west instead of threading beneath its footprint. |
| SharedArches entry | -128,12,64 | Shared climb to CP01 retained. |
| CP01 | -144,28,-112 | Ordered first checkpoint and both arch fork entries. |
| ArchMerge | -122,52,44 | Separate final landing before the shared cloister; extra room for ordinary rising jumps. |
| CP02 / GalleryFrame | -80,52,28 | Frame yaw -pi/2, local forward -Z points toward world +X. |
| Gallery bands | z=-44,-98,-152; y=2,6,10 | 54-stud spacing supplies real inter-band takeoff/landing room. |
| Normal gallery waits/crossings | local x=-26 / -16 | Wide outer refuges, three timed crossings. |
| Expert gallery crossings | local x=10 | Separate narrow lane, all three swings retained. |
| GalleryExit | 112,66,28 | Shared merge before machinery approach at x164. |
| CP03 | 112,72,-52 | Broad lower boarding terrace. |
| Lower lift origin | 112,72,-69 | Preserved paired bays, travel34, cycle14, delay7. |
| CP04 | 112,106,-86 | Preserved lower lift arrival and ordered fourth checkpoint. |
| Upper lift origin | 112,106,-145 | Moved north42; CP04 no longer touches the upper deck approach. |
| UpperRearBoarding | 112,106,-162 | Normal east and Expert west approaches rejoin behind the lift. |
| SharedUpperExit | 112,140,-162 | Both modes retain the full upper ride. |
| CrownTerrace / Finish | -8,150,-30 | Crown gap route via x48,z-162 and x48,z-56. |

The three pendulums retain 32-degree swing, 6-second cycle and existing phase offsets. Their point/pivot vertical difference grows from14 to26 studs, placing rest centre at deck+3 and pivot at deck+29. That supplies approximately13.78 studs of centre swing each side, with the 4-stud cage reaching both timing lanes26 studs apart. Runtime and any clearance tests must derive rod length from the new point/pivot records. This is a geometry calculation; actual safe crossing timing still needs native avatar tests.

Each checkpoint uses its terrace as `pocketSupport`, with a30×14 respawn area supporting21 existing4.5-stud grid positions. It does not create a second overlapping recovery-pocket floor.

Recovery shelves extend beyond their checkpoint floors, with explicit off-edge drop goals. ArchCatch is centred(-139,12,-112),44×28; LiftCatch is centred(112,90,-84),60×26. Continuous outer ramps return to CP01 and CP04 respectively. A shelf placed exactly beneath the checkpoint footprint would be unreachable by a normal off-edge drop; these overhangs avoid that mistake.

## Five-image draft closure mapping

| Image | Before mapping and problem | Draft placement and required proof |
| --- | --- | --- |
| 01 | Parent positively confirmed `Gate/GateCourt` x[-166,-122],z[128,164], nearby `Landing_1`(-120,0,146), `Causeway_2_1`(-120,0,159), `Landing_2`(-120,0,174). The broad court and low route overlap. | Remove that tucked side sequence. Gate leaves toward(-170,6,94) then(-128,12,64), using supported4.5-stud rising gaps. Take matching player-height images and check court lip visibility/headroom. |
| 02 | The image marks a sideways jump between neighboring red-gate approach contacts and questions the nearby broad landing. Exact native names remain with the parent to confirm. | Shared arches use four successive staggered stone spans; Normal takes a separate west ascent at x-188 rather than following long red-gate strips beside a broad terrace. Check the confirmed old pair against new corresponding approaches and attempt diagonal/backward jumps. |
| 03 | The pictured turquoise checkpoint and two-colour fork identify the CP01 decision terrace. Parent should confirm the marked side steps/long strip names from native recovery. | Shared climb meets CP01 from south; Normal leaves west and Expert leaves east. Final arch merge sits at(-122,52,44) at24 studs above CP01, without a long parallel entrance strip. Verify skip attempts from each final shared stone to each branch and the checkpoint from both sides. |
| 04 | Broad pads beside a parallel hazard strip, with a cross-lane jump marked. Exact native gallery/approach names still require parent confirmation. | Gallery lanes have26-stud centre separation at crossings, leaving roughly20.5 studs between an8-stud Normal and3-stud Expert crossing. Their waits are still farther apart. New54-stud band spacing replaces unclear inter-band strips. Attempt all side jumps at every band and verify the widened pendulum sweep affects both lanes. |
| 05 | `Lifts/CP04Terrace`, `UpperBoardingWall`, upper mechanism and rear boarding fork. Removing only the old wall leaves a2-stud gap from CP04 to the old upper deck. | Retire wall and move the mechanism42 studs north. CP04 north edge=-95; new deck south edge=-139, leaving44 studs before boarding. Normal visibly leaves east toward x160; Expert commits west and traverses a precision route. Both board rear at106 and exit138, preserving full upper travel. Test direct CP04-to-car attempts at all car phases, both approaches and both bays. |

Only image01 and05 are currently confirmed exact native name mappings here. The remaining images must not be called closed until the parent maps the marked pieces and supplies corresponding native views/movement results.

## Required native checks

Check ordinary R15 jumps with speed16, JumpHeight7.2 and gravity196.2. Flat authored stones expose their rises; Normal generation asserts at least0.65 stud of ideal reach margin and rejects landing lengths below5 studs. These checks cannot prove human timing or moving contact.

The configured Lune0.10.5 read-only fixture has verified the Normal layout in isolation:96 fixed surfaces,77 air transfers,22 shared low red obstacles and272 directed route goals. Empty gaps measured4.499991–5.500004 studs. Minimum ideal reach spare was0.973292 studs, and all route feet points kept a1-stud half-width footprint supported, with minimum spare0.049999 stud. A separating-axis rectangle check found no fixed non-recovery floor footprint overlaps with vertical separation between1.5 and10.4 studs. The recovery routes each resolve11 goals. This fixture deliberately substituted Expert's function while its separately owned final merge was repaired; these numbers are not a complete integrated candidate check.

After adding MergeNeedle, the full compatible draft passed all32 route/bay combinations:133 surfaces,117 air transfers and42 low red obstacles. Every route keeps all four checkpoints, all three timed bands and both rides; the upper ride always boards106 and exits138. Minimum ideal reach spare is0.569248 studs, and minimum1-stud foot support spare is0.049997 stud. Directed static footstep travel measures1509.32 studs Normal and1518.58 studs Expert. These include route goals and obstacle manoeuvres; they are not human pacing or race timing.

The integrated footprint check exposed two small Expert overhead overlaps that the parent must close while integrating its Expert draft: WrapTurn/HurdleBeam overlap0.5 stud with2-stud rise, and GalleryExit/Expert ExitTurn overlap1 stud with2-stud rise. Suggested minimal edits are HurdleBeam worldX=-98.4 instead of-99, and Gallery Expert ExitTurn localX=13 instead of11.5. Recheck the Expert transfers and feet goals after those edits. The existence of these two overlaps prevents calling the unintegrated draft clearance-complete.

Draft slope/flat frames use explicit CFrame.Angles. The configured Lune CFrame.lookAt produced a reversed Z component in a small datatype probe; native Studio frame/readback checks remain authoritative.

Attempt cross-route jumps, diagonal corner cuts, direct car boarding, checkpoint skips, roof/trim/support shortcuts and recovery returns. A recovery return may lead only backward to its checkpoint. Confirm all three swings, both complete lift stages, CP01–CP04 order and legitimate Finish touch for all route choices/bays.

Reserve player camera and jump headroom above every takeoff/landing; world pieces must not become route blockers or fill the air gaps. Inspect approach, landing and final night visibility. Branch and whole-run timings remain measurements to perform;4–6 minute Normal and2–3 minute practiced Expert remain goals.
