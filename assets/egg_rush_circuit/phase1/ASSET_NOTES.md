# Egg Rush Phase 1 reusable kit

October 21, 2026. Recipe `ER_P1_KIT_C03`; current output **candidate_c04**. This is an offline asset candidate, not a course acceptance or native gameplay result. The selected Phase 1 B02, C03, D02 and E03 PNGs and ER-B15 brief supplied shape, material and role references. Their illustrated spacing was not used as measured gameplay geometry.

## Files and use

- `build_kit.py`: saved Blender 5.2.1 builder; no add-ons or external textures.
- `candidate_c04/ER_phase1_kit.blend`: editable source parts plus the inspected labeled overview.
- `candidate_c04/ER_kit_sheet.png`: offline overview, visibly square stepped eggs, thick shell forms, broad nest bands, simple machinery and separated chicken/tail.
- `candidate_c04/ER_Eggs.fbx`, `ER_Shells.fbx`, `ER_Machinery.fbx`, `ER_Workshop.fbx`, `ER_Guardian.fbx`: five independently selectable semantic upload packages.
- `candidate_c04/manifest.json`: exact bounds, material roles, part names, atlas offsets, contact suggestions, file hashes, recipe hash and roundtrip results.

Run from the repository root with the installed Blender executable, choosing a fresh output path:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/egg_rush_circuit/phase1/build_kit.py -- --out assets/egg_rush_circuit/phase1/candidate_next --render
```

`--only Shells` rebuilds one family; the other valid names are Eggs, Machinery, Workshop and Guardian. Omit `--render` for exports without the overview. The builder refuses to overwrite an output directory with a completed manifest. Failed/earlier `candidate_c01`–`candidate_c03` outputs are retained for recovery and excluded from the current handoff. C01 failed during preview setup; C02's preview was too bright; C03 preceded the export roundtrip check.

Useful dimensions are ordinary Python parameters: `egg(width,height,patch)`, `shell(width,depth,height,hollow,hinge)` and `nest(diameter)`. Change explicit machinery values for a measured fit; do not distort several axes to fake route difficulty. The whole-egg profile is shared by all sizes, with one square cap, broad stepped shoulders, square middle and inward stepped base. Egg boundary faces have no buried stacked-box interior faces. Color patches are broad regions of the same surface, without raised stickers or noisy texture.

## Import and assembly

Use the existing `docs/BLENDER_ROBLOX_UPLOAD.md` uploader and verified destination only when the lead performs the authorized upload. This builder never uploads, inserts, saves a Studio place or publishes.

Units follow the existing Moonlit export pattern: **one Blender unit is one intended stud**, `axis_forward=-Z`, `axis_up=Y`, `FBX_SCALE_UNITS`. Convert coordinates by **Roblox XYZ = Blender X, Z, -Y**. Import scale still needs checking in Studio.

Each asset is split into one mesh per material role, named `ER_<Asset>__<Role>`, with vertices already in that asset's local coordinates and a common origin. There are no texture files. Each FBX is a spaced atlas: remove its manifest `packageOffsetRoblox` when reconstructing a local asset. Preserve the imported relative placement of all parts within one asset; do not center each colored part independently. Set the assembled model pivot explicitly from the manifest; an importer's automatic bounding-box pivot is insufficient for a hinge or tail.

The saved blend keeps editable originals in `AUTHOR_<Asset>` collections, hidden from the viewport/render to avoid overlapping previews. Unhide one collection's objects for local editing. Visible overview copies share their mesh data. Export generation uses originals only.

## Dimensions and contacts

Sizes below are rounded **Roblox width × height × depth**, in studs. Exact bounds, including small patch thickness and supports, are in the manifest.

| Asset | Size | Assembly guidance |
| --- | --- | --- |
| EggCoral, EggMint, EggLilac | 6 × 8 × 6 | Bottom-center pivot; uniformly scale for central or roller use. |
| EggDisplay | 2.25 × 3 × 2.25 | Same square-stepped profile. |
| ShellPad | 8.035 × 2.4 × 6 | Flat cream top; suggested separate native contact 7.6 × .6 × 5.6. |
| ShellBowl | 12.035 × 4 × 10 | Open interior, one-stud rim and 1.1-stud floor; never use a full bounding-box collider. |
| ShellLeaf | 10.035 × 3.2 × 8 | **Pivot Blender0,0,0; topZ0; leaf spans Y0..8. Roblox topY0 and Z-8..0.** Rotate localX; native contact center0,-.3,-4 and size9.6,.6,7.8. |
| NestRing | 14.3 × 2 × 14 | Open two-band ring with six bindings; separate floor if required. |
| SlidingTray | 10 × 3.55 × 8.2 | Deck topBlenderZ.9; travel localY (Roblox-Z); rail and tray are separate assets. |
| RailPair | 10 × 1.3 × 22 | Rail topBlenderZ.9; keep exposed rails noncollidable. |
| EggChute | 10.5 × 10.576 × 17.2 | Feed centerBlenderY0,Z8; outletY16,Z.6; controlled hazard trajectory remains separate. |
| PipeStraight | 2.8 × 2.8 × 10 | Hollow 12-sided mint pipe. |
| PipeElbow | 2.8 × 6.9 × 7.4 | Hollow bent pipe; .28-stud wall. |
| ShellHinge | 11.6 × 2.1 × 2.1 | AxleBlenderZ1, orientedX; mate leaf pivot to axle center. |
| WarningBeacon | 1.4 × 1.85 × 1.4 | Amber visual housing; runtime owns warning state, light and sound. |
| WorkshopBay | 16 × 10.6 × 2.8 | Faces Blender-Y (Roblox+Z); two cream window bays and coral cornice. |
| NurseryArch | 11.1 × 8.4 × 2.4 | Simple mint arch; opening about8.1 wide ×6.2 high. |
| SortingShed | 12 × 9.2 × 9 | Four honey supports, simple coral stepped roof. |
| GuardianBody | 9.96 × 11.65 × 12.8 | Faces Blender-Y; feet at bottom0; socketBlender0,4.8,4.5 = Roblox0,4.5,-4.8. |
| GuardianTail | 6.5 × 7.4 × 5.6 | Root origin0, extends Blender+Y. Mate root to body socket; rotate localBlenderZ / RobloxY. |

For example ShellLeaf is the third Shells atlas item, offsetBlender56,0,0 = Roblox56,0,0. GuardianTail is the second Guardian item, offsetBlender28,0,0. All exact atlas offsets are listed per asset.

All exported meshes are visual parts. Disable collision, touch and query as appropriate on art, then supply intentional native contact shapes. The manifest's suggested contact centers and sizes already use local Roblox XYZ; apply the same animated transform as the art. The guardian's tail is deliberately separate, but its full sweep volume and safe waits are runtime/Studio checks. No mechanism timing or gameplay script is included here.

## Checks and limits

Current candidate built with exit code0 in Blender5.2.1: **20 assets,46 material parts,5,056 triangles across the entire unique kit**, about10.7 seconds including a24-sample1800×1500 overview. All five FBXs were reimported into the isolated process: exact part counts, one material slot per part and bounds within0.000003 studs passed. Every exported polygon has positive area and finite coordinates. Manifest hashes bind the actual outputs and builder. The inspected overview exposed and corrected an elbow frame twist and initial bright render.

Part-level `nonManifoldEdges` counts in the manifest include expected open material seams: a cream surface and its color patch export as separate meshes. They are not a whole-asset hole count. Intentional intersecting chicken/machinery blocks remain simple separate forms; no universal watertight-solid claim is made. The bowl and tubes have visible interiors and explicit wall thickness. Studs are intentionally left to deliberate native contact surfaces rather than modeled over every decorative face.

Blender printed a failed optional OS thumbnail write outside the workspace, while the requested `.blend` and PNG saved successfully; those files were opened/inspected. No live Blender scene was reset. This is local authoring and FBX roundtrip evidence only. Roblox material appearance, imported color/scale, native face coverage, hinge joins, moving contact, crowd clearance and device performance remain unverified. A complete Shellworks scene must still combine the branch, moving shells, compact waits/recovery, ordinary short jumps and nearby buildings under the lead's control.
