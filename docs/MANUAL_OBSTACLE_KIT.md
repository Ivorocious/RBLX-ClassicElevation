# Manual obstacle kit

**66 reusable sets, shared across all current and future courses.** V5 adds **24 sets, numbered 43–66**, in a new wing beside the original palette. All first 42 models, their display pieces and the palette position are preserved. Recolor and decorate the pieces for your course while keeping danger, crumble and timed surfaces readable.

The kit is currently at `Workspace.ObstacleKit_Palette.CopyThese`, at its owner-controlled position. When storing it outside the scene, use `ServerStorage.DeveloperAssets.ObstacleKit_Palette`. Live servers move it there at startup ([StoreObstaclePalette.server.luau](../src/ServerScriptService/StoreObstaclePalette.server.luau)) so players never download it; Studio Edit and Play leave it in Workspace. Select the Workspace palette in Explorer and press **F** to find it. `Display_DoNotCopy` contains only labels and non-colliding display mats.

## Place a trap or set

1. Stop Play. Select a numbered model inside `CopyThese` and duplicate it with **Ctrl+D**.
2. Move the duplicate into the **editable course's `Obstacles` folder**. For example, City Run uses `Workspace.Course_CityRun.Obstacles`; another course uses its own authored model. Move and rotate the whole obstacle into position; resize individual parts as needed.
3. Keep parts anchored. Preserve `HazardType`, `CanTouch` and `CanQuery` on trap parts. Duplicate the templates again whenever you need more pieces.
4. Press Play and wait for the race to begin. Red parts return an active racer to their last checkpoint. Crumble tiles shake for 0.75 seconds in set 15 or 0.65 seconds in the new sets, then visibly fall while anchored and return after their 2.5-second reset window. Change `CrumbleDelay` and `CrumbleResetTime` on a tile to tune those timings.

Hazards bind when a race course is loaded. The palette itself is outside the active course and does not act as a race hazard. Pieces left elsewhere in Workspace are not included. Place copies in the authored course in Edit, not the temporary `RaceCourse` created during Play. Future courses need the standard course structure and shared CourseHazardService/RespawnService, just like existing courses. Save your Studio place to retain manual placements.

## Included pieces

| Number | Piece or set | Behavior |
| --- | --- | --- |
| 01 | Red kill block | Resizable lethal block |
| 02 | Red kill strip | Thin bar for jump timing |
| 03 | Red kill wall | Lethal vertical obstacle |
| 04 | Red kill sphere | Round lethal obstacle |
| 05 | Hurdle lane | Three red bars on a safe deck |
| 06 | Offset jumps | Four alternating landings |
| 07 | Zigzag beams | Narrow connected balance route |
| 08 | Post jumps | Four round landing tops |
| 09 | Rising jumps | Four steps with increasing height |
| 10 | Window hops | Two offset framed openings |
| 11 | Wall wrap | Jump around the end of a wall |
| 12 | Corner ledges | Three rising ledges around a column |
| 13 | Checker traps | Alternating safe and red floor tiles |
| 14 | Precision over lava | Small offset landings above a red floor |
| 15 | Crumble bridge | Five timed collapsing tiles |
| 16 | Kill gate weave | Alternating red walls with side openings |
| 17 | Spinning strip | One rotating red bar; six seconds per revolution |
| 18 | Cross spinner | Two rotating red bars; eight seconds per revolution |
| 19 | Swinging bar | Red bar swings up and down by 65 degrees |
| 20 | Sliding gate | Red wall slides eight studs to either side |
| 21 | Crumble stones | Six alternating collapsing steps |
| 22 | Crumble fork | Wide and narrow collapsing branches |
| 23 | Triple rotor | Three horizontal bars rotate together |
| 24 | Vertical wheel | Two bars rotate around a supported axle |
| 25 | Twin swings | Two supported bars swing on different periods |
| 26 | Low sweep | Two low bars sweep across the deck |
| 27 | Twin shutters | Two panels slide in opposite directions |
| 28 | Travelling hurdles | Two low bars move along the lane |
| 29 | Crumble and rotor | Collapsing bridge beneath a rotating bar |
| 30 | Sliding slalom | Three moving panels with changing gaps |
| 31 | Piston presses | Three vertical presses with staggered timing |
| 32 | Clockwork crossing | Narrow spokes, a safe raised hub and two rotating hands |
| 33 | Cargo shuttle | Three sliding loads with waiting islands between tracks |
| 34 | Rising shutter vault | Alternating lift-up doors and a waiting chamber |
| 35 | Spiral chimney | Eight ledges climbing around a central tower |
| 36 | Canal mooring hops | Alternating round bollard caps above a danger floor |
| 37 | Switchback pipewalk | Narrow turns and brass elbows over a danger floor |
| 38 | Crumble stair choice | Broad forgiving steps versus a shorter, tighter route |
| 39 | Falling piano keys | Collapsing keys with raised safe resting keys |
| 40 | Rooftop skylights | Collapsing panes surrounded by narrow safe frames |
| 41 | Keyhole hops | Offset framed openings with low red jump thresholds |
| 42 | Scissor crossing | Opposing swinging blades at two crossing points |
| 43 | Hammer arcade | Three top-hinged hammer heads with staggered timing |
| 44 | Satellite causeway | Two orbiting hazards around a permanent central island |
| 45 | Rotating doorway | A complete red frame rotates around its opening |
| 46 | Crescent sweep | Curved stepping caps around a swinging radial arm |
| 47 | Folding fan gates | Paired doors rotate around their outer hinges |
| 48 | Orbital jump rope | A low bar circles an overhead axle |
| 49 | Pulse stones | Fading stepping stones with a permanent middle island |
| 50 | Alternating isles | Two lanes take turns becoming solid |
| 51 | Heartbeat causeway | A warning wave travels along the bridge |
| 52 | Vanishing stairs | Fading steps climb past permanent waiting balconies |
| 53 | Switchboard | A changing three-by-three grid around a permanent centre |
| 54 | Ghost lattice | Fading balance beams join permanent corner pads |
| 55 | Twisted trestles | Alternating tilted landing beams |
| 56 | Broken aqueduct | A broken, curving ascent over tall piers |
| 57 | Over under knot | A continuous lower passage curls into an overhead climb |
| 58 | Compass spiral | Eight rising compass points around a red central needle |
| 59 | Cantilever canyon | Alternating ledges inside two tall walls |
| 60 | Split level braid | Early and late climbing routes cross at different heights |
| 61 | Hourglass crossing | Crumbling approaches and hinged sweepers around a raised island |
| 62 | Eclipse chamber | An orbiting hazard crosses a fading route |
| 63 | Shuffle vault | Three timed lanes, a sliding shutter and crosswise waiting bays |
| 64 | Tidal lock | Fading approaches around a permanent chamber and rising gate |
| 65 | Domino stair sprint | Crumbling stairs, a waiting balcony and an overhead hammer |
| 66 | Clockwork gauntlet | A hinged entry, fading middle pads and crumbling exit |

### V5: hinges, timed platforms and new routes

The new wing has four rows of six: **43–48 machinery, 49–54 timed platforms, 55–60 climbing routes, and 61–66 combined challenges**. Each model has `Instructions`, `Difficulty` and `Category` attributes. V5 adds **442 obstacle parts: 22 moving red hazards (20 use an offset hinge), 55 timed platforms, and 12 crumble tiles**, plus ordinary platforms and decoration. There are no embedded scripts or new remotes. Display boards and mats are separate from those counts.

Duplicate a whole numbered model into the editable course's `Obstacles` folder, then move or rotate it as a unit. Keep the permanent waiting islands. For set 57, walk along the lower underpass before jumping around the rising outer steps. Set 60 offers two routes to the same raised exit.

`AddInventivePieces(existingPalette)` adds only missing sets 43–66 and the new display signs. Calling it again does not duplicate or replace anything. `AddCreativePieces` continues to add only sets 31–42. The new definitions are in `ManualObstacleInventive.luau`; the builder remains `ManualObstacleKit.luau`.

New models have `Instructions` and `Difficulty` attributes. Read them in Properties after selecting a numbered model. Sets 31–42 add **143 obstacle parts**, including **14 moving hazards and 20 crumble tiles**, with no embedded scripts or new remotes. Display boards/mats are separate. `AddCreativePieces(existingPalette)` appends only missing new sets and keeps the palette's current position; repeating it does not make duplicates. Source: `ManualObstacleCreative.luau`, integrated by `ManualObstacleKit.luau`.

The original 30 models contain 141 obstacle parts, including 40 kill parts, 20 crumble tiles and 22 moving trap parts. These are native editable primitives for manual resizing and placement. They use the existing server-side CourseHazardService and RespawnService; there are no per-block scripts or new remotes. `AddAdvancedPieces(existingPalette)` appends sets 21–30 without changing earlier pieces and preserves the palette's position.

## Moving trap settings

Copy the whole numbered set into the course's Obstacles folder before Play. Move/rotate it in Edit; its placed position becomes the motion origin. Motion runs during an active race and resets afterward. The palette itself remains still.

Select the moving red part and edit its Attributes:

- `MotionPeriod`: seconds per complete cycle; larger is slower (supported range 2-120).
- `MotionAxis`: local X, Y or Z axis. Rotate the model to orient its motion in the course.
- `MotionDistance`: slide distance on each side of the starting position.
- `MotionPhase`: starting cycle offset in degrees (0�360); 180 makes matching slides move in opposite directions. Defaults to 0.
- `MotionAngle`: maximum swing angle in degrees.
- `MotionPivotOffset`: a Vector3 from the moving part's centre to its hinge, measured along that part's local axes. Zero keeps the original centre rotation. The supported distance is at most 100 studs. Keep the offset aligned with the visible axle when resizing the part. Whole-model rotation needs no offset changes.

Keep both cross-spinner bars on the same period. Moving red parts are anchored but non-colliding, so they trigger checkpoint recovery without physically pushing players. Keep their `HazardType`, `KitMotion`, touch and query settings. Leave enough clear space for the complete movement, including nearby safe waiting and respawn areas.

ManualObstacleMotion is called by CourseHazardService for the active course. It collects parts with `KitMotion` and, through ManualObstaclePhases, platforms with `KitPhase`. Moving hazards sample their path between positions, use the existing active-racer recovery checks, and restore placed transforms when stopped or unbound. The sampling distance includes the hinge radius. On a large frame delay or extreme size it slows the timeline rather than skipping the intervening movement. It does not add a moving-platform riding system.

## Timed platform settings

**Cyan is solid. Amber warns that the platform will disappear. A faint purple ghost cannot hold a character.** The narrow purple outline is decoration. The warning lasts 1.2 seconds in the supplied sets. Permanent teal islands give racers somewhere to wait.

Select the cyan platform and edit its Attributes:

- `KitPhase`: keep `Pulse` to enable its cycle during a race.
- `PhasePeriod`: total cycle length in seconds, supported from 2 to 120.
- `PhaseSolidTime`: seconds before the warning starts.
- `PhaseWarningTime`: seconds of warning while the platform still holds characters.
- `PhaseOffset`: starting offset in degrees; 180 shifts a matching platform by half a cycle.

The remaining cycle time is the ghost interval. The controller keeps at least 0.5 seconds solid, 0.25 seconds of warning and 0.25 seconds ghost, clamping conflicting settings to fit the period. All platforms start solid in Edit. Offset platforms can start a race at different points in their cycles. Colours, materials, transparency and collision/touch/query flags restore when the race stops or the course changes.

Keep these platforms anchored and initially collidable, and do not add `HazardType` to the same part. Place them above a fall zone or the included red floor. They also work in a course that contains no moving red hazards. Changing attributes during Play requires rebinding the course; tune them in Edit for normal use.

The sets are building pieces, not accepted final route layouts. After placing them, check jump gaps, body/head clearance, safe checkpoint respawns and room to pass. Putting a small model on top of an existing broad floor may allow racers to walk around it; position traps and route edges deliberately.

## Source and checks

V5 passed **17 live service checks**: an existing spinner and every one of the 12 new moving sets moved and recovered an actual R15 character with zero checkpoint-position error; non-racers were excluded from recovery; timed platforms restored when inactive; a real character stood on a solid platform, remained supported during its warning, fell through its ghost and saw it return; unbind/rebind and Stop restored the platform.

Controller checks covered **all 58 moving parts and 55 timed platforms**, with the palette rotated 120 degrees, over 22 simulated seconds. All transforms, colours and physical flags restored. A course containing only timed platforms and the minimum two-second cycle with default timings also passed.

All six new static climbing sets passed **seven scripted solo traversals**, including both braid paths, at walk speed 16 and jump height 7.2. The driver made 51 jumps and walked the knot's lower passage, with no teleports after each route's initial placement. Testing found and corrected the knot's lower gaps and the lower braid's final step. These checks establish basic traversal; they do not establish human difficulty, complete traversal of the moving/combined sets, multiplayer traffic, device performance or owner acceptance.

The native backup comparison preserves all 500 original instance records, including attributes and recorded part properties. All 369 original parts also kept their exact Studio transforms and sizes, and the palette pivot stayed at its owner-controlled position. Both native files reopen and survive a serialize/deserialize roundtrip. Five kit sources compile, the Studio test executes, and Rojo build passes. [Static and preservation results](artifacts/shared-obstacle-kit-v5-static.json), [controller and live results](artifacts/shared-obstacle-kit-v5-live.json), [test source](../tests/studio/ManualObstacleKitV5.luau).

Native recovery files are `backups/shared-obstacle-kit-v5-2026-10-11/palette-before-v5.rbxm` and `backups/shared-obstacle-kit-v5-2026-10-11/palette-v5.rbxm`. The live palette is left in Edit. Save your Studio place to retain the expanded library in that place; the native V5 backup is already saved locally.

V4 passed **13 live checks**: five new moving-set contacts plus an existing spinner regression check, checkpoint recovery, non-racer/inactive-race exclusion, motion reset/rebind, and the three new crumble families falling and resetting. All tested checkpoint errors were zero. A separate rotated-placement check verified all 14 new moving parts move and restore their authored transforms. The first 30 sets and all 202 original palette/display parts retained their positions and sizes. All 110 source files compiled and Rojo build passed. Full manual traversal and course-specific difficulty remain to be checked. [V4 evidence](artifacts/shared-obstacle-kit-v4-checks.json), [test source](../tests/studio/ManualObstacleKitV4.luau).

A native, restore-checked palette backup is saved at `backups/shared-obstacle-kit-v4-2026-09-23/shared-obstacle-palette-v4.rbxm`. Save the Studio place after placing new obstacles. No copies were automatically inserted into a course.

The C11 V3 check passed 15 cases: eight moving-set contacts and checkpoint recoveries, non-racer and inactive-race exclusion, motion reset and rebind, and all three new crumble-set cycles. Every tested recovery had zero checkpoint position error. These use isolated race dependencies; complete obstacle traversal and owner placements still need playtesting. [V3 evidence](artifacts/city-run/C11-kit-play-checks.json), [test source](../tests/studio/ManualObstacleKitV3.luau).

`src/ServerStorage/CourseBuilders/ManualObstacleKit.luau` recreates the palette. It does not run automatically or replace an existing palette. With Rojo synchronized, the Edit Command Bar can create a missing palette using:

```lua
require(game.ServerStorage.CourseBuilders.ManualObstacleKit).Build(workspace)
```

Initial installation checked all 71 parts for anchoring, collision, touch/query properties and hazard attributes, confirmed 16 separate models with no embedded scripts, and confirmed City Run retained its 1,803 descendants. The actual Studio overview was inspected and Rojo build passed.

The focused Play check passed all seven cases: red block/strip/wall/sphere recovery (zero checkpoint error), non-racer exclusion, inactive-race exclusion, and crumble touch/disappear/reset. It used the existing services with isolated race/checkpoint dependencies. The test fixture was removed and Studio returned to Edit. [Recorded results](artifacts/manual-obstacle-kit-checks.json); test source: `tests/studio/ManualObstacleKit.luau`. Owner placements and complete obstacle traversal remain unverified.

The V2 check passed all 13 cases, retaining the static/crumble cases and adding four moving-trap contacts, inactive-motion reset and unbind/rebind restoration. Every tested contact had zero checkpoint error. No console errors were observed, and Rojo build passed. [V2 evidence](artifacts/manual-kit-v2-checks.json). The added [floor and horizon depth kit](DEPTH_ILLUSION_KIT.md) is separate from the traps.
