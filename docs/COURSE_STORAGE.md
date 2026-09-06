# Course storage

Updated September 6, 2026 after the pre-tuning cleanup.

## Active library

`ServerStorage.CourseLibrary` contains only these three maps:

- `Course_ClassicAscentPointToPoint`: accepted design, builder 7 / altitude revision 2, 19 checkpoints.
- `Course_ClassicPointToPoint`: existing MVP course, six checkpoints.
- `Course_ClassicCircuit`: existing lap-testing course, four checkpoints.

The configured selection remains `classic_ascent_point_to_point`. Startup leaves the course unloaded; round selection creates the runtime `Workspace.RaceCourse` copy.

## Authoring and recovery

- Reusable template: `ServerStorage.CourseTemplates.CourseTemplate`.
- Hidden Ascent preview: `ServerStorage.CoursePreviews.ClassicAscent_ManualPreview_1788647832`.
- Existing build backups: `ServerStorage.CourseBuildArchive`.
- Latest cleanup batch: `ServerStorage.CourseBuildArchive.Cleanup_1788676882`.

The cleanup batch contains four disabled old Ascent versions in `LegacyLibrary`, six temporary review objects/folders in `ReviewArtifacts`, and 17 duplicate modules in `DuplicateModules`. Duplicate sources were checked for exact equality before one copy of each was retained in its normal location. No accepted map geometry was edited or deleted.

The v5/v7 mesh libraries and original import models remain at their existing ServerStorage paths because `AscentProps` uses those paths. Unfinished oak/pillar work and unrelated repository changes were left intact.

Thirty remaining source containers compiled in Studio. Course discovery returned three unique enabled map IDs, accepted Ascent validation returned no warnings, all 19 checkpoints remained, and Workspace had no loaded RaceCourse. These were focused Edit-mode checks, not a full race test.

These hierarchy changes live in the Studio place; Git records this inventory, not the model geometry. Save the place in Studio to persist the cleanup. Restoring an archived old map should be deliberate: placing disabled revisions or duplicate CourseIds back in CourseLibrary can confuse discovery.

For fine-tuning, stop Play, back up the authored map, move it into Workspace to edit, and return it to CourseLibrary before starting Play. Keep its name and version/revision attributes. Save the place after editing.
