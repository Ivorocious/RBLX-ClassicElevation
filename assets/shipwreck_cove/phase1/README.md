# Shipwreck Cove Phase 1 kit
September 23, 2026. Course revision 1.0, low-poly visual revision 2.
Current library: **SC_KIT_04**. Current Studio fit studies: **SC_P1_07**.

These files are an editable asset kit and three small studies, not the completed circuit. The native plan and course brief still govern later route assembly.

## Current files
- `ShipwreckCove_Kit04.blend`: editable 35-mesh library. Stable `SC_` names and local mounting origins.
- `ShipwreckCove_Kit04.fbx`: approved upload package, asset **131167579113033**, creator **86069177**.
- `ShipwreckCove_FitStudies07.blend`: editable real-scale dock/wreck, cave and ribs/spars studies.
- `ShipwreckCove_Study07.rbxm`: recoverable native study plus normalized MeshPart library.
- `build_kit.py`: deterministic Blender authoring source. Full run rebuilds the kit and studies; `--studies-only` leaves the uploaded FBX and kit blend unchanged.
- `manifest.json`, `CATALOG.md`: dimensions, triangle counts, mounting notes, simple colliders and estimated reuse.
- `studies.json`: exact repeated placements, visual-only flags and study totals.
- `palette.png`: one opaque 128Ã—128 atlas; broad flat swatches, no texture grain.
- `export-verification.json`: evaluated FBX re-import counts and current file hashes.
- `upload-receipt-04.json`, `import-report-04.json`: completed upload and inspected Studio normalization.
- `studio-inventory-07.json`: native instance/property counts and full collider parity with tested SC_P1_03.
- `fit-results-03.json`, `runtime-sample-03.json`: retained bounded evidence, explicitly dated to the earlier study.
- [Current Studio views](../../../docs/artifacts/shipwreck-cove/phase1/REPORT.md): current native screenshots. See the project report for convenient links.

Earlier numbered files, reviews, views and receipts are historical candidates. In particular, the initial client-clone probe did not provide working physics evidence; use the server-owned probe and `fit-results-03.json`. Do not treat old counts, scores or upload hashes as current.

## Mounting and scale
One Blender unit means one intended Roblox stud. Blender uses Z up; desired Roblox mapping is **(X, Z, -Y)**. Authoring origins are the useful bottom, beam centerline or bay join, not necessarily the visual bounding-box center.

The observed FBX insertion was 20.48 times the intended dimensions. Normalize each MeshPart using `dimensionsRobloxXYZ`; do not blindly apply a universal conversion factor to future imports. The current imported meshes also require a 180-degree yaw correction. Keep the original mesh asset and use the included installers or normalized library.

For each placement:
1. Build a mount from the study origin plus `(pos.x, pos.z, -pos.y)` and its yaw.
2. Scale visual size by `(scale.x, scale.z, scale.y)`.
3. Offset by the scaled `centerBlender`, mapped to `(x,z,-y)`, then apply the mesh's 180-degree yaw.
4. Place independent collider boxes from the manifest. Collider coordinates/sizes already use Roblox axes. Do not fill intentional deck gaps with a single large box.

The library uses shared mesh IDs and one texture. MeshParts are anchored, opaque, SmoothPlastic, white-tinted, Automatic rendering fidelity, and have collision/touch/query disabled. Keep the 42 simple colliders separate. They collide and answer queries but do not emit touch events. Visual-only context pieces have no colliders. Anchored decorative parts need no scripts.

The installers are **isolated Studio study tools**, not Rojo production services:
- On an inspected, intended Edit-mode place with the raw Kit04 import available, run `install-colliders.luau`, then `install-visuals.luau` to normalize and mount it.
- If the normalized Kit04 library already exists, use `install-from-normalized-kit.luau` after the collider installer instead.
- Installers intentionally refuse to overwrite an existing study. Archive only owned previous candidates before a revision. Never replace owner courses.
- `prepare_studio.py` regenerates the collider installer from the current manifests.
- The study root uses Persistent streaming for repeatable inspection only. This is not the shipping map streaming policy.

## Family rules
- Dock/deck modules: preserve playable widths and align walking faces, including the 0.03-stud broad color panels. No stretched whole hulls to change jump difficulty.
- Boarding ramp: rise 5.3 over a 12-stud run; walking surface is 1 stud above its lower mount and 6.3 above its upper local endpoint.
- Hull: 16-stud bays, paired half-shells, tapered bow and transom. Keep the boarding side open and make keel contacts visibly overlap large rock foundations. Broken upper rails are visual, not new walkable pads.
- Ribs: 3.2Ã—3.6-stud top pads. Tested rising sample uses 10-stud center spacing and 1.5-stud rises. Do not scale pad width to disguise a missing gap.
- Spars: 16Ã—2.8-stud beams, separated supports, modest alternating yaw. Test every changed gap/height in the eventual branch.
- Rocks: reuse a few broad faceted forms. Standard uniform scale is 0.75â€“1.5. The recorded decorative grounding/ceiling study scales are deliberate exceptions; they do not redefine any playable ledge.
- Cave: raised pale dry shelves, dark inner rock, a light foam front, flat red entry markings and visible daylight. Main roof minimum local underside is zero; mount at least 12 studs above refuge tops. In this study the roof mounts at 19 and refuges top at 7. Do not intrude decorative overhangs into the avatar's jump envelope.
- Palms: five broad leaves, three trunk segments. Mount the base on rock/shore; keep foliage out of the approach and landing sightlines.
- Sails: sparse broad tears; fixed mesh, no cloth simulation.
- Cannon: low 1.6-stud ball, muzzle 3.1 studs above deck, seven-stud full-height cover. Maintain the whole shot corridor through the impact/reset beyond play, not just the crossing center.
- Water/foam: opaque local surfaces; no overlapping transparent ocean, particles or global water simulation.

## What the studies prove
The server-owned live R15 clone passed 13 focused checks at WalkSpeed 16, JumpHeight 7.2, HipHeight 2 and gravity 196.2. These covered the boarding ramp, 5-stud interior gap with 14.2-stud headroom, two rib jumps, two spar jumps, cave entry/exit, jump-over versus standing cannon contact, whole-body cover clearance and both dry refuges.

The cannon check sampled a mathematical ball/body intersection at 48 studs/s. It proves a feasible local jump configuration, not the final cannon controller or human reaction timing. H02 is a spatial surge/refuge arrangement, not an implemented cycle.

The final 42 colliders have identical size, transform, touch and query signatures to the tested 03 study. Changed decorative shapes were checked in native views. This carries the collision fit result forward; it is not a fresh 07 gameplay run.

One five-second desktop Studio sample from 03 recorded 16.30 ms median and 20.24 ms 95th-percentile frame intervals, with no asset-fetch failures. Total 3326.5 MB was for the **mixed existing place**, including City Run/lobby. It cannot be attributed to this kit. There is no isolated GPU, mobile, 20-player, peak-memory, loading-time or full-race proof.

## Later Map Creation obligations
Keep the three-lap order R0â†’R1â†’R2â†’R3â†’R4â†’forward SAME R0 gate. Preserve H01 and H02, X01 R2-to-R3 recovery to R2, X02 R3-to-R4 recovery to R3, and no branch that skips a signature hazard. Implement warnings, audio, safe windows, impact/reset and recovery only in the later authorized phase.

Inspect and extend existing circuit support rather than replacing it: ordered requirements are present, but direction-aware shared-gate handling still needs verification/integration. Deaths must preserve completed laps without recovery teleports awarding a lap. Existing racer collisions remain enabled; no pushing mechanic was added.

Before acceptance of the full course: test normal movement, touch input, 20 racers, both shortcuts, congestion/refuges/respawns, all 3 laps, backwards/invalid crossings, deaths near lap boundaries, and measured expert2â€“3minute/average4â€“6minute full races. These timing targets remain unverified. Stud style is unresolved. Full course composition and owner acceptance remain separate from these Phase 1 reviews.

