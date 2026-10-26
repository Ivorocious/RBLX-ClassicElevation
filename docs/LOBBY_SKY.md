# Bright cloud sea

**City Run update:** The cloud sea remains the lobby baseline. City Run now selects its own [Golden Hour environment](CITY_RUN_SKY.md), and Classic Ascent keeps its existing appearance. All nine focused map-switch/restore checks passed.

The approved cloud-sea concept is installed in the lobby as six sky textures with brighter ambient light. The source settings live in `default.project.json`; asset sources, build instructions, upload receipts and the prior lighting values live in [assets/sky/bright-cloud-sea](../assets/sky/bright-cloud-sea/README.md).

![Current softer lobby lighting](artifacts/lobby-cloud-sea-softer.jpg)

The owner requested a brightness reduction after viewing the initial cloud-sea lighting. Current sunlight brightness is 2 (previously 3), ambient RGB is 70/80/100 (previously 100/110/130), and outdoor ambient RGB is 100/115/135 (previously 140/152/170). These are the only three adjusted properties. Studio inspection and Rojo build passed. The earlier check report below records the initial installation; its source-match result predates this adjustment.

To revert this brightness adjustment, restore the three values in [before-brightness-reduction.json](../assets/sky/bright-cloud-sea/before-brightness-reduction.json) to both `default.project.json` and Studio Lighting. The original brighter preview remains in [lobby-cloud-sea-final.jpg](artifacts/lobby-cloud-sea-final.jpg).

All twelve source edge comparisons pass with zero channel difference. Studio inspection verified corrected side, upper and lower joins; all six installed textures load. Rojo build passes. A fresh Play session spawned into the lobby without console errors. A temporary client course fixture verified Classic Ascent's atmosphere activates and every saved sky, atmosphere and lighting property restores on leaving its range. This is a focused ambience check, not a full race test. [Check results](artifacts/lobby-cloud-sea-checks.json).

The existing lobby remains at 2,112 descendants and the same pivot; CourseLibrary remains at 12,088 descendants. No geometry or UI changes were made for the sky. The clouds are a distant background. Their detail is limited by the generated 1774 x 887 panorama. Phone and low-end-device appearance remain manual checks.

Manual check: start Play, look around and below the lobby, enter a real Classic Ascent race, then return to the lobby and confirm the cloud-sea sky returns. Save the Studio place to keep the current editor scene; the repository preserves the lighting configuration. Nothing was published.
