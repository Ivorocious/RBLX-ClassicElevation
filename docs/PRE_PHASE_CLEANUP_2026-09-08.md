# Pre-phase cleanup — 8 September 2026

Completed the approved repairs and archive cleanup from the [pre-phase review](PRE_PHASE_REVIEW_2026-09-08.md). The eight lobby trees now have trunk collision, the course library contains one accepted Classic Ascent, and verified historical models have been removed from the working place.

## Changes

- Added one narrow, invisible, locked collider to each editable tree group. The builder, Blender generator and B10 manifests include them; existing-lobby startup repairs missing colliders without rebuilding the lobby. Moving or scaling the complete tree includes its collider. All 1,145 existing lobby parts retained their checked geometry, color, material and collision properties; eight parts were added. The owner's lobby pivot remains `(1552, 388, -847)`.
- Compared the two authored Classic Ascent copies again immediately before deletion; both had 5,993 descendants and identical checked fingerprints. Kept one. Course discovery now warns and excludes an ambiguous ID entirely, including when three copies share it. Other unique courses remain available.
- Removed the four approved historical containers and the duplicate course: **556,627 instances including their roots**. The accepted course retains all 5,993 descendants. Other asset libraries remain in place.
- Updated older lobby safety/traversal helpers to use the current lobby pivot instead of the original fixed location.

Six native model backups were exported and verified before deletion. Two additional native backups preserve the final lobby and course library. See [recovery instructions](../backups/pre-phase-cleanup-2026-09-08/README.md). These local files are excluded from Git and must be retained separately; this package is not a complete place backup.

## Verification

| Check | Result |
| --- | --- |
| Trunk collision rays | 16/16 passed above planter height |
| R15 movement against trunk copies | 16/16 approached and stopped at solid trunks from grounded starts |
| Tree move, rotation and scale | 8/8 passed on isolated copies |
| Existing lobby barriers and seats | 15/15 barrier rays and 16/16 seat checks passed |
| Lower-lobby walking routes | 5/5 passed, all grounded at the start |
| Duplicate discovery | Actual duplicate rejected before removal; separate three-copy regression passed |
| Course lifecycle | Three courses discovered; accepted course cloned with 19 checkpoints, unloaded twice safely, authored course preserved |
| Final Studio state | Edit mode; eight solid trunks; one accepted course; archives and owned test fixtures absent; HttpEnabled restored to false |
| Repository | Rojo 7.7 build and git diff --check passed |

The warm Play command acknowledgement decreased from **14.433 seconds to 4.644 seconds**, about **68% faster**, after cleanup. Each condition has one sample including tool overhead. This supports the archive-related startup finding; it is not a cold-load, live-player, FPS or multiplayer benchmark. The client was loaded with a character and zero pending content requests after startup.

The trunk movement test used isolated tree copies with a floor at planter-top height. A human jump onto each actual planter remains a useful final feel check; it was not established by those collision tests. Full-course traversal, touch controls and multiplayer performance were outside this cleanup.

Evidence: [tree repair](artifacts/cleanup-tree-repair.json), [static tree checks](artifacts/cleanup-tree-static.json), [tree movement](artifacts/cleanup-tree-movement.json), [barriers/seats](artifacts/cleanup-lobby-safety.json), [walking routes](artifacts/cleanup-lobby-traversal.json), [duplicate discovery](artifacts/cleanup-course-discovery.json), [course lifecycle](artifacts/cleanup-course-lifecycle.json), [removal](artifacts/cleanup-removal.json), [startup](artifacts/cleanup-startup.json), [final state](artifacts/cleanup-final-state.json).

Save the Studio place to persist the in-place geometry and archive removal. The finished model backups already preserve the repaired lobby and accepted course locally. Nothing was published.
