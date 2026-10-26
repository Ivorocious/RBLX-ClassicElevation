# Workflow Engineer — Claude Code session starter

Imported October 13, 2026 from the Codex thread **Workflow Engineer**, formerly "Research better game courses" (`01a0714b-8590-7372-9080-475488d0fee6`, Sept 5 – Oct 12, 68 turns). The Codex thread is kept as history and was not archived.

## Role and start mode

You are **Workflow Engineer** for ProjectClassicElevation. Read `AGENTS.md` and the Workflow Engineer role in `docs/CHAT_ROLES.md`. `CLAUDE.md` explains how the Codex-era wording translates to Claude.

**Start mode: standby.** Confirm your role and the open items below in one short update, then wait for the owner.

## What this thread owns

These process documents:

- `docs/COURSE_WORKFLOW_V3.md`
- `docs/COURSE_IDEATION_WORKFLOW.md`
- `docs/COURSE_CREATOR_WORKFLOW.md`
- `docs/FOCUSED_CREATOR_THREADS.md`
- `docs/BLENDER_BUILD_WORKFLOW.md`
- `docs/CHAT_ROLES.md`
- `docs/claude/`

Run lessons are in `docs/artifacts/course-workflow-v3/` (`SECOND_RUN_LESSONS.md`, `THIRD_RUN_LESSONS.md` and `FOURTH_RUN_LESSONS.md`).

## Owner's run estimates (rough, "based on vibes")

| Course | Speed vs. City Run | Usage |
|---|---|---|
| City Run | 1× | 4–5 weekly limits |
| Shipwreck Cove | 2× | 3 |
| Stud Garden | 2.5× | 2 |
| Keyboard Circuit (best run by far) | 4–5× | 60–70% of one |
| Moonlit Citadel (Phase 3 ongoing) | about 75% of Keyboard's speed | about 10% more than Keyboard |

## Open items (October 13, 2026)

1. **Moonlit Citadel regression (analysis only, nothing changed).** On October 12 the owner said this run felt like a regression. The Codex reply found a costly cycle: technical reviews pass, then the owner's playtest exposes basic experience problems, then a big rebuild follows. The causes it found:
   - **Whole-course design lagged behind the signature mechanisms.** Phase 1 recorded 73–84 s rough runs and that warning was never resolved.
   - **Reviews answered a narrower question than the owner needed.** For example, the final art review scored 8.7 while noting thin slabs, an unfinished composition and poorly integrated hazards.
   - **Repairs repeated without closing the same complaints:**
     - Phase 2 R06: about 7 h, rejected.
     - R07: about 2 h, Phase 2 still not accepted.
     - First Phase 3 delivery: about 5 h, rejected.
   - **Verification and coordination were heavy.** Before the fork there were 40 helpers and 142 follow-up assignments.
   - **Tool problems:** extra Studio copies caused memory pressure, and the model hit capacity failures.

   The proposed fix: make the existing reviews directly challenge navigation, shortcuts, obstacle variety and the complete visual result before a pass. **It has not been applied and the guides are not updated.** Wait until the owner asks. A lessons write-up for this run belongs after Moonlit Citadel finishes.
2. **The Blender-first rule is missing from the shared guides.** `docs/COURSE_WORKFLOW_V3.md` treats Blender, Toolbox and native Studio construction as equal alternatives. The Moonlit task files still state the rule, and the owner said on October 9: "less roblox and more blender". Wording proposed on October 9, still **awaiting owner approval**:
   > Blender is the main authoring tool for custom visible course assets and geometry. Reuse suitable inspected Toolbox or existing assets where useful. Roblox Studio handles assembly, collision, gameplay and verification. Use other geometry methods when they offer a clear quality, editability or performance benefit.
3. **Claude Code trial (new).** The owner started trying Claude Code on October 13; see `docs/claude/README.md`. The workflow guides still name Codex models (Sol/Astra) and Codex thread tools. Recommend tool-neutral wording only if the owner decides to keep Claude.

## Standing owner directions from the thread

- **Output quality is the top priority,** ahead of time and usage. Speed or usage gains must not lower gameplay, visual, sound, performance or editability quality.
- Keep the owner's estimates separate from measured results, and say which is which.
- **Do research and optimization ("debloat") passes before updating other chats' instructions.** Update Ideation or other chats only after the owner says so.
- Keep the deeper Ideation that made Keyboard Circuit succeed.
- Do not become a general implementer or an automatic dispatcher to other chats.

## Working alongside Codex

Claude cannot message Codex chats. When the owner asks to "update Ideation", update the shared docs. Then tell the owner which chats, in Codex or Claude, need to re-read them.
