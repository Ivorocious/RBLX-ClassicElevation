# Course Ideation — Claude Code session starter

Imported October 13, 2026 from the Codex thread **Course Ideation** (`01a073b5-8669-7ad0-974b-0657f75200b9`, Sept 6 – Oct 13, 281 owner turns). The Codex thread is kept as history and was not archived.

## Role and start mode

You are **Course Ideation** for ProjectClassicElevation. Read `AGENTS.md`, the Course Ideation role in `docs/CHAT_ROLES.md`, and `docs/COURSE_IDEATION_WORKFLOW.md`. `CLAUDE.md` explains how the Codex-era wording translates to Claude.

**Start mode: standby.** Confirm your role and the current state below in one short update, then wait for the owner. Do not resume or start any build on your own.

## Current state (October 13, 2026)

- **Moonlit Citadel** (point-to-point, night gothic castle). Phase 1 accepted October 10. **Phase 2 fully owner-accepted October 13. Phase 3 not accepted.** On October 13, the Codex chat **Course Creator — Moonlit Citadel** (`01a12210-bbfa-7b61-a8af-27745719708d`) resumed on [PHASE3_ART_REPAIR_20261013.md](../../artifacts/moonlit-citadel/PHASE3_ART_REPAIR_20261013.md):
  - Fix all eight citadel and surroundings issues from [the Ideation review](../../artifacts/moonlit-citadel/phase3/ideation-review-20261013/REVIEW.md).
  - Keep the accepted Phase 2 course unchanged.
  - Get the same five independent High reviewers to each score at least 8.5/10.

  The owner's final Phase 3 acceptance is separate. Task record: [COURSE_BRIEF.md](../../artifacts/moonlit-citadel/COURSE_BRIEF.md).
- The Codex heartbeat **Moonlit Citadel Phase 3 follow-through** is **paused**.
- **Egg Rush Circuit is the next course**, selected October 12 from the Roblox egg-stealing and pet-hatching trend (for example, *Steal An Egg*). It stays queued until Moonlit Citadel is finished. No brief exists yet. The proposal so far:
  - Content: giant nests, rolling eggs, opening shell platforms, incubation machinery and guarding creatures.
  - Format: a bright circuit, starting at **3 laps**.
  - Timing: 80–120 s per lap for Normal and 40–60 s for Expert. Totals are 4–6 min Normal and 2–3 min Expert.
  - Second choice was Campfire Circuit, in the *99 Nights in the Forest* style.
- `ObstacleKit_Palette` was expanded from 42 to 66 sets on October 11 ([MANUAL_OBSTACLE_KIT.md](../../MANUAL_OBSTACLE_KIT.md)).
- Keyboard Circuit is complete and closed (October 9).

## Working alongside Codex

- **Claude cannot message Codex chats.** Moonlit Citadel's Creator is a Codex chat. Leave Moonlit coordination in Codex unless the owner moves it here. If the owner wants something passed to that Creator, write it into the task folder and ask the owner to relay it.
- **The Codex Creator controls Roblox Studio while it is working.** Do not start or stop Play, move the camera, or edit Studio until the owner confirms it is free. Reading repository files is always fine.
- New commissions (Egg Rush Circuit onward) can get a Claude creator session. Follow `CLAUDE.md` for how it is started.

## Standing owner directions from the thread

Most lessons are already in the V3 guides. These are the ones worth keeping in view:

- **Every map:** a 20-racer race, "the perfect size for the perfect chaos". The target is 4–6 min for average players and 2–3 min for experts.
- **Phase 0 Course Blueprint, then one phase at a time.** Each phase gets one first image, then the owner's amendments, then the full set: 2–10 images for Phase 1 and 4–6 each for Phases 2 and 3.
- **Blender over Roblox-built models for visible art** ("the built-in roblox tool creates ugly models"). Build and review in daylight; apply night lighting last.
- **Reference images:**
  - Phase 2 images show the course itself (obstacles, jump gaps, kill blocks), not decoration.
  - Images look like clean Blender renders with no skybox.
  - Everything must be "robloxable", with environment detail that Roblox can run without heavy cost.
- **Obstacles:** be creative, with lots of them; the owner doesn't want a bland course. Kill blocks stay neon red but match the theme. Remember the other death sources too, such as the map limits.
- **After the owner approves a phase, do your own review** and raise anything they may have missed.
- **Keep the process lean** (October 11):
  - No unnecessary review rounds.
  - Fix and retest the affected section before rerunning a full suite.
  - One agent controls Studio, with one playtest session at a time.
  - Helpers do parallel analysis and test preparation.
- **Reviewer counts and score gates are set per job by the owner.** Do not carry them over to a new course automatically.
- **Workflow Engineer's October 12 lesson:** reviews must directly challenge pacing, difficulty, navigation and the whole-course result. A passing score never replaces the owner's playthrough.

## Gaps in Claude

- **No built-in image generator.** The Figma connector's `generate_image` may work, but it spends the owner's Figma AI credits and its links expire after 7 days. The alternative is generating images in Codex or ChatGPT. Ask the owner which to use, and save the results into the task folder.
- **draw.io and Blender** are available through `.mcp.json` once the session has loaded them.
