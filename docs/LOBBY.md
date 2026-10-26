# Blender lobby

**Skycourt B10 is the main Workspace.Lobby.** The owner's latest bench and wall edits were preserved when applying this finish pass. Earlier lobby versions were exported from ServerStorage.LobbyArchive into verified local backups during the [8 September cleanup](PRE_PHASE_CLEANUP_2026-09-08.md). All eight trees now include solid trunk colliders.

For manual adjustments, use [Fine-tuning the lobby in Roblox Studio](LOBBY_STUDIO_EDITING.md).

## Current layout

- The Hall of Champions header is removed, exposing podium numbers 1, 2 and 3. Shallow front and side frames finish the existing podium blocks.
- Two fluted cream pillars with restrained gold trim frame the lower staircase.
- The lower hall has two rectangular floor inlays, a central compass, small Practice arrows, a Records crest, ceiling trim and three soft fill lights.
- Two inward-facing edge benches add four seats. Mixed round and rectangular planters form small groups at the perimeter.
- The centre stays open for gathering and crossing. The lower hall is a social and records area; the spawn remains on the arrival floor.
- Existing practice, the last-race winner display and four invisible barriers remain. The current counter and records behavior is described below.

## Editing in Studio

Workspace → Lobby → Editable → 01_Lower contains **44 named models**. Move, rotate or scale a complete model so its collision, seats and lights stay with its visible geometry. New pillars, benches, planters, inlays, crest and ceiling bays are separately selectable.

Podium/MonumentFinish follows the complete functional Podium model. SideWallFinish_-1 / 1 under Editable/02_Arrival are separate decorative models fitted to the owner's manually rotated walls; select the wall and finish together when repositioning that assembly.

Save the Studio place to retain geometry changes. LobbyService preserves the existing lobby when Play starts. Rojo synchronizes scripts; Blender does not receive manual Studio edits.

## Source and reconstruction

- assets/lobby_blender/build_lobby.py generates Skycourt_B10.blend, Skycourt_B10.fbx and manifest_B10.json.
- src/ServerStorage/CourseBuilders/LobbyBuilders/BlenderComparison.luau installs the Blender asset with editable groups and functional helpers. BlenderManifest.luau is generated data.
- Roblox asset **119601098254709** is inserted as ServerStorage.SkycourtB10Import. Its receipt is .tools/uploads/lobby-blender-b10.json.
- tools/apply_lobby_b09.luau and tools/apply_lobby_b10.luau apply scoped revisions while preserving the existing layout. They reject repeat application and archive a backup first.
- tools/finish_lobby_side_walls.luau adds shallow native Roblox relief fitted to the two manually positioned side walls.

A full install reconstructs the Blender starting layout, **not the owner's later Studio adjustments**. The installer refuses to overwrite an existing target. Prefer the saved Studio lobby or its archive when recovering manual work.

The B10 Blender export has 494 visible meshes plus four import markers and 300,563 triangles. The reviewed live lobby has 500 visible architecture meshes, including the owner's extra meshes, plus native side-wall relief. It contains 464 marked collision parts, 29 lights and 16 seats. These counts are not a device-performance benchmark.

## Verification

Final B10 checks passed:

- Five grounded R15 lower-floor routes: stair descent/turn, ascent, forecourt crossing and both board approaches.
- All four added seats accept an R15 humanoid and face inward.
- Twenty sampled avatar spaces, each 4.2 × 6 × 4.2 studs, are clear of marked lobby collision.
- The B10 change preserves 1,027 existing parts outside the two deliberately replaced planter groups, compared with the fresh pre-B10 backup. CourseLibrary remains at 12,088 descendants.
- Blender generation, Python compilation and the Rojo source build pass.

Evidence: B10-movement.json, B10-seats.json and B10-preservation.json under docs/artifacts/blender-lobby. The static 20-figure screenshot demonstrates spacing only. Live 20-player traffic, first-person camera comfort and multiplayer/device performance remain human playtest items. Earlier B08/B09 test reports remain historical evidence.

## Independent visual reviews

All reviewers assessed the same nine B10 Studio captures: front, oblique, lower, lower-reverse, pillars, podium, side, crowd and approach.

| Reviewer | Focus | B10 score |
| --- | --- | --- |
| Luna Max | Grounding and clipping | 8.5/10 |
| Luna Max | Route readability | 8.6/10 |
| Luna Max | Variation and reference fidelity | 8.4/10 |
| Terra High | Composition, scale, atmosphere and cohesion | 8.4/10 |

B09 did not pass the complete gate; B10 followed the reported finish and wayfinding concerns. All four B10 scores are independently above 8, with no averaging or dropped reviewer. Extra High was not needed. Remaining suggestions concern finer asset variation, floor-arrow contrast and human crowd/camera checks.

Studio is left in Edit mode. Temporary crowd figures are archived. No desktop mouse/keyboard control or place publishing was used.

## Lobby functions and Grand Arcade — October 2, 2026

The current scoped changes preserve the saved lobby and the entire practice area. After C01 installation, all 1,071 original lobby parts match the saved snapshot, accounting for the archived originals. All 35 archived parts retain their original properties.

- Arrival, the lower junction and the Style stairs have small cream/navy/gold direction signs. Arrival Front/Back, LowerJunction Front and StyleStairs Back pass native level-camera review. LowerJunction Back and StyleStairs Front still need clear walking-route views; benches obstructed the selected camera positions.
- The existing records frames contain reversible navy overlays. SESSION WINS counts official first-place finishes in this server; LATEST RACE shows up to five official finishers from the most recently completed race. Duplicate/stale completions and invalid results are rejected. The state is temporary and bounded; it does not write profiles or change rewards.
- The native Style prompt opens the existing My Racer editor and shares its arrival, race, busy and tournament-readiness restrictions. Style is Collider315 in this imported layout. A normal E press from the customer side opened the existing editor; Keep current look restored the lobby with unchanged gold. Trails and Gear have inset Coming later plaques.
- Grand Arcade remains separate from RaceCourse. Its idle panels show the four actual eligible courses: City Run V3, Classic Circuit, Classic Point-to-Point and Shipwreck Cove. The fifth panel explains the five-course requirement. Idle previews do not imply a resolved race order.
- Q01 adds decorative arch casings, column layers and podium caps to the existing stage. The five groups retain fifteen separate winner slots and a separate presenter. Native empty views pass visual review; populated names and the presenter still need Play visual checks.

TournamentController avoids replaying a completed Ready presentation when results or arrival attributes change. A player whose course-readiness gate remains false can still resume delivery. The actual controller passed the labelled native replay/readiness fixture. TournamentPresentation also restores an abandoned Scriptable camera to Custom when arrival is closed and it still owns that camera. Ten fresh-module checks and13 full freshly loaded production-controller lifecycle/input checks passed: authoritative death/respawn, pending resumption, terminal failure cleanup, current Humanoid, FOV70, HUD/controls and normal W7.4681studs. These are labelled solo preparation fixtures, not real map-delivery or multiplayer proof.

C01 is installed after direct approval. It replaces the blocked central rail/stepped approach and relocates four complete lamps. All 35 affected original parts are retained under ServerStorage/DeveloperArchives/GrandArcadeConnection/C01 for restoration. Three continuous native round trips passed at normal walking speed with jumping disabled: center X1552 and edges X1544.8/1559.2, with no intermediate teleports. The earlier 139 recovery checks remain separate evidence.

The podium appearance path now uses Roblox's valid ShouldersAccessory property. A fresh exact-service native fixture produced twelve genuine avatar models and three safe invalid-user fallbacks, with all fifteen feet aligned to their slots. Resetting an in-flight appearance left no stale figures. Populated names and board readability still need visual verification; fitting native text bounds is not a substitute for rendered views.

Studio is back in Edit. Temporary probes are retained only under tests/studio, outside the game mapping. The earlier eight production fingerprints,26 compiles and build remain separate evidence; the latest regression confirms both affected production fingerprints and compiles its two new test sources. The final native framing sequence closes G1: the installed ramp and stage entrance pass strict visual review alongside the previous three walking round trips. Four sign faces pass; two remain pending, as do populated records/podium client views. No client capture peer is connected. Native probes are absent, and camera CFrame/Focus/type/FOV, empty selection and the default nonsimulated viewport were restored exactly. [Partial completion report](artifacts/lobby-improvement-study-2026-10-02/completion-report.json).

Source: LobbyAmenities, LobbyActivityService, LobbySessionRecords, GrandArcadeService, TournamentController, TournamentPresentation, GrandArcade/QualityTrim and LobbyBuilders/GrandArcadeConnection. [Current progress and evidence](artifacts/lobby-improvement-study-2026-10-02/implementation-status.json). C01/Q01 upload receipts are in `.tools/uploads/grand-arcade-C01.json` and `.tools/uploads/grand-arcade-Q01.json`; no game publishing occurred.
