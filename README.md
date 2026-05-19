# ProjectClassicElevation

Roblox project baseline for building ProjectClassicElevation with filesystem-first source control, Rojo sync, and lightweight documentation for design and implementation work.

## Workflow

- ChatGPT project chat handles planning, design, architecture, and decisions.
- Codex handles scoped implementation tasks, refactors, debugging, and reviews.
- Roblox Studio handles visual assembly, UI layout, assets, terrain, and playtesting.
- Rojo syncs filesystem source into Roblox Studio.
- Git is the source of truth for scripts, documentation, configuration, and history.

## Project Layout

- `AGENTS.md`: Codex rules and project workflow guidance.
- `default.project.json`: Rojo project mapping.
- `docs/`: design notes, architecture, decisions, tasks, bugs, and playtest notes.
- `src/ReplicatedStorage/Shared`: shared modules.
- `src/ReplicatedStorage/Config`: shared configuration.
- `src/ReplicatedStorage/Remotes`: RemoteEvents and RemoteFunctions.
- `src/ServerScriptService`: server scripts and services.
- `src/StarterPlayer/StarterPlayerScripts`: client scripts.
- `src/StarterGui`: UI assets and scripts.
- `tests/`: future automated tests.
- `packages/`: future package-managed dependencies.

## Local Setup

Required:

- Roblox Studio
- Rojo
- Git

Recommended later:

- StyLua for formatting
- Selene for linting
- Wally for package management
- TestEZ or another Luau test setup when pure logic modules exist

## Development Loop

1. Define or refine the feature in docs.
2. Give Codex one scoped task.
3. Edit source files in the repo.
4. Sync into Roblox Studio with Rojo.
5. Playtest in Studio.
6. Record bugs, decisions, or playtest notes in `docs/`.
7. Commit working changes to Git.

## Safety Rules

- Keep gameplay-critical logic server-authoritative.
- Treat client remote payloads as untrusted.
- Do not modify DataStore, economy, purchases, or monetization systems without explicit approval.
- Prefer small, reviewable changes over large rewrites.
