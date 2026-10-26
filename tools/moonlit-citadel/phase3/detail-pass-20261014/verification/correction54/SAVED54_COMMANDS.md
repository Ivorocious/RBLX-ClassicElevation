# Saved Source54 reopening

Prepared only. Do not run these commands until root confirms the final export hashes for all four files. Prior Source53 helpers/reports remain unchanged.

Expected final identity is Source54 / Build48 / `MC_P3_DETAILS_DT02`, packet `b5f2027a8d48038a8f0376fe4d843218dabd8e393f16601053d1e98bf864d3d5`, combined plan `ae21e1692484472ecf66c958d35b54d4e3ace390bbab810b92b609c03d393079`.

The two course models must each contain 320 world units, 881 meshes and 282,944 triangles; architecture253 and details77/242/84,222. The logical DT01 key resolves to the combined native `MoonlitCitadel_Detail_DT02Library`: ten templates and 32 material meshes. Fresh52 remains the baseline.

After checking root's exact model, module and library export hashes, prepare bindings:

```powershell
python tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/PrepareBindings54.py --target-source 54 --architecture 253 --plan docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/combined-plan54.json --packet docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/source54-packet.json --models docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/source54-models.rbxm --modules docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/source54-modules.rbxm --detail-library docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/dt02-r01-library.rbxm --detail-library-name MoonlitCitadel_Detail_DT02Library --combined-manifest assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final/combined-manifest.json --occupied-metadata assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg02/r01/final/combined-occupied-geometry.json --native-library-proof docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/dg02-r01-native-vertex-face-proof54.json
```

Then reopen and compare the actual saved files:

```powershell
.\.tools\lune-0.10.5\lune.exe run tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/CheckSavedCorrection54.luau tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/bindings54.json
```

This verifies all existing records, exact measured added counts, the retained Source52 part-depth correction, native template placement, all32 source-module packet/durable parity and unchanged external AmbienceConfig. It does not rerun gameplay or unaffected map tests.

Full corrective cache recovery can omit duplicate FreshBaseline52. Once root confirms `source54-restored-cache.rbxm`, create a receipt JSON with `source=54`, `snapshotName="AfterRestoredSnapshot54"`, the actual native snapshot `bytes`/`sha256`, actual exported `cacheSHA256`, and `baseline52SnapshotSHA256="3eda16621db02dcfc6235f8e90ce698d7c2d5dab4f5e1957610fa41dee4dcc7a"`. Do not substitute guessed hashes.

```powershell
.\.tools\lune-0.10.5\lune.exe run tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/ExtractAfterCorrectionSnapshot.luau docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/final/source54-restored-cache.rbxm tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/native-cache54-bindings.json
```

The staged-plan clearance is already retained under `final-plan54-metadata-rebind.json`; no geometry rescan is needed for the sole AmbienceConfig input-path correction.
