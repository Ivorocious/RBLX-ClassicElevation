# Feature Ideation — Claude Code session starter

Imported October 13, 2026 from the Codex thread **Feature Ideation** (`01a0f0a5-6e54-73f2-8ed4-2442f236a528`, Sept 30 – Oct 4, 77 turns). The Codex thread is kept as history and was not archived.

## Role and start mode

You are **Feature Ideation** for ProjectClassicElevation. Read `AGENTS.md` and the Feature Ideation role in `docs/CHAT_ROLES.md`. `CLAUDE.md` explains how the Codex-era wording translates to Claude.

**Start mode: standby.** Confirm your role and the current state below in one short update, then wait for the owner.

## Current state (last active October 4, 2026)

Work produced in this thread, now recorded in its own docs:

- **Lobby UI:** the "Soft Modern" direction.
- **Five-race tournament and voting.**
- **Grand Arcade tournament stage:** map displays with top-3 mini podiums ([implementation brief](../../artifacts/grand-arcade-implementation-brief-2026-10-02/)).
- **Lobby improvement study:** [completion report](../../artifacts/lobby-improvement-study-2026-10-02/completion-report.json).
- **Grand Arcade repair:** [repair brief](../../artifacts/grand-arcade-repair-2026-10-03/repair-brief.json). The later cleanup is done; see `docs/TASKS.md`.

**Open item: game flow, pacing and cutscenes.** On October 2 the owner asked how the game flows for the first player, later players and other scenarios, covering both current improvements and a bigger redesign. The study was delivered in chat but never saved, so it is now at [FLOW_STUDY.md](../../artifacts/game-flow-study-2026-10-02/FLOW_STUDY.md). Nothing in it is accepted or implemented, and its code references are from October 2. Ask the owner whether to continue it.

**Owner-reserved:** the lobby practice section ("I'll work on it later").

**UI overhaul (Claude Code, October 13–14):** designed over seven rounds and commissioned. Brief, starter and current state: [ui-overhaul-concepts-2026-10-13](../../artifacts/ui-overhaul-concepts-2026-10-13/BUILD_BRIEF.md). Revision 2 (October 14) adds the owner's new race-flow screens and waits for the Codex race-flow job to finish. The owner opens the Feature Creator session from its `CREATOR_START.md`. Game rules there (Shop contents and prices, champion, quests, course coins) are deliberately left as placeholders.

## Standing owner directions from the thread

- The owner likes **choosing between visual options**. Show several candidates in different styles, refine the chosen one, and give implementers clay renders from multiple angles. Check the images for consistency before handing them off.
- **Feature Creator tools in Codex:** Blender, Figma and image generation.
- **The owner sets the lead model, helpers and reviewer gates for each job.** Do not reuse an earlier job's team. In Codex, helpers were capped at Sol 6.1 ExtraHigh; in Claude the matching cap is **xhigh**.
- For repairs, act as orchestrator. Find the problems yourself, write precise fix requirements with evidence, and then hand the build to a focused Feature Creator.

## Working alongside Codex

- Claude cannot message Codex chats, so a Codex Feature Creator can only be reached through the owner.
- Before touching Roblox Studio, confirm with the owner that no Codex chat is controlling it. Moonlit Citadel's Creator may be.

## Gaps in Claude

- **No built-in image generator.** The Figma connector's `generate_image` may work, but it spends the owner's Figma AI credits. Ask the owner before using it.
- **Figma is connected** as a claude.ai connector. Blender and draw.io are available through `.mcp.json`.
