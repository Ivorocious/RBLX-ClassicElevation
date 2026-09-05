# Classic Ascent v6 — grounded scenery and moving-log control

September 6, 2026. This pass follows the owner's v5 screenshots and moving-log bug report.

## Design changes

- Continuous deep cliff faces connect the ledges to the mountain. Small rock strata support stationary jump platforms; recovery-height gaps remain open. Bridges and moving logs stay suspended over their ravines.
- Soil banks support irregular forest clusters on both sides of the lower trail and river. Small plants within the trail use explicit soil pockets between the dirt paths; checkpoint cobblestone remains clear. Rocky sections have no trees.
- Removed floating rock shelves and oversized diagonal pillar assemblies. The causeway now passes through a rock-cut gallery connected to the mountain, with regular structural piers and smaller ruined remains off the playable path. The roof conceals falling-rock sources.
- Invisible, continuous walls keep racers inside the approximately 70-stud course corridor. The adjacent scenery and mountain are not alternate routes. Gaps inside the course still cause falls and checkpoint recovery.
- Two layers of distant ridges fill the horizon. River waterfalls and spray give the crossings a visible destination and drop. Alpine atmosphere settings strengthen distant haze while preserving nearby obstacle contrast.
- Reuses the existing approved Blender mesh kit (asset 89332142209949). No new external asset upload or Blender scene reset is needed.

## Moving-log fix

The server's per-frame character teleport competed with the player's locally simulated movement. The server now moves only the logs. River logs use unanchored, server-owned assemblies driven by LinearVelocity, with AlignOrientation holding their rotation and welded end caps. There is no character teleport or client carry script.

Logs anchor and hide before resetting to the start. Runtime constraints and welds are cleaned up when the course changes. Separate collision groups let logs pass the invisible boundary walls and mountain scenery while those surfaces still block avatars. No new remote or progression change is involved.

## Verification

- Rojo build and Studio source compilation passed.
- Installed course has 19 checkpoints, 340 boundary segments and 3,636 authored BaseParts. Both side-boundary rays hit at all 170 route samples.
- Visual review covered the forest, river, cliff jumps, gallery and summit. Inner rock forms were varied further after review; refuge footings were extended down into the cliff structure.
- Rojo synced the final native-log service and removed the experimental client carry script. Live logs were unanchored and moved at their configured velocity; player walking and jumping were possible.
- Idle rider carry is **not accepted as verified**: focused automated samples showed roughly 4.6 studs of rider-relative drift while the log travelled roughly 4.6 studs. Several temporary carry approaches were rejected. The owner should check standing, walking and jumping on the native logs before accepting this section. No full-course or 20-player test was performed.
- Client atmosphere activation was observed at Density 0.29.

## Source and recovery

Builder version 6 preserves an existing v6 authored model. Changes are durable in source; rebuilding uses the approved Blender mesh templates. The owner approved installation, and both previous copies are retained in ServerStorage.CourseBuildArchive as ClassicAscent_v5_Preview_1788639767 and ClassicAscent_v5_Authored_1788639767. No place was published.

For a quick manual check, start a Studio race and use the existing **Skip Checkpoint** control to reach the river. Stand still on a log, walk along it, jump to another log, and wait on a safe bank through one disappearance/reappearance cycle.

Atmosphere reference: [Roblox atmospheric effects](https://create.roblox.com/docs/environment/atmosphere).
