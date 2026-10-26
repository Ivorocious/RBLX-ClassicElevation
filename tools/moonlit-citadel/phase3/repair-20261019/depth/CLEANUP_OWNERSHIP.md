This is an inventory filter for the lead's proposed native moves. It does not authorize deleting anything.

- Active course roots remain `Workspace/Course_MoonlitCitadel`, runtime `Workspace/RaceCourse` when present, and `ServerStorage/CourseLibrary/Course_MoonlitCitadel`.
- Current course construction uses `CourseBuilders/MoonlitCitadelCourse`, the BL02 MeshKit/library, and the RW01, AR01, TL01, ER01 and DT02 asset libraries. Keep all of them. The proposed DP01 library must also remain active after verified integration.
- The three legacy Workspace roots named in `MoonlitCitadelAmbienceConfig.HideWorkspaceRoots` are distinct prototypes: `MoonlitCitadelPhase1_C01`, `MoonlitCitadelPhase1_BL01`, and `MoonlitCitadelPhase1_BL02`. The lead's fresh inventory places them away from the current course. They are candidates for reversible archival only after exact identity, ownership and references are checked.
- Before moving a candidate root, bind its full native serialization, all descendant/property counts and hash to the fresh recovery. Check native ObjectValue references and source string/path references, including saved configuration. Record the original parent and name. Moving a parent must preserve descendants, attributes, tags, pivots and child sources exactly.
- Never classify an object from a generic name such as `Recovery`, `Preview`, `Library`, or `Temporary` alone. Preserve all recovery/archival folders, import libraries, source modules, map cache/library entries, other courses and published state.
- A move is accepted only after a fresh paired export reopens and proves the moved branch unchanged and every unrelated protected root unchanged. Do not infer native safety from filesystem Git status.

References read: `phase3/PreserveOwner.luau`, `phase3/enclosure-repair-20261013/PreserveFinal49.luau`, and the Source54 saved reopening/snapshot checks. They serialize paired models and source and restore HTTP state; these exports are not a whole-place Save.
