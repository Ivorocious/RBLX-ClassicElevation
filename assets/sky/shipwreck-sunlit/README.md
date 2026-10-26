# Shipwreck Cove — Sunlit Treasure Coast

Built-in ImageGen generated `panorama-source.png` from `approved-concept-A.png`; the exact request is in `generation-prompt.txt`.

Run `python assets/sky/shipwreck-sunlit/build_faces.py` from the project root to reproduce the six cube faces. Install files identified by `roblox_faces` in `texture-manifest.json`, which includes hashes and all twelve edge checks. `upload-status.json` records the six completed Roblox uploads; do not upload again unnecessarily.

`config-before.luau` preserves the previous Shipwreck ambience. Runtime settings are in `src/ReplicatedStorage/Config/ShipwreckAmbienceConfig.luau`. See `docs/SHIPWRECK_COVE_SKY.md` for behavior and verification. The generated art is a distant sky, not physical geometry.
