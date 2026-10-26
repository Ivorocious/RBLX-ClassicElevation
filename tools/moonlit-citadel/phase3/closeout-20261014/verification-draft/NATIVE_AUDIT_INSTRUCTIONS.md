# Final Source 50 native audit

This preparation reads saved artifacts only. It does not certify the live installation. The root alone installs the helper under its owned recovery folder and runs it after restoring Edit mode and all temporary sample visibility. There are no camera, lighting, source, mesh or physics mutations in the audit functions.

## Bound candidate and saved inputs

- Candidate `MC_P3_CLOSEOUT_FC01`, Source 50, Build 44.
- Packet SHA256 `2aca31596c1264413a10c554ae81ee7c42630a8732567c98fb7c276ecd4fe2c1`.
- Combined plan: `docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json`, SHA256 `74c77a93fd4a4c3e477f54333edc67d21b5d0bcc92b39084c49c21891cf59eb4`.
- Expected scenery: 233 edit units, 609 mesh parts and 197,402 known triangles, in both current courses.
- Appearance oracle is bound to the LF source of staged `WorldAssembly.luau`, SHA256 `545ed7ddeac6205559f775d81548e290ff5d8070dff87365325c1ab34932cd8e`.
- Fresh native protected baseline: `before/closeout_protected_baseline49.json`, SHA256 `2a0cd5a394f1b042311a9b137a97b612cacf5eddcaaafc9e5c2f7dd2e929479d`.

`approved-templates50.json` binds all 36 used assets and 101 distinct template mesh parts to the already approved saved native libraries. Repetition in the plan produces the 609 cloned mesh parts. The ER01 library also retains the independently proved actual-vertex identity from Source 49. The saved four-library recovery predates Source 49, but it is an immutable approved asset recovery, not a common-script source baseline. Root's fresh accepted-library comparison has confirmed it remains exact.

## Files to load as sibling ModuleScripts

Load these exact files into one new owned folder beneath `ServerStorage.MoonlitP3ReworkRecovery.Closeout20261014`:

1. `GeometryAudit49.luau` as `GeometryAudit49`.
2. `ExpectedAppearance50.luau` as `ExpectedAppearance50`.
3. `AuditNative50.luau` as `AuditNative50`.
4. `RunAudit50.luau` as `RunAudit50`.

The first module is an unchanged copy of the previous focused audit's geometry implementation. The wrapper supplies every Source 50 identity and count, so its old default candidate is never used. Its old Source 48 filesystem guard is not included or invoked. Do not load `CheckFrozen49.luau` for this pass.

## Run inputs

Root supplies verified raw UTF8 strings using its existing owned receiver/chunks. Keep HTTP setup and restoration outside this audit:

```lua
local report = require(ownedFolder.RunAudit50).Check({
    planRaw = finalCombinedPlanRaw,
    templatesRaw = approvedTemplates50Raw,
    sourcesRaw = sourceSpecs50Raw,
    protectedBeforeRaw = freshCloseoutProtectedBaseline49Raw,
    erMetadataRaw = approvedER01TemplateMetadata49Raw,
    protector = require(ownedRecovery.ProtectedCourse),
})
```

`templatesRaw` and `sourcesRaw` refer to `approved-templates50.json` and `source-specs50.json` in this draft. `erMetadataRaw` refers to `tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json`. The entry module verifies each raw input's exact SHA before decoding. If the final packet, placement plan or assembly appearance changes, rebind and rerun the preparation rather than relabeling this audit.

Save the complete report, including fresh `protectedAfter` snapshots, through root's existing evidence receiver. Require `report.pass`, `geometryPass`, `sourceGuard.pass`, `protected.pass` and `otherMaps.pass`. Preserve failure paths as findings. A native source path collision stops the entry audit instead of guessing which instance was meant.

## Source and unrelated-work boundary

`source-specs50.json` merges the fresh 1,031 existing native Lua source hashes with the 30 final packet records, resulting in 1,035 expected existing/production source paths. The four additional paths are the approved new builder modules. Current native hashes and packet source hashes use UTF8 after CRLF-to-LF normalization. This preserves Race Flow's legitimate current text. No Source 48 common-file hashes are consulted. Newly created, owned audit/recovery scripts are outside the original inventory and are not presented as unexpected global changes.

Filesystem preservation is separate: root's `before/current-source-all.json` hashes exact raw bytes. Compare it against current filesystem data with only the six explicitly approved Moonlit files changed/added. This helper does not overwrite, restore or compare old Race Flow source files.

## Verification scope and limits

The audit checks every planned clone's position, rotation, size, mesh identity, source material/asset attributes, texture identity, actual color/material/shadow settings, inherited transparency/material variant, double-sided setting, render fidelity and unit pivot. It binds current templates to the frozen approved identity rather than trusting a mutable library name alone. Collision fidelity is compared with the actual template when script-readable; the saved Lune reader cannot expose that property, so it is not claimed as an independently frozen saved-property comparison. Every scenery part must remain anchored and unable to collide, query or touch.

Full nonworld records include the accepted course contacts, skins, gaps, hazards, scripts, mechanism data, checkpoints, recovery, finish, owner edits, signs and all 19 arrows. Phase 1, the accepted BL02 library and both arrow templates are compared exactly. Existing world-light records are also compared. The six other saved course models are compared by fresh pre-install serialization hash, byte length and descendant count.

The test report `audit-fixtures50.json` is an offline synthetic-clone test. It checks all 1,218 appearance parts and confirms deliberate pose, size, color, material, source-material, contact-flag, arrow, Phase 1, source and plan-binding faults are rejected. It is not native installation, visual stability, multiplayer, gameplay, performance or reviewer evidence. The root still needs actual player-height day/night views, the focused moving-render sequence and the original five independent judgments.
