# Editing City Run

**Current workflow (September 22, 2026): City Run V3 is the only active City Run.** Edit `Workspace > Course_CityRun` while Play is stopped, save the Studio place, then press Play. The latest authored V3 is used automatically. Open **F6 / DEV TOOLS** for maps, race states, teleports and checkpoint jumps. See [Map editing and playtests](DEVELOPMENT_WORKFLOW.md).

The C13/C12 notes below are historical. Their snapshots now live in the [offline archive](../archive/retired-maps-2026-09-22/README.md), removed from ServerStorage; do not replay those migrations over the current V3.

**Current workflow (September 22, 2026): City Run V3 is the only active City Run.** Edit `Workspace > Course_CityRun` while Play is stopped, save the Studio place, then press Play. The latest authored V3 is used automatically. Open **F6 / DEV TOOLS** for maps, race states, teleports and checkpoint jumps. See [Map editing and playtests](DEVELOPMENT_WORKFLOW.md).

The C13/C12 notes below are historical. Their snapshots and old root archive folders now live under `ServerStorage > Archive > CityRun`; do not replay those migrations over the current V3.

Work in **Edit mode** under `Workspace > Course_CityRun`. Changes made during Play are discarded when Play stops.

## C13 editing controls

C13_05 keeps the owner's removed StationMain_00_00 pale coping in both Studio and Blender. The active terminal is under `Decoration > C13Terminal`. Select one of its **60 assembly Models** to move a building with all its windows and roof pieces. Expand the assembly to select one of **571 smaller visual units**. Each has a local pivot; all new scenery is anchored and has no collision or touch behavior.

- `C13_RiversidePortal`: separate piers, columns, bearing beam, canopy and lettering.
- `C13_MainHall`: body, lower window group, individual upper window bays, left/right roof slopes, front/rear gables, eave and sign. `C13_NorthGallery` holds the lower side gallery and its lean-to roof.
- `C13_ExpertService01–04`, `C13_ExpertBack01–03`, and the `East...` / `South...` assemblies form the surrounding streets. Their roof, window and service-detail units can move separately.
- `C13_FinalStation`: clock crown panels, lantern/cornice, wing gables and roof slopes, finish sign, colonnades and terrace details.
- `C13_Surface_StationMain_...` and `C13_Surface_X03_...`: separate platform visual skins, coping and edges. **Their invisible gameplay Parts remain under `Obstacles > WalkingSurfaces`.** Move both deliberately when changing gameplay; changing a visual alone only changes appearance.
- `C13_Depot` contains the replacement retaining wall bays, piers, rail beds and canopy. The retained maintenance shed/control tower remain under `Decoration > C11Depot`; the active train stays under `Obstacles > Moving`.

For ultrafine edits inside a local material mesh, open `assets/city_run/CityRun_C13_terminal.blend`, find the same named assembly collection and mesh, enter Edit Mode, hover a connected piece and use Select Linked. The Blender scene has the same assembly names as Studio. Some structural meshes contain multiple connected pieces; not every post is a separate Roblox Part.

The final editable backup is [city-run-c13-owner-final.rbxm](../backups/city-run-owner-edits-2026-09-12-c13/city-run-c13-owner-final.rbxm), verified against the reviewed C13_05 state including the owner edits. Originals and preliminary C13 pieces are preserved in `ServerStorage > CityRun_C13_Archive`. The before-change native backup is `backups/city-run-owner-edits-2026-09-12-c13/city-run-before-c13.rbxm`. `build_c13_terminal.py`, `C13Manifest.luau`, `C13Patch.luau`, `C13Refinement.luau`, `C13Editing.luau` and `C13Endcaps.luau` record the build and guarded migrations. Do not replay old migrations over new manual edits. See [QC ledger](artifacts/city-run/C13_QC_LEDGER.md).

## Previous C12 controls and retained gameplay


- C12 terminal scenery was replaced and archived by C13. The course geometry remains; the expert scaffold now has C13 stone/steel visual supports.
- `Decoration > C12CheckpointSupport` carries the relocated main CP03 pocket.
- `Decoration > C11Depot` contains the Blender-authored maintenance shed, retaining viaduct, control tower, crossing equipment and service props. Each named model is an editable group.
- Parked train visuals are inside matching `Obstacles > WalkingSurfaces > StationaryTrains_00_00` through `StationaryTrains_00_04`. Move the whole walking-surface model to keep each train and its existing roof collider together.
- `Obstacles > Moving` contains the three active coaches and both warning gates. Lowered gate arms remain non-colliding. The train still returns a hit racer to their checkpoint.
- `OwnerEdits > C11InvisibleWalls` contains 12 added boundary segments. Original owner walls remain in place. Check nearby routes before moving a boundary.
- `Decoration > C11FloorDepth` contains three editable district groups with 12 fade layers each. Keep the layers non-colliding, non-touching and non-queryable.
- CP03 now has two physical triggers: the main trigger is on the supported pocket before the first crumble row at `(3287.5,43.1182,-0.5)`; `AlternateTriggers > ExpertRoute` stays at `(3403.9727,53.4018,-49.1432)`. The mural checkpoint is archived. These C13_05 positions and trigger sizes preserve the owner's manual edits. Each accepted trigger saves its own respawn position. CP07 after the train remains the last checkpoint.
- CP03's two plates are under `Obstacles > WalkingSurfaces > C11CheckpointLandings`, with matching signs in `RouteMarkers > CheckpointSigns`. Move the specific plate, sign and trigger together to relocate one landing. Moving the primary trigger alone does not move its alternate parts.
- Fog settings in `CityRunAmbienceConfig` are density `0.20` and haze `0.70`. Restore the temporary Edit sky preview before Play or saving the place.

`ServerStorage > CityRun_C11_Archive` retains replaced depot visuals, checkpoint originals, two hazard pieces cleared from the expert landing, and preliminary C11 visuals. The before-C11 backup is `backups/city-run-owner-edits-2026-09-12/city-run-owner-edits-before-c11.rbxm`. `ServerStorage > CityRun_C12_Archive` retains replaced station and train scenery, previous CP03 objects, and preliminary C12 visuals. `assets/city_run/build_c12_terminal.py` authors `CityRun_C12_terminal.blend` and its FBX; `upload_receipt_C12_terminal_02.json` is the current upload receipt. Train body size and center are in `CityRunTuning` and its source `layout.py`. Guarded migrations must not be replayed over a newer owner-edited course. See [current build status](artifacts/city-run/BUILD_STATUS.md).

## C10 editing controls

The owner's opening and other existing manual edits were preserved. The later course continues its close city framing, red obstacles, cyan arrows, and three-lane crumble pattern. [Observed changes and design interpretation](artifacts/city-run/C10_OWNER_INTENT.md).

- `Obstacles > C10Obstacles` contains the new hurdles, side blocks, spinners, and 27 station crumble tiles. Move a whole named model. Each tile's dark seams are children of its physical yellow mesh so they disappear and return with it.
- `Decoration > C10Streets` contains the new nearby buildings and service details. `Decoration > C10Refinements` contains the renovation scaffold, rail gantries/wires, and retained street details. Current terminal buildings are under `C13Terminal`. These are anchored scenery with no collision or touch behavior.
- `RouteMarkers > C10Directions` contains the new arrows and the overhead `KEEP MOVING` notice. The low arrow at CP03 intentionally sits within the checkpoint's invisible trigger volume.
- `ServerStorage > CityRun_C10_Archive` retains the four original station platforms replaced by crumble tiles, the original finish banner, and the superseded C10 entry sign. Do not restore these over a newer manual edit without comparing first.

Red parts use the existing `HazardType = Kill` behavior. New spinners use `KitMotion = Spin`; their sweep must stay away from safe landings and checkpoints. The station tiles use `CrumbleDelay = 0.75` and `CrumbleResetTime = 2.5`. Collapse is shared across racers. A frame under a tile is scenery, not a backup floor.

The before-C10 native backup is `backups/city-run-owner-edits-2026-09-11/city-run-owner-edits-before-c10.rbxm`. The source overlay is `build_c10_remainder.py` / `C10Patch.luau`, followed by `build_c10_refinement.py` / `C10Refinement.luau`. The import guards expect their specific preceding builds; they are not general tools for resetting a manually edited course. [Current checks and review status](artifacts/city-run/BUILD_STATUS.md).

## C09 editing controls

`Decoration > BranchDirections2`, `BranchDirections4`, and `BranchDirections8` now contain separate board, text, arrow, floor-arrow, and support models. Select the named child to move that piece; select the outer model to move the full sign assembly. The owner's moved branch sign is retained.

`Decoration > MarketEditableProps > MarketArch` separates posts, caps, panel, and front/back lettering. `Decoration > MarketCloseFronts` separates the seven storefronts into named window, awning, panel, lettering, and planter groups. Existing owner moves and resizes are carried into these pieces.

The previously blank owner building is now `OwnerEdits > OwnerCourtyardBuilding`. Its four original meshes remain, with individually editable windows, trim, and roof vents in `EditableFacade`. Select the building model to move all of it together.

`Decoration > CourtyardPark` contains separate `Paths`, `Lawn1`â€“`Lawn4`, `Bench1`â€“`Bench4`, and `Tree1`â€“`Tree4` models. The park uses the original ground level and adds no collision or route surfaces. Move each whole named model to keep its pieces together. `CourtyardPark > Details` contains editable tree beds, planting, and lamps. `Decoration > CourtStairBase > ParkFrontage` holds the new ground-level doors, windows, and awnings.

The courtyard floor fade and superseded decorative tiles are preserved in `ServerStorage > CityRun_C09_Archive`. The rejected lowered-courtyard geometry is also archived there; it is not part of the active course. The original physical ground, platform elevations, and surrounding buildings remain in place.

At C09 acceptance the owner hazard group had **15 kill parts**. Later owner edits raised the whole-course count to 73 before C10 added its 34 kill parts. Their dimensions remain owner-controlled. Contact ignores accessories, held tools, fully transparent body parts, and the invisible HumanoidRootPart; visible limbs and the torso still count. Standing beside a block should be safe while the visible body remains clear. Moving blocks check their full travel between updates.

Car speed is **56 studs/second**, up from 40. Tune `assets/city_run/layout.py` and regenerate the matching `CityRunTuning.luau`; spawn intervals are unchanged.

The final C09 native backup is `backups/city-run-owner-edits-2026-09-09/city-run-c09-final.rbxm`. Its 5,027 saved instances and checked properties passed restoration verification. See the [C09 report](artifacts/city-run/BUILD_STATUS.md). The historical C08 counts and backup references below describe that earlier revision.

## Move a platform

Open `Obstacles > WalkingSurfaces`. C10 has 193 named models here; new crumble tiles live separately in `C10Obstacles`. Select and move the **whole model** so the visible pieces and the surface you stand on stay together. Some owner-modified platforms now use visible meshes for collision, while others retain a separate invisible collision part. Inspect `CanCollide` before resizing: a visible mesh resize does not automatically resize a separate collision part.

## Move market scenery

Open `Decoration > MarketEditableProps`. Trees, stalls, lamps, bunting spans, and the market arch are separate named models. Select the whole model to move a complete prop. The five new buildings are under `Decoration > MarketBackdrop`.

The later city and skyline buildings are under `Decoration > CityDepth`. These backdrop meshes have no collision; they are scenery, not playable platforms.

Other existing buildings remain separate models under `Decoration`. Some window, trim, and detail pieces within a building still share a mesh; C08 does not make every individual window editable.

## Find your additions

- `OwnerEdits` contains the preserved owner scenery, starting structures, and other manual additions.
- `OwnerEdits > InvisibleWalls` contains the ten existing walls. C10 adds no invisible walls.
- `Obstacles > OwnerKillStrips` contains the owner's manual hazard groups, including the later strips and moving pieces. C10's additions are in `C10Obstacles`.

New kill blocks must be descendants of `Course_CityRun`, normally inside `Obstacles`. Copy a whole template from `ObstacleKit_Palette > CopyThese`. Its red part must retain `HazardType = Kill`, `CanTouch = true`, and `CanQuery = true`. Course hazards recover active racers to their checkpoint; they do not act as unrestricted damage blocks during lobby waiting.

## Move a checkpoint

The visible blue Neon borders and numbered signs are under `RouteMarkers > CheckpointSigns`. The actual invisible trigger parts are under `Checkpoints`, named `Checkpoint_001` through `Checkpoint_007`. CP03 also has one expert alternate trigger as described above.

When relocating a checkpoint, move its platform model, matching sign model, and matching trigger together. Keep the trigger names and leave them directly inside `Checkpoints`. A sign alone does not set the respawn position.

## Preserved source and backups

The native backup `backups/city-run-owner-edits-2026-09-08/city-run-owner-edits-before-c08.rbxm` contains the first batch of owner edits, including the loose Workspace additions. Its round trip was checked across 2,134 instances.

The accepted result is saved beside it as `city-run-c08-final.rbxm`. Its saved bytes and all 3,709 backed-up instances passed the final restore comparison. See [verification and review scores](artifacts/city-run/BUILD_STATUS.md).

Replaced generated meshes remain in `ServerStorage > CityRun_C08_ReplacedGeneratedParts`. The far-away loose mesh copies were retained in Workspace.

`assets/city_run/build_c08_patch.py` builds the Blender overlay. `C08Patch.luau` applies it once to the preserved C07 course. Do not run the original full-course installer over a manually edited course.

`build_c08_refinement.py` and `C08Refinement.luau` provide the final city depth, slimmer station supports, and checkpoint sign placement. Both Blender scenes and upload receipts are retained.


## C15 fine editing

The current C15_04 route models, Blender file, native backup and tuning controls are described in [the C15 handoff](artifacts/city-run/c15/C15_HANDOFF.md). Move named units with their Collider and matching support; keep crumble visual guides under their Collider.
