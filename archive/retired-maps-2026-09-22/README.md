# Retired maps outside the game

These files are intentionally outside the Rojo mapping. Keeping them here or in Git adds no instances to the Roblox place.

| File | Contents | Verified instances |
| --- | --- | ---: |
| `retired-studio-archive.rbxm` | Entire former ServerStorage.Archive: City Run V1/V2, old V3 snapshots, old lobby builds, loose assets and legacy tools | 106,646 |
| `classic-ascent-v7.rbxm` | Authored Classic Ascent V7 course from CourseLibrary | 5,994 |
| `source-at-archive.zip` | Repository src folder and Rojo project mapping at archive time, including uncommitted source | — |

The native exports were saved to disk, read back byte-for-byte, deserialized in Studio, and checked against original fingerprints before removal. `manifest.json` records hashes, counts, source locations and the before snapshot; `.receipt.json` files record native file hashes. Later cleanup verification is in `docs/artifacts/offline-archive-2026-09-22.json`.

## Restore a map

1. Stop Play and save your current place first. Prefer opening a separate blank Studio place to inspect the old archives.
2. In Explorer, right-click the destination and use **Insert from File** to select the `.rbxm`.
3. For Classic Ascent, insert `classic-ascent-v7.rbxm` under `ServerStorage > CourseLibrary`. The imported model must be named `Course_ClassicAscentPointToPoint`. Its CourseInfo already identifies and enables it. On the next Play it should appear in DEV TOOLS > Maps. `CourseConfig.AutoBuildClassicAscent=false` can stay false when restoring the authored model; it prevents generating a replacement.
4. For old City Run or loose assets, inspect `retired-studio-archive.rbxm` in a separate place and copy only the desired items. V1 is `Archive > CityRun > CityRun_V1_Editable`; V2 and other comparison snapshots are under `Archive > CityRun > CityRunInspectionSources`. Do not replace current V3 or re-enable old inspection startup accidentally.
5. The source zip is recovery material. Extract it to a separate folder and compare changes before restoring scripts. Do not extract it over current development work.

Keep the native files and their manifests together. Roblox mesh/texture references use asset IDs, so asset availability and permissions are still required. Original Blender source/assets remain elsewhere in this repository.

## Git and backup scope

This dated snapshot is small enough for a one-time normal Git commit. Avoid repeatedly committing whole-place binaries; use new snapshots only at meaningful milestones. Git LFS or separate backup storage is better if these grow frequently.

A local Git commit protects against accidental edits/deletion, not loss of this computer. A remote copy is only confirmed after a successful push or backup upload. Nothing in this workflow publishes the Roblox place.
