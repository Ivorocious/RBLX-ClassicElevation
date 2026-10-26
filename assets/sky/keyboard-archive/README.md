# Keyboard Archive skybox

The owner selected Keycap Archive preview 37 and clarified on October 9, 2026 that it must be the actual skybox. These files provide distant background imagery only. No course, platforms, avatars, signs or UI are baked into the textures.

`panorama-source.png` is the selected 1774 × 887 ImageGen panorama. `panorama-source-r01.png` preserves the first draft; its close shelves and sharp pole details were rejected. The second ImageGen edit moved all shelving into the distance and simplified the ceiling and floor near the poles. The exact prompts are in `generation-prompt.json`.

Run `python assets/sky/keyboard-archive/build_faces.py` from the repository root to reproduce the six 1024-square textures. The converter reuses the existing Stud Garden and Shipwreck spherical projection, technical seam/pole normalization and Roblox face mapping. The output resolution does not increase source detail. `texture-manifest.json` records the hashes and twelve shared-edge checks; all edge channel differences are zero. Projected side faces and both poles were visually inspected.

Use the `roblox_faces` mapping, not raw filename intuition: front/back names and the pole transforms follow the established project mapping. `upload-status.json` records the six imported Roblox image IDs. Reuse those IDs. Image import succeeded; live loading, appearance and restoration are separate native checks recorded by the final candidate. The temporary localhost upload server was stopped after import. No place was published.

Apply through the Keyboard Circuit client sky/lighting lifecycle. Preserve and restore all six previous Sky textures and orientation. The added physical ArchiveBackdrop enclosure is superseded; original accepted course scenery remains.

The final saved M04 sources have passed a clean native Play check. [Sky loading evidence](../../../docs/artifacts/keyboard-circuit/phase3/P3-M04-native-sky-load-03.json) records six successful loads, all six actual Lighting Sky properties matching these imported IDs, and no remaining preload objects or tasks. [Lifecycle evidence](../../../docs/artifacts/keyboard-circuit/phase3/P3-M04-effects-lifecycle-03.json) and the [actual death check](../../../docs/artifacts/keyboard-circuit/phase3/P3-M04-effects-death-03.json) record restoration of the original lighting and Sky. The [direct City Run handoff](../../../docs/artifacts/keyboard-circuit/phase3/P3-M04-effects-other-map-handoff-01.json) also restores the real other-map profile and Lobby baseline, then returns to a complete streamed decoration pool. The pending-load wording in `upload-status.json` is retained as part of the original import record; these later checks establish application and restoration. Native camera-direction and visible-seam inspection remain unverified. These asset checks do not constitute the full course closure gate.

[Roblox skybox documentation](https://create.roblox.com/docs/environment/skybox).
