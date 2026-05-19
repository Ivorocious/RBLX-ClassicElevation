# AGENTS.md

## Project Context

This is a Roblox Luau project.

The intended workflow is AI-assisted development:

- ChatGPT project chat is used for planning, game design, architecture, and decisions.
- Codex is used for scoped implementation, refactoring, debugging, and review.
- Roblox Studio is used for visual editing, assembly, playtesting, terrain, UI layout, and asset work.
- Rojo keeps filesystem source synchronized with Roblox Studio.
- Git is the source of truth for scripts, documentation, configuration, and project history.

## Project Rules

- Inspect the repository and, when relevant, the active Roblox Studio hierarchy before editing.
- Prefer small, reviewable changes over large rewrites.
- Prefer modular ModuleScripts over giant scripts.
- Keep gameplay-critical logic server-authoritative.
- Never trust client input for currency, damage, inventory, progression, rewards, purchases, matchmaking, or unlocks.
- Keep RemoteEvents and RemoteFunctions inside `ReplicatedStorage/Remotes`.
- Shared constants and tuning values belong in `ReplicatedStorage/Shared` or `ReplicatedStorage/Config`.
- Use clear service names such as `PlayerDataService`, `RoundService`, `InventoryService`, `CombatService`, and `EconomyService`.
- Do not delete existing files, scripts, or Roblox instances unless explicitly instructed.
- Do not make destructive Studio edits without explaining the risk first.
- Do not create large systems without updating the relevant documentation.
- Do not modify DataStore, economy, monetization, purchases, or security-sensitive systems without explicit approval.

## Rojo and Source of Truth

- Filesystem source should be treated as the durable source for scripts.
- Prefer editing repository files that Rojo syncs into Studio.
- Avoid script-only edits directly in Studio unless the user explicitly requests them.
- If a temporary Studio edit is made through MCP, clearly say whether it must be mirrored back into the repository.
- Keep `default.project.json` aligned with the intended Roblox hierarchy.
- Do not assume an instance exists in Studio just because a matching folder exists in the repository; inspect when needed.

## MCP and Roblox Studio

- Before modifying Studio through MCP, verify the active Studio instance is the intended experience.
- Read-only MCP inspection is allowed for hierarchy, properties, scripts, screenshots, and project state.
- Safe MCP edits may include creating folders, scripts, ModuleScripts, RemoteEvents, RemoteFunctions, and simple test objects when instructed.
- Risky MCP edits require explicit user approval. Risky edits include deletes, large hierarchy moves, mass script edits, DataStore changes, economy changes, monetization changes, RemoteEvent security changes, publishing, or irreversible actions.
- Never publish the Roblox place through automation unless the user explicitly asks for that action.

## Code Style

- Use Luau.
- Prefer typed Luau where practical.
- Use descriptive function and variable names.
- Avoid global variables.
- Keep client UI logic separate from server gameplay logic.
- Keep gameplay-critical validation on the server.
- Keep modules focused and readable.
- Avoid hidden side effects in shared modules.
- Favor explicit configuration over magic numbers in gameplay code.

## Networking and Security

- Treat every RemoteEvent and RemoteFunction as untrusted input from the client.
- Validate player identity, distance, cooldowns, ownership, permissions, inventory, currency, and state transitions on the server.
- Do not let clients directly set currency, damage, rewards, inventory, progression, purchases, or authoritative game state.
- Document expected remote payloads and server validation for new networking systems.

## Documentation

- Update documentation when adding important systems, changing architecture, or making decisions that affect future work.
- Record important technical decisions in `docs/DECISIONS.md`.
- Track known bugs in `docs/BUGS.md`.
- Track implementation tasks in `docs/TASKS.md`.
- Add playtest findings to `docs/PLAYTEST_NOTES.md`.
- Keep documentation concise and practical.

## Testing and Verification

- Include test steps after implementation.
- Use Studio playtesting for gameplay behavior.
- Use focused unit tests where practical for pure logic modules.
- Run available linting, formatting, type checking, or test commands when they exist.
- If verification cannot be run, explain what was not verified and why.

## Codex Workflow

- Start by inspecting relevant files and current project state.
- Explain planned changes before destructive edits.
- Keep changes scoped to the requested task.
- Summarize changed files and behavior after implementation.
- Include manual test steps or automated test results.
- Do not continue into unrelated feature work without a new scoped task.
