# Classic Ascent recovery pass (historical)

**Superseded, September 7:** the owner's later exhaustive review rejected V8, including this recovery work. V7 is restored; see the [current editing guide](CLASSIC_ASCENT_EDITING.md). Earlier acceptance and tests below are historical.

September 6, 2026. Historical build: **Recovery Candidate38**. Its independent reviews did not meet the requested score threshold. The owner subsequently accepted the visual direction directly and requested restored jump difficulty before manual fine-tuning. See the [current jump-restoration report](CLASSIC_ASCENT_JUMP_TUNING.md). Passing movement checks does not establish visual quality.

## Current implementation

- All ten section themes and all 80 accepted river pads remain. Earlier V7 and recovery candidates are preserved in Studio.
- Sections 3 and 9 now use seven course-specific curved terrain runs built in Blender: 25 consecutive path segments and 75 flank pieces. The surfaces follow the actual route positions and heights. Section 6 retains two continuous stone shoulders.
- Thirty-six joined route caps are hidden and noninteractive; the visible physical terrain supports the character. Branches and exposed gap islands retain distinct jump landings.
- Imported template caches include the routed asset version and merge only manifest-listed props. This prevents an older same-named terrain asset from silently replacing the current geometry.
- Lower/mid-course groves, close rock faces, and upper snow/rock clusters frame selected route groups. The live reviews still identify broad planar rock/ice bands and disconnected-looking upper scenery.
- The narrow winding lava channel has 68 visible physical kill wedges. Twelve tapered moving vents retain their authored motion/contact and use near-flush dark cracks with small localized warning strips.
- Upper refuge rocks remain physical cover. Visible checkpoint landing meshes retain the original server-authoritative checkpoint triggers.
- Durable source is under `src/ServerStorage/CourseBuilders/`. Blender generators and exports are under `assets/ascent/`; the current routed asset is `121291227897684`. Its source is `routed_terrain/RoutedTerrain.blend` and `RoutedTerrain.fbx`. The existing routed `preview.png` depicts the earlier terrain version; use the current Studio build for visual judgment.
- No place publication or Git commit has been made.

## Current Candidate38 evidence

- **Geometry passed:** 639 individual landing rays, 297 samples across 27 connecting path meshes, 108 curved-path footprint samples, 228 snow-path samples, checkpoint clearance, and visible-lava contact settings. The checker measures 238 separate-surface connections and identifies 26 connections on the same continuous physical interval. [Geometry](artifacts/journey-geometry.json).
- All **80 river pads** retain their original position, size, and orientation. Largest measured gap: approximately **7.385 studs**. Route length: **2,237.64 studs** (rounded metadata 2,238).
- **9/9 continuous-path walk fixtures passed**, covering 38 nodes at WalkSpeed 16 without jumping. Fixtures copy the actual connected surfaces and use a real client character. [Walk results](artifacts/journey-curve-walks.json).
- **18/18 sampled jump fixtures passed**, using a real client character at WalkSpeed 16 and JumpHeight 7.2. The sample includes the ten widest connections, two largest rises, and six additional routed-terrain boundaries. The character steers toward the landing while airborne; a prior fixed-direction trial overshot one short jump. [Jump results](artifacts/journey-jumps.json).
- **19/19 checkpoint contacts passed again on Candidate38** in a fresh normal race. Teleported approaches reached every trigger in order and recorded all 19 splits. [Results](artifacts/journey-checkpoints.json).
- Candidate38 contains **1,644 MeshParts**: 1,020 noninteractive Box scenery meshes and 213 individual Hull landing meshes. These categories do not include every interactive mesh and do not prove a performance target.
- Five registered shared-approach landing overlaps remain documented in the geometry artifact, with higher route surfaces 0.53–2.21 studs above the lower centres. Unexpected scenery over a landing centre fails the check.

## Earlier recovery runtime evidence retained

These tests ran before the final scenery/curved-terrain revision. The relevant hazard services and contact meshes remain unchanged unless stated.

- **24/24 generic-cover cases:** actual live race services affected exposed/front positions and blocked snowballs, boulders, and avalanches behind cover. Two cycles per case. [Results](artifacts/journey-cover.json).
- **12/12 authored-refuge cases:** a copy of the smallest refuge mesh blocked actual snowball and avalanche effects behind it; exposed/front positions were affected. [Results](artifacts/journey-authored-cover.json).
- **4/4 tapered-lava contact cases:** the running movement service recovered a racer contacting the actual rising mesh and left an outside position safe. [Results](artifacts/journey-lava.json).
- **480 vent warning observations on Candidate35:** 137 warning-visible and 343 other-state-hidden samples, with zero mismatches. Candidate38 retains these vent visuals and timing. [Results](artifacts/journey-vent-warnings.json).
- The earlier checkpoint pass found and corrected two snow shoulders covering their triggers; the Candidate38 recheck above confirms current contact/order.

The cover harness isolates hazard paths and forces deterministic motion; it does not test every authored bounce trajectory. Walk/jump fixtures use isolated copies, not an end-to-end course playthrough. Checkpoint tests use teleported approaches and validate contact/order, not traversal.

## Independent visual acceptance

Candidate38's fresh live scores are **4.8/10 art**, **7.8/10 composition**, and **7.7/10 player view**. All reviewers took their own current Studio screenshots. Earlier candidates' passing individual scores do not carry forward.

- [Independent art review](artifacts/recovery-art-independent.md)
- [Composition review](artifacts/recovery-composition.md)
- [Player-view review](artifacts/recovery-player-view.md)

The requested condition—all three reviewers above 8/10—was not met by these reviews. The owner's later direct visual acceptance supersedes that review gate; the scores themselves remain unchanged. Reviewers identified repeated rock/ice silhouettes and upper framing as weaknesses, with the river and lower switchback as strengths.

## Remaining checks

- Human traversal of every branch, slippery transitions, refuge use, and the final climb.
- Actual budget-phone 30 FPS, PC 60 FPS, and 20-racer checks. Single-player Studio tests and mesh counts do not establish these targets.
- Complete the owner's subsequent jump-restoration request before manual fine-tuning; see the current report above.

Final handoff checks: Rojo build and whitespace check passed. Studio was returned to Edit mode, discarding the temporary runtime fixtures and review camera/UI changes.

## Reproduce

1. Connect Rojo and build the course in the intended experience.
2. Run `tests/studio/ClassicAscentJourney.luau` against authored geometry before Play. Runtime moving hazards intentionally do not satisfy the authored anchored-root assertion.
3. Start a real Studio race. Run cover/checkpoint harnesses as normal Scripts and walk/jump harnesses as LocalScripts using copied surfaces. Direct MCP `require` can read a separate uninitialized service cache.
4. Stop Play to discard temporary fixtures, scripts, character movement, and review UI changes.
