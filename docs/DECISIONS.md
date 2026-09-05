# Decisions

Record important project decisions here.

### 2026-05-19 - Use Git and Rojo as Source of Truth

**Decision:** Git stores durable project source, and Rojo syncs filesystem source into Roblox Studio.

**Reasoning:** This keeps AI-assisted edits reviewable, diffable, reversible, and portable across sessions.

**Impact:** Scripts and configuration should normally be edited in the repository first. Studio-only script edits should be treated as temporary unless mirrored back into the repo.

**Alternatives Considered:** Editing directly in Roblox Studio as the primary workflow. Rejected because it weakens review, rollback, and AI collaboration.

### 2026-05-19 - Keep Gameplay-Critical Logic Server-Authoritative

**Decision:** Currency, inventory, damage, rewards, progression, purchases, unlocks, matchmaking, and other gameplay-critical systems must be owned and validated by the server.

**Reasoning:** Client input can be modified or faked. Server validation is required for security and consistency.

**Impact:** RemoteEvents and RemoteFunctions must validate payloads, permissions, cooldowns, ownership, and state transitions server-side.

**Alternatives Considered:** Faster client-trusting prototypes. Rejected for systems that affect progression, economy, combat, rewards, or purchases.

### 2026-05-19 - Use a Service-Oriented Server Layout

**Decision:** Server systems should live under `ServerScriptService/Services` as focused ModuleScripts when they become substantial.

**Reasoning:** This keeps gameplay systems modular, testable, and easier for Codex to modify safely.

**Impact:** Avoid growing `Main.server.luau` into a large script. Use it mainly for bootstrap/wiring when services are introduced.

**Alternatives Considered:** One large server script. Rejected because it becomes hard to review and maintain.

### 2026-05-20 - MVP Race Foundation Is Server-Authoritative and Point-to-Point First

**Decision:** The MVP race architecture starts with `RaceFormat = "PointToPoint"` while keeping
`LapBased` as a planned type/config option for later implementation.

**Reasoning:** The first playable milestone should prove one excellent live race loop before adding
course selection or lap/circuit complexity.

**Impact:** Race state, player status, checkpoint progress, finish validation, placement, and result
data are owned by the server. Personal bests are in-memory only until DataStore use is explicitly
approved.

**Alternatives Considered:** Building multiple formats, persistent PBs, ranked points, or course
selection immediately. Rejected for MVP scope control.

### 2026-05-30 - Add LapBased Validation Without Course Selection UI

**Decision:** LapBased race validation is implemented server-side for enabled course models, but
public course selection, course voting, and persistence remain outside MVP scope.

**Reasoning:** Friend playtesting needs a circuit race path, but players should not be able to
choose or authoritatively influence active course state from the client.

**Impact:** `CheckpointService` owns lap progression, `ResultsService` stores lap-aware in-memory
result data, and `CourseConfig.ActiveCourseId` remains the server-owned way to pick the active
course for now.

**Alternatives Considered:** Adding player-facing course selection or full rotation immediately.
Rejected until both course formats are smoke-tested.

## Template

### 2026-09-05 - Classic Ascent Uses a Reproducible Course Builder

**Decision:** Add Course_ClassicAscentPointToPoint as a separate course, generated
from a server-only builder when absent. Preserve the original Studio courses.

**Reasoning:** New course geometry must be recoverable from Git while allowing
explicit Studio authoring without silently overwriting it.

**Impact:** Fixed selection uses classic_ascent_point_to_point. Course-specific
fall volumes replace the assumption of one named trigger. The shared timeout is
nine minutes, with early completion when all official racers finish or leave.
Completion targets remain unvalidated until human timing passes. See CLASSIC_ASCENT.md.


### YYYY-MM-DD - Decision Title

**Decision:** TBD.

**Reasoning:** TBD.

**Impact:** TBD.

**Alternatives Considered:** TBD.

### 2026-09-05 - Alpine environment rebuild and explicit authoring refresh

**Decision:** Replace the rectangular placeholder with a ten-section, 146-transition
mountain route. Separate route construction from deterministic scenery. Keep the
nineteen checkpoints, nine-minute maximum, and existing authoritative race rules.

**Reasoning:** Passing mechanics tests did not satisfy the requested complete
setting. The route needs recognizable places and visible progress while retaining
short recovery distances. Native parts and materials keep the course reproducible.

**Impact:** Builder version 1 is archived under a disabled placeholder name when
upgraded. Version 2 authoring models are not silently overwritten. Review iterations
are preserved in ServerStorage.CourseBuildArchive. The current Edit RaceCourse is
a copy of the new authoring model; normal CourseService startup archives this copy
and spawns the selected runtime course. Local ambience restores the preexisting
Lighting values when the player returns to the lobby. Human acceptance is pending.

### 2026-09-05 - Integrate mountain terrain, active obstacles, and safe staging

**Decision:** Version 3 joins the route to solid banks and cliff foundations,
replaces floating signs with mounted waymarkers, simplifies summit slopes, and
connects bridge rope spans. Add three small hazard types with server-owned timing.

**Reasoning:** The first alpine version still played as an unchallenging walkway
with disconnected scenery. Hazards need visible warnings and checkpoint recovery,
not unpredictable unavoidable deaths. A start barrier should define the race start
without teleporting players twice.

**Impact:** CourseHazardService binds with the active course and uses existing
RespawnService death recovery. All hazard timing is in HazardConfig. Intermission
stages once; the gate opens on Racing without a second teleport. Local sky and
lighting restore when the player returns to the lobby. No economy, DataStore,
publishing, course rotation, or new circuit work is included.
## 2026-09-05 — Shared adventure space and instant hazard recovery

Version 4 uses three branching lines and wide shared checkpoints for the requested
20-player race. Scenery sits between and above routes, with shared forest/snow ground.
Keep the nine-minute ceiling; the user's roughly six-minute v3 run is human evidence,
while v4 timings remain unmeasured. Do not increase enforced waiting to stretch runs.

Ordinary lethal contacts call server-only RespawnService.RecoverPlayer instead of
killing the Humanoid. Nonlethal snowballs deal 35 damage; lethal damage recovers and
heals. CourseMotionService owns log travel, vents and projectile cycles. No client
authority or new gameplay remotes. Unexpected real deaths retain the old fallback.
Preserve the user's manual sign transforms in source and archive the original model.

## 2026-09-06 - Classic Ascent v5 mesh scenery

Use the explicitly approved Blender prop asset 89332142209949, cached as named templates, for the v5 course. Preserve the approved mountain and the archived v4 course; remove repetitive ellipsoid decoration. Moving logs use one-way hidden resets; rolling hazards remain server-authoritative. See [v5 handoff](CLASSIC_ASCENT_V5.md).

## 2026-09-06 - Classic Ascent v6 grounding

Use supported cliff strata, planted scenic banks, a mountain-connected gallery and distant ridges around the preserved mountain. Block mountain/scenery shortcuts with continuous boundaries. River logs use native server-owned physics instead of moving rider characters; keep rider-carry acceptance open until the manual check passes. Previous Studio course copies were archived with explicit approval. See [v6 handoff](CLASSIC_ASCENT_V6.md).
