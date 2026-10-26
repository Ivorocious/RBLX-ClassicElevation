# Lobby reference artwork

Current runtime icons are the nine transparent ImageGen sprites in `imagegen-r6/`: `shop.png`, `coin.png`, `key.png`, `racer.png`, `trophy.png`, `gear.png`, `clock-v4.png`, `check.png` and `chevron-v2.png`. Labels, balances and timers remain separate native UI text. Settings and Race options reuse the same gear. The accepted Shop, coin and key images are unchanged. [Current set and prompts](../../../docs/artifacts/hud-reference-2026-10-01/r6/README.md).

Earlier Blender icons and their editable `.blend` sources/scripts remain for history. The new icons use built-in ImageGen with the owner's reference crops. `LobbyIcons` sizes each image by its visible alpha bounds so transparent padding does not change apparent size; spare padding is clipped by native UI frames. The original PNG pixels and alpha are preserved. No runtime icon meshes are needed.

The ticket is426×122 RGBA with9px side notches, stepped shoulders and a4px navy edge. `panel-ticket-r3.svg` and `generate_ticket_r3.py` are editable. Roblox9-slice uses `Rect.new(32,32,394,90)`; the transparent notches reveal the actual world behind the UI.

`race-panel-r5.svg` and `generate_race_panel_r5.py` supply a426×190 transparent panel with a clean rounded blue side tab. The owner requested removal of the white side facet and cyan decorative curves. Roblox9-slice uses `Rect.new(30,30,396,160)` to retain the rounded edges during resize.

`imagegen-candidates/r5/` preserves the first-three style checkpoint. The owner accepted its Shop, coin and key images on October1 and authorized completing the set; exact copies are now installed in `imagegen-r6/`. Earlier alternatives are retained but are not runtime assets.

[Figma specification](https://www.figma.com/design/xmfVLaBWKD9yY1Jm79ImSc?node-id=3-143) contains editable components and text through R2. The local Figma export/manifest in `figma/` records R1; the previous final export hit the Starter-plan tool-call limit. It has not been updated for R6. Current PNG assets, ImageGen prompts and editable panel SVG sources are local. [Native Studio R6 image](../../../docs/artifacts/hud-reference-2026-10-01/r6/native-desktop-final.jpg).

Uploaded asset IDs and source hashes: [R6 manifest](../../../docs/artifacts/hud-reference-2026-10-01/r6/source-manifest.json). Sample currency/progression numbers are available only in the Edit-only Reference HUD screen. Use **Plugins → Classic Elevation → UI Preview → Reference HUD**, then Refresh after Rojo sync.
