# Fine-tuning Classic Ascent V7

**Retired September 22, 2026:** this map is no longer loaded in the active game. Restore it from the [offline native archive](../archive/retired-maps-2026-09-22/README.md) before following the historical editing notes below. Automatic generation is disabled in CourseConfig.

Edit **Workspace → Course_ClassicAscentPointToPoint** while Play is stopped. This is the working course. Press Play to test it, then Stop to continue editing. Save the Studio place to keep your geometry changes.

The restored baseline is `BuilderVersion = 7`, `AltitudeRevision = 2`, `RiverFinishRevision = 1`. It came from `CourseBuildArchive.ClassicAscent_V7_BeforeJourney_20260906`, the saved V7 immediately before the V8 rebuild. The archive is now preserved in the verified local `course-build-archive.rbxm` [backup package](../backups/pre-phase-cleanup-2026-09-08/README.md). One accepted authored course remains in CourseLibrary.

## Find what you want to change

| In the working course | What to edit |
| --- | --- |
| `Obstacles → 03_SwitchbackClimb → MainPath` | Middle-lane platforms in section 03. Every section has MainPath, ValleyPath and MountainPath. |
| `Obstacles → 05_PillarYard`, `06_BrokenCauseway`, `07_CliffsideTraverse`, `09_Skyline` | Other jump sections; choose a lane, then a platform. |
| `Hazards → 02_RiverRapids` | Whole moving-log groups and river hazards. |
| `Hazards → 05_PillarYard`, `06_BrokenCauseway`, `07_CliffsideTraverse`, `08_SummitSteps`, `10_SummitRun` | Lava, falling rocks, boulders, snowballs and avalanches. |
| `Decoration → Environment` | Trees and the large mountain scenery. |
| `Decoration → CliffsAndValley` | Cliff faces, scenery rocks and distant landscape. |
| `Decoration → RouteStructures` | Bridge boards, ropes, cover and nearby props. |
| `Checkpoints` | The 19 shared rest/checkpoint platforms. |
| `RouteMarkers` | Signs, checkpoint markers and finish decoration. |
| `Bounds`, `FallZones` | Invisible boundaries and fall recovery. These affect where players can go. |

Select a platform or model in Explorer and press **F** to bring it into view. A platform's `SectionStep` attribute gives its position within that section; `Route_039` is a permanent identifier, not step 39 of section 03.

## Adjust a jump

1. Stop Play, open the section and lane, and select the platform.
2. Use Studio's Move, Rotate or Scale tool. Start with a small change, such as 0.5 studs.
3. Press Play and use the existing **Skip checkpoint** control to reach the section.
4. Test the approach and landing, then Stop before making the next edit.

In sections 02 and 04, some route parts are invisible layout markers. Edit the visible river logs or bridge boards instead. Nearby scenery, cover and checkpoint signs are separate objects: moving a platform does not automatically redesign its surroundings.

## Adjust a hazard

Select the **whole hazard model** in its section folder when moving or rotating it. Its warning and visible parts move together. For moving logs, lava spurts, boulders and snowballs, the saved travel path follows the model when Play starts. Keep `MotionAuthoringPivot` unchanged; it records where that path was originally authored.

To change timing, expand the model, select the moving part, and edit its existing Attributes in Properties:

| Attribute | Meaning |
| --- | --- |
| `MotionDuration` | Seconds to travel; a larger positive number means slower movement. |
| `PauseDuration` | Seconds between cycles for hazards that use a fixed pause. |
| `PauseMin`, `PauseMax` | Minimum and maximum pause for hazards with varied timing. Keep Min no greater than Max. |
| `WarningDuration` | Seconds of warning before a moving hazard launches. |
| `CycleOffset` | Delay before its first cycle; separates neighboring hazards. |
| `CrumbleDelay`, `CrumbleResetTime` | Bridge-board warning and reset timing, on the board itself. |

Use positive travel times and nonnegative pauses. Moving one child part or scaling a whole hazard does not resize its travel path. For path-length changes, `MotionStart` and `MotionEnd` are still advanced controls using world positions and rotations.

## What Play and saving do

- At startup, the server places its copy of the visible editing course into CourseLibrary. The race then loads `Workspace.RaceCourse` from that copy.
- The editing copy is hidden during Play, so it does not overlap the race. Stop returns you to the original editing scene.
- The builder returns an existing V7 unchanged. It does not rerun scenery, gap or altitude passes over your edits.
- Changes made during Play disappear when you stop. Make lasting edits while stopped.
- While an editing course exists in Workspace, that is the source used by Play. The Edit-mode CourseLibrary copy is a backup, not a second working copy.
- Save the Studio place for geometry. Rojo/Git preserve scripts; a Rojo build does not capture your hand-edited map. Nothing was published by this restoration.

## Cleanup and verification

Rejected Studio candidates, temporary mesh libraries and the loose V8 lava piece are preserved under `CourseBuildArchive.RejectedV8_20260907` inside the local `course-build-archive.rbxm` backup. That historical container was removed from the working place after native export and restore verification. Archived scripts and V8-specific test fixtures remain in `archive/classic-ascent-v8-2026-09-07`, outside the active Rojo tree. Existing asset source files and historical reports are retained.

The organizing pass preserves the restored V7's 4,732 BaseParts and 19 checkpoints. Automated restoration and editing checks are in `tests/studio/ClassicAscentEditing.luau`; current results are recorded in [playtest notes](PLAYTEST_NOTES.md). This restores V7 and improves editing; it does not certify a full manual traversal or multiplayer performance.
