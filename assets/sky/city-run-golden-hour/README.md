# City Run — Golden Hour

The owner selected [concept B](../city-run-concepts/B-golden-hour.png). The full-sphere sky artwork was generated with built-in image_gen; `panorama-source.png` preserves the result. It is 1774 × 887 pixels. Six 1024-pixel cube faces are prepared from that source; projection does not add source detail.

Run `python assets/sky/city-run-golden-hour/build_faces.py` to reproduce the textures. This uses the same checked cube-axis mapping as the lobby sky. `texture-manifest.json` records file hashes and all 12 shared-edge comparisons, which pass with zero channel error. The upper and lower Roblox faces have their required orientation transforms applied. Use the `roblox_faces` entries for installation.

`upload-status.json` records the six completed image uploads. Do not upload them again without checking those receipts. All six loaded successfully through the installed Sky object's `ContentProvider:PreloadAsync` check in Studio Play. A preload of bare asset-ID strings returned Failure even for an existing lobby image, so that method was not used as the acceptance check.

The settings are in `src/ReplicatedStorage/Config/CityRunAmbienceConfig.luau`. The existing `ClassicAscentAmbience.client.luau` now selects the City Run or Classic Ascent profile by active course ID and player distance from its start. It restores the saved lobby settings before applying another map. `default.project.json` still defines the cloud-sea lobby sky.

Pre-change ambience source and Classic Ascent config are preserved as `ambience-before.luau` and `ascent-config-before.luau`. They are outside the Rojo source tree. Restoring both rolls back the course-sky extension; the uploaded sky assets can remain unused.

See [implementation and checks](../../../docs/CITY_RUN_SKY.md). The place has not been published.

## Generation prompt

Use case: stylized-concept. Asset type: full-sphere equirectangular sky panorama for a Roblox game skybox. Reference image is the approved City Run Golden Hour preview; use ONLY its SKY appearance, colors and cloud character as reference. Generate a new clean 2:1 equirectangular spherical environment texture, ideally 4096x2048, full 360-degree longitude by 180-degree latitude. Sky only everywhere: absolutely NO buildings, streets, trees, landscape, horizon objects, ground, water, text, border or interface. Upper half: spacious clear blue zenith fading to blue gray and pale warm apricot toward the horizon, scattered elegant cumulus clouds with rich champagne-gold illuminated rims and cool muted mauve undersides, like the reference. Golden light source toward longitude center-left just above horizon, off-screen sun feeling with no white solar disk, no sun flare. Do not make the whole sky orange; preserve generous blue openings and golden clouds. The horizon is at EXACT vertical midpoint with warm pale golden atmospheric haze, NOT a hard line. Below horizon continues softly into pale warm atmospheric sky, with subtle hazy distant gold/mauve cloud wisps, no opaque ground and no cloud ocean. Bottom pole should be a subdued pale blue-gray warm haze, subtle seamless change. Map clouds correctly for spherical equirectangular projection (progressive polar distortion; no pinching artifacts when viewed as a sphere). Seamless left/right longitude, smooth continuous zenith/nadir poles. Natural softly stylized detailed sky texture, no painterly strokes, matches warm late-afternoon city game mood, sharp clean cloud edges. This is the actual sky environment texture, not a screenshot, not a cubemap cross, not a collage.

Reference: [Roblox skybox construction](https://create.roblox.com/docs/environment/skybox).
