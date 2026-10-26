# Blender builds for courses and features

October 20, 2026. Standing build guidance for Course Creator and applicable 3D feature work. Blender is the main authoring tool for custom visible course assets and meaningful geometry. Suitable existing/inspected Toolbox assets remain useful; native Studio handles assembly, rough studies, intentional contacts and gameplay, with other visible construction chosen for a clear benefit. This adds no phase, team or approval stop.

## Choose the execution method

For substantial or repeated Blender construction, prefer a saved Python builder run by the installed Blender executable in a separate process. Use background mode when the work does not need a visible editor. Keep MCP for inspecting the open scene, screenshots and small adjustments where live context is useful. A saved script can also run through MCP when that is the practical choice; retain its durable source and inspect the result.

Both routes use Blender's Python interface. Switching routes alone does not improve geometry, art quality or game performance. Python can use meshes, curves, modifiers, materials and node setups where useful; do not restrict a design to stacked primitives just because it is scripted. Choose the simplest implementation that achieves the reference and remains editable.

| Potential gain | Working rule |
| --- | --- |
| Less repeated work | Expose the few useful dimensions, palette/layout inputs and a fixed random seed where randomness is used. Reuse small existing helpers and stable asset names. |
| Smaller corrections | Rebuild the affected asset or section and its actual dependencies. Separate geometry generation, preview rendering and export where that avoids repeating expensive work. |
| Fewer interruptions to live work | Use an isolated process and candidate output paths for long builds, renders and exports. Leave the owner's open scene intact. |
| More useful visual iteration | Render a few relevant, consistent views; compare a bounded number of variants only when a real design choice remains. Inspect them before expanding the kit. |
| Clearer failure and recovery | Keep source, inputs, outputs and compact logs together. Detect failed scripts and check output contents before uploading or assembling them. |

These are expected workflow benefits, not measured speedups or visual scores. Several project builders already use this approach; apply it consistently where it saves work rather than rewriting accepted assets merely to follow a new pattern.

## Build and revise

1. **Inspect the current source and preserve edits.** Identify the accepted Blender/native source, active candidate and live owner changes. A separate Blender process cannot see unsaved edits in another instance. Use an authorized working copy or record the relevant edits before rebuilding. Write a new candidate first; compare it with the accepted version before replacing any affected content. Keep manual overrides distinct from generated defaults. Never replay an old whole-map installer over newer edits.
2. **Make a small repeatable builder.** Keep the recipe beside the existing asset sources. State required Blender version/add-ons and important settings in the existing manifest or handoff. Use explicit units, axes, pivots, materials and asset names. Prefer direct data access (`bpy.data`) or mesh editing (`bmesh`) for bulk work when it avoids dependence on selection and the active editor. Use Blender operations (`bpy.ops`) when appropriate, with their required context; some editor-dependent operations need a visible session. Do not add a general build framework or convert working scripts without a current benefit.
3. **Run with useful failure handling.** Launch the Blender executable, not ordinary system Python. Use `--background` where suitable and put `--python-exit-code 1` before `--python` so uncaught script errors produce a failing process status. For a fresh scene, `--factory-startup` avoids inheriting an unrelated startup scene; load required saved input before the builder. Preserve required dependencies and never reset the live editor. For long jobs, poll that same process and read new log output instead of starting another copy. A timeout is not proof that the earlier operation stopped: inspect its process/output or live scene before retrying. Existing permission boundaries apply to every route.
4. **Check the candidate before expensive work.** Use focused checks for expected objects, usable dimensions, finite/nondegenerate geometry, outward faces, pivots and material assignments as relevant to the change. Confirm the actual saved/exported files belong to this candidate; a successful exit or an old file's existence is insufficient. Keep a short build summary and file hashes in the existing record where needed for uploads and comparisons. Reuse existing validation rather than adding tests that only restate the builder.
5. **Inspect appearance at the right scale.** Use consistent camera, lighting and render settings when judging variants. Compare shape, proportions, silhouette, materials and composition to the selected reference. Fix the underlying design before adding more detail. For courses, keep V3's cheap whole-route study and finished playable section at the existing critique checkpoint. For feature assets, use the relevant real UI size or lobby view; do not impose course phases on ordinary feature work.
6. **Export and verify the affected result.** Use the existing [upload workflow](BLENDER_ROBLOX_UPLOAD.md), permissions and receipts. Upload only changed packages that need it, and inspect changed imports and dependent joins in Studio. Test scale, orientation, editability, actual imported face/triangle coverage, visible/collision agreement and relevant runtime behavior. Check one representative mesh internally and where it meets neighboring units before repetition; vertex/bounds equality alone can miss holes or overlapping faces. A flashing repair needs moving-camera native evidence when available, with missing rendering kept explicit. Blender previews do not prove Roblox appearance or performance. Shared Blender mesh data does not by itself prove the exporter/importer reused runtime assets; inspect the actual imported cost before claiming savings.

Keep successful live adjustments in the appropriate durable source before the next rebuild. Prefer a scoped patch over regenerating an accepted map. Do not rerender, reupload or rerun unaffected gameplay checks merely because one input changed.

## Apply only where relevant

Course Creator uses this automatically when authoring substantial Blender geometry. Keep the three course phases (Asset Creation → Course Creation → Map Creation), owner checkpoint, flexible asset sourcing, performance requirements and owner-selected reviews.

Feature Creator uses it for 3D lobby props, emblems, preview models and comparable assets. Native Roblox UI/Luau and the existing image workflow remain the default where appropriate. Do not rebuild accepted icons, UI, arrival assets or gameplay as part of adopting this guidance. A role update is not an asset-build request.

## Measure the benefit without creating more work

On the next substantial applicable build, add a brief observation to its existing report: generation/render/export time when available, retries or connection failures, amount rebuilt, owner corrections, output complexity and visible result. Use a comparable prior run only when inputs, settings and scope match; otherwise establish a baseline. Do not rebuild both implementations solely to obtain a benchmark unless the comparison will resolve a current decision.

Report measured changes separately from predicted benefits. Fewer tool calls do not prove lower total cost, a fast build does not prove better art, and asset counts do not prove Roblox frame rate or mobile readiness. Keep numerical improvement claims pending until measured.

## Basis for this guidance

- Blender documents [command-line automation and batch processing](https://docs.blender.org/manual/en/dev/advanced/command_line/) and [operator context limitations](https://docs.blender.org/api/main/info_gotchas_operators.html). The installed Blender 5.2.1 command help confirms background scripts and Python-error exit codes.
- The [MCP source](https://github.com/ahujasid/mcp-for-blender/blob/main/src/blender_mcp/server.py) executes Python in a live Blender instance. The locally inspected 1.9.1 server uses a 180-second socket receive timeout; this is implementation-specific, not an inherent limit on Python or every MCP server. No live connection or comparative performance claim follows from source inspection.
- Existing project examples are the [medieval prop builder](../assets/medieval_stud_showcase/build_showcase.py), [Shipwreck kit builder](../assets/shipwreck_cove/phase1/build_kit.py) and [arrival emblem builder](../assets/onboarding/create_arrival_emblem.py). They demonstrate saved recipes and direct mesh construction. They are evidence, not commands to rerun: some write fixed output paths, and the emblem builder also writes generated Luau source.
