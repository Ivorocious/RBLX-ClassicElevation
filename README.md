# ProjectClassicElevation

**City Run V3 is the active City Run editing source.** Edit `Workspace > Course_CityRun` with Play stopped, save the place, and Play uses those edits. Press **F6** for Studio testing tools. Start with the [map development workflow](docs/DEVELOPMENT_WORKFLOW.md) for editing, saving, map switching and the organized ServerStorage layout.

Classic Ascent V7 and retired City Run builds are now [archived outside the game](archive/retired-maps-2026-09-22/README.md). The native model files and source snapshot are preserved in Git; import them deliberately when needed again.

Classic Ascent is shelved (October 27, 2026). Its code was removed from `src` and kept in [archive/classic-ascent-shelved-2026-10-27](archive/classic-ascent-shelved-2026-10-27/README.md); the `docs/CLASSIC_ASCENT*.md` pages remain as history.

Roblox project baseline for building ProjectClassicElevation with filesystem-first source control, Rojo sync, and lightweight documentation for design and implementation work.

## Workflow

Use the [project chat roles](docs/CHAT_ROLES.md) to choose between game direction, feature/course design and creation, technical visualization, workflow improvement, startup and prompt storage. Ideation chats create a focused creator for each commissioned course or substantial feature using the [starter template](docs/FOCUSED_CREATOR_THREADS.md). Course work automatically follows [V3](docs/COURSE_WORKFLOW_V3.md): Phase 0 planning and sequential references, then Asset Creation → Course Creation → Map Creation. The linked guides define current reference counts, quality checks and Blender's primary custom-art role.

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

For both Roblox MCP connections, reboot recovery, and current verification limits, see [Roblox MCP setup](docs/ROBLOX_MCP_SETUP.md). The **Project Startup — Rojo & MCP** task should check both connections.


Use Rojo **7.7.1** on both the CLI and
Studio plugin. The machine's older `rojo` command may still resolve to 7.6.1.
The project-local executable (ignored by Git) can be started with:

```powershell
./tools/start_rojo.ps1
```

Keep this terminal session running. The launcher logs to `.tools/rojo-runtime/`,
prevents duplicate launches, and retries up to five consecutive early exits.
Closing its terminal or rebooting stops the session. If Rojo restarts, reconnect
the Studio plugin in Edit mode.

Obtain the matching Windows executable from the
[official release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1) if absent.
Connect the Studio plugin to `localhost:34872`. Keep only one Rojo server running
on that port. For a second Studio window (two agents playtesting at once), run
`./tools/start_rojo_second.ps1` on port 34873; see
[Roblox MCP setup](docs/ROBLOX_MCP_SETUP.md). See the [level design guide](docs/LEVEL_DESIGN_GUIDE.md) for course authoring.

Use one Studio plugin: the matching local `RojoManagedPlugin.rbxm`. Disable
the Marketplace Rojo copy in **Manage Plugins** to avoid duplicate toolbars,
then reopen Studio after changing the local plugin file. Previous plugin files
are backed up under `.tools/rojo-plugin-backups/` during an upgrade.

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

The floating lobby's source, Studio editing workflow and verification are documented in [docs/LOBBY.md](docs/LOBBY.md).

## Safety Rules

- Keep gameplay-critical logic server-authoritative.
- Treat client remote payloads as untrusted.
- Do not modify DataStore, economy, purchases, or monetization systems without explicit approval.
- Prefer small, reviewable changes over large rewrites.
