# Bright cloud sea

Selected concept: `selected-concept.png`. ImageGen produced `panorama-source.png` and the corrected downward cloud view in `nadir-source.png`.

`python assets/sky/bright-cloud-sea/build_faces.py` prepares six 1024-pixel square textures. It normalizes the spherical longitude seam and poles, projects the panorama, and stitches the generated nadir while retaining the matching perimeter. `texture-manifest.json` records the hashes and all twelve shared-edge checks. The final local textures pass with zero edge-channel difference.

These are distant sky textures, not physical cloud geometry. Their effective detail is limited by the 1774 × 887 generated panorama; the 1024-pixel faces do not create additional source detail.

## Installed lobby sky

The six final textures are uploaded and applied to the existing `Lighting.Sky`. `default.project.json` preserves the sky and brighter lobby lighting. `original-lighting.json` preserves the prior values. All six assets preload successfully in Studio.

Use `texture-manifest.json`'s `roblox_faces` mapping when uploading or rebuilding. The projected `ft` file maps to `SkyboxBk`, and `bk` maps to `SkyboxFt`; left/right retain their names. The final upper texture transposes the projected up face; the final downward texture reflects across the opposite diagonal. These exact mappings remove the visible joins in Studio. The intermediate `cloud-sea-dn-roblox.png` is retained for provenance and is not installed.

The first upload batch was interrupted when Studio exited. Five successful uploads were recovered by matching 64 sampled RGB pixels per image against local files. The missing down face and subsequent orientation corrections were uploaded separately. `upload-status.json` records current and earlier IDs; do not repeat uploads without checking it.

Classic Ascent's existing client ambience activates and restores every saved sky, atmosphere and lighting property in a temporary client fixture. No ambience script changes were needed. See [verification](../../../docs/artifacts/lobby-cloud-sea-checks.json) and [final Studio view](../../../docs/artifacts/lobby-cloud-sea-final.jpg). Lobby and course-library counts and the lobby pivot are unchanged. Studio was returned to Edit; the place was not published.

References: [Roblox skybox construction](https://create.roblox.com/docs/environment/skybox), [Sky properties](https://create.roblox.com/docs/reference/engine/classes/Sky).
