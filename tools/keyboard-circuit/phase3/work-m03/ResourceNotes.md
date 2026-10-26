# M03 presentation budget and route directions

`PresentationBudget.Apply(course)` is a build-time pass over this course only. Call it after archive, decoration and effect anchors are built. It adds no objects, runtime update loops, timers or connections. It changes only selected `SurfaceGui.MaxDistance` values, inert artwork `CastShadow` values, and five course-level presentation attributes.

## Draw-distance rules

Only a `Legend` SurfaceGui on a BasePart carrying a string `KeyLegend` is classified as a key legend. Existing shorter finite ranges are retained. GUI availability, text, colors, held-key clones and physics properties are untouched.

| Class | Rule | Limit | M02 copy count |
| --- | --- | ---: | ---: |
| Ordinary key | `Role=WalkableSkin`, neither special nor warning class | 120 studs | 2,944 |
| Warning key | Walkable key legend containing the existing `DropWarning` frame | 170 studs | 36 |
| Special key | Walkable `KeyTop`, or X/Z dimension above 3.2 studs | 180 studs | 10 |
| Display key | `MapArtwork=true`, nonpressable decorative cap legend | 64 studs | 111 |
| Preserved | Every other GUI, including lethal X, hazard boards and checkpoint panels | Original | 167 |

The 120-stud ordinary-key range leaves substantial headroom beyond nearby jumps and the 30-stud camera example used for this choice. Final native checks must confirm the actual supported camera bounds; no camera range was changed here. Large special-key glyphs keep 180 studs; key-top falling-zone warnings use the same 170-stud range as the existing main warning boards. All 17 main warning boards retain 170; all 44 checkpoint/wayfinding panels retain 100. The 10 special GUIs include the intentionally disabled joined-key secondary legend, so this count exceeds the nine pressable special caps.

On the copied frozen native M02 model, 3,101 unlimited GUIs become finite. The full distance histogram changes from `0:3207, 100:44, 170:17` to `0:106, 64:111, 100:44, 120:2944, 170:53, 180:10`. The remaining unlimited labels describe lethal or other course information and were deliberately left outside this small-key classification.

## Shadow rules and measured counts

A shadow can be disabled only when its part is explicitly `MapArtwork=true`, has neither press flag, and has no collision, query or touch flag. Within that inert set, disable shadows for a small detail whose longest dimension is at most 6 studs and volume at most 128 cubic studs, or a thin detail whose shortest dimension is at most 0.4 and longest at most 24 studs. Larger housings, landmark silhouettes, shelf masses, warning panels and upper rails/stands retain their original setting. No gameplay/held-key cap is included.

Frozen M02 decorative shadow casters drop from **1,623 to 502**, a reduction of **1,121**. Total native shadow casters would drop from 8,533 to 7,412 before any M03 additions. Disabled details by section: FloatingHardware 601, IslandCircuitPlates 247, HazardIndicators 136, HardwareLandmarks 121, DistrictLayers 16. The warning-board changes affect small feet, caution slashes and lower silver rails; the main display panel, upper rail and upright supports remain shadow casters.

The accompanying [resource study](ResourceStudy01.json) applies the actual module to a deserialized copy of `KC_P3_M02_01_Native.rbxm` (SHA-256 `39ba350a2eea6571ac990e6af4c7fc67b9d2885886be8aca843a72f595c6b9ce`). Across all **8,711** parts it checks that pose, size, color, material, transparency, anchored/collision/query/touch properties and part attributes are unchanged. It verifies unchanged GUI Enabled state, all main/lethal warning and checkpoint ranges, and a second application making no further edits. Both owned sources compile with the bundled Lune 0.10.5 runner. No Studio data was changed by this helper.

At the same eight recovery eye points as Ideation's study, all configured distance-eligible SurfaceGuis average **3,218 before / 875 after** (range after 661–1,071). Enabled eligibility averages **3,217 / 874.75**. Within the 3,101 changed GUI set, eligible counts average **758**, ranging 543–950. This is host-center distance eligibility only: camera offsets, face angle, frustum, occlusion, rendered draws, readability, device costs and FPS are excluded. The figures quantify this pass on the same M02 copy, not the final M03 environment/effect workload. The lead must separately measure the completed native M03 candidate.

## Route boards

Normal/Expert board dimensions, positions, departure targets and geometric arrows stay unchanged. The actual `AHEAD/BACK LEFT/RIGHT` direction moves from the small footer into the large central `Meaning` line. Its available line height rises from 18% to 40% of the 2.4-stud panel; its text-size cap rises from 54 to 96 pixels. Route identity and key width remain in the title (`NORMAL | WIDE KEYS`, `EXPERT | SMALL KEYS`), with short `FULL ROUTE` or `SHORTER / HARDER JUMPS` detail below. Only the existing two cut-choice stations use this arrangement. The wayfinding revision is `KC_WAYFINDING_M03_01`.

Native player-height readability and text-fitting checks under the darker archive lighting remain the lead's integration work. Resource counts do not prove those checks.

## High warning stack findings

The offline study also applies the lead's captured owner warning placements to a copy. From the actual safe-bank center eye, upper Foundry H04 sits 17.5 studs above the eye and 31.40 horizontally away, approximately 29.13 degrees upward; upper Domino H08 has the same height and 26.76 horizontal distance, approximately 33.19 degrees upward. These measurements alone do not establish a readability failure. Preserve these owner poses, keep new shelves clear of their upward reading cones, and include upper Action/Phase corners from close waiting edges and recovery slots in the final visibility check. No warning placement or warning text was edited here.

## Files and verification

- `sources/PresentationBudget.luau`: bounded build-time GUI/shadow pass.
- `sources/Wayfinding.luau`: clearer two-choice direction lines.
- `PresentationBudgetCheck.luau`: focused copied-native compile/preservation/count study.
- `ResourceStudy01.json`: the recorded pass and comparable counts.

Run from the repository root: `.tools/lune-0.10.5/lune.exe run tools/keyboard-circuit/phase3/work-m03/PresentationBudgetCheck.luau`.

The sandboxed runner could not canonicalize the workspace directory; the same read/copy-only check passed with the existing approved Lune-run prefix. An initial fixture serialization attempt could not encode typed Roblox attributes; the check now compares typed attribute values directly. These were fixture issues and did not require a candidate behavior change.
