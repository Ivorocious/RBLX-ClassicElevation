# Stud Garden - Giant's Backyard

The owner selected the refined Giant's Backyard concept and requested implementation on October 6, 2026. This folder contains the source artwork, six Roblox sky textures, upload receipts and source backups.

`panorama-source.png` is the final ImageGen panorama. The original generation and its prompt are preserved in `panorama-source-r01.png` and `generation-prompt.json`. A second ImageGen edit softened the lower 35 percent into diffuse moss-green and gold bokeh, removing the identifiable plants that pinched at the bottom of the sphere. Its original output is `exec-59e8e408-f9cd-4c70-bcc0-3de0b588fc50.png` in the session's generated-images directory. The source is 1774 x 887 pixels; projecting 1024-pixel cube faces does not increase source detail.

Run `python assets/sky/stud-garden-giants-backyard/build_faces.py` from the repository root to reproduce the textures. The converter uses the project's existing Roblox cube-axis mapping, bilinear projection and technical seam/pole normalization. `texture-manifest.json` records the twelve shared-edge checks and texture hashes. All shared edges have zero channel difference.

Install only the files under `roblox_faces` in that manifest. `upload-status.json` and `upload-status-r02.json` contain the final asset IDs. `upload-status-r01.json` is historical. Reuse the final IDs; do not upload again unless the artwork changes.

The active settings are in `src/ReplicatedStorage/Config/StudGardenAmbienceConfig.luau`. Source backups are in `source-before/`; `source-before.json` records their hashes. `native-before.json` records the original lighting, camera and course observations. Restore the saved ambience script to remove this course profile from runtime; the uploaded images can remain unused. This does not require changing course geometry or the lobby sky.

See [implementation, native views and checks](../../../docs/STUD_GARDEN_SKY.md). The sky image uploads do not publish the place.

Reference: [Roblox skybox construction and matching faces](https://create.roblox.com/docs/environment/skybox).
