# Focused native Source49 checks

These scripts read existing data. The author did not access Studio or alter production. The lead runs the live audit and exports the frozen models.

The binding is Source49 / Build43 / packet `7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca`. This replaces the earlier packet after the data-only terrain source split. The combined plan remains178 units/487 meshes. The split equality test compares732,168 exact scalar/Vector3 component values and47,122 occupied rows, including both tree proxies, with zero differences. It does not rerun clearance.

## Live audit API, lead only

Load `AuditNative49.luau` as a read-only module or inline its returned table. Supply both actual courses, actual kit Models, decoded `combined-plan49.json`, and the frozen native source checks:

```lua
local report = Audit.Run({editableCourse, storedCourse}, {
    ER01 = kits.MoonlitCitadel_Enclosure_ER01Library,
    P3 = kits.MoonlitCitadel_P3Rework_RW01Library,
    AR01 = kits.MoonlitCitadel_P3ArtRepair_AR01Library,
    TL01 = kits.MoonlitCitadel_TowerLandscape_TL01Library,
    BL02 = kits.MoonlitCitadel_BL02Library,
}, decodedCombinedPlan, {
    approvedTemplateMetadata = decodedApprovedTemplateMetadata49,
    sourceChecks = frozenNativeSourceChecks,
    requiredSources = 38,
})
```

Each source-check row is `{name=uniqueName, actual=liveModule, expectedSource=frozenBeforeSourceText}` or uses `before=frozenBeforeModule` instead of text. Use `mode="arrow-tail-only"` for the mutable EnvironmentPlan's accepted arrow implementation. Expected source must come from recovery, not current source. If the separately captured native source scope is25 modules, set `requiredSources=25` explicitly and retain the38-file filesystem guard as a separate result. The default source guard requires38 checks and fails when omitted. For a geometry-only report, explicitly use `requireSourceGuard=false`; that does not claim native source preservation.

The audit pins the approved asset `83390081804897`, import/axis flags, FBX/manifest hashes and53 imported parts. `approved-template-metadata49.json` provides the MeshId/CFrame/Size reference from the actual native vertex snapshot that passed parity. It then checks every placed part against its template scaled/rotated exactly as WorldAssembly does, plus model bindings, all scenery contact flags, unit/mesh counts, source/build packet and world ledger. Default tolerances are.001stud for position/size and.00002 for rotation matrix components. Duplicate sibling parts match by path/class and nearest expected geometry rather than occurrence order. Root can serialize the report through its existing receiver; this module performs no HTTP, writes or native mutations.

Offline fixtures use a saved approved library and in-memory clones only. Valid placement passes; changed mesh identity, shifted pose, collision flag and protected source each fail. Saved Lune meshes expose `MeshContent` rather than a readable `MeshId`; the checker uses the project's existing URI-normalization fallback and never silently skips mesh identity.

## Freeze and reopen

Export both final course models in one RBXM. Keep original recovery exports intact. The lead's full protected-course/P1/kit/sign/arrow comparison and live source guard remain required; the reopen checker does not replace them.

```powershell
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/CheckFrozen49.luau docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/final/enclosure_source49_models.rbxm docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/combined-plan49.json docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm
```

Arguments are final two-model RBXM, accepted four-kit RBXM, combined plan and verified ER01 RBXM. Defaults match these paths; use the actual exported model filename if different. The verified ER01 library must hash to `b07d422330ee003a3b1030438b5f8d227dc6f9d42720da02843cc654226da407`. It reopens2 courses, checks178 units/487 world parts against templates, verifies source49/build43/packet, compares complete counts against preserved non-art plus the new487 mesh scenery, and requires147 colliders/135 walkables/55 red contacts/19 arrow IDs. It also reads and compares all38 current protected filesystem entries against the original baseline, including the accepted arrow tail. It writes only `geometry/frozen49-reopen-report.json` with input hashes. Native external moduleSource guards are separately reported, because course RBXMs do not contain all those sources.

Focused local commands:

```powershell
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/CompileNativeChecks.luau
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/TestNativeAudit.luau
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/CheckTerrainSplit49.luau
```

No new geometry, performance claims, gameplay campaign or visual judgment is included. Actual moving-camera day/night evidence and restored editor state remain lead-owned.
