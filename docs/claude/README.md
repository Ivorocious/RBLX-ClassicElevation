# Using Claude Code on ProjectClassicElevation

October 13, 2026. The owner is trying Claude Code alongside Codex. Everything in the main [README](../../README.md) and `docs/` still applies; this page only covers what differs in Claude. Decisions still go in the shared [DECISIONS.md](../DECISIONS.md), so both tools see the same history.

## Words

| Codex | Claude |
|---|---|
| Codex desktop app | Claude desktop app, **Code** tab (Claude Code) |
| Thread / chat | **Session** |
| Global `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| Project `AGENTS.md` | Still used; loaded by [CLAUDE.md](../../CLAUDE.md) |
| MCP servers in `config.toml` | [.mcp.json](../../.mcp.json) (same server names) |
| Helper / reviewer subagents | Subagents (Agent tool) |
| `create_thread` | No equivalent; the owner opens new sessions |
| imagegen | Figma connector's `generate_image` (uses Figma AI credits; untested here), or generate in Codex/ChatGPT. Save results into the task folder |
| Code review plugin | `/code-review` |

Claude Chat (claude.ai) cannot see this repository or Studio. Use it only for discussion away from the files.

## Sessions

| Session title | Starter | Model / effort |
|---|---|---|
| Course Ideation | [sessions/COURSE_IDEATION.md](sessions/COURSE_IDEATION.md) | Opus 5.5, max |
| Feature Ideation | [sessions/FEATURE_IDEATION.md](sessions/FEATURE_IDEATION.md) | Opus 5.5, max |
| Workflow Engineer | [sessions/WORKFLOW_ENGINEER.md](sessions/WORKFLOW_ENGINEER.md) | Opus 5.5, max |
| Project Startup — Rojo & MCP | none; ask it to follow [ROBLOX_MCP_SETUP.md](../ROBLOX_MCP_SETUP.md) | Opus 5.5, high |
| Course / Feature Creator — *job* | the job's `CREATOR_START.md` | see [CLAUDE.md](../../CLAUDE.md) |

**To open one:** in the Claude app choose **New session**, pick this project folder (not a worktree), set the model and effort, and paste:

```text
Read docs/claude/sessions/<FILE>.md and take on that role. Rename this session to "<Session title>".
```

For a creator, paste: `Read <absolute path>/CREATOR_START.md and start.`

Use the project folder itself, not a worktree or cloud session. Rojo syncs from this folder, and much current work is not committed yet. The same rule is in `CHAT_ROLES.md`.

## Running Claude and Codex side by side

- **They cannot message each other.** Pass work between them through the task files (`CREATOR_START.md` and the current-state record) and the owner.
- **One controller per Studio window, and one for Blender, at a time,** across both tools. Before a Claude session starts Play, moves the camera or edits Studio, confirm no Codex chat is using that window.
- **Two agents can work at once.** Editing different repository files never needs coordination. For parallel playtesting, open a second Studio window on the second Rojo port and give each agent its own window; see [ROBLOX_MCP_SETUP.md](../ROBLOX_MCP_SETUP.md), "Two Studio windows for parallel agents".
- **One owner per job.** Don't let a Claude session and a Codex chat both work on the same course or feature.

## Plugins

`roblox-dev` (community plugin from Anthropic's directory) adds Luau and Roblox skills: security, DataStores, performance, UI, testing and a reviewer agent. If it is installed, the project's own rules in `AGENTS.md` and `docs/` still win where they differ.
