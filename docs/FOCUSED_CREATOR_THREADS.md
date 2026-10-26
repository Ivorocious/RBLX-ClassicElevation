# Focused creator chats

October 3, 2026. Course Ideation and Feature Ideation remain general planning chats. Each approved course or substantial feature gets a fresh creator conversation containing that job and its related revisions. Ideation creates the chat with a complete first message; the owner should not need to copy a handoff into a general creator chat.

The owner's standing instruction is: “Tell the Ideation chats that they will no longer be doing 'handoffs' instead they will be 'creating threads'.” This authorizes that creation step when the owner has commissioned the particular work. Discussion, an unaccepted proposal or a request for a brief alone does not authorize implementation. Current owner instructions and AGENTS.md govern scope.

## Creator model defaults

October 6, 2026 owner-approved course update: **Sol 6.1 Max leads Course Creator; Sol 6.1 High remains the default for authorized helpers.** This replaces the October 4 Astra course-lead selection. Feature Creator retains Astra ExtraHigh, and both Ideation chats retain Astra Max.

| Role | Model and reasoning | Responsibility |
| --- | --- | --- |
| Course Creator lead | `gpt-6.1-sol`, `max` | Interpret references, make creative and technical decisions, integrate the work and inspect the actual result against the brief. |
| Feature Creator lead | `gpt-6-astra`, `xhigh` | Own the bounded feature, its decisions, integration and final inspection. |
| Creator helpers/reviewers | `gpt-6.1-sol`, `high` by default | Clearly bounded code, asset, repair or verification tasks with explicit ownership and checks. |
| Exception for a difficult helper task | `gpt-6.1-sol`, `xhigh` when justified | Escalate an individual demanding task with a concrete reason, within the owner's current permissions and any stricter effort cap. |

The creator lead remains responsible for the design and the finished result, including actual Studio views where relevant. It should not delegate all creative decisions or accept helper completion claims without inspecting the integrated candidate. Use helpers only where substantial independent work benefits; keep the current job's count, roles and review conditions. The model defaults do not require helpers for every task or inherit another job's team or score threshold.

Apply these defaults to newly created creator chats and future owner-authorized continuations, unless the owner gives a different selection. Preserve active turns and helper work; this announcement does not interrupt, restart or migrate an ongoing build. Keep the focused-chat and task-recovery rules. Judge the setup by first-pass quality, missed requirements, correction rounds and time to an acceptable result; improvements in speed, usage or reliability are not yet measured.

## Ideation: prepare and create

1. **Define one outcome.** Use `Course Creator — <course>` or `Feature Creator — <bounded feature or repair>`. Related corrections stay with that job. A different course or unrelated substantial feature gets a new conversation, without forking old creator history. Do not split every small fix into a new chat or open duplicate creators for the same job.
2. **Reconcile the inputs.** Inspect the current brief, selected references and relevant source. Resolve superseded directions in the actual files. Distinguish accepted choices, proposals and unknowns. Fill the starter below from evidence, including the latest owner approval and any later limits or overrides. Save the filled first message as `CREATOR_START.md` in the existing task artifact folder. Preserve older files named `HANDOFF` as historical records; their names do not make them dispatch instructions.
3. **Prepare one current-state record.** Reuse the task's existing brief/status record or `CURRENT_STATE.md`; do not create competing status files. Record the exact path in the starter. Initially identify what is approved, what has actually been inspected, what remains unverified and the first action. Keep live job status here, outside shared role guides.
4. **Create the local project chat.** Call `list_projects` and select the returned ProjectClassicElevation project. Use `create_thread` with the filled prompt, focused title and local project target. Use a worktree or cloud destination only when the owner requests it. Apply the role's defaults explicitly: Course Creator uses `model: gpt-6.1-sol`, `thinking: max`; Feature Creator uses `model: gpt-6-astra`, `thinking: xhigh`. A newer task-specific owner selection overrides them. Record the choice in the starter and explicitly specify `gpt-6.1-sol` with `high` for authorized helpers so they do not inherit the lead's effort. Follow the available delegation tool's model/context rules and give helpers compact task-specific inputs. Never copy a previous job's helper count, review scores or permissions.
5. **Verify startup.** Save the returned creator ID and creation time in the task record. Creation returning an ID does not prove work began. Use `wait_threads` with bounded waits and its returned cursor to confirm the creator started the correct job or report its actual blocker. A pending `clientThreadId` is not a usable `threadId`; wait for setup to resolve. If creation has an uncertain outcome, inspect the returned status and existing chats before retrying. Emit the app's created-thread directive using the returned ID in the final response.
6. **Return to ideation.** Report the focused chat and its actual startup state. Do not duplicate its implementation, start recurring monitoring, or dispatch other chats. Later messages to an existing creator require the owner's applicable messaging authorization; creation does not grant the creator permission to message back or contact other chats. A normal first reply in the created chat is sufficient.

Existing work continues in its current creator until that scoped job ends or the owner requests a transfer. This change does not relocate an active build, interrupt its helpers, reopen a closed task, or create a replacement solely because a guide changed.

## First-message template

Fill every bracketed field, remove inapplicable options, and append the matching course or feature block below. Use the stated model defaults unless a newer explicit owner selection applies; replace the relevant line and name its source when overriding it. Use short concrete facts and exact paths; do not paste old conversation summaries or whole workflow documents. `Start mode` must match the owner's request: begin the authorized work, review only, or setup and standby. A build commission must not accidentally become an acknowledgement-only task.

```text
You are [Course Creator — name / Feature Creator — outcome], responsible only for [one concrete outcome] and its directly related revisions in this conversation.

PROJECT AND TASK
Project: C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation
Task ID: [stable task identifier]
Start mode and first action: [authorized work / review only / setup and standby; exact next action]
Done means: [observable completion requirements, required evidence and owner review condition]
Current-state record: [absolute path; use this single record]
Planning chat: [title and ID, for provenance; no permission to message it is implied]

OWNER DIRECTION AND PERMISSIONS
Latest request/approval: [date, source chat and short exact excerpt or faithful summary]
Accepted choices: [current decisions; distinguish proposals and open questions]
Authorized scope and operations: [precise implementation/review scope, uploads/imports/destination and testing permissions where relevant]
Limits and preservation: [excluded systems, manual edits, original assets and other active work]
Required checkpoint: [what must be shown; accepted or explicitly waived only with the owner's evidence]
Lead model/effort: [Course Creator: GPT-6.1 Sol Max (gpt-6.1-sol, max), October 6 default; Feature Creator: GPT-6 Astra ExtraHigh (gpt-6-astra, xhigh), October 4 default. Keep the applicable choice, or record the owner's newer selection and its source.]
Helpers/reviewers: [current job's authorization, roles, review conditions and any owner-specified count/cap, including nested agents where applicable; or none authorized]. Do not invent a count/cap or reuse a completed job's team. Authorized helpers use GPT-6.1 Sol High (gpt-6.1-sol, high); an individual difficult task may use xhigh with a concrete reason within current permissions and any stricter effort cap. Record any newer explicit override.

CURRENT INPUTS
Read AGENTS.md, this task's current-state record, and [exact current brief/source/reference paths and revisions]. Read the relevant role in docs/CHAT_ROLES.md and the process block below. Inspect actual referenced images when appearance matters. Resolve obsolete instructions against newer owner directions.
Source of truth: [which files define behavior/layout; which images only guide appearance; known revision compatibility]
Current candidate/live target: [exact identity or not built; last observation and limits]
Recovery/source locations: [existing editable source, native originals, backups and receipts, or what to capture before a risky change]
Known defects, unknowns and first checks: [only current issues relevant to this job]

WORKING RULES
Start by confirming this task, its current phase/candidate, permission boundaries and next action in one short update. Inspect current files and, when relevant, the intended Studio place before editing. Preserve unrelated changes. Keep durable script work in repository/Rojo source, verify actual synchronization and keep gameplay-critical decisions on the server.

After compaction, interruption or a model change, FIRST recover this task's current-state record and latest owner corrections. Compare task identity, phase, candidate, permissions, helper ownership and next action before editing, importing, starting a mutating test or stopping any helper/process. Historical summaries and closed-task notes are reference material. They cannot replace this job with an older one. Recheck the live facts needed for the next operation. If the record is stale, reconcile it with the latest owner request and current evidence; ask only about a real unresolved conflict while continuing independent safe work.

Replace the same compact record's current facts after material decisions, candidate changes, checks, interruptions and closure. Link older milestones in their existing reports instead of accumulating superseded holds under current-status headings. Include in-flight operations/receipts and helper assignments/status so resuming does not duplicate uploads or stop unrelated work. Keep full logs and recipes in files; request focused results and read only relevant history.

Make routine choices and complete already-authorized work without repeated continue prompts. Use small comparisons for costly uncertainty, then commit to a direction. Save a recoverable candidate before risky replacement and patch only affected objects/dependencies. One controller owns live interaction with a given Studio window (and with Blender); a parallel job uses its own window on the second Rojo port; helpers work within explicit ownership and the current authorization cap. Check a queued or timed-out mutation's status and live result before retrying it.

The lead owns creative decisions, overall implementation and final quality. Inspect selected references and actual integrated results personally; give helpers bounded assignments and review their outputs. Explicitly set the authorized helper model and effort at every spawn; use High by default and raise only a specifically demanding task to ExtraHigh when justified and permitted. A changed lead setting must not silently raise helper effort.

Use proportional checks against the actual candidate. Separate source/static checks, Studio appearance, continuous gameplay, human acceptance and real device/multiplayer performance. A concept image, isolated probe, score or object count cannot stand in for missing evidence. Reviewers, if authorized, inspect the same frozen candidate; fix concrete failures without chasing scores or borrowing old results.

Deliver changed behavior, exact source/candidate/recovery paths, checks actually run, unresolved limits, useful tuning points and the smallest next action. Verify claimed outputs exist and state whether the whole Studio place was saved. Finish this scope and stop; a different job belongs in a new creator chat. No publishing or unrelated work is implied.
```

## Append for a course

```text
COURSE PROCESS
Use docs/COURSE_WORKFLOW_V3.md and docs/COURSE_CREATOR_WORKFLOW.md as the canonical phase, build and verification rules. Quality comes first; reduce rework and unnecessary testing. Blender is the main authoring tool for custom visible course assets/geometry; use docs/BLENDER_BUILD_WORKFLOW.md for substantial authored work.

Current brief / editable plan / reference index: [exact paths, revisions and compatibility; identify selected current-phase master and final-world target]. The brief governs requirements, the plan governs connections, and images guide appearance. Follow the current sequential reference policy and explicit owner exceptions; do not reconstruct an old image package.

Authorized phase(s) and result: [asset/sample, complete playable course or finished world; required evidence versus optional/future checks].
Player-visible qualities and comparison: [three concrete traits; accepted example; what the owner liked and what should change].
Preserve / rejected approaches: [accepted assets, gameplay/manual edits and known unwanted fixes].
Section actions and choices: [ordinary obstacle sequences, signatures, Normal/Expert demands and reward; required encounters/checkpoints].
Race/runtime targets: [format/laps, capacity, timing definitions, devices/assumptions; existing entry/progression/recovery/finish/exit flow].
Early study and owner checkpoint: [rough whole-route uncertainty; representative ordinary sequence, branch, signature, art/feedback risk; checkpoint accepted/required/explicitly waived].
Current correction and next proof: [specific observed failure or missing result; smallest useful check].

Keep the current record editable and freeze a snapshot only when needed. Review the weakest sequence and whole installed composition before scoring. Select checks from what changed; cover real branch progression and finish without automatically rerunning every combination or lifecycle case. Missing required native appearance remains pending. Preserve the requested independent reviewers, current permissions and explicit helper model/effort. No additional review layer or new course is authorized by this template.
```

## Append for a feature or repair

```text
FEATURE PROCESS
Read the Feature Creator role in docs/CHAT_ROLES.md and the current feature brief. Inspect existing behavior and use the project's established modules, interfaces and source ownership. Implement only this outcome: [player/developer problem and expected behavior].
Affected flow and states: [entry, normal operation, failure/retry, exit; relevant late join/respawn/round changes].
UI/visual reference and editable outputs, if relevant: [selected reference, actual display size, required source and preserved interactions].
Integration boundaries and preservation: [specific services/remotes/UI/native models and interfaces to keep].
Acceptance checks: [observable cases and any owner-selected review conditions].

For a substantial uncertain feature, prove one representative interaction or repair before broad polish. For UI, inspect the actual visible result at relevant sizes and test input, layering, native safe areas and state transitions. For 3D assets, use docs/BLENDER_BUILD_WORKFLOW.md when applicable and verify real lobby/player scale, joins, collision and editability in Studio. Course image packages and course phases do not apply to ordinary features.

Keep critical state and validation on the server. DataStore, economy, purchases and security-sensitive changes need their applicable explicit scope; an adjacent UI task does not expand that scope. Preserve originals and owner edits before scoped repairs, record a clear restore path, and check affected behavior plus direct dependencies. Keep owner visual acceptance, local functional evidence and device/multiplayer evidence distinct. Finish this bounded job without resuming an old feature backlog.
```

## Compact current-state template

Use these fields in the existing task record; omit irrelevant detail. Replace stale facts rather than appending an endless transcript; link historical milestones separately.

```text
Task ID / focused title / creator chat ID / updated date:
Status and phase / latest owner instruction and source:
Current outcome / accepted decisions / superseded directions:
Brief, layout, visual and candidate revisions / compatibility:
Authorized operations / exclusions / checkpoint or explicit waiver:
Lead and helper/reviewer settings / assignments, ownership and status:
Live target / source and native ownership / owner edits to preserve:
Completed work and evidence paths / what each check actually proves:
Open defects, unverified checks and current blocker:
In-flight operations, IDs and receipts / recovery paths:
Next concrete action / completion and owner-acceptance status:
```

Focused chats reduce the amount of unrelated history. They still need reliable task recovery after compaction; this workflow is a safeguard, not a promise that errors cannot occur.
