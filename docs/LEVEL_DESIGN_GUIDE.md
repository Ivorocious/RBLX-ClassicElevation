# Level design guide — lessons from Classic Ascent

Owner preferences and reusable working rules, recorded September 6, 2026.

Use this guide for future courses in Project Classic Elevation. It captures the owner's repeated feedback and the implementation lessons from Classic Ascent. It is a design brief, not permission to publish, upload assets, alter progression, or overwrite manual work. See the shorter [chat starter](LEVEL_DESIGN_CHAT_STARTER.md) for a ready-to-paste instruction.

## Current acceptance boundary

**Classic Ascent Point-to-Point has passed the generated level-design phase and moves to manual fine-tuning after the final Skyline haze/global atmosphere changes.** Do not automatically redesign or regenerate it again.

- Current source: builder version 7, `AltitudeRevision = 2`.
- Detailed implementation and evidence: [v7 handoff](CLASSIC_ASCENT_V7.md). Older v4/v5/v6 notes describe earlier builds, not the current course.
- Design acceptance is the owner's judgment. It does not establish a passing 20-player performance test, final difficulty balance, or resolved rider-carry behavior. Those remain manual acceptance items where noted.
- The original mountain, integrated adventure setting, bridge traversal and final broad approach were repeatedly praised. Preserve accepted strengths while correcting specific weaknesses.

## The central design principle

**Build a playable journey through an environment.** The course should wind through the forest, ruins, cliffs and snow. The setting should surround and sometimes participate in play, rather than occupy a decorative strip beside a separate obstacle strip.

The owner's red/green sketch is the clearest reference: the playable route bends through a larger decorated space, with environment around and inside the route's turns. It does not require every future course to branch into the same shape.

Think at three distances:

| Distance | What the player needs |
| --- | --- |
| Immediate | Readable next landing, hazard warning, cover and recovery point |
| Section | A recognizable place with a distinct mechanic, terrain shape and landmark |
| Distant | A believable surrounding world, destination and sense of scale |

Do not solve only the overhead screenshot. Review from avatar height, during traversal, and looking off both sides.

## Owner preferences to carry forward

1. Integrate course and environment. Avoid parallel strips of gameplay and decoration.
2. Make placement natural: irregular clusters, varied spacing, rotations, silhouettes and sizes, with deliberate clearings and view windows.
3. Use substantial scale. Mature trees should tower over avatars; major rocks, ice formations and landmarks can be gigantic. Do not make an entire forest look like saplings.
4. Include both large forms and small detail. Grass, ferns, flowers, roots, scattered stones and believable ground transitions make the environment feel inhabited.
5. Respect the surface and biome. Flowers belong in soil pockets, not emerging randomly through cobblestone. Bare cliff-jump sections should read as cliffs, not a planted garden.
6. Make jump gaps real. Avoid near-touching platforms that can be walked across. Vary positions and heights, while preserving reachable routes and fair landings.
7. Prefer varied, weathered forms over repeated identical arches, rigid rows or stretched oval primitives.
8. Keep a believable connection to the mountain. The idea behind under-course support was good; the original repeated oblong execution was rejected.
9. Give exposed areas depth. Hidden bottoms, long cliff faces, distant ranges and atmospheric separation should make the player feel high up.
10. Hazards should move convincingly, communicate danger, and allow a response. The owner disliked stiff linear-looking rocks and snowballs, even when they technically moved.
11. The ending needs a clear reveal and satisfying arrival. Do not bury the finish beneath roofs, props or hazard clutter.
12. Spend most effort on design quality. Use Blender where it improves shape and variety. Minimize Computer Use and repetitive automated playtesting; the owner wants to play the course.

These are defaults grounded in repeated feedback. A new explicit brief can override them. Do not turn a one-course value into a rule for every level.

## Lessons from each iteration

| Problem the owner identified | Better direction |
| --- | --- |
| Obstacle strip beside a scenery strip | Routes weaving through a shared environment |
| Trees in rows, identical arches | Seeded clusters, several asset families, varied proportions and missing pieces |
| Oval/oblong rocks and hanging supports | Authored angular or weathered meshes; supported ledges and deep cliff strata |
| Removing all underside support made platforms float | Restore convincing vertical mass, then conceal its lower end in depth haze |
| Dirt/cobblestone cluttered with plants | Deliberate soil pockets and grounded scenic banks |
| Blank mountain wall and empty void | Themed foreground screening plus distant landscape layers and a visible summit |
| Mountain usable as a shortcut | Continuous course boundaries, separate scenic collision rules, preserve intended jump gaps |
| Logs overlapping land and incomplete banks | Shorter/fewer logs, full-width rest banks, checks over the complete travel envelope |
| White current lines stayed still | Lightweight local animation that handles course replacement and late-arriving parts |
| Platforms remained three tidy rows | Bounded seeded position/height/angle/width variation, keeping scenery frames independent |
| Rocks and snowballs felt artificial | Visible rotation, varied size and pauses, controlled arcs and actual surface contacts |
| Small wisps still showed a shallow pit floor | Recess the floor, extend supports downward, place haze above all visible underlying geometry |
| Forest felt human-sized | Tall trees and occasional larger landmark specimens, with readable route clearance |
| Whole-map smoke raised performance concerns | Native atmospheric distance haze and existing ridges; local particles only where they serve a specific effect |

## Environment and asset rules

### Scale and composition

- Judge proportions against an avatar and the camera, not just studs in a table.
- Use large silhouettes first, medium props second, micro-detail last. More tiny props will not fix missing large forms.
- Mix dominant trees, smaller companions and open sightlines. Natural placement does not mean uniformly filling every available patch.
- Large canopies may overhang play; trunks, low branches and rocks must leave intended landings readable and usable.
- Themed foreground scenery can screen unfinished edges. Leave selected openings to show the distant view.
- Keep both sides designed. A mountain-facing wall needs texture, layers or vegetation appropriate to the theme; the valley-facing side needs depth and a surrounding world.

### Shape and material

- Reuse a coherent kit with variations, not one shape stretched into every object.
- Distinguish geological rock, ruins, tree roots and ice. A ruined causeway should have broken spans, grounded remnants and believable fractures.
- Avoid unsupported giant caps balanced on thin identical stems. Do not recreate rejected oval arches with a different mesh name.
- Use Blender when primitives cannot provide the required silhouette. Moderate detail is welcome; very low polygon counts are not an artistic requirement.
- Spend mesh detail where players see it. Hidden undersides and distant forms do not need the same detail as foreground assets.
- Preview assets at game scale after import. A good Blender gallery does not prove a good Roblox composition.

### Grounding and pit depth

- Every visible plant or grounded prop needs a plausible supporting surface.
- Check for floating stones, buried trunks, broken bank edges, exposed mesh bases and repeated seams.
- Separate the visual bottom from the recovery plane. A player can recover promptly while the visible chasm appears far deeper.
- Inspect every surface under a pit, including the main mountain, not just the generated floor. Skyline's generic mist was partly hidden by a mountain slope about 65-73 studs below the route.
- Keep local pit haze below landings, dense enough to hide the bottom and layered to avoid a flat-looking fog floor.
- Use native Atmosphere and distant silhouettes for broad distance haze. Do not cover the entire world with large overlapping smoke sprites by default.

## Traversal and hazard rules

### Platforms and paths

- Lay out start, destination, section boundaries, checkpoints and safe areas before decorating.
- Choose branching where it supports multiplayer flow. Multiple routes should reconnect at recognizable safe areas; three paths are not mandatory for every course.
- Use controlled randomness: stable seeds, bounded changes between neighboring platforms, modest vertical differences, and a known reachable route.
- Do not make jumps difficult through visual ambiguity or obstructed landings. Difficulty should come from timing, distance, choice and movement.
- Check diagonal transitions and height changes together. A horizontal gap measurement alone is not proof of playability.
- Preserve the ability for several racers to approach a challenge together. Bridges benefited from stone refuges between lanes.

### Moving logs and water

- Rolling hazards must be low enough to jump over. River logs must have useful, readable jumping space.
- Define the entire life cycle: visible origin, travel direction, endpoint, disappearance, hidden reset and respawn.
- Test the whole log volume, including end caps, against banks and checkpoints at both ends of travel. Center-point checks miss overlaps.
- Water should have a coherent source, flow direction, bank and outlet. Moving foam should agree with the current.
- Complete land platforms before adding motion. More decoration will not fix an overlapping checkpoint or partial bank.
- Avoid per-frame character teleports to carry riders; they competed with local character movement in this project. Native moving-platform physics was retained, but rider acceptance remains open.
- Distinguish server motion, client visibility, standing carry, walking, jumping and hidden reset. Passing one does not prove the others.

### Rocks, snowballs, lava and cover

- Danger warnings should be red in this game's established visual language.
- Give players enough warning, an escape or cover, and recovery opportunities. Randomness must not make the course impossible.
- Vary source timing and rock size within bounds. Repetition should not reveal a mechanical pattern everywhere.
- Rotation, arcs and contact help motion read naturally. A visually round object with no surface detail can spin without looking like it spins.
- Use actual surfaces for bounce points. A missed ground sample must not create a midair bounce.
- Controlled server trajectories are acceptable where they improve fairness and predictability. Do not describe them as unrestricted physics.
- Cover needs both a clear visual shape and working collision behavior. Keep it out of intended jump landings.
- Sources should belong to the environment: mountainside rockfalls, grounded snowmen, believable avalanche entrances. Conceal authored spawn positions without blanketing the whole course in a roof.

## Efficient workflow for future courses

1. **Recover context.** Read the current brief, this guide, applicable AGENTS.md, source and intended Studio hierarchy. Identify accepted work and manual changes before editing.
2. **Write a compact section plan.** For each section state theme, core action, hazard, safe point, landmark and transition. Ask only about missing choices that materially affect the design.
3. **Establish the overall form.** Build the route, terrain mass, altitude and major silhouettes. Prevent shortcuts and reserve the finish reveal.
4. **Build representative sections.** Solve one forest, one exposed jump area and one moving hazard where relevant. Reuse the successful patterns with variation; do not duplicate their exact layout.
5. **Add mechanics and asset kits.** Use existing services and approved assets first. Use Blender for missing shapes. Keep colors, dimensions, names and asset IDs reproducible.
6. **Review from the player's view.** Check path clarity, scale, grounding, both side views, underside depth, hazard origins and the destination. Inspect the moving river or equivalent problematic mechanic directly.
7. **Run proportional checks.** Build/compile, inspect checkpoint order and route boundaries, then one focused live check for changed gameplay. Only repeat when a failure or new change justifies it.
8. **Deliver a concrete result.** Explain changes, evidence and limits. Preserve before-update copies. Request any required upload/replacement approval only after preparing the reviewable asset/candidate.
9. **Stop at acceptance.** Move the accepted course into manual fine-tuning. Do not continue unsolicited aesthetic experiments or regenerate the user's edits.

Use repository tools, Rojo and Studio MCP before Computer Use. Headless Blender is useful when the MCP connection is unavailable; avoid resetting an existing interactive Blender scene. Keep updates concise and reduce repeated searching or large unbounded test loops.

## Proportional review checklist

- Does the course feel embedded in a place, with a clear destination?
- Are silhouettes and props appropriately large from avatar height?
- Are trees clustered, rocks grounded and plants on suitable surfaces?
- Are jump gaps deliberate, varied and readable, with reasonable height changes?
- Are safe areas and multiplayer passing/refuge opportunities clear?
- Do moving hazards have a believable source, motion and reset?
- Is there any log on land, unfinished bank, floating prop or visible hidden spawn?
- Is the mountain blocked as a shortcut without blocking the intended route?
- Do exposed gaps hide their bottom and retain a sense of structural support?
- Are both mountain and valley views finished, without covering the destination?
- Is the finish visible and satisfying to enter?
- Were relevant checks run once, with uncertainties stated accurately?
- Are current authored geometry, source, backups and manual-tuning status clearly identified?

## Technical and handoff boundaries

- Keep scripts durable in the repository and synced through Rojo. Do not leave the only implementation in a temporary Studio command.
- Keep gameplay-critical decisions server-authoritative and use the existing recovery/checkpoint/race services.
- Do not add economy, DataStore, monetization, unrelated UI, or new security-sensitive networking as part of a scenery pass.
- Preserve accepted signs, checkpoints, start staging, recovery behavior and manual adjustments unless explicitly changed.
- Prefer safe property edits and additive changes when sufficient. Back up before risky replacement; follow the project's explicit approval rules for destructive edits, large hierarchy moves and asset uploads.
- Asset upload approval is specific to the stated kit and creator. It does not authorize publishing the place.
- Never equate a lower part count with a measured FPS improvement. Consider mesh complexity, particles, transparency overlap, collision and replication as well.
- A build, screenshot or automated movement sample is not proof of final difficulty, 20-player fairness or human fun.

For manual tuning, the durable authored course is `ServerStorage.CourseLibrary.Course_ClassicAscentPointToPoint`; `Workspace.RaceCourse` is the preview/runtime copy. Capture accepted manual geometry into the library and save the Studio place. Rojo/Git do not automatically save all hand-authored place geometry. Preserve the current version/revision markers so an already-applied pass does not scale props again.

## Classic Ascent reference values — not universal defaults

| Item | Reference |
| --- | --- |
| Accepted course structure | Ten themed sections, 19 shared checkpoints; designed for 20 racers, not load-tested |
| Current tree scale | Approximately 41-94 studs |
| Revised river logs | 40 logs, 16 studs long; two per water row |
| Varied central gap sample | Up to approximately 6.86 projected studs; not a complete jump proof |
| Vertical variation | Up to approximately 1.48 studs from authored route height |
| Visual pit floor | Approximately 240 studs below the route in selected open sections |
| Final global haze | Native Atmosphere, Density 0.37 / Offset 0.02 / Haze 3.1 |
| Human pacing evidence | Owner enjoyed a nearly six-minute v3 run with falls; not a timing result for the final build |
| Fast validation | Existing Studio-only Skip checkpoint control |

## Research notes

Roblox documents that Atmosphere controls distant haze and blending between geometry and the sky. This supports using it with existing mountain silhouettes for the broad landscape effect. [Atmospheric effects](https://create.roblox.com/docs/environment/atmosphere).

Roblox also identifies screen coverage and overlapping transparent particles as GPU costs. Its particle guide states that particle lifetimes above 20 seconds are internally capped. The final pass retires 60 broad smoke emitters and uses 16-20-second lifetimes for local pit mist. This is a structural reduction in particle work, not a measured FPS claim. [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters).
