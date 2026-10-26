# Stud Garden tools

Stud Garden was owner-approved and cleaned on 2026-10-06. Its active source now uses `src/ServerStorage/CourseBuilders/StudGarden`, with `Runtime.luau` as the course entry and `SprinklerRuntime.luau` for the sprinkler. See [the current editing guide](../../docs/STUD_GARDEN_EDITING.md).

Earlier build, import, gallery and study recipes here are historical authoring tools. Their source dependencies are preserved in [the cleanup archive](../../archives/stud-garden/cleanup-20261006/README.md). Restore the required dependencies in an isolated working copy before using them. Do not rerun an old builder over the approved native model.

The existing pure checks moved to [StudGardenHazardClock.luau](../../tests/StudGardenHazardClock.luau) and [StudGardenFruitMotion.luau](../../tests/StudGardenFruitMotion.luau). Cleanup/verification recipes in `cleanup` describe their original capture paths; adapt them to the current guide before a new scoped use. StartupQA must run as an ordinary temporary server Script during Play to read the game's initialized service instances.

[Current state and evidence](../../docs/artifacts/stud-garden-v2/CURRENT_STATE.md).
