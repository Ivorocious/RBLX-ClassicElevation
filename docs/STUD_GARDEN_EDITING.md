# Stud Garden editing

Stud Garden follows the same course naming and runtime layout as the other maps.

## Current locations

| Location | Purpose |
| --- | --- |
| `ServerStorage > CourseLibrary > Course_StudGarden` | Approved native course to edit before Play |
| `Workspace > RaceCourse` | Temporary copy used during Play |
| `src/ServerStorage/CourseBuilders/StudGarden/Runtime.luau` | Starts and stops both course hazards |
| `src/ServerStorage/CourseBuilders/StudGarden/SprinklerRuntime.luau` | Sprinkler motion and contact checks |
| `src/ServerStorage/CourseBuilders/StudGarden/FruitRuntime.luau` | Fruit motion and contact checks |
| `src/ServerScriptService/Services/StudGardenService.luau` | Connects the course to the normal race services |
| `src/ReplicatedStorage/Config/StudGardenAmbienceConfig.luau` | Garden sky and lighting settings |
| `tests/StudGardenFruitMotion.luau` and `tests/StudGardenHazardClock.luau` | Focused existing logic checks |

The display name is **Stud Garden**. The existing course ID `stud_garden_v2` remains the stable identifier used by selection, timing, ambience and recorded history. Revision and provenance attributes remain on the native model; its public-selection Enabled setting remains false.

## Editing and playtesting

1. Stop Play and edit the native `Course_StudGarden` model. Keep scenery and course objects inside it.
2. Save a native Studio backup before geometry changes. Rojo saves scripts, not authored geometry.
3. Press Play and complete arrival, then choose **F6 → Stud Garden — start race** or **MAPS → Stud Garden**.
4. Check both timed hazards, warnings, recovery and nine ordered checkpoints. Changes to `RaceCourse` disappear when Play stops.
5. Stop Play before making lasting changes or saving the place.

[Sky and ambience](STUD_GARDEN_SKY.md) · [Developer controls](DEVELOPMENT_WORKFLOW.md) · [Naming alignment record](artifacts/stud-garden/alignment-20261014/REPORT.md).

## Tools and recovery

Run the focused checks from the repository root with the local Lune runtime:

```powershell
& './.tools/lune-0.10.5/lune.exe' run 'tests/StudGardenFruitMotion.luau'
& './.tools/lune-0.10.5/lune.exe' run 'tests/StudGardenHazardClock.luau'
```

Earlier versioned tools, assets and evidence remain at their recorded paths for recovery. Old builders require their archived dependencies and must run only in an isolated working copy. Use the current course and runtime paths above for new work. The three installed C01 optimizations remain in these renamed modules; optional C02 is still staged separately.
