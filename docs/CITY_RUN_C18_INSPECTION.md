# City Run C18 inspection guide

## Purpose

C18 keeps the final City Run in two Studio-only templates so the owner can compare the original and the optimized mesh-reuse version before making any shipping decision.

- Original: the preserved manual scene.
- Optimized: the same inspected course with safe mesh reuse and the C18 runtime changes.
- Both templates live in ServerStorage.CityRunInspectionSources.
- The inspection service is enabled only in Studio. It is not a player-facing shipping feature.

The original editor course is untouched. Keeping both templates in ServerStorage has a memory cost while inspection is enabled.

## Before inspecting

1. Open the intended City Run place in Roblox Studio.
2. Save the current Studio file locally before switching variants. The inspection templates persist only when this place is saved.
3. In Explorer, confirm ServerStorage.CityRunInspectionSources contains Original and Optimized, and that its Enabled attribute is true.
4. Start a Studio Play session. Do not publish from this inspection session.

## Controls

The City Run inspection controls are collapsed by default. Touch or click the City Run Inspection header to open them; the final UI capture confirms that interaction.

- Show original / optimized: switches the active test course.
- Next checkpoint: advances the inspection target.
- Jump to start: resets checkpoint progress and respawn state to the course start.
- Unlimited time: the validated UnlimitedTime setting persists across variant switches.

Wait for the switch confirmation before using a checkpoint control. The switch recreates the active course and its context; use the controls only after the UI reports the selected variant.

## Expected checks

Run this sequence in the same Studio Play session:

1. Original to Optimized to Original to Optimized.
2. After each switch, verify there is one active RaceCourse and one active context, and the train controller continues updating its phase.
3. Open the controls, use Next checkpoint through checkpoint 8, then force a fall. Expected respawn is near 3705, 85, 14.
4. Use Jump to start, then force a fall. Expected respawn is near 3330, 11, 250.
5. Confirm UnlimitedTime remains true across switches and the avatar can move after an inspection jump from a finished state.

The C18 focused runtime test passed four checks on one avatar: conveyor velocity/tread behaviour, train phase, one eligibility snapshot, and 600 steps in 0.3321199 seconds.

## Recorded preservation evidence

- Native original backup: 3,606,711 bytes.
- Optimized Studio export: 1,844,066 bytes; local transfer verification passed with SHA-256 46a858971a3e101ebeeecba93b007ac054b558d812af68d27a44c1710f6c7cce.
- The optimized export deserializes in Studio with 6,853 descendants.
- Original inventory: 7,150 descendants, 5,411 BaseParts, 3,857 MeshParts, 2,807 unique mesh IDs, 3,461 query-enabled parts.
- Optimized inventory: 6,853 descendants, 5,209 BaseParts, 3,857 MeshParts, 2,406 unique mesh IDs, 1,044 query-enabled parts, 1,957 mesh parts using box collision data.
- Mesh reuse result: 658 replacements, 365 already shared, 1 guarded skip.
- Geometry comparison: 82,656 checks with 0 differences.

These counts show preservation and focused work reduction. They are not an FPS result or a 20-player mobile-capacity guarantee.

## Final visual review

All four final reviews used the same C18_01 geometry and the final collapsed inspection UI.

| Review | Score |
| --- | ---: |
| Luna Fidelity | 8.7 / 10 |
| Luna Route | 8.5 / 10 |
| Terra | 8.5 / 10 |
| Sol | 8.7 / 10 |

## After inspecting

1. Return to the variant the owner wants to keep open in Studio.
2. Save the current Studio file locally if the templates or inspection settings need to persist.
3. Leave the optimized template as an inspection candidate until the owner deliberately promotes it.
4. Disable or remove the Studio-only inspection setup before a shipping build if it is no longer needed.

Disabling inspection does not select the optimized course for shipping. Promotion must be a separate, deliberate change after review. Native Studio geometry is not recreated by a Rojo source build, even though the C18 script changes are synchronized through Rojo.

## Optional next steps

- Run a real 20-player test on target mobile devices, including server frame time, client FPS, memory, network traffic, and route/hazard behaviour.
- Deliberately promote a reviewed course for shipping, or remove/disable the inspection setup.
- Do not publish until the owner has selected the shipping course.

## Temporary test state

The temporary Studio test controls are disabled: RunRuntimeAudit is false and C18InspectionTest is false. Removing temporary helpers remains optional cleanup and is not complete because the cleanup authorization is pending.