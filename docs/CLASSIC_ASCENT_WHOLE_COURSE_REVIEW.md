# Classic Ascent Point-to-Point — whole-course critique and proposal

September 6, 2026 · **Approved by the owner; implementation and verification tracked in [V8 verification](CLASSIC_ASCENT_V8_VERIFICATION.md)**

The owner approved implementation and added two requirements: modest increases to rolling boulders, snowballs, and giant snowballs; and retained jump gaps with irregular platform positions and height differences. The audit below records the proposal as presented before approval.

## Recommendation

Keep the ten-theme mountain journey and protect the river as the visual reference. Rebuild the weakest route environments so each section feels like a specific place on the mountain. Give the finish a proper arrival. Improve performance through measured changes to asset and runtime cost while retaining the dense, layered views that the owner likes.

The main weakness is repetition: different materials and hazards are placed on similarly parallel rows of platforms, with repeated side boulders, trees, rails, or ice teeth. More decoration alone will not solve this. The route, mountain structure, landmarks, and views need to be composed together.

Six fresh Terra High critics completed one bounded evidence pass: five section-pair reviews and one technical performance review. Each pair inspected four player-height views; the performance critic inspected two. The coordinator checked whole-course route length and pacing, reconciled conflicting advice, and gave the owner's river preference priority. No gameplay scripts, assets, or authored scene geometry were changed. Review documents are the only new work from this audit; temporary camera inspection was used.

## Decisions already supplied by the owner

- Rebuild weak sections while keeping all ten themes, the mountain journey, and the improved river quality.
- Aim for 30 FPS on budget phones and 60 FPS on PC with 20 racers.
- Use Blender where it improves the result, with attention to polygon cost.
- Keep multiple Terra High reviewers, with bounded initial reviews and focused rechecks.
- Present one consolidated critique and proposed changes before implementation.
- Preserve the river's dense, layered **left bank** and its immersive ground-level view.

Approval of this proposal would authorize the scoped overhaul below. Publishing, economy, player data, monetization, and unrelated systems are outside this proposal. Existing unrelated workspace work must remain intact.

## What stays

The ten named sections retain their order and identity. The mountain remains the supporting landform and destination. Keep the 19-checkpoint progression structure, recovery behavior, multiplayer passing capacity, and each section's established hazard concept. Checkpoint positions and connecting geometry may be adjusted only where an approved weak-section rebuild needs them, with progression and recovery revalidated.

The river keeps its layered banks, five staggered logs per stream, current motion, hidden resets, and playable layout. The overhaul can improve its sign and the transitions into Trailhead and Switchback. Its quality is a composition reference, not a requirement to plant dense forests in lava or alpine sections.

Skyline keeps the accepted 0.5-stud shortening of its pads/supports, cyan ice against dark slate, opened entrance, and pit-depth treatment. Changing any of those needs a demonstrated problem and a focused replacement test. The current camera limit of 30 studs remains the inspection constraint; distant camera views cannot substitute for readable player views.

## Section-by-section decision

Scores are the individual critics' subjective visual/readability judgments. They are not calibrated between reviewers and do not measure fun, reachability, difficulty, accessibility, or FPS. Earlier high scores on specific river/Skyline fixes covered a narrower scope and should not be treated as contradictory whole-section grades.

| Section | Visual / readability | Main problem | Recommended change |
| --- | --- | --- | --- |
| 01 Trailhead | 6.5 / 4 | Ground lanes merge, sign wraps, canopy hides the first action. | Targeted refinement: a clear start threshold, warm trail cues, two deliberate view windows, and readable signage. Keep dense forest framing. |
| 02 River Rapids | 7.5 / 5 | Some repeated crossing/rest geometry and an obstructive entry sign remain. | Protect the accepted section. Fix the sign and adjoining transitions; measure runtime cost without changing its crossing rhythm. |
| 03 Switchback Climb | 5 / 4 | Repeated slabs do not read as a turning mountain ascent. | Substantial rebuild: three distinct switchback shelves, from green lower talus through a rock cleft to exposed granite. Make the route actually turn with the landform where needed. |
| 04 Ridge Bridges | 6 / 6 | Parallel bridges and repeated rails crowd the view. | Reshape into bridges between believable rock anchors, with distinct central, valley, and sheltered lines reconnecting at clear refuges. Retain crumble behavior. |
| 05 Pillar Yard | 5 / 6 | A tiled lava tray and small blocks do not establish a pillar field. | Substantial rebuild: broken basalt columns grounded in a caldera, recessed lava channels, and one strong supported landmark. Preserve vent warnings and safe crossing windows. |
| 06 Broken Causeway | 5 / 6 | Regular steps beneath a visually detached rock ceiling. | Substantial rebuild: retained mountain-road approach, failed span with a broad refuge, then a rockfall gallery visibly attached to the cliff. |
| 07 Cliffside Traverse | 4 / 4 | Slab rows and a tree/boulder wall hide the exposed-cliff identity. | Substantial rebuild: narrow rock throat, exposed boulder chutes, then a snowline buttress. Make hazard sources and refuge shelves readable. |
| 08 Summit Steps | 5 / 5 | A white stair grid enclosed by forest; cover and snowmen compete. | Targeted reshaping: last forest shelf, thinning treeline, then open alpine ascent. Show snowball source, path, and protection clearly. |
| 09 Skyline | 5 / 4 | Similar cyan pads and repeated ice teeth obscure the intended line. | Readability and scenery pass: distinguish the main route by surface/edge cues, vary glacial forms, and build depth below and beside it. Preserve accepted spacing and ice behavior. |
| 10 Summit Run | 4 / 6 | Repeated cover props and an obstructed finish identity weaken arrival. | Recompose as an avalanche scar leading to a summit terrace. Frame the gate during the approach, clear its sign, and reveal a layered valley beyond the finish. |

### The continuous journey

The proposed sequence is sheltered forest → lively river → turning granite climb → exposed bridges → volcanic pillar field → broken mountain road → bare cliff → thinning snowy treeline → glacial skyline → summit arrival.

Each section should have an entry that explains its next action, a middle beat with a recognizable landmark or refuge, and an exit that reveals the next environment. Keep some sections enclosed and others open. The river's best lesson is overlapping near ground, medium forms, tall structure, and distant depth; that can be made from forest, basalt, ruin, snow, or ice.

The upper course must gradually lose trees and gain open sky. The finish should be visible at a few deliberate moments without filling every view. At the last checkpoint, show the gate, open finish approach, and mountain/valley reveal together. Keep the terrace clear enough for a group of racers and unchanged finish detection.

### Route and accessibility requirements

- A new player should see the next safe landing and hazard warning before committing. Use surface shape, contrast, placement, and short text together; do not rely on color alone.
- Separate sign title and action text. Test short copy at actual phone scale and during movement. Keep boards outside landing sightlines.
- Preserve an understandable main route and passing room. Branches should offer useful alternative paths, then reconnect at recognizable shared rests; they need not stay parallel throughout a rebuilt section.
- Keep scenery out of takeoff, landing, headroom, and recovery space. Collision must match the usable ground and intended cover.
- Do not increase jump difficulty merely to create a better silhouette. Verify horizontal distance, height, diagonal movement, and slippery surfaces together.
- Use cover shapes and hazard-source framing to explain protection. Visual alcoves only count as safe if the existing hazard logic actually protects a player there.
- Keep touch controls usable through the narrow and moving-platform sections. No new camera system or control redesign is proposed.

## Whole-course pacing

The current live central route contains 170 nodes and climbs from the start near Y=64 to the finish near Y=244. Every theme contributes approximately 18 studs of net ascent, which reinforces the repeated recipe. Vary the local rhythm of shelves, short climbs, and visual rests while keeping the overall uphill progression.

The coordinator measured approximately **2,215 studs** along successive central-route nodes including the start connection. The stored `RouteLengthStuds` value is 2,161 and should be refreshed from the final geometry after implementation. The current section contributions, rounded, are 280, 266, 269, 237, 232, 212, 205, 181, 180, and 153 studs. These describe the center route, not all branch travel or player trajectories.

At walk speed 16, distance divided by speed is about 138 seconds before any jumping, waiting, slipping, recovery, or route choice. This is a geometric reference, not a predicted completion time. Existing casual/expert time targets and the nine-minute limit should remain provisional until current-route human runs exist; an older roughly six-minute run used a different revision. Do not shorten sections or tighten the timer from this calculation alone.

The first two sections should teach route reading and timing. The middle should vary exposure and hazard type. The last three should progressively reveal altitude, then give a broad final push after Skyline's precision movement. A full human run is needed to identify where repetition becomes tiring or waits become excessive.

## Performance: evidence and proposed work

The live Edit-mode model is `Workspace.Course_ClassicAscentPointToPoint`, place 85558151074819, BuilderVersion 7 / AltitudeRevision 2 / RiverFinishRevision 1. It contains 5,956 descendants, 4,732 BaseParts, and 1,297 MeshParts. All parts were anchored in Edit mode; moving-platform assemblies become dynamic at runtime.

Mesh reuse is already strong: 33 unique mesh/texture pairs. The local Blender manifests and complete live prop-family counts give about **554,456 placed prop triangles**. This excludes primitive geometry and is not the number rendered in a frame; imported meshes, visibility, and Roblox's detail selection can change that cost. Part count alone cannot establish performance.

| Candidate | Evidence | Proposed decision and guardrail |
| --- | --- | --- |
| Decorative collision memory | 1,255 MeshParts are noncollidable, non-touching, and non-queryable, but all use Default collision fidelity. | Use simple Box collision data for this noninteractive set, then measure memory. Review the 42 query-enabled meshes separately because some scenery is used by visibility checks. |
| River simulation | 100 moving-log records, within 134 motion records visited each server heartbeat. The river uses server-owned moving assemblies. | Profile occupied and spread-out crossings first. Only if significant, prototype conservative activation of nearby streams with early activation and preserved visual traffic. This is a separate high-risk regression gate, not a promised FPS gain. |
| Mist arrival cost | 72 enabled altitude-mist emitters; existing prewarming emits a burst per arriving marked emitter. | If measured as material, queue nearby prewarming and prepare upcoming visible pits early. Preserve depth and prevent haze appearing late. |
| Expensive foliage meshes | 46 Cedar instances × 5,574 source triangles = 256,404 triangles, about 46% of the manifest-derived prop estimate. | Compare a simpler Blender cedar variant at player height. Keep canopy volume, branch silhouette, ground-level density, and reuse. Adopt only if the imported view and measurements justify it. |
| Hazard queries | 38 kill-volume overlap checks at 10 Hz, approximately 380 queries/second before active falling rocks. Each query filters the characters; this is not multiplied by 20 again. | Measure before changing. Nearby-section filtering is optional only if needed, with conservative buffers for movement and respawn and no reduction in recovery reliability. |
| Shadows and foam | Every part has CastShadow enabled, including invisible volumes; water foam also updates locally. | Low priority until profiling identifies cost. Invisible shadow flags do not prove expensive shadow rendering. Keep canopy/crag shadows and smooth river motion where they matter. |

Roblox recommends measuring the actual bottleneck, reusing meshes, and simplifying collision data for noninteractive geometry; disabled collisions can still leave collision geometry in memory. These support the measured approach above, without predicting an FPS improvement. [Roblox performance guidance](https://create.roblox.com/docs/performance-optimization/improve).

Reducing five logs to three is excluded: at unchanged travel time it would extend arrivals from about 6.85 to 11.42 seconds. Only 40 log centers are inside the original ±35-stud crossing envelope in the reviewed arrangement; 100 authored logs do not mean 100 simultaneously visible logs. Optimizations must not break the accepted river to lower a count.

### Blender scope

Prefer a small shared kit: fractured basalt columns, broken causeway/abutment forms, cliff buttresses and chutes, and glacial/snow-ridge forms. Make geometry that establishes the place, with simple unseen backs and distant variants where appropriate. Reuse existing materials and meshes whenever they already serve that purpose.

Build playable geometry first. Add or replace scenic assets only after the routes and views are approved internally. Record triangles per source asset and placed counts; inspect actual Roblox imports at player height. A Blender preview or lower triangle total cannot establish game performance or successful art direction. Any replacement should be scoped to generated course content with a recoverable source checkpoint; do not delete unrelated authored assets.

## Proposed implementation sequence

1. **Baseline and design blocks.** Preserve the current source/revision, record measured runtime costs where tooling permits, and lay out simple playable revisions for 03, 05, 06, and 07 plus a finish sightline block. Preserve the river and the ten-section progression. Check jumps, landing space, checkpoints, boundaries, and recovery before detailed art.
2. **Middle-course rebuild.** Complete the switchbacks, pillar field, causeway, and cliff traverse using the shared kit. Reshape Ridge Bridges alongside its adjacent transitions. Keep each change independently reviewable and test its hazard behavior.
3. **Journey and arrival.** Refine Trailhead, signs, treeline progression, Skyline readability, and Summit Run. Integrate the section transitions and final panorama. Inspect from the same player-height constraints used in the audit.
4. **Measured optimization.** Apply safe noninteractive asset settings and evaluate the foliage candidate. Tackle river/mist/hazard runtime changes only where a baseline demonstrates need, one category at a time.
5. **Acceptance.** Each relevant Terra High critic checks the changed section pair once; rechecks target unresolved findings rather than repeating the entire review. Run a whole-course human pass and performance checks, then record accepted evidence and remaining device limits.

Keep script changes durable in the repository and synchronized through Rojo. Inspect the intended Studio instance before rebuilding. Use small modules following existing builders, not a new framework. Update the level-design notes and relevant decisions/tasks/playtest records with the final accepted changes.

## Acceptance gates

| Area | Required evidence |
| --- | --- |
| Visual quality | Ground-level views at entries, middle rests, transitions, and finish show grounded near/middle/distant layers. Main landings stay visible within the 30-stud camera limit. River left-bank richness remains intact. |
| Traversal | Meaningful checks of all changed central and branch transitions using the real character/runtime, followed by human movement on keyboard and touch. Include height changes, diagonals, ice takeoff/stopping, crowded refuge approaches, and finish arrival. |
| Hazards and recovery | Correct warning lead time, log carry/jump/reset behavior, crumble reset, vents, rockfall, snowball/avalanche cover, checkpoint respawn, and out-of-bounds recovery. Reuse accepted river endpoint/occlusion and Skyline checks when their dependencies change. |
| Multiplayer | Validate several racers meeting at rests and finish, then a 20-racer river test and a spread-out race. Local simulated load can find faults, but is not proof of real-device/network conditions. |
| Phone and PC performance | Record actual device/model, graphics settings, player count, scene state, client frame time/FPS, memory, server physics/script cost, and network behavior. Aim for sustained 30 FPS on representative budget phones and 60 FPS on PC; review slow frames and sustained load as well as averages. |
| Pacing and usability | Human full-course run records completion time, repeated failures, forced waits, route confusion, and touch-control difficulty. Adjust only demonstrated problems. |

Studio emulation does not reproduce a budget phone's processor, memory, or thermal behavior. The representative phone and PC have not been specified or benchmarked. If device access is unavailable, report those tests as pending; do not label the overhaul performance-validated. The audit itself ran no new Play session, full-route traversal, or 20-racer test.

## Reviewer records

- [01–02: Trailhead and River Rapids](artifacts/review-01-02.md) — condensed critic record with coordinator decisions.
- [03–04: Switchback and Ridge Bridges](artifacts/review-03-04.md).
- [05–06: Pillar Yard and Broken Causeway](artifacts/review-05-06.md).
- [07–08: Cliffside and Summit Steps](artifacts/review-07-08.md).
- [09–10: Skyline and Summit Run](artifacts/review-09-10.md).
- [Performance and asset inventory](artifacts/review-performance.md).

The consolidated proposal above controls the recommended scope. Several critics conservatively proposed preserving every route pad; the owner's broader allowance to rebuild weak sections permits scoped route changes in those sections. The river critic's larger river rebuild and five-to-three-log option are deliberately excluded. No implementation begins until the owner approves this consolidated direction.
