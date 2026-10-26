# Pre-phase review — 8 September 2026

**Follow-up:** The approved fixes and archive cleanup are now complete. See [implementation and verification](PRE_PHASE_CLEANUP_2026-09-08.md). This report preserves the original inspection findings and baseline measurements.

Fix the eight lobby tree trunks and reconcile the duplicated Classic Ascent course before expanding gameplay. The strongest startup-performance lead is the large historical archive still inside the working place. Export and verify backups before removing any of those saved models.

This was an inspection and one normal Play/Stop smoke test. No gameplay scripts, collision settings, geometry, archives, or publishing settings were changed. [Raw evidence](artifacts/pre-phase-review-2026-09-08.json).

## Confirmed findings

| Priority | Finding | Evidence and effect | Proposed action |
| --- | --- | --- | --- |
| High | Eight lobby tree trunks have no solid collision | All eight `Gardens_Tree_01`–`08` wood meshes have `CanCollide = false`; their only solid part is the 1.7–1.8-stud-high planter. All eight server collision rays pass through the trunk area above the planter. | Add a narrow, simple trunk collider inside each editable tree group, and include it in the durable builder/manifest. Verify walking, jumping onto the planter, and moving/scaling the tree. |
| High | Two enabled Classic Ascent models share the same name and course ID | Both `Course_ClassicAscentPointToPoint` models have 5,993 descendants, the same pivot and revision attributes, and zero differences across the checked instance/part/mesh properties. `CourseService` overwrites `discoveredCoursesById[courseId]` while adding both entries to its order list, with no duplicate warning. | Preserve a backup, retain one accepted authored course, and reject duplicate IDs during discovery so the ambiguity cannot silently return. |
| Medium | The working place contains a very large historical archive | `CourseBuildArchive` contains 520,196 descendants, about 90.4% of the 575,370-instance place hierarchy. Most are old rejected candidates and review copies. | Export historical versions outside the active place, verify the exports can be reopened, then remove only the approved archived copies from the working place and repeat startup timing. |
| Medium | Existing collision checks miss the tree defect | `BlenderLobbyEditing` only requires a tree to have some collider, which its planter satisfies. The older safety/traversal checks also use a fixed world origin; the current lobby has been repositioned. | Add trunk-specific checks and derive route coordinates from the current lobby or named components. Keep actual walking checks as well as static rays. |

### Collision cause and boundaries

`BlenderComparison.Install` deliberately makes imported visual meshes non-solid, then creates separate collision parts from the manifest. That is a reasonable approach for simple, predictable collision, but the tree generator only adds the planter collider. Its wood rods have no separate collision definition. Turning on collision for every decorative mesh would add unnecessary blocking to foliage and trim; a small trunk collider is the focused repair.

The eleven non-solid models named `*_Pier_*` are decorative hanging supports below the terraces. They are not the walkable structural columns, so their non-solid state is recorded as a design choice rather than a confirmed movement defect. Small lamps, vines and trim also remain decorative. The newer entrance and grand pillars have solid collision parts.

Relevant source: `assets/lobby_blender/build_lobby.py` (`tree`, `planter`, `pier`, `column`), `src/ServerStorage/CourseBuilders/LobbyBuilders/BlenderComparison.luau`, and `tests/studio/BlenderLobbyEditing.luau` / `BlenderLobbySafety.luau` / `BlenderLobbyTraversal.luau`.

## Why Play is slow

The measured warm `start_stop_play` call took **14.433 seconds** to acknowledge startup. Immediately afterwards, the client was loaded with a character/root, 2,449 Workspace descendants and zero pending content requests. This measurement includes tool overhead and is not an exact mouse-click-to-first-frame or cold-load benchmark.

The test server still contained about 520,000 objects in `CourseBuildArchive`; the client contained zero ServerStorage descendants. The archive therefore adds to the working place/server setup rather than directly sending all those old models to each player. Studio reported roughly 6,153 MB of memory in Edit and 6,439 MB during the client check; those Studio readings are not standalone player-memory figures.

| In-place historical container | Descendants |
| --- | ---: |
| `ServerStorage.CourseBuildArchive` | 520,196 |
| `ServerStorage.LobbyArchive` | 19,549 |
| `ServerStorage.CoursePreviews` | 5,404 |
| `ServerStorage.B09CrowdScale` | 5,480 |
| Combined | 550,629 |

These four historical groups contain about **95.7%** of the current place hierarchy. Inside the course archive, `RejectedV8_20260907` alone has 317,043 descendants, including 234,708 under `AscentCandidates`. These are counts, not a measured percentage of startup time.

The archive buildup is the leading explanation to test first. The current lobby builder returns the existing lobby immediately. The course builder returns the existing authored V7 rather than rebuilding it. No project-wide asset preloader was found, and the warm client had no pending content requests. Exact time saved by archive removal remains unmeasured until a reversible before/after test is performed. Studio plugins, cold downloads and other host work were not isolated.

Roblox documents [separate client/server Studio simulations](https://create.roblox.com/docs/studio/testing-modes), [ServerStorage as not replicated](https://create.roblox.com/docs/reference/engine/classes/ServerStorage), and [baseline load-time measurement](https://create.roblox.com/docs/performance-optimization/identify). These support the distinction between Studio setup costs and player download/render costs.

## Other checks

- All **48 repository Luau scripts** matched their Studio counterparts after line-ending normalization. No missing or changed counterpart was found.
- `ServerScriptService.FloatingIslandAnimation` exists only in Studio. It exits immediately because `Workspace.FloatingIsland` is absent. It is an obsolete cleanup candidate, not the observed startup bottleneck.
- No enabled `RunContext.Server` scripts were found inside `CourseBuildArchive`. No current `src` reference or external `ObjectValue` into that archive was found. Historical tools/docs still reference it for recovery, so exported backups and updated recovery paths are required before removal.
- The lobby has **1,145 parts, 549 meshes, 469 distinct mesh IDs, 486 solid parts and 16 seats**. All lobby parts are anchored. None of its solid MeshParts use expensive precise collision decomposition.
- All 549 lobby MeshParts use `RenderFidelity.Precise`. That is a later rendering optimization candidate to compare against `Automatic`; it is not yet a demonstrated frame-rate problem. The lobby has 29 enabled lights, all with light shadows disabled.
- The fresh Play console contained normal boot/lobby-preview messages and no errors. Automatic races are intentionally paused by `StudioLobbyPreview = true`.
- The inspected client requests use server-side race-state checks; the developer race command is Studio-gated. This was a focused code inspection, not a security audit or adversarial multiplayer test.
- Rojo **7.7.0 build passed**. Selene and StyLua were not available on PATH; no dependency installation or bulk formatting was attempted.
- Lobby descendant count **2,112**, pivot, and the approved softer lighting remained unchanged. Studio was returned to Edit.

## Cleanup order

1. Repair the eight trunks and add checks that fail when the trunk is pass-through. Keep colliders within the editable tree groups.
2. Back up the two same-ID Classic Ascent models, retain one accepted copy, and add a clear duplicate-ID failure to course discovery.
3. Save a complete recovery copy of the current Studio place. Export the historical course/lobby archives, previews and crowd fixtures to a separate local backup location; verify the exports, counts and restore procedure.
4. Remove only the approved historical copies from the working place. Keep current CourseLibrary, required mesh/import libraries and the owner's live lobby. Update the recovery documentation to point to external backups.
5. Repeat the same Play startup measurement, followed by a lobby walking pass and a real course load/reset check. Compare against this baseline before claiming a speed improvement.

Large archive removal needs explicit approval under `AGENTS.md` because it changes stored Studio models. No stored models have been removed in this review.

## Readiness limits

This review does not establish full-course traversal, river rider carry, 20-player traffic, real phone/touch/gamepad performance or a cold player join. Those remain prior open acceptance items. The attempted frame sample did not return from `RenderStepped` and was cancelled; there is no new FPS result. Existing historical visual scores and smoke tests do not cover these gaps.

The saved Studio place remains the source for manual geometry. A successful Rojo build covers the mapped scripts/configuration; it does not back up the owner's hand-edited map. Keep this boundary when performing cleanup.
