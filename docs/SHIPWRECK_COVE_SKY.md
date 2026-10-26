# Shipwreck Cove — Sunlit Treasure Coast

Approved concept A is implemented as a Shipwreck-only client ambience profile. It uses a dedicated blue/cumulus sky, late-morning sunlight, readable cool shadows, light marine haze, gentle color correction, restrained bloom and sun rays.

`src/ReplicatedStorage/Config/ShipwreckAmbienceConfig.luau` owns the settings. `ClassicAscentAmbience.client.luau` applies them only when the loaded race identifies itself as `shipwreck_cove` and the player is within 750 studs of its Start. Leaving the range, unloading the course or entering another map restores the previous lighting, sky, atmosphere and effects first. Maps without an Effects section keep their existing effects. The lobby configuration and global LightingStyle were not changed.

This implements the lighting/sky direction. The concept's detailed water ripples and shoreline foam are artwork, not a water simulation introduced by this change. Authored meshes, texture atlas, hazards, collisions and route layout are preserved.

## Assets

[Asset sources](../assets/sky/shipwreck-sunlit) include the approved reference, generated panorama, full prompt, reproducible cube projection, hashes, upload receipts and prior config. Built-in ImageGen produced the 1774 × 887 panorama. Six projected 1024-square textures are installed; projection does not add source detail. All twelve shared-edge comparisons have zero channel error.

## Verification — September 23, 2026

- All 119 source Luau files compiled; Rojo build passed.
- All six sky textures loaded successfully on the actual Shipwreck Cove client.
- Fourteen client transition checks passed in `tests/studio/CourseAmbience.luau`, covering the lobby baseline, Shipwreck, City Run, Classic Ascent, distance exit, an unconfigured map and course unload. Bloom and sun rays restore when switching away from Shipwreck.
- A real developer teleport back to the lobby restored ClockTime 14.5, its original cloud-sea sky, original ambient light, bloom intensity 1 and sun-ray intensity 0.01; course color correction was disabled.
- The actual course was visually checked in Play. Studio returned to Edit afterward. Nothing was published.

To see it: Play, open F6 developer tools, select Shipwreck Cove and start a race. Edit mode retains the lobby environment; do not replace global Lighting to preview a single course.

Phone appearance and performance have not been measured.
