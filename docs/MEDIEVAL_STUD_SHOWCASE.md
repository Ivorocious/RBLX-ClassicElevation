# Medieval stud showcase

Recreated the user's reference image as 20 separate Blender-authored prop groups.
The current Studio model is `Workspace.MedievalStudShowcase_M02`, with its origin
at `(2300, 600, -1200)`. Roblox asset: `128735338032773`.

The collection includes the drawer/candle cabinet, crown banner, brewer's barrel,
archery target, shield rack, quest board, roofed well and lantern, tavern table,
candle pedestal, alchemy bench, stone gate, broken wall, catapult, sword rack,
two chests, bundled timber, hay bales, anvil and brazier. These are visual props;
doors, weapons, fire, catapult and storage do not have gameplay behavior.

## Style and source

All visible prop geometry comes from Blender. Repeated shallow square studs,
stepped silhouettes, layered planks, pixel emblems, masonry blocks and blue-gray
metal define the style. The ground uses native Roblox Plastic with Studs.
This is a reconstruction from one screenshot, not the original asset pack;
hidden surfaces and exact dimensions were inferred.

- `assets/medieval_stud_showcase/build_showcase.py`: deterministic generator.
- `MedievalStudShowcase_M02.blend`: editable source and preview scene.
- `MedievalStudShowcase_M02.fbx`: uploaded prop geometry only.
- `manifest_M02.json`: palette, prop placements, collision recipes and mesh counts.
- `assemble_showcase.luau`: construction function accepting manifest, asset ID
  and origin; corrects FBX import scale/orientation and assembles the groups.
- `M02_studio_overview.png`, `M02_studio_well.png`: actual Studio screenshots.
- `M02_overview.png`, `M02_craft.png`, `M02_well.png`: Blender renders.

M01 is retained as a local first draft. M02 tightens spacing, shortens the banner,
enlarges the barrel and adds cabinet/roof relief. No other project content was
replaced. The owner's live ground resize to 76 by 38 studs, offset `(2,-0.5,1)`
from the showcase origin, is preserved in the assembly source.

## Reuse

Clone the entire named model under `Props`, then move or rotate it. Its invisible
collision shapes move with the visible meshes. Each material is a separate mesh,
so colors remain editable in Studio. Avoid stretching finished props if their
detail scale must stay consistent. Use the Blender generator for shape changes.

To recreate the showcase, load asset `128735338032773` into ServerStorage named
`MedievalStudShowcase_M02`. Invoke the function in `assemble_showcase.luau` with
the decoded manifest, that asset ID as a string, and the origin above. It refuses
to replace an existing showcase. The recorded upload receipt is
`.tools/uploads/medieval-stud-showcase-m02.json`; do not submit a duplicate upload.

## Verification

- Blender exported 20 props, 190 meshes and 47,876 triangles. All mesh faces have
  positive area; every individual mesh is below 20,000 triangles.
- Roblox upload completed and the asset loaded through InsertService.
- All 190 mesh assets reported successful loading before the final screenshots.
- All visible meshes are anchored, with collision, touch and query disabled.
- 24 simple collision shapes are anchored and collidable; zero scripts imported.
- Inspected the full Studio display and a well/stonework close-up against the
  supplied reference. The current project lighting gives the stone a cooler cast.
- The preview is an unsaved Studio edit. Local source, exported geometry and
  assembly instructions preserve it independently. No place publication occurred.

No avatar traversal or device-performance claim is made. Broad prop collision is
for display placement; collision should be fitted to each future gameplay use.
