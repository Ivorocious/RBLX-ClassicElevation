# Accepted-course protection tools

Implementation/check author handoff. Only this draft directory was changed. No Studio, Blender, production code, protected course or reviewer file was edited. The Source38 commission and all eight Ideation findings were read; gallery daylight and machinery night views were inspected at original resolution.

## Native baseline — lead only

Verify the intended Obby Tournament, Edit mode, Source38/Build32 and packet `56d992fa0cda21e53736b06f3d409e36911b1b77a9d3b5d9ce9cd1584b0dfc05` before the first capture. Capture the actual Workspace course and ServerStorage course-library model separately, plus recovery. Save each returned table as JSON, retaining its identity and the original native evidence. The helper did not capture these native baselines.

`ProtectedCourse.luau` is a read-only module. The lead can evaluate its source inside the existing MCP executor without creating a product script, or use the established local tool-loader. Call:

```luau
local baseline = Protected.Capture(explicitMoonlitModel)
local after = Protected.Capture(theSameModelAfterArtIntegration)
local comparison = Protected.Compare(baseline, after)
```

Use `CaptureAcceptedKit(ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library)` for the accepted Phase1 library, and `CaptureArrowTemplate` on each accepted `MC_P3_Rework_ArrowMount` / `MC_P3_Rework_SolidArrow` template in the P3 library. Compare each against its own baseline. Do not compare the Workspace model directly to the library model: absolute guidance-source strings can correctly differ by container.

Repeated sibling names use their deterministic occurrence in `GetChildren()` order only when duplicated, for example `SideRailContact[1]` / `[2]`. Instance-reference properties use the same path rule. The collector preserves both originals and does not rename or ignore duplicates.

The capture freezes every non-art descendant and its class, tags and attributes, including:

- All accepted contacts and their visible floor skins, including the owner's lowered Shared Arches pieces; transforms, size, collision/query/touch, material, transparency and mesh/texture identifiers.
- Normal/Expert contacts and hazards; both catches and every return part; Start, forward-facing Finish, checkpoint order and respawn metadata, Bounds and all five independent fall/reset zones.
- Moving car decks, rails, parts, full model pivots, attachments, cable links, counterweight links, lantern cage/kill geometry, axes, rest poses, travel, cycle, dwell and phase metadata. Captures require Edit/rest state; runtime motion is not a geometry regression.
- Full `Decoration/Wayfinding` and `Decoration/Arrows` trees, sign lettering and mounting, source contacts, arrow target/forward vectors, colors and the exact selected IDs. Course comparison also requires exactly 19 unique arrow IDs; arrow mounts share their arrow's ID and do not inflate this count.

Only `Decoration/Phase3World` can change and is captured separately in `artParts`. Accepted `Decoration/ArchUndersides`, other accepted Phase2 decoration, signs and arrows remain exact. A newly and explicitly authorized `Decoration/Phase3OuterWorld` root can be included by passing `{allowPhase3OuterWorld=true}` to both baseline and after captures; it is not excluded by default. **Only lights explicitly tagged by the attribute `MoonlitWorldLight=true` are excluded from course equality**, even when parented to a contact; their properties are retained separately as `worldLights`. Original mechanism lights stay protected. Phase1/arrow-template captures exclude no decorative pieces or lights. New art outside these explicit art roots is an added protected object and fails until its intended ownership is resolved.

Scripts and gameplay-tagged branches inside an art root are also protected, so adding a hidden hazard, walkable contact or moving mechanism under scenery cannot bypass the comparison.

Source/build/packet/candidate labels and the existing course-level work-light/world-applied/night metadata can change. All other protected values compare exactly, with no floating-point tolerance or silent clamping. Tiny numeric differences are reported for inspection, not erased to manufacture a pass. `Compare.pass` concerns protected equality only; it does not judge art quality, resource limits or camera comfort.

## Durable behavior source baseline

`accepted-source-baseline-complete.json` freezes 38 source entries. The earlier 33-entry inventory is retained as historical preparation; use the complete file. The current comparison reports zero changes. This is local source evidence, not native recovery or an accepted-course geometry comparison.

Run after integration:

```powershell
python tools/moonlit-citadel/phase3/art-repair-20261013/drafts/protection/source_baseline.py compare
```

The exact files include route/Expert/hazard/layout/foot-goal code, runtime, coverage, route builder and floor visual assembly, wayfinding, movement/lift configs, checkpoint/forward-finish rules, shared race/recovery/motion services, ambience lifecycle gate and accepted Phase1 kit/bindings/installers. The exact arrow-placement tail of `EnvironmentPlan` is also protected while its world plan/profile can change. `WorldPlan`, `WorldAssembly`, scenery `EnvironmentPlan.Get/Profile`, and `MoonlitCitadelAmbienceConfig` are art-editable. This tool never edits source and refuses to overwrite an existing baseline. Re-freezing a changed behavior file is not a substitute for restoring the accepted behavior or obtaining a specific owner decision.

## Architecture clearance

`ArchitectureClearance.Prepare(layout, courseConfig)` returns course-local oriented boxes. It uses current source contacts, explicit transfers, two branch-union route traces and both catches. It does not start or replay a race.

```luau
local volumes = Clearance.Prepare(layout, config)
local report = Clearance.CheckParts(nativeCapture.artParts, volumes, config.Origin)
```

The native art rows have world-space frames, so pass the world origin. A source-plan adapter can instead give course-local frames and omit the origin. `AddImportantViews(volumes, reviewViewIndex, config.Origin)` optionally adds advisory corridors for the sixteen documented review cameras; a view ray can hit its intended architectural subject and needs visual interpretation.

Practical envelopes:

- Supported-floor standing space: full floor footprint plus one stud around it, 6.5 studs above the top. Ordinary free-jump space: JumpHeight7.2 + body6.5 + .8 reserve =14.5 studs. Each is separate so headroom findings remain visible.
- Gap/hurdle/jump movement: 4.5-stud-wide travel strip, supported before/after points, 1.25-stud end reserve, full jumping/body height. Catch walks and ordinary route walks retain standing-height strips. Boarding/exit corridors include each actual approach.
- Both bays of both lift stages: deck/rail/body envelope 18×49×16 over the full 34-stud rise, plus counterweight travel boxes 8×44×6.5. These are conservatively fitted to the existing mechanism construction; behavior remains frozen by source and native equality.
- Three swing cages: sampled -32° to+32° envelope around each authored pivot/axis, an 8×14×8 cage body allowance and one-stud envelope reserve. Protected native mechanism parts still require equality; a cage-envelope screen does not prove timing or collision behavior.
- Following camera: 11-stud rear reserve, eight-stud width, ordinary/jump vertical ranges. Receiving-lip sight corridors and optional named review views are advisory visibility findings.

`CheckParts` reports movement/mechanism intersections, jump headroom, camera and sightline findings separately, plus any new art whose collision/query/touch is enabled or which is unanchored. It never hides, deletes or moves objects. Broad mesh boxes can include an arch's empty opening, so split visible pieces or inspect a reported void before concluding obstruction. A static screen cannot prove moving-camera comfort or actual night readability. Review changed/new art first; existing frozen course pieces are not candidates for clearance-driven route edits.

## Focused tool validation

`CheckTools.luau` compiled both modules against the current source Layout and created 1,574 clearance boxes: 566 movement,135 jump-headroom,11 mechanism,431 camera and431 landing-view boxes. Synthetic checks detected an art box in standing space, accepted a distant box, passed exact baseline self-comparison, and rejected a changed protected property. `tool-checks.json` records this bounded check. No native geometry baseline, physical movement, broad branch campaign, new timing, multiplayer or device proof is claimed.

After installing art, require the exact protected-course/native-library comparisons and source comparison. Recheck only actual visibility/clearance findings and mechanism spaces affected by the art. The implementation author is not a final judge.
