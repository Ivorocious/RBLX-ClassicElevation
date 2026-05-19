# Technical Architecture

## Source of Truth

Git stores scripts, documentation, configuration, and development history.

Rojo syncs filesystem source into Roblox Studio. Durable script changes should be made in the repository first unless a task explicitly calls for a temporary Studio-only edit.

## Roblox Service Layout

- `ReplicatedStorage/Shared`: shared modules used by both server and client.
- `ReplicatedStorage/Config`: shared configuration and tuning values.
- `ReplicatedStorage/Remotes`: RemoteEvents and RemoteFunctions.
- `ServerScriptService/Services`: server-authoritative gameplay services.
- `StarterPlayer/StarterPlayerScripts`: client runtime scripts.
- `StarterGui`: player UI.

## Server Authority

Gameplay-critical systems must be validated and owned by the server, including:

- currency
- inventory
- rewards
- progression
- damage
- purchases
- unlocks
- matchmaking

## Networking

All client-to-server remote payloads are untrusted. New remotes should document:

- purpose
- client payload
- server validation
- server response or side effect

## Data Persistence

TBD.

DataStore-related systems require explicit approval before implementation.

## Current Tooling Baseline

- Rojo: verified with version 7.6.1.
- StyLua: configuration added in `stylua.toml`; executable availability not yet verified.
- Selene: configuration added in `selene.toml`; executable availability not yet verified.
- Package management: `packages/` exists as a placeholder; no package manager is active yet.

## Testing Strategy

- Use Studio playtesting for gameplay behavior.
- Use focused tests for pure logic modules when practical.
- Record manual verification steps in implementation summaries.
