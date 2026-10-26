# Classic Stud Style Kit V1

Five reusable Blender pieces are installed in the current Studio edit session at
`Workspace.ClassicStudKitPreview_V1`, origin `(1770, 355, -845)`. They are separate
from the lobby and course. Roblox asset: `91963888161700`. No place publication.

The kit is a starting style reference, not a pixel-perfect reconstruction of a
particular historical Roblox version or an approved whole-course art direction.

## Fixed style rules

- Square caps: 0.65 studs wide, 0.12 high, with a small tapered top edge.
- Centers are one stud apart. Flat rectangular faces start half a stud from each
  edge. Wedge rows retain one-stud spacing measured along the slope, centered on it.
- One Blender unit is one Roblox stud. Keep the pattern size fixed when building
  larger surfaces: regenerate or tile pieces instead of stretching entire meshes.
- Use restrained solid colors and smooth plastic for visible geometry.
- Studs face outward. Walls use their front face; stairs use treads; wedges follow
  the slope. Undersides and plain sides stay smooth.
- Each piece is one visible mesh with collision disabled. Simple invisible shapes
  provide the walkable surface; decorative studs do not catch feet.

| Piece | Body dimensions (width × depth × height) | Studs | Triangles | Collision shapes |
| --- | --- | ---: | ---: | ---: |
| Floor | 8 × 8 × 1 | 64 | 1,164 | 1 |
| Wall | 8 × 1 × 6 | 48 | 876 | 1 |
| Wedge | 8 × 8 × 4 | 64 | 1,160 | 1 |
| Stair | 8 × 8 × 4 | 64 | 1,200 | 4 |
| Corner | 8 × 8 × 1, L-shaped | 39 | 726 | 2 |

Total: five visual meshes, 279 studs, 5,126 triangles, nine collision shapes.
Repeat geometry selectively; this sample does not establish a whole-map budget.

## Files and reuse

- `assets/classic_stud_kit/ClassicStudKit_V1.blend`: editable objects, materials,
  two comparison panels, camera and lights.
- `ClassicStudKit_V1.fbx`: the five geometry pieces only.
- `build_kit.py`: rebuilds assets in a fresh Blender scene; does not alter the
  interactive Blender scene. Output paths resolve relative to the script.
- `manifest.json`: dimensions, placements, colors, counts and collision recipes.
- `install_preview.luau`: durable Studio assembly instructions. Checks place and
  imported names, corrects the importer’s 100× scale and orientation, and creates
  separate models containing each visual mesh and its collision shapes.
- `stud_shaded_color.png`, `stud_normal_opengl.png`: repeatable comparison tiles.
  Their Blender panels are in the `.blend` file; they are not uploaded or wired
  into Roblox. Normal maps need explicit SurfaceAppearance setup and UV handling.
- `docs/artifacts/classic-stud-kit/style-plan.drawio`: editable schematic plan.

For reuse in this Studio session, clone an entire named piece model, then move or
rotate the model so its collision moves with its visual mesh. Do not clone just
`Visual`. Do not stretch a finished mesh if the studs need to retain their scale.

Rebuild locally:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python assets/classic_stud_kit/build_kit.py
```

To recreate the preview later, import the existing asset into ServerStorage as
`ClassicStudKit_V1`, then execute `install_preview.luau` in Edit mode. It refuses
to replace an existing preview. Upload receipts are under `.tools/uploads`;
reusing the completed receipt prevents a duplicate upload.

## Verification on 2026-09-08

- Blender generation and FBX export completed. Reviewed overview, close-up and
  material-comparison renders. Mesh face areas and triangle limits passed.
- Assets API upload completed. Studio's metadata-based insertion returned 404;
  the same asset loaded successfully through `InsertService:LoadAsset`.
- Inspected all five imported MeshParts, their names, scale and orientation.
  Visuals are anchored and have collision, touch and query disabled.
- Eleven downward ray checks passed: floor, all four stair treads, three wedge
  heights, both corner arms and the open corner cutout.
- Inspected Studio overview and a near-player-height view. Native Roblox studs
  were visible on `Plastic`; the earlier `SmoothPlastic` reference appeared flat.
- Existing lobby/course content was not edited. Preview is in the current edit
  session; it is not a saved/published place change. The FBX and assembly script
  preserve the work independently of that session.

No avatar traversal, phone/touch, multiplayer or large-scene performance testing
was performed. Color-texture and normal-map comparisons were inspected in Blender
only. Before broad course use, check avatar movement and the intended target device.

For future Astra work: reuse this generator and explicit measurements, inspect the
exported result in Studio, and compare against the included native reference.
Do not ask the model to reinvent the stud shape from prose for every asset.
