# Keycap Archive backdrop

`ArchiveBackdrop.Build(course: Model, origin: Vector3, template: MeshPart): Model` creates and returns `course.MapEnvironment.ArchiveBackdrop`. Call after the existing M02 environment and artwork. Calling it again returns the existing backdrop without rebuilding or deleting anything.

The four shelving runs use sixteen tall bays, with eighty shelf tiers in total. They contain sparse cap trays, visible cross-stem switches, and closed storage cases in cream, mint, blush and cobalt. The room has dark teal/slate walls and structure, an overhead roof, a distant lower floor, eight warm shelf strips and four warm pendant lenses. The twelve emissive pieces use geometry only; there are no Light instances, GUI labels, timers or connections.

All positions are relative to the supplied course origin. At the current owner origin `(2222, 330, -1158)`:

- Shelves center at local `z = -351 / 351` and `x = -361 / 361`. Their closest faces are about local `|z| = 330` and `|x| = 340`.
- Four bays on each wall use local cross-wall centers `-246, -82, 82, 246`. Each bay is 148 studs wide and about 42 studs deep; posts extend from local `y = -140` to `130`.
- The room bounds are local `(-408, -148, -398)` to `(408, 142, 398)`.
- `ArchiveBackdrop.Floor` is centered at local `y = -144`; its top is `-140`. Both the floor and backdrop expose `ArchiveFloorY = -140` for the effects helper.
- The roof center is local `y = 138`, with its bottom at `134`. The lowest overhead light lens is above local `y = 116`.
- The explicit central clear volume is local `(-320, -125, -320)` to `(320, 104, 320)`. No backdrop part intersects it. The final integrated moving-volume and warning tests remain the lead's responsibility.

Shelf caps deliberately represent enlarged stored inventory: `9.6 × 3.4 × 9.6`, using clones of the supplied K02 mesh. They are inert archive scenery. The playable course's ordinary caps, districts, landmarks, route, jump gaps, checkpoints and warning poses are untouched. The appearance reference shows an oversized parts archive; the image is not used as a cubemap or a rendered wall texture.

The module sets every added part anchored, noncolliding, nontouching, nonquerying, with `Pressable = false`, `KCPress = false`, `MapArtwork = true` and `CastShadow = false`. Existing template SurfaceGuis, if supplied, are disabled on inventory clones. It creates no new SurfaceGuis. Lighting activation/restoration and the restrained low depth layer are handled by the separate effects/session integration.

## Focused checks

The installed Lune 0.10.5 runtime compiled the module, built it from the accepted C08 K02 template at the owner origin, and checked the central clear volume, physical flags and repeated-call behavior. Results:

| Resource or check | Result |
| --- | --- |
| Added parts | 947, below the hard 1,000-part limit |
| Reused inventory mesh caps | 128 |
| Shelf bays / tiers | 16 / 80 |
| Emissive geometry pieces | 12 |
| Light instances | 0 |
| SurfaceGuis with the clean K02 template | 0 |
| Colliders / query parts / touch parts | 0 / 0 / 0 |
| Shadow-casting parts | 0 |
| Central clear-volume overlaps | 0 |
| Second Build call | Returns the same model |

The initial checker attempted to read `MeshId`, which Lune does not expose for this deserialized template, and failed only at that checker read after a successful build. The corrected check retained all resource, clearance, flag and idempotence assertions. Mesh identity still needs the normal native candidate comparison; the implementation clones the supplied mesh without changing its asset properties.

This is offline geometry/resource evidence. Player-height appearance under the final profile, complete moving clearances, owner warning poses, F6 entry/restart/Lobby restoration, native rebuild/reopen and final whole-candidate reviews are integration checks; this helper did not use Studio, computer input, focus or camera control. Resource counts do not establish FPS or device performance.
