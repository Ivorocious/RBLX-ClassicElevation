# Expert and red-obstacle draft

Author implementation note, October 12, 2026. No reviewer grade or native gameplay pass is claimed. Inspected owner images 01–05 at original resolution. Only the four named draft modules and this note were authored; production and Studio were not changed by this helper.

## Required integration

- `ExpertRoutes(Layout, surface, archMerge, cp04, galleryFrame, galleryExitNode, upperExit)` keeps its existing function signature. Pass the actual `surface` constructor; retire the old Expert coordinate shifts, goal shifts, transfer shifts and mirrored UpperBrace generation. It reads actual contact records and `Layout.GalleryBands`. The current gallery bands are local z `-44/-98/-152`, y `2/6/10`.
- Upper rear waiting is read from `Obstacles/Lifts/UpperRearBoarding/Contact`; the current anchor is `(112,106,-162)`, Upper origin `(112,106,-145)`. CP04 stays `(112,106,-86)`. Both bays use the same western Expert approach and rear boarding. Expert `boardY=106`, `exitY=138`, `earlyExit=upperExit`, `expertExit={}`. No partial-height ride or post-lift bypass remains.
- E1/E2 wayfinding must target the first contact whose path differs from the fork path. The Expert arrays begin with an explicit supported departure on CP01/CP02.
- `RouteHazards.Build` needs `CrenelWeave`: a low, 2.8-stud side contact, supported opposite opening, opening minimum 3.2 for Expert / 5.5 for Normal, same existing side-contact arithmetic and low iron mount. Do not render it as the historical 13-stud WeaveGate slab. All hurdles stay below ordinary jump height.
- `SupportingObstacles.Apply` now only indexes and checks unique contacts. It never moves, resizes, clamps or rewrites geometry. `EnrichRoute` calls `RouteHazardGoals` once. Do not separately enrich an already enriched route.

## Draft behavior

Arch Expert takes twelve inner contacts with rising turns, 3.2/3.6-stud rails, paired hurdles and a shared merge. Lantern Expert uses a separated local x=10 lane through all three bands, 3-stud timed crossings, 1.5-stud offset exits and narrow supported hurdles. Upper Expert commits west from CP04, follows the x=51 needle sequence down to the rear, weaves through a 3.2-stud opening, and reaches rear boarding before the same full upper ride as Normal. Its final connection cannot use the retired close upper-car origin.

Normal/shared causeway hazards are selected deterministically from supported level causeway contacts: a hurdle, a low side weave, then a gap-only floor. Hazard records carry their direction and supported before/after points. Raised floors, waiting refuges, recovery ramps and checkpoint terraces are not automatically filled with red obstacles.

## Static checks completed

- All four modules compile with the repository's Lune compiler.
- Isolated mock with the coordinated actual anchors loads 43 surfaces, 39 explicit Expert transfers and 21 hazards, including an extra normal weave used to exercise that goal path.
- All Expert transfer and enriched hazard points contain a one-stud half-footprint inside their declared support. Expert authoring reserves 1.05 studs at each floor edge.
- Smallest ideal flight margin is 0.569 studs using speed 16, JumpHeight 7.2 and gravity 196.2. Transfers record actual floor-centerline air gaps, rise, flight distance and ideal margin. These equations assume perfect full-speed takeoff and are only a screen for impossible geometry.
- Directed footstep distance in that mock: Arch 244.3 studs; Lantern 203.6; Upper approach 184.4, before the full upper ride. These are path distances, not human run times or reward measurements.
- Full draft integration was attempted. At the first attempt, Layout rejected its Normal SharedArches Landing_1→Causeway_2_1 transfer (9.539-stud flight, 1.333 rise, -1.291 ideal margin). The Layout author received the exact failure. That does not invalidate the isolated Expert geometry checks and is not a full candidate pass.

## Required ordinary-avatar evidence

Use real R15 movement at speed 16 / JumpHeight 7.2 / gravity 196.2. Test each changed Expert transfer and hurdle before running the full route. Do not teleport, alter velocity/speed/gravity, fly, move contacts during play or erase misses. Keep each miss and its recovery outcome in the report.

1. Test E1 from CP01 to ArchMerge, including both paired hurdle chains and directional exits. Confirm the avatar body clears the red contacts, not just its feet. Try skipping each rise/turn and jumping from nearby Normal supports and recovery return pieces.
2. Test all three E2 timed crossings and raised exits with both safe and late swing phases. A 3-stud crossing gives only 0.5 studs on each side of a one-stud half-footprint. Verify the longer shared pendulum rod actually sweeps both lanes and leaves a usable phase window.
3. Test E3 into west boarding, both actual upper cars, their whole 106→138 ascent, rear exit and shared crown. Attempt the CP04→upper deck shortcut at the new origin and cross from each Expert support to Normal, rear waiting, lift guides, roofs and trim. Both lower and upper stages must occur in every branch combination.
4. Run Normal/Expert branches between the same fork/rejoin and report elapsed movement, lift/swing waiting and failures separately. A harder route is not proof of the requested time targets; no time claim is supplied here.

The narrow corners, paired hurdle feet/body clearance and moving lantern contact need native tests. The implementation author is not one of the five final independent reviewers.
