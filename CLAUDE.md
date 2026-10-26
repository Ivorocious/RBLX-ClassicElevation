# CLAUDE.md

@AGENTS.md

## Reading the Codex-era docs in Claude Code

AGENTS.md and `docs/` were written for Codex. They still apply; translate them this way. Owner-facing guide: `docs/claude/README.md`.

- "Codex" means Claude Code. "ChatGPT project chat" means a planning session. Codex "threads" are Claude "sessions".
- Each role in `docs/CHAT_ROLES.md` is a separate Claude Code session in this project folder, titled the same way. The chat IDs listed there are Codex threads, not Claude sessions. Role starters are in `docs/claude/sessions/`.
- Codex is still in use. Claude cannot message Codex chats. Only one tool may control a given Studio window, and only one may control Blender, at a time. Before Play, camera moves or Studio edits, confirm no Codex chat is using that window. Two agents can playtest in parallel only with two windows on separate Rojo ports (`docs/ROBLOX_MCP_SETUP.md`, "Two Studio windows for parallel agents").
- Codex `create_thread` / `wait_threads` do not exist. When Ideation commissions a creator, save the filled starter as `CREATOR_START.md` (per `docs/FOCUSED_CREATOR_THREADS.md`) and ask the owner to open a new session in this project folder with: "Read <absolute path>/CREATOR_START.md and start." Do not use `spawn_task` for this: it opens a separate worktree that lacks uncommitted work and the Rojo link. The creator has not started until the owner opens it.
- Helpers/reviewers are subagents (Agent tool), under the same limits: only when authorized and genuinely parallel, bounded inputs, and the lead inspects the results.
- Model defaults translate as below. The owner picks the lead's model and effort in the app; record the actual choice in the starter.

| Role | Codex default | Claude Code |
| --- | --- | --- |
| Course Creator lead | Sol 6.1 Max | Opus 5.5, max effort |
| Feature Creator lead | Astra ExtraHigh | Opus 5.5, xhigh effort |
| Ideation and Game Direction | Astra Max | Opus 5.5, max effort |
| Authorized helpers | Sol 6.1 High | Agent tool with `model: opus`, `effort: high` |

- MCP servers keep their Codex names (`Roblox_Studio`, `Roblox_Studio_Chrrxs`, `blender`, `drawio`) and are configured in `.mcp.json`. Tools appear as `mcp__Roblox_Studio__<tool>`. Follow `docs/ROBLOX_MCP_SETUP.md`; where it says "reload Codex", start a new Claude Code session.
- Start Rojo (`./tools/start_rojo.ps1`, or `./tools/start_rojo_second.ps1` for the second window) as a background command; never block a turn waiting on it.
- Claude Code has no built-in image generator, so Codex `imagegen` steps need another source. The Figma connector, when enabled, offers `generate_image`, which spends the owner's Figma AI credits and returns links that expire after 7 days (save results into the task folder). Otherwise the owner generates images in Codex/ChatGPT. Ask the owner which to use before an image step. Never mark an image step done without the actual files.
