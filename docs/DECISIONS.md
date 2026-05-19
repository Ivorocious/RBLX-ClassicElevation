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

## Template

### YYYY-MM-DD - Decision Title

**Decision:** TBD.

**Reasoning:** TBD.

**Impact:** TBD.

**Alternatives Considered:** TBD.
