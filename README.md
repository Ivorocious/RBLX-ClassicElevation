# ProjectClassicElevation

Classic Ascent version 3 has **integrated mountain terrain, active obby hazards, safe staging, and a course sky** on the rebuild branch.
Human visual acceptance, pacing, and multiplayer validation remain outstanding;
see [current status](docs/CLASSIC_ASCENT.md).

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
- `tests/studio/`: Studio-only traversal and recovery checks.
- `packages/`: future package-managed dependencies.

## Local Setup

For the September Classic Ascent build, use Rojo **7.7.0** on both the CLI and
Studio plugin. The machine's older `rojo` command may still resolve to 7.6.1.
The project-local executable (ignored by Git) can be started with:

```powershell
./.tools/rojo-7.7.0/rojo.exe serve default.project.json
```

Obtain the matching Windows executable from the
[official release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0) if absent.
Connect the Studio plugin to `localhost:34872`. Keep only one Rojo server running
on that port. See [Classic Ascent](docs/CLASSIC_ASCENT.md) for course authoring,
timing targets, and human acceptance tests.

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
