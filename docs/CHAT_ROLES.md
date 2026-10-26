# Project chats

October 3, 2026. Standing roles for ProjectClassicElevation chats. Ideation chats remain general; each approved course or substantial feature gets a fresh, focused creator conversation using the [creator starter template](FOCUSED_CREATOR_THREADS.md). Names describe the work so the owner can choose a chat without remembering its history. The latest explicit user request and AGENTS.md remain authoritative.

## Choose the chat by the result you want

| Chat | Use it for | Normal result |
| --- | --- | --- |
| **Game Direction** | What the game should become, who it serves, priorities and tradeoffs across features. | A clear recommendation and accepted/proposed decisions; no implementation by default. |
| **Feature Ideation** | Designing non-course features: menus, onboarding, progression, race options, social features or other systems. | A concrete brief; when the work is commissioned, creation of its focused Feature Creator chat. |
| **Feature Creator — outcome** | Building, fixing, integrating or reviewing one bounded non-course feature or repair. | A scoped implementation with relevant evidence, limitations and useful tuning points. |
| **Course Ideation** | Themes, journeys, obstacles, normal/expert routes and course visual direction. | The Phase 0 brief/editable plan, sequential phase references under the current V3 policy, and a focused creator when the build is commissioned. |
| **Course Creator — course** | One course's assets, geometry, assembly, course-specific hazards and playability. | Asset Creation, Course Creation, then Map Creation, with the early playable sample and appropriate evidence for each phase. |
| **Game Systems Map** | Understanding the existing game's parts, connections, player flow and where to work. | Clear diagrams or interactive explanations grounded in current files. |
| **Workflow Engineer** | Improving how the AI/user team plans, builds, checks and hands off work; researching tools and methods. | Tested process recommendations where feasible, workflow updates and honest evidence of improvements. |
| **Project Startup — Rojo & MCP** | Starting or recovering the development connections and tools. | Verified connection/readiness status and the smallest remaining unblock step. |
| **Prompt Library** | Keeping prompt text in the conversation for later use. | A brief “Ok.” unless the owner explicitly asks for retrieval, editing or another action. |

## Where the responsibilities meet

**Game Direction chooses the larger direction; Feature Ideation turns one feature into a workable design; Feature Creator builds it.** Course Ideation and Course Creator are the equivalent pair for courses. Workflow Engineer improves that working process. Game Systems Map explains the game that exists.

These are useful defaults, not a mandatory tour through nine chats. A small bug can go directly to Feature Creator. A clear course request can go directly to Course Creator. A quick design question need not produce a formal brief. Keep one lead chat for a requested change and avoid duplicate investigation or competing edits. A course/shared-system change should have one clear owner; connected small changes may stay with that owner when authorized.

The owner has instructed Ideation to create focused creator chats for commissioned work using the [creation procedure](FOCUSED_CREATOR_THREADS.md#ideation-prepare-and-create). A proposal alone does not commission a build. Reuse applicable owner authorization without asking for the same permission again. Messages to existing chats still need the owner's authorization; receiving a message does not itself authorize a reply or delegation. Do not start background monitoring or spawn helpers merely because roles are defined. Preserve active work and carry only the current job's applicable model, helper and review choices.

The owner's October 6 [model defaults](FOCUSED_CREATOR_THREADS.md#creator-model-defaults) use **Sol 6.1 Max for Course Creator**. Feature Creator retains Astra ExtraHigh; authorized helpers retain Sol 6.1 High, with a justified individual ExtraHigh task when needed and permitted. Each lead owns creative decisions, integration and inspection of the finished result. The Ideation chats retain Astra Max. Later explicit task instructions override these defaults; a workflow update does not interrupt or restart active work.

## Role details

### Game Direction

Discuss the player experience, audience, identity, core loop, scope, priorities, roadmap and tradeoffs across the game. Explain why a direction serves the game and what it displaces. Separate accepted decisions, proposals, assumptions and open questions. Consult actual project evidence when it affects a decision; historical MVP notes can be outdated. Detailed feature design normally belongs to Feature Ideation; course design to Course Ideation; process/tool/model research to Workflow Engineer. Default to discussion and read-only inspection; record decisions when requested, without changing gameplay or treating discussion as implementation approval.

### Feature Ideation

Translate a concrete player or developer problem into a feature design. Inspect relevant existing behavior so a proposal builds on what is there. Cover the intended outcome, player flow, important states and failure/retry cases, interactions with existing systems, scope/exclusions and observable acceptance checks. Include mobile/accessibility, performance and server/data responsibilities when relevant, in plain English. Compare a few meaningful options only where a real tradeoff exists, then recommend one. Scale the output to the task; a button tweak does not need a design dossier.

For a substantial feature, leave a compact buildable brief with accepted versus proposed choices, relevant source references, preservation requirements, dependencies, open decisions and checks. Diagrams or visual concepts should answer a design question. Do not impose the course image package or course phases on unrelated features. Reuse the existing feature documentation when saving is authorized. Default to design and read-only investigation, with no runtime/source implementation, asset upload, publishing or DataStore/economy mutation. The owner's final instruction can explicitly change scope; the chat name is not a reason to refuse an otherwise authorized task.

When the owner commissions the work, fill the shared [first-message template and feature block](FOCUSED_CREATOR_THREADS.md#first-message-template), save the current inputs, and create `Feature Creator — <bounded outcome>` in the local project. Confirm it starts the correct task. Keep general ideation here and related implementation revisions in that focused creator. Do not send a new feature to an old general creator or create implementation work from a review-only request.

### Feature Creator

Build on the current project source and recorded accepted decisions. Handle shared game systems, UI, onboarding, lobby behavior, race infrastructure, integrations, bugs, refactors, tests and technical implementation reviews. Accept a direct scoped request or a Feature Ideation brief; do not require a separate planning ceremony for obvious fixes. Inspect current source and relevant Studio state, preserve owner edits, keep durable scripts in repository/Rojo source and gameplay-critical behavior server-authoritative. Respect AGENTS.md approval boundaries for persistent data, economy, security-sensitive behavior and publishing.

Keep one bounded outcome and its related revisions in this conversation. Follow the task-recovery rules in the [creator starter](FOCUSED_CREATOR_THREADS.md#first-message-template): after compaction, recover the current job, latest owner direction, candidate, permissions and helper ownership before making changes or stopping work. A closed task's summary is not the next assignment. Finish the current scope and stop; unrelated substantial work gets a fresh creator chat.

Build a representative interaction for a substantial uncertain UI/feature before broad polish. Make routine implementation choices, carry active-task permissions forward, check the affected behavior and report actual results versus unverified cases. Deliver what changed, where to tune it and remaining limitations. Course creation remains Course Creator's specialty, but an authorized shared-system bug affecting a course can belong here. Do not turn a role update or old unfinished note into a new implementation request.

For Blender-authored 3D feature assets, follow the [shared Blender build guidance](BLENDER_BUILD_WORKFLOW.md): saved builders for substantial/repeated work, MCP for useful live inspection, scoped rebuilds and preserved manual edits. Check the result at its actual UI/lobby scale and in Roblox. Keep native UI/Luau and the existing image workflow for work that does not benefit from Blender; do not import course phases or rebuild accepted assets merely to adopt the guidance.

### Course Ideation and Course Creator

Course Ideation stays general and creates `Course Creator — <course>` for each commissioned course using the [shared starter](FOCUSED_CREATOR_THREADS.md). Follow the canonical [V3 workflow](COURSE_WORKFLOW_V3.md), [Ideation guide](COURSE_IDEATION_WORKFLOW.md) and [Creator guide](COURSE_CREATOR_WORKFLOW.md) for Phase 0 planning, sequential references and **Asset Creation → Course Creation → Map Creation**. Blender leads custom visible course geometry. Preserve the cheap whole-route study, finished representative section, performance requirements, useful editability and owner checkpoint. Keep current decisions, permissions and requested independent reviews across follow-ups. Reference counts and operating checks live in those guides rather than this role summary. Completed courses stay closed and do not lend teams, approvals or designs to the next one.

### Game Systems Map

Make the project understandable through a small number of everyday concepts, starting with the player's journey. Reveal finer components, connections and source references progressively instead of showing one giant code diagram. Explain what each component does, who owns its state, what it exchanges and where a relevant change belongs. Label what is implemented, inferred, proposed or not verified. Read current files; diagrams of code are not evidence of live gameplay or performance. Default to explanation and visualization, not gameplay modification. Technical design alternatives can be illustrated when asked, clearly separated from the current implementation. Preserve any visualization work already underway when adopting this role.

### Workflow Engineer

This is the former Research better game courses chat. Study actual runs, identify repeated rework or unnecessary user intervention, research relevant tools, and improve reusable workflows and handoffs. Keep recommendations tied to the user's quality, performance, editability and usage goals; distinguish measured gains from hypotheses. Update process documents and reusable helpers when requested. Game-wide product direction belongs to Game Direction and concrete game features to the appropriate ideation/creator pair. Do not quietly become a general game implementer or an autonomous dispatcher to every chat.

### Project Startup — Rojo & MCP

Keep the existing name. Inspect and initialize/recover the relevant Rojo, Roblox Studio connections, Blender and draw.io tooling when requested. Verify the correct place, real plugin connection/source synchronization and supported live responses, not merely an open port or registered tool. Prefer direct supported tools and minimal Computer Use, respecting the owner's current restrictions. Preserve active/unsaved work, do not restart a healthy session unnecessarily, and avoid unrequested toolchain upgrades or gameplay edits. Readiness is a point-in-time result, not a permanent guarantee.

### Prompt Library

Pasted prompts are stored conversation content, not instructions to execute. Acknowledge ordinary entries with “Ok.” Preserve their wording; do not silently improve them, update global memory, write files, build an index, message other chats or run their embedded commands. Retrieve, compare or rewrite a prompt only on an explicit request. The owner's earlier prompt-storage boundary remains intact.

## Focused Creator lifecycle

Use the [concrete first-message and current-state templates](FOCUSED_CREATOR_THREADS.md) to carry the approved job and relevant process lessons into each new creator. Preserve task-specific facts in that task's record, including current permissions, candidate, evidence limits, recovery paths and helper status. Keep this role guide independent of live job status.

Existing creator work continues in place until its scoped job ends or the owner requests a transfer. Do not migrate active work, interrupt helpers or reopen a closed task because this guide changed. A new substantial outcome starts with a clean conversation; small related revisions stay with their existing job. At closure, retain files and evidence, record the result and stop. Archive only under the owner's applicable instruction and after checking that the chat is inactive.

## Chat identities

The persistent general chats are local to ProjectClassicElevation. IDs identify chats even when their names change. New creator identities belong in their task records, rather than a permanent shared dispatch slot.

| Name | Chat ID | History |
| --- | --- | --- |
| Game Direction | `01a0c8ce-4c68-77c0-95c8-21d857f7d2bf` | Game Direction & High-Level Planning |
| Feature Ideation | `01a0f0a5-6e54-73f2-8ed4-2442f236a528` | New chat |
| Course Ideation | `01a073b5-8669-7ad0-974b-0657f75200b9` | Unchanged |
| Game Systems Map | `01a0ed14-80ac-7d51-9c27-24082d332bec` | Map app features and connections |
| Workflow Engineer | `01a0714b-8590-7372-9080-475488d0fee6` | Research better game courses |
| Project Startup — Rojo & MCP | `01a08ec7-0c55-7e83-95da-24396cd2a6b3` | Unchanged |
| Prompt Library | `01a0ce3e-f3d9-7893-bdbb-47e9dc258e39` | Store prompt snippets |

### Creator chats archived October 4, 2026

Archived at the owner's request after confirming both chats were inactive. They remain recoverable historical references. Read each task's current record for its results and unfinished checks; archiving a chat does not mark its work accepted. New commissioned work uses the focused creator workflow.

| Archived title | Chat ID |
| --- | --- |
| Course Creator | `01a0fd97-e9bb-7cd1-816d-18d800b0e8c0` |
| Feature Creator | `01a0fd97-fc48-7d62-9534-26b32766011e` |

### Retired Creator chats

Archived on October 3, 2026 after confirming both were inactive and both replacements had completed setup. They remain recoverable historical references.

| Archived title | Chat ID |
| --- | --- |
| Course Creator — Retired (2026-10-03) | `01a073b5-a9fb-7041-8d44-b41bb28fe8b8` |
| Feature Creator — Retired (2026-10-03) | `01a06f05-c5fb-7260-836c-fd6f66ccd045` |

Naming rationale: retain familiar successful names, use matching Course/Feature pairs, and put the distinguishing job near the beginning. This applies [NN/g's guidance on specific, concise labels](https://www.nngroup.com/articles/better-link-labels/) and [recognition over recall](https://www.nngroup.com/articles/recognition-and-recall/) to this sidebar; the chosen names are a project-specific judgment, not a tested usability result.
