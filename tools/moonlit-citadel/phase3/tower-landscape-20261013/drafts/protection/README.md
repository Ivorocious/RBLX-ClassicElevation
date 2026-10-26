# Source43 tower and landscape protection

Read-only safety/evidence helper. Only this protection draft directory was edited. No Studio, Blender, production or accepted course changes were made. This helper is an author/checker, not a final judge.

## Baseline and commands

Starting saved candidate: `MC_P3_ART_REPAIR_AR04`, Source43, Build37, packet `81ba6fdb12b23d4a4abee5795dece2a1994b146c93dc528b4b8b4198e3a2f0cb`. Saved recovery comes from `docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source43/final/`.

`prepare_source43.py` verified all three saved recovery file receipts, all 23 embedded native-source hashes and their current filesystem text. It extracted 894 protected physical parts,805 Phase3World art parts and19 selected mesh arrows. That physical export lacks complete Model/GUI/attachment metadata; it does not replace the lead's fresh native snapshot. The saved source matches were observed before this integration, not asserted for later art edits.

`source43-behavior-baseline.json` was captured immediately before integration. It contains 37 exact behavior/config/Phase1 source hashes plus the exact accepted arrow-implementation tail in EnvironmentPlan. The initial comparison passed with no changes.

After integration, run only the focused source and combined-plan checks:

```powershell
python tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/source_baseline.py compare
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/CheckIntegration.luau
```

The combined checker defaults to the new pass's `stage/`; an explicit directory can be supplied as its first argument. It loads architecture/environment and their source dependencies, compiles WorldAssembly, verifies returned unit counts/unique names, combined limits, and complete occupied geometry rows. It checks new tower pieces and all proposed landscape canopy/trunk/ground rows. Missing landscape staging or missing occupied rows is a concrete failure, never an implied pass. It does not place anything or start gameplay.

Current staged result after the connected countryside base: **283 units,717 scenery meshes,251,878 triangles**, with zero movement, jump-headroom, camera, landing-view, mechanism or scenery-contact-flag findings. Remaining under unchanged350/900/420,000 limits:67 units,183 meshes,168,122 triangles. These are static staged facts; actual installed/native counts and pictures remain required.

## Fresh native comparison and duplicate names

Use this directory's `ProtectedCourse.luau`, schema2, for **fresh** before/after captures in Edit/rest state. The lead reports it captured the fresh current Source43 courses, current Phase1, BL02 kit and arrow templates with no ambiguous duplicate groups. Do not compare those new records directly to an older schema1 occurrence-indexed baseline.

```luau
local before = Protected.Capture(explicitCourse)
local after = Protected.Capture(theSameCourseAfterArt)
local report = Protected.Compare(before, after)
```

Capture and compare Workspace and stored course separately, accepted BL02 kit, both arrow templates, and current accepted Phase1. `CaptureFrozenPhase1Model` accepts the current `MoonlitCitadelPhase1_BL02` or the lead's fresh `BeforePhase1Current43` recovery clone. Do not rename, move or revert the live Phase1 model to make a comparison pass.

Repeated sibling names are ranked by complete property/attribute/tag and child signatures, including frame/size and reference-target geometry. Reordering CableAnchor, MachineGuide or EntryRailContact siblings after reloading does not change their meaningful match. Object references use the same ranked paths. Exact equal signatures are reported as ambiguous and block pass; the tool does not pick an arbitrary match and hide possible behavior changes. Focused synthetic checks passed reordering, actual mutation detection and ambiguity rejection.

The earlier20 Phase1 differences are historical findings from an occurrence-indexed comparison. This tool neither declares them owner changes nor erases them. Preserve the fresh current state regardless of their origin. Freeze the collector code used for the new native baseline alongside that baseline; changing the matching scheme requires fresh captures.

Only `Decoration/Phase3World` is art-editable by default. Existing Phase2 decoration, accepted arch undersides, floor skins, all geometry/collision/query/touch flags,55 on-course red contacts,135 floor contacts,147 colliders, four checkpoints, both lift stages, three swings, catches/returns, fall zones, forward finish and exact selected19 arrows remain protected. The collector preserves signs/lettering, template geometry, pivots, attachments/links, runtime/config metadata and sources. World lights with `MoonlitWorldLight=true` are reported separately; original mechanism lights remain frozen. Scripts or gameplay-tagged branches cannot become exempt by being parented under scenery.

## Safe scenery rules

- **Full asset clearance:** use separate occupied trunk/canopy/branch boxes, not only the tree's origin. The checker retains6.5-stud standing height,14.5-stud ordinary free-jump/headroom,4.5-stud travel strips, receiving-lip views and eight-stud follow-camera strips. Use actual source positions; no new course adjustments are authorized.
- **Original fall coverage:** BelowPlayableRoute is local X[-266,236],Z[-216,216],Y[-27,-23]. Inside that footprint, landform crests at or below-29.2 remain2.2 studs below the trigger bottom. Do not use the narrower side-wall footprint to approve a high hill. The proposed high outer hill AABBs use eight additional studs: west highX<-274, east lowX>244, north highZ<-224 or south lowZ>224. A high landform that overlaps the reset footprint needs measured occupied geometry proving its overlapping portion stays below-29.2.
- **No false recovery platforms:** all scenery parts remain anchored with collision/query/touch disabled; no MCWalkable/MoonlitHazard/Checkpoint/Travel/Pivot tags. Keep rural ground visibly separate from checkpoint/catch floors, leave the open fall spaces readable, and do not mount route arrows on landscape. Raised visual hills remain outside fall coverage and camera/movement reserves.
- **Trees and green canopy:** outer rural groves may rise above the low ground when their entire canopy clears route/camera/landing/mechanism volumes. The proposed court X[-58,104],Z[-10,62] stays deep and tree-free; only low greenery beneath the reset region. Actual imported canopy bounds and authored vertex receipts take precedence over a guessed tree height.
- **Grand keep:** the east crown approach portal remains local low(12,137,-68),high(43,168,-34). Retain CrownTerrace standing/jumping/camera space and its finish/emblem. The proposed north apse/pinnacle supports the skyline from behind the keep, with the central peak237.8 and bounded real masonry/tower bases. Attached buttresses must seat into visible masses and stay within the declared occupied geometry. Do not add collision or a traversable roof shortcut. Conservative occupied boxes can flag an empty arch opening; use separated real pieces or inspect the actual surfaces rather than discarding a finding.
- **Mechanisms:** both bays of both lifts retain full34-stud travel with18×49×16 deck/rail/body boxes and8×44×6.5 counterweight spaces. All three32° swing envelopes remain protected. Tree foliage and tower projections cannot cross those volumes or mask the next boarding/landing.

The source43 controller/ambience lifecycle remains unchanged. New tree colors and skyline placement still need actual day/night player-height views; a zero-box-conflict result is not readability or moving-camera proof.

## Replacement accounting

Source43 is already350 units/805 meshes/357,402 triangles. Do not append trees until a cap drops them, trim an arbitrary first N placements or silently omit planting. Retire named **Phase3World** units with recovery preserved and charge every retained/replacement unit in one combined ledger.

The tower author replaced49 old art units with12 new units. The landscape author retained seated bedrocks, actual gallery planting and four-light lantern groups while replacing63 old terrain/plant units with32 coherent rural units, then adding one connected island base whose highest point is-30.2. These substitutions free room for the requested result under the existing caps. New imported assets must carry measured parts/triangle receipts; provisional upper bounds are not final native costs. `resource-ledger.json` records the conservative proposal envelope; `combined-stage-check.json` records the newer actual staged totals. Neither is a device/FPS claim.

## Restore and close the focused checks

1. Preserve the lead's current native/source recovery and fresh schema2 before baseline. Keep Source43 history and any earlier failed comparison reports.
2. Replace only approved Phase3 art through the lead's guarded integration. Do not rebuild or retune accepted Phase2, alter Phase1, replace19 arrows, or change behavior sources.
3. Restore the saved `EditorState` camera, focus/FOV/type, editor lighting/sky/effects and every temporarily altered visibility value. Remove only temporary preview effects by their verified identity. Actual course-local night configuration stays attached to the new art pass and must restore when the Moonlit lifecycle exits.
4. Return to Edit/rest before native comparison. Compare current editable/stored courses, current Phase1, accepted kit and arrow templates against their **fresh current Source43** snapshots. Require zero protected changes and zero unresolved duplicate ambiguity, and run the38-entry source comparison.
5. Verify actual scenery collision/query/touch flags and native resource counts. Inspect the new tower, open crown approach, groves/ground, signs and mechanisms from relevant player-height/day/night and overview cameras. Recheck movement only if a specific new art finding creates a concrete regression concern; do not reopen accepted difficulty or launch a broad timing/gameplay campaign.

Outstanding external work is lead-owned native integration/comparison, actual day/night visibility and final independent judgments. This author supplies no final grade.
