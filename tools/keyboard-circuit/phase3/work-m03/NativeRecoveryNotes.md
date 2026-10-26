# M03 recovery and source-agreement fixtures

The helper prepared and compiled these fixtures without calling Studio. The lead should run them once the owned test has returned to Edit; both enforce the intended place/universe and stop immediately if Play is running. No owner Play or computer/camera state is changed by these guards.

## NativeRecovery.server.luau

This creates a new inert proof folder at `ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009.KCP3M03NativeRecovery01`, containing a native engine reopening and a fresh source build. It checks for an existing proof before creation; on failure, inspect and preserve that partial proof before choosing a fresh suffix rather than overwriting it.

The source build starts from a fresh clone of `Phase3FinalTuning20261009.M03Sources01`, not a cached required module or recovery model. All 28 complete source strings must already match the installed candidate. `Map.Build` therefore reapplies the durable captured `WarningPlacements` and presentation budget. Both recreated courses are compared with the active M03, including:

- Root and instance attributes, all hierarchy paths/classes and model PrimaryPart references.
- Part transforms/pivots, dimensions, colors/materials/transparency/reflectance, anchored/collision/query/touch/shadow states and collision groups.
- Shapes, mesh/texture identities and collision/render fidelity.
- GUI positions, sizes, anchors, rotation, visibility, colors/borders, clip/layout order, complete visible text, font identities, text sizes/alignment/scaling/wrapping/strokes, and text-size/corner/stroke constraints.
- SurfaceGui faces, canvas sizing, pixel density, brightness/light influence, draw distance, Z offset, Enabled state and Adornee references.
- Attachment transforms, prismatic/hinge settings, internal ObjectValue/constraint/weld/model references and value objects.
- All 28 source classes/names and full byte strings.

Expected physical counts in each copy: **9,755 parts, 2,989 press targets, 282 colliders, 3,289 query parts, zero touch parts, 2,841 artwork parts, 28 snapshot sources**. Root must inspect any count failure before changing expectations. Numeric comparison follows the existing recovery precision of 0.001, including signed-zero normalization; it is not bitwise floating-point equality. Recovery BaseScripts are intentionally disabled and this Disabled difference is excluded from equivalent geometry. The active candidate's Session must remain enabled.

The fixture also confirms one active Keyboard Circuit and **15** inert older courses including M02. It never deletes the active candidate, M02 or any existing evidence.

On success, read:

- `shared.KCP3M03RecoveryReceipt01`: count/row comparisons, proof path, byte size and native SHA-256.
- `shared.KCP3M03NativeExport01`: engine-native export compressed as Zstandard and then Base64 for transport. This is the encoded native model, not a whole-place save.

The receipt is saved before the final assertion so comparison failures remain inspectable. No success claim should be recorded unless both `roundTrip.passed` and `freshSourceRebuild.passed` are true.

## SourceAgreementFull.luau

Use this fresh fixture in place of the earlier `SourceAgreement.luau`, which is preserved. It returns **32 source rows**: all 28 snapshots plus the global StudioDevService, KeyboardCircuitPhase2Preview, ClassicAscentAmbience and unchanged StudioDevController. The last global is deliberately included so an unintended dev-control implementation change is visible.

Each row includes its live path/class, repository file path, exact byte count/SHA-256 and a second count/hash after CRLF becomes LF. Prefer exact agreement; a normalized hash permits only the stated newline difference, never changed source text. The native fixture cannot read repository files, so the lead must compare these 32 rows with current durable files before reporting filesystem/live agreement.

The native pass checks all snapshot bytes against M03Sources01, exact owner origin `(2222,330,-1158)`, one active M03, 15 inert archived courses, and unchanged unrelated map counts. It stores the return value in `shared.KCP3M03SourceAgreementFull01`. No scene objects or script sources are written by this check.

## Compile status and limits

The bundled Lune 0.10.5 runner compiled all **58** current scoped candidate/traversal/audit files after these fixtures were added. Native execution, recovered export transport, full final source hashes and the resulting comparisons remain the lead's checks. This helper made no Studio calls or edits to candidate sources, globals or immutable evidence.
