# Decisions

## 2026-10-27 — Shelve Classic Ascent

The owner shelved Classic Ascent. `classic_ascent_point_to_point` is now in `CourseConfig.RetiredCourseIds`, so course discovery skips any remaining copy and it cannot appear in voting. Its 13 builders, `CourseMotionService` (only Classic Ascent used its snowball/lava/log hazards), `AscentMotionConfig`, its ambience config, `AscentWater.client.luau` and 10 Studio tests were removed from the repository; the source and pre-edit copies of the eight edited files are in [archive/classic-ascent-shelved-2026-10-27](../archive/classic-ascent-shelved-2026-10-27/README.md). `ClassicAscentAmbience.client.luau` is the shared sky/lighting script for City Run, Shipwreck, Stud Garden and Moonlit, so it stays under its old name (the Keyboard Circuit client finds it by that name). `CourseLifecycle` now checks the configured active course. Heartwood Ascent is a separate course and is unaffected. The Studio models still need exporting and removing after the playtest.

## 2026-10-27 — Retire the slanted Sky Rush plate images

The owner flagged buttons whose lower edge looked cut ("sliced"). Roblox draws a 9-slice image in separately rounded pieces, which is invisible on straight edges but leaves a visible step on slanted ones at nearly every size, so the earlier height-range rule could not prevent it. Every Sky Rush plate and button is now a straight rounded panel (gradient body, navy outline, drop shadow) built in `UiKit`; no UI draws from the slanted images (`assets/ui/race/make_sky_plates.py` output is unused). `Kit.SkySlant` returns 0 for the layouts that still ask.

## 2026-10-27 — Preview UI with UI Labs stories instead of the custom plugin

The owner found the custom UI Preview plugin unusable and chose UI Labs (free community Storybook plugin) to see screens without Play. Stories live in `src/ServerStorage/UIStories` (Rojo-synced, ServerStorage so they never ship to players) and draw the real screen modules with sample data through one helper, `StoryKit`. To allow this, `RaceFlowView.Create` takes an optional host frame, `NextCourseView` accepts a plain frame, `LobbyUiController` gains `ToggleCoins` and an optional shop tab, and `UiKit` has a `Silent` flag; game behaviour is unchanged. The old `tools/ui-preview` plugin is superseded and kept, not deleted. [Guide](UI_PREVIEW.md).

## 2026-10-27 — Open-sky Egg Rush and an honest per-role 8.5 visual gate

The owner rejects the broad grey pit and commissions a floating sky course plus improved Start/checkpoints. Remove the added shared bedrock/long supports and use compact local undersides; retain original contacts, invisible fall recovery, Expert, hazards, chicken and lap/respawn rules. Finish safe pockets through restrained mint/honey trim and legible single numerals, with no extra walls or raised catch floors. Correct the observed Egg Rush banner cleanup in staging without changing other maps or gate collision. Record allowed appearance changes explicitly.

Require each requested role to independently reach at least 8.5/10 on the frozen visual evidence. Preserve C01's failed helper 8.3 and fix its real numeral-orientation finding; C02's three 8.7 scores cover inspected native Edit visuals only. Keep actual lifecycle, source/recovery, runtime-horizon, traversal and owner acceptance claims separate. The owner explicitly approved the two named current-pass draft deletions after automatic review blocked them; no broader deletion authority follows. [Handoff](artifacts/egg-rush-circuit/phase3/sky-pass/STATUS.md).

## 2026-10-27 — Egg Rush QC preserves gameplay and removes competing scenery

Use installed `ER_P3_W05_C05` for the owner's comprehensive quality-control pass. Correct demonstrated composition and assembly faults in the durable world plan and reusable kit. Keep the accepted route, hazard timings, lap/checkpoint behavior, Expert difficulty and chicken motion. Hide only the six explicitly named types of superseded nonfunctional art after checking their physics and saved references; record their 25 transparency changes as exceptions rather than claiming unchanged appearance. Preserve the original instances and recovery history.

Use one Studio through MCP without further desktop control. Judge the final course-local assembly through frozen native Edit views, sampled native clearance and separate reviewer/helper/inspector reports. Actual initialized client checks govern race/asset/ambience evidence. Failed or HUD-only Play captures cannot clear the 3D horizon or justify changing production rendering. Save a fresh candidate-named scoped recovery without replacing older payloads; distinguish it from a whole-place save. [QC status](artifacts/egg-rush-circuit/phase3/qc-pass/QC_STATUS.md).

## Historical 2026-10-26 — Complete authorized Egg Rush Phase3 while preserving accepted R03/R05

The owner accepted Phase2 and authorized the complete immersive Phase3 world while asleep. This supersedes earlier Egg Rush chicken-only, pending-Phase2 and stop-before-Phase3 gates; those decisions and evidence limits remain below as history. Final acceptance of the unseen Phase3 world is still the owner's decision. Keep one Studio and prefer active Rojo/Studio MCP, with minimal necessary UI for a verified local save. No authentication/sign-in/account or publication changes are authorized. The [current course brief](artifacts/egg-rush-circuit/COURSE_BRIEF.md) is the current record.

Use installed/canonical `ER_P3_W03_C02`, WorldPlan W03: 976 new scenery parts, six lights and the unchanged A03 mesh assets. Correct rejected W02 C02 composition through inward fronts, vaulted/setback masses and broad visible gardens. Review demonstrated a reachable gallery ghost floor; use matching solid geometry (17 walls and one floor), with floor/collar/stem below the actual Fall top. Keep the original 626 gameplay parts / 1,185 instances exact rather than softening Expert or changing progression for a test driver. The 4,064-query QA pass retains all source/native collision, rectangle-envelope and raw fall limits.

Run actual flow checks from the initialized native LocalScript/server contexts. A cold plugin require without RaceFlow state does not establish a production fault. Keep failed preparations and driver contacts as evidence: Normal R04 never started; Gallery R02 passed geometry preflight but hit ReturnHotGrate before jumping. Full Normal R05 and corrected gallery R03 results remain **PENDING**, as do the W03 atmosphere repeat and three final review updates. Do not reuse focused pre-world/C02 passes or old scores as full W03 acceptance.

The owner separately approved exactly five old candidate Models; remove only those 11,019 instances and retain source history, accepted Phase2 and recovery. [Exact cleanup](artifacts/egg-rush-circuit/phase3/current-w01/cleanup-five-approved-drafts.json). Keep the verified 270,794-byte W02 C02 scoped recovery as earlier recovery, not final W03 coverage or a whole-place save. Final W03 scoped recovery and verified native whole-place save remain **PENDING**; record their receipts before test teardown/cleanup and final owner handoff.

## Historical 2026-10-26 — Continuous chicken attention and retained stance

The owner rejects R04's repeated fixed-home reset. Use a deterministic previous-target watch pose, lifted recovery and raised transition toward the next target. Head attention leads body and alternating steps; only Stop restores authored transforms. Preserve the same three targets/order, lethal beak and warning/strike timings. The new classic native-part model keeps the short-neck attachment contract while adding stepped body/feather/face shaping. Leave all other course content outside this pass. Independent review supports, but does not grant, owner acceptance. [Current handoff](artifacts/egg-rush-circuit/phase2/chicken-r05/FINAL_HANDOFF.md).

## Historical 2026-10-26 — One pass solely on the chicken

The owner rejects the swan-like bird and limits this pass to the chicken. Replace the long-necked fixed-body silhouette with a full blocky body/head,12-stud total neck, bold chicken features and body-led bow/turn with foot shuffles. Keep the three target positions/order/timings and visible red-beak contact. Move/raise only its explicit roost support; preserve Expert, laps, other hazards, storage and unrelated work. Judge identity through current in-course poses/motion, not isolated anatomy math or prior R03 acceptance. Three independent Sol6.1 Extra High reviewers support owner judgment; stop before Phase3 or further Phase2 work. [Current handoff](artifacts/egg-rush-circuit/phase2/chicken-r04/FINAL_HANDOFF.md).

## Historical 2026-10-26 — R03 peck, readable hazards and owner-tested Expert

The owner requests another scoped Phase2 revision: plain red lethal forms/clear placement, a cleared Incubator pipe/decor corridor, lap/Start clarity, a three-target peck replacing the chicken tail, Play/storage investigation and even harder Expert for personal testing. Keep the body/feet fixed and connect the moving head with two constant-length neck links. Amber target warnings are nonlethal; only the visible red beak is queried during strike/impact. Preserve three laps/four ordered checkpoints and existing server progression; expose lap count separately and author Start recovery rather than rewriting correct lap rules.

Current C04 uses narrower Expert contacts and shorter Crown windows. Disclose the two slightly negative ideal surface projections; do not soften Expert to satisfy an automated driver or claim human completion from the audit. Storage and one warm Play sample are an investigation, not a diagnosed delay or measured speed gain. Preserve external files, authentication and history; use one Studio/Play session, verify recovery and stop for owner review before Phase3 or further Phase2 changes. [Current handoff](artifacts/egg-rush-circuit/phase2/revision-r03/FINAL_HANDOFF.md).

## Historical 2026-10-26 — Implement the six-image critique without softening Expert to suit the test driver

The owner authorizes a scoped Phase2 revision and explicitly permits visual/physical feasibility judgment for Expert when automated controls are limited. Use narrow angled contacts, rises/drops and shorter Crown windows; keep impossible jumps and actual clipping separate from an automated driver's inability. Preserve three laps, four ordered checkpoints and the main encounters. LayoutR02/RevisionR02 govern current geometry; old C05 shapes and timings do not establish C07.

Increase meaningful themed hazards and egg frequency, require two differently directed tray transfers, enlarge local decor and make the 3.6× chicken a landmark. Resolve demonstrated bypass/false-support findings through geometry, with no hypothetical race/security additions. Four independent `gpt-6.1-sol` / `xhigh` reviewers support strict owner review within stated limits. Keep one Studio, preserve owner placement/history, finish local recovery/cleanup and stop before Phase3 or further Phase2 changes. [Current handoff](artifacts/egg-rush-circuit/phase2/revision-r02/FINAL_HANDOFF.md).

## Historical 2026-10-22 — Close Phase2 at owner review after the restored-session checks

The owner restored Studio asset fetching by signing back in. Keep the required structural/hazard readiness gate; do not replace or reupload valid Open Use meshes. The final supported ordinary flow and both continuous three-lap races pass in one Studio/client. The intermittent automated return-hop slowdown is addressed in the test fixture by isolating default movement only after real Racing/camera handoff and restoring it afterward; no course widening or production-control change is justified. Preserve failed receipts, static merge-support qualifications and bounded two-body exit limits.

Save exact traces/read back before Play teardown; final36–40 do so. Leave the sole Studio open in Edit with owner work preserved. Scoped implementation/automated checks are complete, owner acceptance is pending, and Phase3 or Phase2 continuation requires a new owner instruction. [Final closeout](artifacts/egg-rush-circuit/phase2/restart-r01/FINAL_CLOSEOUT.md).

## 2026-10-21 — Visible lobby architecture is required for arrival

The owner observed a broken lobby after reporting restored asset access. Fresh inspection confirms missing visible walls/floors and authentication-required mesh requests. Hidden primitive colliders cannot establish a complete lobby. Supersede the earlier blanket optional treatment of lobby mesh geometry: require confirmed content for existing structural components, while textures, plants, benches, UI and avatar/NPC appearance remain optional. Preserve collision/geometry and server validation. Restore the missing live ArrivalAssets dependency from canonical source. Do not call the earlier Ready-only observations a functioning-lobby pass, or restart final races while fresh geometry fetches still fail. [Evidence and source recovery](artifacts/egg-rush-circuit/phase2/restart-r01/LOBBY_LOADING_FOLLOWUP.md).

## 2026-10-21 — Keep required mesh readiness and stop at the asset-access block

Separate optional appearance fetches from physical lobby readiness. Keep collidable, support and lethal course mesh geometry required for race admission. The owner approved inspecting the eight listed meshes and repairing missing use access only for Obby Tournament10191126818. All eight are already Open Use; no permission or sign-in change was needed. Studio still reports mesh authentication/fetch errors. Wait for owner-restored access in the existing Studio before final ordinary admission/race/finish/rejoin checks; do not hide the error by weakening hazard readiness.

The bounded one-client/fitted-rig full tray/exit check passes in both lane assignments. This closes that tested physical sequence, while the original two-client primary miss and broader multiplayer capacity remain unproved. Keep one Studio, save raw receipts before stopping tests, and preserve the Phase2 owner-review gate before Phase3 or further Phase2 scope. [Follow-up record](artifacts/egg-rush-circuit/phase2/restart-r01/ENTRY_EXIT_FOLLOWUP.md).

## 2026-10-21 — Bound Studio resource use

The owner explicitly warned that the device has limited performance and requires efficient testing and cleanup. Continue Egg Rush with one Studio session/client and sequential controllers. Do not repeat the larger-group launches. Preserve failed entry/traffic evidence and distinguish test-assisted pacing from supported entry. Stop owned tests and local receivers after saving their receipts; preserve owner work and credentials.

## Historical 2026-10-21 — Egg Rush Phase1 accepted, Phase2 authorized

The owner explicitly said “proceed with Phase 2. Remember I will be very strict with Phase 2 and the course”. This supersedes only the Phase1 wait. Use the accepted ER_P1_R01/R03/T01 foundation,26-unit kit and near-lobby placement. Complete the actual course experience, entry/progress/recovery/three-lap finish and bounded physical traffic checks. Present for strict owner review and STOP before Phase3. No C15 readmission, publication or unrelated systems work is authorized. [Current contract](artifacts/egg-rush-circuit/COURSE_BRIEF.md) / [active work](artifacts/egg-rush-circuit/phase2/restart-r01/STATUS.md).

## Historical Phase1 restart decision — superseded only by later phase approval

The owner requested moving the Phase1 course and gallery nearer the lobby and confirmed their latest Studio positions. Current course origin is `(1544,388,-1134)`; gallery pivot is `(1710,330.9,-850)`. Preserve that placement, synchronize world-space checkpoint/landing data and the source origin, and retain the before-move recovery. This changes placement only and does not authorize Phase2.

The owner correction controls: start again at Phase1, deliver the reusable kit, cheap whole-route study and one finished playable Shellworks sample, then STOP for owner assessment. Explicit approval is required before Phase2 and again before Phase3. C15 and its results remain unaccepted history. ER_P1_R01 stays Phase1/disabled in authoring; only the owned test-server copy is deliberately enabled. Both approved frozen FBX uploads to creator86069177 completed; no further upload or publication is part of this fix.

R03 keeps eight physical volumes matching each shell solid, opposing hinges and90-degree closed poses. The existing character collider is fitted once for eligible racers on the opt-in FullBodyContacts course. Body bounds receive0.5-stud padding and1.25-stud forward animation clearance because native measurements showed about0.75 stud of jump-head lean outside the standing fit. Restore the original collider Size/WeldC0/C1 and movement profile on release. Keep climbing settings and shared Avatar Settings unchanged; do not add world blockers. The failed no-Climb trial is evidence, not shipped behavior.

Final-source native29 found zero crossing/Head-torso overlap in four bounded closed attempts; native30/31 completed both rough lap choices including the sample/S4 join with zero observed shell overlap. This is not exhaustive closed-route/all-avatar proof. Keep the inconclusive unrestricted-turning bound visible. The Expert timing mismatch was resolved within Phase1 by T01 shared dwell/phase timing, preserving accepted geometry and all encounters. T01 actual consecutive three-lap races finished **174.511 seconds Expert / 306.537 seconds Normal**, inside the 120–180 / 240–360-second design ranges for these scripted controls. Each recorded 12 ordered checkpoint splits, 3 forward gates, 0 falls and 3 supported full 21-stud tray carries. Head/Torso queries found 0 shell-overlap samples across 1,593 Expert / 2,795 Normal observations at about 10 Hz. Expert used the existing practiced controls; Normal used conservative controls and an explicitly recorded earlier takeoff on the one static red hop. This is actual native scripted timing, not human, crowd, physical-device/FPS or universal-route acceptance. [Pacing decision](artifacts/egg-rush-circuit/phase1/restart-r01/pacing/CLOSEOUT.md). The owner explicitly approved the local-only Phase1 backup after the automatic review block. The187,627-byte R03 package passed file-hash, byte-readback and detached five-root /18-source checks. HTTP is restored and the receiver stopped; the current owner camera is untouched. [Review and recovery record](artifacts/egg-rush-circuit/phase1/restart-r01/PHASE1_REVIEW.md). Preserve unrelated work/global lighting and do not start Phase2.

[Current brief](artifacts/egg-rush-circuit/COURSE_BRIEF.md) · [Restart record](artifacts/egg-rush-circuit/phase1/restart-r01/STATUS.md).

## 2026-10-21 — Moonlit Violet Veil sky with slow local rotation

The owner selected D/S04 and requested implementation with slow rotation. Use six projected 512px faces, zero engine stars, the existing engine moon and a level 0.2-degree/second yaw in the course ambience profile. The shared controller restores orientation with the other Sky properties and rotates only configured active profiles. Preserve accepted Source57/Build51 geometry and lighting. Source/offline checks pass; native appearance and lifecycle checks remain pending after the owner objected to Computer Use while using the device. [Feature handoff](artifacts/moonlit-citadel/skybox-20261021/HANDOFF.md).

## Moonlit Citadel accepted and closed — October20

The owner directed “Consider Moonlit Citadel done.” Accept Source57 / Build51 and close the map work, superseding earlier pending-work requirements. Preserve the frozen verification reports and unscored visual-review limits as historical facts; do not relabel unperformed checks as passed. Further map changes require a new owner request. This closeout changes acceptance metadata and records only, without publishing or a whole-place Save.

## Moonlit exact surface repair and recoverable cleanup — October20

Source57 uses guarded inert-part relief plus Blender union of exact same-facing overlapping faces, retaining surface bounds, UVs and normal direction. The broader independent scan caught incomplete Kit01 and an incoherent niche trim offset; only full-plane Kit02 and coherent138-target poses are active. Preserve original nonzero relief, queryable lantern geometry, floor/veil and gameplay contacts. Archive inactive native history/imports with instance restore links rather than deleting it; keep current recovery and seven required libraries. Source57 native/full-build proof does not replace moving-camera appearance approval when screenshots are blank.

## Moonlit depth must retain the floor — October20

The owner means a veil that obscures the low ground and suggests height. Preserve the original floor; do not replace it with an open void. Source56 uses local feathered horizontal smoke below the route, with the existing night profile unchanged. Source55 floor-removal scores are historical and do not override this direction. Current source and native recovery are retained; automatic approval review blocked a fresh backup-file transfer to the local HTTP receiver, so that optional export did not run.

## 2026-10-20 — Repair the measured surface/finish cause and retain recoverable history

Moonlit Source55 separates only explicit decorative material faces and reuses existing art for the crown/gallery grouping. The Blender DP01 chasm removes unsupported bed faces while retaining the actual support/top triangles; compare native oriented faces rather than vertex counts alone. Keep the normal race/checkpoint/forward-gate logic unchanged: its instant crossing was correct, but the finish volume excluded valid jump/edge arrivals. Resize that one trigger to the supported envelope. Archive inactive prototypes/snapshots by identity with original-parent references and verified binary recovery, rather than deleting them.

Full WorldAssembly.Apply is the current fresh-build path. AddDetails supports a prepared matching base, not arbitrary legacy migrations; every placement path must apply the same surface corrections. This local decision changes no global workflow or memory. [Source55 record](artifacts/moonlit-citadel/phase3/repair-20261019/REVIEW_PACKET55.md).

## 2026-10-15 — Moonlit details need visible scale and actual triangle proof

Source53 passed technical integration but its art review held bare gate/west walls and weak nearby planting/machinery. Source54 uses larger connected architectural bays and visible mounted gardens/hoists while preserving all Source52 records. Keep the rejected composition recoverable; judge the corrected frozen candidate independently. Matching vertices did not prove imported surfaces: actual Roblox face comparison exposed holes in the first hoist curves. Stable torus frames and explicit FBX triangles corrected the handwheel/coils; all six final supplemental parts now match all3,258 oriented triangles through FBX and native import. Preserve those failed receipts and use actual face proof for this asset handoff. This is a local decision record, with no global workflow or memory change. [Final handoff](artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/FINAL_HANDOFF_SOURCE54.md).

## 2026-10-14 — Moonlit detail fits the preserved world

The owner supplied a bare-wall photograph and authorized map-wide detail. Use a Blender-authored reusable kit and measured support surfaces to add niches, cornices, roof features, banners, ivy, herb planting and yard props around the existing citadel. Keep all Source52 art and accepted course records exact; integrate through additive WorldAssembly.AddDetails. Retain failed drafts and the unused first upload; use corrected R01 only. Final native/property, import-basis, saved/source and occupied-clearance evidence close the integration. No global workflow or memory edits. [Current frozen packet](artifacts/moonlit-citadel/phase3/detail-pass-20261014/REVIEW_PACKET53.md).


## 2026-10-14 — Moonlit finishing around the accepted course

Use the existing approved meshes for the final scenery correction. An explicit one-part depth override separates the pinnacle trim while preserving its position, material, original template and every accepted contact. Assembled Blender views and actual-face proof found defects that clearance rays alone missed; original current Roblox movement samples establish the rendered result. Preserve intermediate failures and exact evidence limits. No workflow rules or memory were changed. [Current evidence](artifacts/moonlit-citadel/phase3/closeout-20261014/REVIEW_PACKET52.md).

## 2026-10-13 — Moonlit art fits the accepted course

Source40 joins the citadel through art-only volumes, complete Blender roof/body units, broad foundations and deeper rock groups. Accepted course contacts, mechanisms, falls and19 selected arrows remain exact. Keep the old lower-keep recipe in BaselineWorldPlan and custom hollow bounds/costs in AssetGeometry; place the art through existing WorldAssembly. Normalize only the new AR01 import to the author's axes, and verify native poses against the corrected library. Course-local night remains in the existing ambience controller; its real held-lobby restoration was checked. [Eight repairs and evidence](artifacts/moonlit-citadel/phase3/art-repair-20261013/REPORT.md).

## 2026-10-13 — Claude Code trial alongside Codex

The owner is trying Claude Code with the same workflow. Keep one shared `AGENTS.md`, `docs/` and this decision log; Claude-specific setup lives in `CLAUDE.md`, `.mcp.json` and [docs/claude/](claude/README.md). Codex configuration and Codex-era docs stay unchanged so both tools work. Course Ideation, Feature Ideation and Workflow Engineer have Claude session starters; their Codex threads remain as history. Moonlit Citadel stays with its Codex Creator unless the owner moves it. Only one tool controls Studio/Blender at a time. Claude has no built-in image generator; reference images come from the Figma connector (Figma AI credits) or are produced elsewhere. The October 2 flow study was saved from chat to [game-flow-study-2026-10-02](artifacts/game-flow-study-2026-10-02/FLOW_STUDY.md).

## Shipwreck Cove stored editing source

The owner requested Shipwreck Cove in ServerStorage with working Dev Tools. Keep its editable Folder in `ServerStorage.CourseLibrary`. Prepare a runtime Model there before normal Model-only discovery; preserve the existing Workspace editing path. A converted template already in the library must not be archived as its own predecessor. Other course discovery, progression and UI stay on their existing paths.

## 2026-10-06 - Giant's Backyard course sky

Use the owner-selected Giant's Backyard artwork as Stud Garden's own environment profile in the existing client ambience controller. Keep the lobby baseline in `default.project.json`; exclude the nearby Grand Arcade through the optional profile setting. Use six uploaded sky images without adding course geometry. Zero haze preserves the pictured garden floor. [Implementation and verification](STUD_GARDEN_SKY.md).

## 2026-10-06 — Grand Arcade installed-model runtime

The owner extended cleanup to Grand Arcade. Keep the current native stage and lobby walkway, and load the installed stage directly in GrandArcadeService. Retire the old A01 auto-install fallback and five authoring modules from the running game; preserve them with old imports and repair records in the verified disk archive. Include the complete lobby and stage in the recovery archive so C01/R01 ObjectValue links survive. Current geometry and presentation behavior remain unchanged. [Cleanup and recovery](artifacts/grand-arcade-cleanup-20261006/REPORT.md).

## 2026-10-06 — Stud Garden approved runtime and offline authoring

Owner approval closes the requested course iteration. Keep the approved editable native model and seven runtime modules in the game; preserve old builders, prototypes, imports and recovery copies in a verified disk archive. Move HazardState into V2 and retire the V1 service path. Group visible owner scenery into the course without changing parts. Record owner approval separately from full-race, twenty-player and device/performance evidence. Cleanup does not enable public selection or publish the place. [Cleanup and recovery](artifacts/stud-garden-v2/cleanup-20261006/REPORT.md).

## 2026-10-06 — Stud Garden V2 final pass boundaries

Reuse the shared moving-thorn controller for three local patterns and explicit visual followers. Preserve full green crossing windows while moderately shortening the timed hazards' active periods. Keep giant sculptures outside gameplay physics; reapply flags when the avatar is cloned. Preserve the owner's native geometry and archive the frozen avatar appearance. Report the empty Roblox Status object's serialization omission explicitly and keep full-race, twenty-player and performance acceptance separate from the focused F01 pass. [Final report](artifacts/stud-garden-v2/finalpass-20261006/REPORT.md).

## 2026-10-03 — Heartwood Ascent archived outside the game

Owner put Heartwood on hold and authorized removal, including deletion if necessary. Preserve native manual edits and history in a verified disk archive, then remove its models, imports, libraries and mapped source from the place. ServerStorage archives still consume memory, so no Heartwood archive remains there. Remove only its three shared registrations. Existing courses and unrelated edits remain. No automatic resumption or new-map asset approval is inherited. [Recovery and proof](../archives/heartwood-ascent/hold-2026-10-03/README.md).

## 2026-10-03 - Heartwood Ascent HA04 completion

Complete the existing Heartwood form requirements with connected bark relief, varied shelf undersides, attached broader crowns and supported forest depth. Preserve route planes, mechanics and originals. The independent final form review closes the preceding three concrete omissions. Placed art is 246,536 triangles, below the 250,000 working assumption; that is not performance acceptance.

Keep Main_1's original outline and the successful B1 centre aim. The main recipe explicitly walks to Wide's supported edge before Detour1, adding one observation to the original 65 ordered beats. The finish fixture permits four studs from unchanged F0 because avatar contact immediately locks movement; exact support, Finished, checkpoint 3 and no new hit/recovery remain required. No gameplay tuning or arbitrary waits were added.

Separate current solo gameplay, visual implementation, source and recovery evidence from owner preference, human pace, devices and multiplayer. One foreground gardens stationary sample is recorded without a matched foreground HA03 baseline or FPS/improvement claim.

[Final HA04 evidence](artifacts/heartwood-ascent/v1/FINAL_REPORT.md).

## 2026-10-03 — Heartwood Ascent HA03

The native brief/diagram keep route authority; A3 and visual set 2 guide appearance. HA03 retains the HA02 route planes and mechanics while replacing visible route tops/ramps with fitted physical meshes and adding joined bark, roots, foliage and an open sanctuary. Visible nearby bark and petals have checked collision; distant scenery is marked separately. Materials retain the previous effective physics.

Bloom eligibility, personal tokens, cue acknowledgement, release and recovery stay on the server. A client acknowledges two placed ring frames; release requires the same eligible grounded character and at least 0.55 seconds after acknowledgement. The deeper mesh tops preserve the original floor-relative missed-landing threshold. No auto-aim or boost increase was introduced.

Keep HA03 at 492,368 placed art triangles for owner review. This exceeds the 250,000 working assumption; it is not an approved shipping budget. Appearance, measured performance, human pacing and multiplayer/device acceptance remain separate decisions. [Evidence report](artifacts/heartwood-ascent/v1/FINAL_REPORT_HA03_HISTORY.md).

Record important project decisions here.

## 2026-10-02 — Phase capsule layout stays consistent between screens

Lobby and Voting use `PhaseCapsule.UseDesktopLayout` for their top-middle timer, independently of the Voting panel's breakpoint. This keeps the accepted capsule size and position when Voting opens at intermediate desktop widths.

## 2026-10-01 — Lobby HUD follows the supplied reference

Replace the earlier approximation with the owner's exact image proportions and styling. Use original Blender-rendered transparent icons, native interactive buttons/text and a transparent resizable quest ticket; keep editable Figma components and source files. Preserve existing server-owned balances, race messages and actions. Sample keys/quest progress exist only in an Edit-only Reference HUD view. Four changed game modules matched Rojo source; no gameplay backend or economy change was required. See [lobby guide](LOBBY_UI.md).

## 2026-09-24 — Shipwreck Cove final critique candidate

Keep the approved cave shell and owner placements. Build the requested route changes from frozen layout27 through routes28.py/layout28.py, with reusable Blender meshes and separate simple walking colliders. Preserve removed instructional signs. Strong outlined floor arrows identify the main route; amber narrow landings identify expert shortcuts; the cave stone jumps stay arrowless.

Use two independent wave zones with a safe middle refuge and checkpoint5 after the second crossing. A curling crest advances before its trailing flood; refuges remain above the pool. Warning phases are nonlethal. Server runtime owns contact, cannon arcs, crumble, falling spikes and randomized coconut timing. Keep the existing player collision policy. No new remotes or map-embedded scripts.

The horizon uses38 persistent distant meshes to remain visible while streaming. Working ceilings are120k placed mesh triangles,1600 parts,60 unique live meshes,6 lights and32 falling hazards; these budgets are not device-performance measurements. The Toolbox rope candidate was rejected because geometry and texture costs could not be verified. The custom wave and palm source remain editable in Blender.

## 2026-09-23 — One shared obstacle palette

ObstacleKit_Palette is a reusable library for all current and future courses, not a City Run-specific kit. Sets 31–42 use the existing generic motion, kill and crumble systems. Add new shapes and compositions without per-piece scripts or remotes. Keep the owner's existing pieces and chosen palette position. Future course templates should bind CourseHazardService and RespawnService, preserving the standard hazard attributes when obstacles are reskinned.

## 2026-09-22 — Retired maps live outside the place

At the owner's request, export and remove ServerStorage.Archive plus authored Classic Ascent V7. Native exports and a source snapshot are preserved in local Git commit `c1f85b1`, under `archive/retired-maps-2026-09-22`; this folder is outside Rojo. Save/readback/deserialization fingerprints and Git blob bytes were checked before removal. Disable automatic Classic Ascent generation so startup cannot restore the retired map. Keep shared asset libraries, the obstacle palette, V3 and the lobby. No push or Roblox publishing was performed. See [restore instructions](../archive/retired-maps-2026-09-22/README.md).

## 2026-09-22 — Edited V3 and Studio development controls

Use `Workspace.Course_CityRun` as the sole editable City Run V3. Retire inspection startup that selected stale V1/V2 snapshots. At Play startup, CourseService adopts the visible model into the session library, preserving Edit-mode geometry; map selection remains session-only. Keep scripts in Rojo/Git and geometry in saved native places/backups. Group ServerStorage into DeveloperAssets, AssetLibraries, AssetImports, CourseLibrary, CourseBuilders and Archive. User approved the prepared migration; 3,117 V3 part transforms/sizes were preserved.

One F6 panel replaces the previous development panels. Its RemoteFunction is created only in Studio and validates all actions on the server. See [workflow and payload behavior](DEVELOPMENT_WORKFLOW.md) and [evidence](artifacts/development-cleanup-2026-09-22.json).

### 2026-09-06 — River reset concealment and modest Skyline tuning

Cap camera zoom at 30 studs. Keep the extended river outside the existing
boundaries and enclose complete log reset positions with opaque scenery. Preserve
log speed and arrival frequency. Shorten Section 09 footholds by 0.5 studs while
improving their contrast. See [verification](RIVER_FINISH_VERIFICATION.md).

### 2026-05-19 - Use Git and Rojo as Source of Truth

**Decision:** Git stores durable project source, and Rojo syncs filesystem source into Roblox Studio.

**Reasoning:** This keeps AI-assisted edits reviewable, diffable, reversible, and portable across sessions.

**Impact:** Scripts and configuration should normally be edited in the repository first. Studio-only script edits should be treated as temporary unless mirrored back into the repo.

**Alternatives Considered:** Editing directly in Roblox Studio as the primary workflow. Rejected because it weakens review, rollback, and AI collaboration.

### 2026-05-19 - Keep Gameplay-Critical Logic Server-Authoritative

**Decision:** Currency, inventory, damage, rewards, progression, purchases, unlocks, matchmaking, and other gameplay-critical systems must be owned and validated by the server.

**Reasoning:** Client input can be modified or faked. Server validation is required for security and consistency.

**Impact:** RemoteEvents and RemoteFunctions must validate payloads, permissions, cooldowns, ownership, and state transitions server-side.

**Alternatives Considered:** Faster client-trusting prototypes. Rejected for systems that affect progression, economy, combat, rewards, or purchases.

### 2026-05-19 - Use a Service-Oriented Server Layout

**Decision:** Server systems should live under `ServerScriptService/Services` as focused ModuleScripts when they become substantial.

**Reasoning:** This keeps gameplay systems modular, testable, and easier for Codex to modify safely.

**Impact:** Avoid growing `Main.server.luau` into a large script. Use it mainly for bootstrap/wiring when services are introduced.

**Alternatives Considered:** One large server script. Rejected because it becomes hard to review and maintain.

### 2026-05-20 - MVP Race Foundation Is Server-Authoritative and Point-to-Point First

**Decision:** The MVP race architecture starts with `RaceFormat = "PointToPoint"` while keeping
`LapBased` as a planned type/config option for later implementation.

**Reasoning:** The first playable milestone should prove one excellent live race loop before adding
course selection or lap/circuit complexity.

**Impact:** Race state, player status, checkpoint progress, finish validation, placement, and result
data are owned by the server. Personal bests are in-memory only until DataStore use is explicitly
approved.

**Alternatives Considered:** Building multiple formats, persistent PBs, ranked points, or course
selection immediately. Rejected for MVP scope control.

### 2026-05-30 - Add LapBased Validation Without Course Selection UI

**Decision:** LapBased race validation is implemented server-side for enabled course models, but
public course selection, course voting, and persistence remain outside MVP scope.

**Reasoning:** Friend playtesting needs a circuit race path, but players should not be able to
choose or authoritatively influence active course state from the client.

**Impact:** `CheckpointService` owns lap progression, `ResultsService` stores lap-aware in-memory
result data, and `CourseConfig.ActiveCourseId` remains the server-owned way to pick the active
course for now.

**Alternatives Considered:** Adding player-facing course selection or full rotation immediately.
Rejected until both course formats are smoke-tested.

## Template

### 2026-09-05 - Classic Ascent Uses a Reproducible Course Builder

**Decision:** Add Course_ClassicAscentPointToPoint as a separate course, generated
from a server-only builder when absent. Preserve the original Studio courses.

**Reasoning:** New course geometry must be recoverable from Git while allowing
explicit Studio authoring without silently overwriting it.

**Impact:** Fixed selection uses classic_ascent_point_to_point. Course-specific
fall volumes replace the assumption of one named trigger. The shared timeout is
nine minutes, with early completion when all official racers finish or leave.
Completion targets remain unvalidated until human timing passes. See CLASSIC_ASCENT.md.


### YYYY-MM-DD - Decision Title

**Decision:** TBD.

**Reasoning:** TBD.

**Impact:** TBD.

**Alternatives Considered:** TBD.

### 2026-09-05 - Alpine environment rebuild and explicit authoring refresh

**Decision:** Replace the rectangular placeholder with a ten-section, 146-transition
mountain route. Separate route construction from deterministic scenery. Keep the
nineteen checkpoints, nine-minute maximum, and existing authoritative race rules.

**Reasoning:** Passing mechanics tests did not satisfy the requested complete
setting. The route needs recognizable places and visible progress while retaining
short recovery distances. Native parts and materials keep the course reproducible.

**Impact:** Builder version 1 is archived under a disabled placeholder name when
upgraded. Version 2 authoring models are not silently overwritten. Review iterations
are preserved in ServerStorage.CourseBuildArchive. The current Edit RaceCourse is
a copy of the new authoring model; normal CourseService startup archives this copy
and spawns the selected runtime course. Local ambience restores the preexisting
Lighting values when the player returns to the lobby. Human acceptance is pending.

### 2026-09-05 - Integrate mountain terrain, active obstacles, and safe staging

**Decision:** Version 3 joins the route to solid banks and cliff foundations,
replaces floating signs with mounted waymarkers, simplifies summit slopes, and
connects bridge rope spans. Add three small hazard types with server-owned timing.

**Reasoning:** The first alpine version still played as an unchallenging walkway
with disconnected scenery. Hazards need visible warnings and checkpoint recovery,
not unpredictable unavoidable deaths. A start barrier should define the race start
without teleporting players twice.

**Impact:** CourseHazardService binds with the active course and uses existing
RespawnService death recovery. All hazard timing is in HazardConfig. Intermission
stages once; the gate opens on Racing without a second teleport. Local sky and
lighting restore when the player returns to the lobby. No economy, DataStore,
publishing, course rotation, or new circuit work is included.
## 2026-09-05 — Shared adventure space and instant hazard recovery

Version 4 uses three branching lines and wide shared checkpoints for the requested
20-player race. Scenery sits between and above routes, with shared forest/snow ground.
Keep the nine-minute ceiling; the user's roughly six-minute v3 run is human evidence,
while v4 timings remain unmeasured. Do not increase enforced waiting to stretch runs.

Ordinary lethal contacts call server-only RespawnService.RecoverPlayer instead of
killing the Humanoid. Nonlethal snowballs deal 35 damage; lethal damage recovers and
heals. CourseMotionService owns log travel, vents and projectile cycles. No client
authority or new gameplay remotes. Unexpected real deaths retain the old fallback.
Preserve the user's manual sign transforms in source and archive the original model.

## 2026-09-06 - Classic Ascent v5 mesh scenery

Use the explicitly approved Blender prop asset 89332142209949, cached as named templates, for the v5 course. Preserve the approved mountain and the archived v4 course; remove repetitive ellipsoid decoration. Moving logs use one-way hidden resets; rolling hazards remain server-authoritative. See [v5 handoff](CLASSIC_ASCENT_V5.md).

## 2026-09-06 - Classic Ascent v6 grounding

Use supported cliff strata, planted scenic banks, a mountain-connected gallery and distant ridges around the preserved mountain. Block mountain/scenery shortcuts with continuous boundaries. River logs use native server-owned physics instead of moving rider characters; keep rider-carry acceptance open until the manual check passes. Previous Studio course copies were archived with explicit approval. See [v6 handoff](CLASSIC_ASCENT_V6.md).

## 2026-09-06 - Classic Ascent v7

Use bounded seeded foothold variation, full river banks with shorter/fewer logs, client-only foam, and cached ground-contact projectile arcs. Keep scenery boundaries independent of platform offsets. Approved Blender kit 112260230711687 adds cedar, fern and sculpted summits. Approved v6 copies were archived before installing v7. See [v7 handoff](CLASSIC_ASCENT_V7.md).

## 2026-09-06 - Final altitude treatment

Keep gameplay geometry intact and apply a one-time scenery pass to v7. Recess the rock floor, extend supports into layered ravine haze, add lower valley clouds, and enlarge scenery trees to 41-94 studs. Preserve before-update copies. See [v7 handoff](CLASSIC_ASCENT_V7.md#final-altitude-and-scale-pass).

## 2026-09-06 - Final haze and manual design handoff

Use native Atmosphere and distant ranges for broad haze; retire the 60 valley smoke emitters. Keep local bottomless-pit effects and place Skyline layers above the actual mountain slope. Classic Ascent has passed generated level design and moves to manual fine-tuning. Preserve accepted geometry unless another change is requested. See [v7 handoff](CLASSIC_ASCENT_V7.md#final-haze-and-design-acceptance) and [reusable design guide](LEVEL_DESIGN_GUIDE.md).


## 2026-09-16 - City Run C18 Studio inspection and deliberate promotion

Keep the preserved original and optimized City Run templates in ServerStorage.CityRunInspectionSources while the owner compares them in Studio. The Studio-only inspection service may switch and jump through either template, but it must not publish, replace the original editor course, or silently choose the optimized course for shipping. Retaining both templates has a temporary server-storage cost. Disable or remove inspection separately from a deliberate optimized-course promotion. Native Studio geometry remains outside Rojo source builds; save the current Studio file locally to preserve templates and inspection settings.
## 2026-09-16 - City Run V3 assets before assembly

Build V3 in two passes: complete and review the reusable painted asset kit first, then assemble scenery around preserved course geometry. Density along traversal and falling views takes priority over tiny realistic detail. Preserve V1 and V2. Use shared opaque texture artwork, named editable Blender meshes, and separate runtime collision/hazard assemblies. Local library counts are not map performance claims. See [asset-kit handoff](CITY_RUN_V3_ASSET_KIT.md).


### V3 imported asset normalization and evidence boundary

Normalize imported visuals to manifest stud dimensions and source-derived pivots instead of assuming cloud-import scale. Preserve outward normals on opaque artwork planes instead of enabling double-sided meshes. The verified kit04 uses one texture ID; latest kit05 remains local pending explicit revised upload permission. Review fixtures are separate from shipping course geometry.


### V3 Stage1 final delivery

Deliver the69asset library as one editable CityRun_V3_Stage1.blend and two immutable uploaded packages sharing one atlas. Keep sparse district accents as reusable meshes rather than multiplying small detail objects. All69 native sizes/pivots/visual flags and final independent asset reviews pass. Earlier pending-upload entries are historical. Preserve all review fixtures and V1/V2; Stage2 assembly and device performance validation remain separate.

## 2026-09-16 - City Run V3 Stage2 scenery assembly

Keep all three Studio inspection templates; add Rebuilt as an optional third variant with V1/V2 fallback. Use linked, opaque painted shells for scenery while preserving V2 gameplay geometry, pivots, physics flags, and moving-hazard configuration. Keep V3 preview/gallery out of the active Workspace during inspection. No automatic shipping promotion or publishing. See [Stage2 handoff](CITY_RUN_V3_STAGE2.md); its inventory reductions are not measured mobile or 20-player performance claims.


## 2026-09-16 - City Run Final03C quality and resource balance
Restore the original civic terminal geometry in 35 consolidated visual meshes and author surrounding shells to actual dimensions rather than stretching whole buildings. Keep richer city colors, shallow visual accents and shared props; add no dynamic lights or gameplay colliders. Accept 206,542 replacement-scenery triangles in exchange for the requested terminal quality while retaining 39.0% fewer overall parts than V2. Triangle counts rose relative to Stage2; inventory savings are not FPS claims. Preserve V1/V2, keep V3 an inspection option, and do not publish or promote automatically. [Final handoff](CITY_RUN_V3_FINAL.md).

## 2026-09-21 - Course workflow V2

Reuse the existing Course Ideation and Course Creator tasks with [V2](COURSE_WORKFLOW_V2.md). Ideation produces the editable draw.io plan plus ChatGPT ImageGen prompts for one appearance reference, one mood board, one loose clay idea and complementary layout images. Creator works through Asset Creation (including real-scale fit studies), then Map Creation. Carry scoped phase approval forward; the owner chooses subagents per prompt. Preserve player-view density, signature mechanics, manual edits and destination quality while optimizing. Use Chrrxs alongside official Studio MCP and Rojo for appropriate checks. This changes the workflow only; it does not authorize a new course, upload or publication.

## 2026-09-22 - Performance throughout Course Creator V2

Treat mobile/lower-end accessibility and the intended race population as requirements from Asset Creation onward. Plan resource costs before large-scale reuse, check representative assembled sections early and include a separate performance status at delivery. Keep device/full-race checks pending when unmeasured; visual scores and object counts cannot replace them. Ideation carries these priorities into every Creator handoff.

## 2026-09-23 - Shipwreck Cove low-poly asset kit

Use 35 reusable meshes with one opaque 128x128 palette and separate simple colliders. SC_KIT_04 contains 1,478 verified exported triangles; SC_P1_07 places 3,292 visual triangles across three small studies. Accept the documented small geometry increase for clearer grounding and cave silhouette without raising working ceilings. Preserve existing courses and keep the kit separate from production gameplay. Phase 1 upload approval covers creator 86069177 and necessary revisions, not publishing or full-map assembly. [Delivery and limits](artifacts/shipwreck-cove/phase1/REPORT.md).

## 2026-09-23 - Shipwreck Cove Phase 2 assembly

The owner authorized Map Creation and its necessary scoped revisions/uploads. Keep Shipwreck Cove as an optional course, preserve City Run and use the existing Studio inspection controls. Reuse the approved low-poly kit with 71 separate walking colliders. Both hard branches share their required checkpoint endpoints; both hazards remain mandatory. Use the same directional gate for all three laps and preserve completed laps across death. Only the new course opts into sampled forward-crossing detection; existing courses retain their existing finish-contact path.

SC_MAP_07 spends 728 more mesh triangles and 24 direction-mark parts than SC_MAP_06 on connected coastline/hull scenery and cliff readability. Working limits remain unchanged. One opaque water plane and a controlled local surge replace ocean simulation; active-course code owns hazard updates and recovery stays with the existing service. Four original low-cost audio cues are approved uploads, not a place publication. Native backups preserve earlier owned candidates. [Phase 2 evidence](artifacts/shipwreck-cove/phase2/REPORT.md) distinguishes focused checks from unverified 20-player/mobile and human pacing results.

## Shipwreck Cove concept A — September 23, 2026

Shipwreck Cove uses its own Sunlit Treasure Coast sky and ambience profile. Optional per-profile bloom/sun-ray overrides restore before switching maps or returning to the lobby. No global lighting configuration or geometry changes. See [settings and verification](SHIPWRECK_COVE_SKY.md).

## Shipwreck Cove editable pieces — September 25, 2026

SC_MAP_29 uses a Folder in Edit mode, individual platform Models pairing mesh and walking collider, and separate palm trunks/crowns. CourseService converts this hierarchy into the existing runtime Model when Play starts, retaining ordinary piece movement/deletion. Hazard contact uses visible oriented volumes without killbox padding or accessory hits. Procedural rebuilds remain explicit; Studio edits do not silently rewrite generators. See [editing guide](artifacts/shipwreck-cove/review29/EDITING.md) and [same-build evidence](artifacts/shipwreck-cove/review29/EVIDENCE.md).

## Shipwreck Cove ocean and route pass — September 26, 2026

SC_MAP_30 keeps ocean movement cosmetic and client-side. The server fall plane and damage rules remain fixed. Water pieces have no collision, touch, or query behavior; motion is capped at 30 updates per second and culled by camera distance. Blender supplies editable curved water accents and short cliff ledges; unsuitable Toolbox results were not inserted. Expert ribs and spars combine small or tilted landings with collapsing steps. Their landing markers fall and reset with them. The owner snapshot and candidate native models remain recoverable. [Scope and evidence](artifacts/shipwreck-cove/review30/REVIEW.md).

## Shipwreck SC31 shoreline and hazard boundaries — September 27, 2026

Visible shore geometry defines support: precise mesh collision for ten sand pieces and Blender-derived fitted wedges for the connected bank, grouped for manual movement. Old narrow hidden strips are disabled. The bank has 496 wedges and requires device/load profiling before performance acceptance. Coconut targets reject their full swept visible volume against start/refuge safety regions rather than checking only the landing point. Gameplay remains server-owned. Same-build reviewer scores below9 are recorded as an unmet gate, not completion. [Details](artifacts/shipwreck-cove/review31/HANDOFF.md).

C10 leaves the wreck's main structural ribs intact while removing the 25 extra posts beneath the jumping platforms, consistent with the owner's preference for clear floating platforms over misleading decoration. Texture-aware SurfaceAppearance tint separates hull and cave forms without importing another texture. Official StudioTestService is a working fallback for two-client tests when the custom plugin has stale session state; isolated test fixtures must not be saved into the course.
# Shipwreck SC31 C11 hull readability

Keep the original hull outlines, rails and palette while removing disconnected interior diagonal braces that compete visually with the jumping platforms. Use three separately editable replacement meshes with unchanged bounds and preserve owner transforms. Place the two mast/sail pairs beside the hull rather than across the route sightline. This is a noncollidable visual correction; gameplay controller source and all collidable positions/settings remain unchanged.

## 2026-09-28 - Course workflow V3 after Shipwreck Cove

Adopt [V3](COURSE_WORKFLOW_V3.md) in the existing Course Ideation and Course Creator chats. Keep two phases, with one representative playable section inside Asset Creation before multiplying assets or expanding a new direction. Carry forward the owner's mid-V2 choices: Blender plus inspected Toolbox/native assets, polished stylized detail, useful editability, no fixed iteration timer and current-prompt agent selection. Reconcile brief/layout/visual revisions, prove normal/expert contrast and scenery collision intent, preserve phase permissions and manual edits, and measure performance throughout. [Second-run evidence](artifacts/course-workflow-v3/SECOND_RUN_LESSONS.md) records the reasons and final-build evidence limits. This updates standing guidance only; Shipwreck Cove remains accepted and no new course, upload, tool installation or publication is authorized by this update.

The pre-use refinement keeps the V3 name and makes it the automatic default. Clarify that the active course/request's owner-selected team and approvals persist across follow-ups; “current prompt” did not mean the owner must repeat them each message. Add a cheap whole-route study beside the finished section, bounded alternatives for expensive uncertainties, imperfect-input/timing checks, and focused rebuilds/checks with compact tool output. These use the existing two phases and owner checkpoint, with no new mandatory review team or approval ceremony.

## 2026-09-28 — First arrival and game-only racers

Implement the approved minimal dark starfield chooser using native UI and isolated 3D previews. Customization is optional and available later from the lobby. Award 100 Gold once on the first successful custom save, with the claim and balance committed atomically alongside the look. Studio uses temporary profiles only. Published servers protect existing records on load failures and reject stale writes. Gate race eligibility on a server-owned readiness flag; preserve course-specific lighting. See [ONBOARDING.md](ONBOARDING.md) for the profile schema, remotes and test boundaries.

## 2026-09-28 — Avatar consistency

Both appearance paths and their previews opt into native Avatar Settings. Retain a fixed 5.5-stud R15 height and 2 × 3 × 1 movement collider, standard R15 animations and existing movement tuning. Preserve body-part hit/touch detection: the small collider did not report floor contact in the controlled Play check. Keep player clothing/accessories, scale oversized accessories with 25% padding, and disable accessory audio/VFX. Native settings are experience-wide and saved separately from the source; they must be copied when creating a new experience. See [avatar rules](ONBOARDING.md#shared-avatar-rules).

## 2026-09-28 — Shared Stage B

Replace separate landing cards with a single local ViewportFrame containing both characters and one studded capsule platform, plus one ivory action dock. Preserve both appearance choices and existing reward/server rules. Use restrained procedural joint poses rather than uploaded animations; support both Roblox joint generations. Pause hidden previews and honor reduced motion immediately. This changes only arrival presentation and its Studio toggle visibility. Keep map lighting and gameplay characters outside the preview world.

## 2026-09-29 — Arrival selection and save dialogs

Keep first arrival on the shared stage. Use original native geometry for the decorative coin, avoiding another external asset dependency. Place reward information beside the coin and the revisiting note in the footer. Pair a pressed action with a floor highlight and one restrained greeting. Confirm only the final appearance save; editing remains freely accessible. Reuse the existing server operation ID for popup retries; server profile and Gold rules are unchanged.

## 2026-09-29 — Bubbly character selection and Player Pass

Owner requested livelier highlights, direct character hover, and a fresh popup treatment. Use stable projected character hit areas so moving arms do not repeatedly lose hover. Clicking a model uses the same guarded action as its dock button. Keep preview movement bounded and local; Motion off disables bounce, gesture and ticket entrance. Replace the centered navy modal with a lower cream tear-off ticket, mint Player Pass confirmation and amber Quick Pit Stop failure state. Keep save confirmation, exact retry payload and server rules unchanged.


## 2026-09-29 - Quiet confirmations and lobby delivery

Remove popup slogans and stamp labels; keep one useful prompt and buttons. First-time arrival now has an Entering state between saving and race eligibility. Preload the actual retained lobby and character, verify the floor, then complete the camera handoff before acknowledging arrival. Use a Blender-authored six-part native emblem, real lobby overview and curved approach; reduced motion uses fades. Keep returning-player behavior and profile/currency writes unchanged. Failed delivery remains retryable without repeating the save.

## 2026-09-30 - Project chat roles

Keep Course Ideation and Course Creator, and mirror them with Feature Ideation and Feature Creator for non-course work. Game Direction handles game-wide choices; Workflow Engineer improves the development process; Game Systems Map explains the existing game. Preserve Project Startup — Rojo & MCP and the prompt-storage boundary in Prompt Library. The [chat role guide](CHAT_ROLES.md) records purposes, boundaries and identities. These are routing defaults, not a required sequence: clear requests can go directly to a creator. Preserve refined V3, current permissions and active work; role definitions do not authorize automatic cross-chat messaging or new implementation.

## 2026-09-30 — UI preview without Play

Use a local Studio plugin panel with fresh copies of the game's UI builders, rather than keeping a second editable runtime GUI under StarterGui. `ArrivalScreen` and `ArrivalEntranceView` own shared presentation; player/server behavior stays in the existing controllers. The lobby builder has an Edit-only preview entry. The plugin reads source from the connected place on Refresh, uses temporary sample state and never invokes gameplay remotes or changes Lighting/camera. It clears when closed and automatically closes for Play. Keep the plugin outside the game's Rojo mapping. [Guide](UI_PREVIEW.md).

## 2026-10-01 — Air × Pop lobby and one shared preview

Use the owner-approved Air layout with Pop styling. Share native layout, icon and presentation modules between the game and Edit preview so the preview remains useful as source changes. Keep Gold and race copy tied to existing authoritative data; unavailable Keys, Shop and Quests remain explicit. My racer binds the existing onboarding editor; late choices bind existing validated remotes.

Keep the old racing/results screens outside the lobby. Hide personal summary while the new lobby HUD is visible. Release unanswered client choice guards after six seconds only when race/status remain unchanged, with request-version protection. This changes client recovery only. No new economy, DataStore, purchases, remotes or server rules.

## 2026-10-01 — Reference HUD surface refinement

Use coherent upper-left lighting across Blender icon renders and native enamel surfaces. Keep cream faces warm with narrow lower bevels, asymmetric glints and stronger colored buttons. Render raised coin facets, curved trophy handles and cyan/blue key edges as lightweight image assets; retain editable Blender scenes. The stepped ticket outline remains resizable9-slice artwork. The shared theme supplies the existing race buttons too; behavior and server rules are unchanged. [Current evidence](artifacts/hud-reference-2026-10-01/r3/verification.json).

For R4, follow the owner's approachability critique: sculpt the race-panel spine as rounded9-slice artwork, use material-colored inner edges and lighter navy outer borders, and replace oval shine patches with faint full-face lighting. SourceSansBold is scoped to the lobby view after comparing native font samples; race/arrival lettering keeps its existing font. Angle the chunky key's shaft independently from its diamond bow. [R4 evidence](artifacts/hud-reference-2026-10-01/r4/verification.json).

For R5, the owner's newer request removes the white facet and cyan decorative side curves from the race-panel tab. Keep its rounded blue silhouette. Generate Shop, coin and key as separate transparent ImageGen sprites, with text rendered by the existing native UI. Compare at matched visible heights before owner acceptance and extension to the remaining icons. Reviewer judgments are pass/needs revision by asset, with no inherited scores. Reference edges have1–2px uncertainty; comparison uses original pixels in CSS, with candidate alpha bounds measured without editing the images.

For R6, the owner's acceptance authorizes completing and installing the ImageGen family. Preserve the accepted three PNGs exactly and use them as references for racer, trophy, gear and check. Reuse one gear for Settings/Race options. Give clock and arrow lighter, simpler strokes so they stay readable at small sizes. Size sprites using measured visible alpha bounds, with native frames clipping spare transparent padding; preserve original PNG pixels. Keep all labels, balances and timers separate. The stricter reviewer must inspect actual native sizes and compact layouts, not just enlarged artwork. [R6 evidence](artifacts/hud-reference-2026-10-01/r6/README.md).

## 2026-10-01 — One coordinated arrival and quiet lobby states

Keep the accepted ImageGen family and open centre. Measure long title height before placing format/actions; distinguish actual timed/queued state from quiet idle. Unknown Keys and empty quests must not imply a balance or progress.

ArrivalTransition owns the title/audio/camera timeline; LobbyUiController owns HUD reveal and its input lock. Preload the shared HUD while the title covers the world. Start its stagger during the last landing fade after real acknowledgement; release client controls only after HUD settle. Restore canonical styles before refreshing content and apply the same elapsed reveal time.

Use independent position/rotation interpolation and sample the actual native player camera rather than a fixed assumed view. Current mute preference survives subsequent arrivals. Returning visits get the short native-camera path. Keep server readiness, profile/economy/remotes and map ambience unchanged. Validate camera timing without screenshot calls because the official capture tool changes Play camera mode. [Frozen revision and three independent reviews](artifacts/soft-landing-2026-10-01/r4/README.md).

## 2026-10-02 - Saved Blender builders where they help

Use [shared Blender build guidance](BLENDER_BUILD_WORKFLOW.md) for substantial/repeated Blender-authored course work and relevant 3D feature assets. Prefer saved scripts in a separate process for builds, previews and exports; retain MCP for useful live inspection and targeted edits. Preserve owner changes, check candidate outputs and rebuild only affected dependencies. Keep native UI/image workflows and V3's existing choices, phases and checkpoints. Scripts already exist for project kits and the arrival emblem; this makes their useful patterns consistent without reopening accepted work. Reliability, iteration and time savings are potential benefits until measured on comparable work.

## 2026-10-02 - Independent lobby phase capsule

Follow the approved HUD with one top-center phase capsule, top-right currencies, a compact full-width course/status card and slim empty quest strip. Keep accepted icon sprites and existing actions. Progress uses received remaining time divided by valid server duration; unknown timing hides it and unlimited Racing never derives a timer from duration. Reserve native topbar space for controls while modal shade covers the entire viewport. Responsive placement can move the capsule below currencies to prevent overlap. [Frozen source and two independent reviews](artifacts/hud-refinement-2026-10-02/r4/README.md).

## 2026-10-02 - Course Creator continuity across models

The owner plans to switch Course Creator from GPT-6 Astra to GPT-6.1 Sol in the existing chat. Keep V3 and the accepted Blender guidance; the wider tool research remains research only. The [Creator guide](COURSE_CREATOR_WORKFLOW.md#continuing-after-a-model-change) now calls for a compact recovery of current scope, accepted inputs, permissions and next steps after a model change. Keep the owner's model/reasoning selection in the app, with no project-wide model override or special prompt rewrite. This is a continuity measure, not evidence that course quality or performance has improved.

## 2026-10-02 — Scoped lobby functions and Grand Arcade

Keep the permanent stage separate from RaceCourse and preserve the actual four-course fallback. Idle panels use the eligible server catalog; resolved race labels require a real five-map lineup. Winner miniatures and session boards read authoritative completed results, preserve original places and reject duplicates/stale data. Session records are bounded and temporary, with no persistence or reward changes.

Reuse the existing My Racer flow at the native Style counter; client prompt availability and server Edit validation include pending tournament-course readiness. The imported Style counter is Collider315. Use reversible overlays and additions; preserve manual lobby edits and the whole practice area. C01 is directly approved and installed, with unchanged originals archived for restoration. Completed Ready presentations must not replay when results or arrival attributes change; pending player readiness can resume delivery. [Current evidence and remaining checks](artifacts/lobby-improvement-study-2026-10-02/implementation-status.json).

When presentation cleanup still owns the current camera and arrival is closed, restore an abandoned saved Scriptable camera to Custom. Preserve other camera types, the saved FOV and the current character's Humanoid subject. This addresses interrupted handoffs without a new camera framework. Native fixture checks and final visual acceptance remain separate.


## 2026-10-03 - Fresh Sol 6.1 Creator chats

The owner requested fresh Course Creator and Feature Creator conversations after reporting unreliable answers in the older chats. Create both with GPT-6.1 Sol, retain their established roles and workflows, and archive the inactive predecessors after setup succeeds. Bootstrap from current project guidance and a compact saved checkpoint without forking the old conversation history. Both replacements start on standby; the stopped partial lobby/Grand Arcade work stays stopped. The [chat directory](CHAT_ROLES.md#chat-identities) records active and retired identities. This replaces the owner's earlier plan to keep the existing Course Creator chat while changing its model. No course, feature, asset or Studio change is part of this reset.

## 2026-10-03 - Ideation creates focused creator chats

The owner instructed both Ideation chats to create new focused creator conversations instead of handing new jobs to general Creator chats. Use the [concrete starter and current-state templates](FOCUSED_CREATOR_THREADS.md): one commissioned course or bounded substantial feature per conversation, with related revisions staying in that job. Keep Ideation general. This supersedes reuse of the general Creator identities for unrelated new work; existing active jobs continue in place unless the owner requests a transfer.

Carry current inputs, approval evidence, preservation requirements, model/helper choices, completion checks and relevant process lessons into the first message. V3, the existing Blender guidance and evidence limits remain. Recover the actual task and latest owner direction after compaction before mutations or helper interruptions. Keep live task status in one task record, outside shared roles; historical summaries cannot revive closed work. The change responds to observed switches back to older tasks after compaction, including in the fresh Sol chat. Focused conversations and recovery rules are safeguards, not verified prevention of every error. This workflow update does not commission a new game build.

## 2026-10-04 — Stud Garden full candidate

Build Stud Garden as a separate editable native course, SG_V1_01 / SG_LAYOUT_04 / SG_ART_03. Keep the five areas, 22 main sequences, two harder expert paths, warned shared hazards and ordered checkpoints. Use original native plants/pets and noncolliding artwork; movement floors and 14 solid dividers own route support/separation.

Local opening refinement widens A1_09/A2_04 to24×24 and shifts A1_09 five studs east to retain its incoming gap. Preserve other courses/manual work and Heartwood's completed archive. Existing race loading accepts the authored course; checkpoint recovery uses optional server-authored areas with legacy fallback. Global race/movement/collision/economy/security policies remain unchanged.

The full candidate is built, not accepted for human timing,20-player capacity or device performance. Preserve failed crowd evidence and observed15FPS samples without assigning an unverified cause. [Final build and evidence](artifacts/stud-garden/FINAL_BUILD_REPORT.md).

## 2026-10-04 - Creator model split

The owner adopted **Astra ExtraHigh leads with Sol 6.1 High helpers** for creator work and requested notification of both Ideation chats. Use `gpt-6-astra` / `xhigh` for new creator leads; use `gpt-6.1-sol` / `high` for authorized helpers, with an individual `xhigh` task only when justified and permitted. Ideation retains Astra Max. This replaces the prior Sol 6.1 creator-lead default in the [starter template](FOCUSED_CREATOR_THREADS.md#creator-model-defaults).

The lead owns creative decisions, integration and inspection of the actual result. Keep helper assignments bounded, current task limits intact, focused chats and recovery after compaction. Apply the defaults to new creator chats and future authorized continuations, honoring newer explicit selections. This announcement does not interrupt or restart active work. Improvements in quality, rework, speed and usage remain to be assessed on actual creator milestones.

## Stud Garden V2 — October 4, 2026

The owner commissioned three phases: extensive asset creation, course creation, then map creation. Early P07 and majority kit K13 are separate preserved studies; V1 is unchanged. Match visible leaf/fruit shapes with native polygon support and swept-sphere contact, keeping normal movement and global race policy unchanged. Use short varied planting assemblies after the local layering review. [Current state](artifacts/stud-garden-v2/CURRENT_STATE.md).

C06 V2 uses nine existing-format ordered recovery points; both branches retain them and the complete festival follows checkpoint9. Keep selection disabled until authorized play validates this candidate. Full source/native assembly and plan2.2 are retained in the [course report](artifacts/stud-garden-v2/phase2/COURSE_REPORT.md).

R207 preserves that structure while adding separated intermediate main-route landings, static garden windows/ledges/hurdles, harder precision branches and visible start/checkpoints. The crop expert route shares BambooWest before splitting to five isolated caps; this removes the reviewed DryWait detour. Hold local hazard time/motion/warnings/contact together during frames over0.2seconds rather than discard a moved sweep. Three focused final reviews closed their construction/source findings; native gameplay is still unverified. Keep R207 disabled and preserve C06/manual originals. [Revision report](artifacts/stud-garden-v2/phase2/round2/ROUND2_REPORT.md).

The final Phase 2 quality pass replaces R207's visible preview with disabled R305 geometry while preserving R207. Recompose crops into one main loop, one expert line, one checkpoint 4 merge and one north-side tool exit; retain the liked vine composition with separated expert landings. Use grounded side checkpoint signs and recognizable three-dimensional tools. R305 source stays frozen outside Rojo, and the separate eleven-script integration remains uninstalled. Require three independent whole-course 8.5 judgments plus required native gameplay evidence; a static score cannot close the acceptance gate. Final scores of 8.3/8.4/8.6 do not meet that gate. No automatic Phase 3 was authorized by that pass; the later owner commission below supersedes the hold. [R305 report](artifacts/stud-garden-v2/phase2/round3/ROUND3_REPORT.md).

### October 5, 2026 — Phase 3 owner continuation

The owner approved larger plants and raised studs, authorized Phase 3 with Astra Extra High at normal speed and exactly three Sol 6.1 High reviewers, each final score strictly above 8.5. Use a separate disabled art clone; preserve R305 and manual work. F03 combines Blender art with individually fitted scenery collision. After the owner explicitly approved the exact F04 upload, nine convex tapered knot meshes replaced nine cylinder contacts in a new clone, closing the required root appearance finding. All three final F04 reviewers independently scored 8.7. Preserve the exact crowns, maximum heights and other geometry; record tapered-end traversal as a local gameplay uncertainty. The art/static milestone is complete, with native recovery verified. The course remains disabled pending separately authorized integration, gameplay, camera, twenty-racer and device checks. [Final Phase 3 report](artifacts/stud-garden-v2/phase3/PHASE3_STATUS.md).

## 2026-10-05 - Three course phases and phase reference images

The owner made three phases the standing course process: **Asset Creation → Course Creation → Map Creation**. This replaces the older two-phase wording in V3 and its creator starter; the workflow keeps its existing V3 file names. Phase 1 produces the majority reusable kit after a finished playable sample and cheap whole-route outline. Phase 2 completes the playable course with rough large surroundings. Phase 3 finishes the world and rechecks traversal, visibility, collision and resource use.

Ideation now follows **brief + native draw.io → three linked end-of-phase concepts → iteration → four views per phase → consistency review → focused Creator creation for commissioned work**. The twelve selected final views normally reuse the three initial masters as view A. Mood boards, clay studies and extra detail views are optional for a named unresolved question. Use orthographic/isometric presentation, but choose the course footprint from its experience rather than imposing a square display base. Resolve visual contradictions against the brief and native plan; distinguish ImageGen concepts, optional shared-scene reconstructions and actual Studio evidence.

The [shared workflow](COURSE_WORKFLOW_V3.md), [Ideation guide](COURSE_IDEATION_WORKFLOW.md), [Creator guide](COURSE_CREATOR_WORKFLOW.md), [image recipes](COURSE_IMAGEGEN_PROMPTS.md) and [starter](FOCUSED_CREATOR_THREADS.md) carry the same definitions. Preserve existing phase permissions, the representative-section checkpoint, model/helper arrangements, editability, performance and task-recovery rules. This setup update leaves existing course work in its current chat and prepares Course Ideation for the next map; it does not commission a new map or restart an active build.

## 2026-10-05 - Rojo 7.7.1 and one Studio plugin

The owner requested the latest Rojo and repair of duplicate Studio plugins. Use the verified official 7.7.1 CLI through `tools/start_rojo.ps1` and its matching local `RojoManagedPlugin.rbxm`; disable the Marketplace Rojo (asset 13916111004) in Manage Plugins. Preserve the old local plugin under `.tools/rojo-plugin-backups/` and retain the 7.7.0 executable for recovery.

The 7.7.1 project build, release SHA256 checks, server response and duplicate-server prevention passed. Studio still had Marketplace 7.6.1 and local 7.7.0 loaded during inspection. Plugin management requires a Studio-only capability unavailable through MCP; the owner must disable the Marketplace copy, save/reopen Studio and connect the new local plugin. The installed file and running server do not prove this final Studio step is complete.

## 2026-10-06 — Stud Garden density and moved respawns

Fill decorative voids with broad planted forms and connected low beds. Keep new solid cores below local Y 0.65 inside the existing fall zone; taller foliage, produce and caps remain decorative. Native square studs require Plastic on these new faces. Preserve all original route parts. Moving this course left absolute RespawnCFrame attributes behind, so the density pass translates ten saved frames and two CourseOrigin attributes by the observed (0,0,-123) move. [D03 evidence](artifacts/stud-garden-v2/density-20261006/REPORT.md).

## 2026-10-06 - Stud Garden workflow lessons and Sol course lead

The owner requested a completed-map retrospective and selected **Sol 6.1 Max** as the Course Creator lead. Use `gpt-6.1-sol` / `max` for future course creators unless a newer course-specific selection applies. This supersedes the October 4 Astra lead default for Course Creator only. Feature Creator retains Astra ExtraHigh; Ideation remains Astra Max; authorized helper defaults remain Sol 6.1 High. Existing chats are not restarted or silently reconfigured.

Keep Asset Creation → Course Creation → Map Creation, the early playable sample/rough route, the three-concept/twelve-view package and independent candidate-specific reviews. Strengthen early native asset recognition, connected player-height scenery, sparse wayfinding, atmosphere and complete hazard-cycle checks. Replace stale current-state facts rather than accumulating old holds, remove the invented two-round stopping quota and continue through already authorized phases. Preserve task-specific permissions, owner edits, recovery, performance limits and actual owner acceptance.

The owner's 20–30% speed improvement estimate remains unmeasured. Record new requests, necessary approvals, waiting and corrections separately in future comparisons. [Evidence and keep/remove decisions](artifacts/course-workflow-v3/THIRD_RUN_LESSONS.md). This update changes workflow documents only; it does not reopen, modify or publish a course.

## 2026-10-07 — Keyboard Circuit Phase 1

Keep Keyboard Circuit's reusable kit, cheap whole-route study, finished S02 sample and early H06 proof isolated from the live race framework. Ten course source files plus shared configuration/client feedback/preview remain durable Rojo source. The original Session is disabled; only the isolated native sample enables its Studio-only server controller. The construction kit is inactive. No new remotes or economy/DataStore changes are needed.

Use one original 28-triangle cap mesh on native editable banks with fixed collision boxes. Native servos physically carry the lift and shuttle; pressure starts the lift's shared boarding window. Server contact/recovery controls remain authoritative. Sound-family names remain provisional until human listening. Preserve earlier candidates before a handoff; the owner explicitly approved C05/kit archival and C06 creation. Exactly the same five Sol 6.1 High judges must independently pass the same final hashes at 8.5/10 before the separate whole-study/sample owner checkpoint. [Current commission and state](artifacts/keyboard-circuit/COURSE_BRIEF.md).

### C07 owner-requested revision

The owner clarified that one avatar should span one or two ordinary keys. Fit fewer approximately 2.4-stud caps inside the existing bank boundaries, with authentic editable legends. Detect actual supported feet and hold a logical key while any nearby supporting player occupies it. Animate a .45-stud local cosmetic stroke over a fixed depressed collision plane; server hazards, lift/shuttle carrying and recovery remain authoritative. Both Enter arms form one press group. Warning borders/arrows follow pressed cosmetics.

Use four new down/up recording pairs with short playback regions, family gains/equalization, quiet releases and a bounded eight-voice own/nearby mix. Native playback and zero-cutoff repeat tests establish operation; human sound preference remains the owner's checkpoint. Preserve C06/kit and initial C07 prototypes. Reuse the five original High judges; the separately requested ExtraHigh critic is advisory. No Phase 2/3 expansion is implied. [Exact current evidence and limits](artifacts/keyboard-circuit/phase1/C07-REVIEW-BRIEF.md).

## Keyboard Circuit C08 asset refinement — October 7, 2026

Keep C07 key size, fixed support, geometry and authoritative hazard/carrying behavior. Use one character per key and hide/restore the original legend together with the cosmetic mesh during a press. Apply decisive attack/smooth release, preserving shared last-occupant holds and grouped Enter. Keep the eight existing recordings and bounded voices; add softer release/body treatment and modest stable variation rather than replacing all four families with one unreviewed pack.

Remove duplicate stationary overlap checks and change-only pose/state/warning writes; retain the exact moving sweep. Publish diagnostics about ten times per second and promptly on important changes/Stop. Both native assets carry 14 self-contained snapshot sources. Preserve C07/kit before the guarded C08 handoff. Focused checks do not establish FPS gain or human sound preference; C07 judge scores cannot endorse C08. [Current evidence](artifacts/keyboard-circuit/phase1/C08-REVIEW-BRIEF.md).


### Keyboard Circuit C08 readiness - October 7, 2026

C08 startup waits for eight usable clips before local movement/contact feedback. One canonical retry and a ten-second deadline resolve to ready or explicit degraded play; no old footstep queue. Server gameplay and accepted sound treatment are retained. The owner checkpoint is accepted; the original five review independently on frozen inputs, with later reports/status audited separately.

## Keyboard Circuit Phase 2 — October 8, 2026

Build an isolated complete course from accepted C08 assets, with sixteen main sequences, eight mechanisms, two precision branches and ordered server-owned three-lap progress. Sixteen self-contained source snapshots and an editable kit allow native reopening and fresh rebuilding. Preserve accepted C08 and every prior owned candidate; rough surroundings are sufficient for this phase.

Keep the existing eight recordings, one-character 2.42-stud caps, fixed collision plane and local held-key cosmetics. Phase 2 holds loading movement only on permanent recovery banks and releases it within the configured deadline; failed clips permit degraded play. A Studio-only lobby presentation check clears the preview view and restores the lobby on exit. Course preview has no economy, reward, DataStore or new remote contract. Phase 3, whole-place save and publication remain separate. [Current candidate and evidence](artifacts/keyboard-circuit/phase2/P2-C01-REVIEW-BRIEF.md).

For the captured H08 grounded-foot defect, lower its builder hinge from -2 to -3.25 while retaining the full lethal body-part checks, timing and support surfaces. The change gives 2.05 studs of under-bank clearance and keeps the upright panel 9.2 studs above support. Do not mask valid foot contacts through character exclusions. The owner approved the exact I05 archive/rebuild; I04 and its failed evidence are preserved, and native arrivals/holds/continuous traversal now pass.

Retain the failed I05 visual and pacing reviews. Prepare arrow-form/bracket-mark and measured pacing repairs. The owner's October 8 targets supersede 240–300 seconds: normal three laps in 240–360 seconds and Expert in 120–180 seconds. Each Expert branch must earn a clear start-to-merge time saving. Preserve current mandatory common encounters, checkpoint order, ordinary movement and all normal features while preparing compact copied geometry. Scripted timing cannot establish typical human race duration.

Keep the compact pacing experiment separate from installed I05. Its complete Expert lap is 129.882 seconds with zero recovery; narrower branches show unpaired time savings but do not meet the 40–60-second share. Require an explicit owner layout choice before replacing the brief's two branches and mandatory common foundry/shuttle/sweep with four earlier district alternatives. The [proposal](artifacts/keyboard-circuit/phase2/I06-EXPERT-SCOPE-PROPOSAL.md) states the bypassed encounters, retained Normal route, evidence and experience tradeoff. No broader layout is implemented; both owned test players return to I05 and the prototype runtime is stopped.

The owner's Dev Tools test request authorizes a separate Edit install of the measured compact prototype and a fixed Studio-only action on the existing developer control. Use its own Session Begin/Leave controls with the invoking player's UserId; hold ordinary rounds before entry. Preserve the installed I05 course. This test request does not select the proposed broader Expert layout. Leave Play launch and hands-on testing to the owner; computer control remains prohibited.

## Keyboard Circuit final isolated timing pass — October 8, 2026

The owner's one-more-pass request authorizes the focused four-district timing redesign and supersedes the pending two-versus-four-branch choice for this isolated prototype. Normal retains all sixteen sections and eight mechanisms; Expert takes four inward precision alternatives and all ordered gates. The accepted C08, I05, compact I06 and earlier I07 models remain preserved.

Use the main checkpoints as recovery banks instead of four optional side islands. Keep the smaller O07 entry landing because the direct checkpoint-to-arrow gap is not a baseline jump. Big keys reuse the accepted beveled K02 mesh and single legends; Shift parking machinery becomes noncolliding recessed trays. Remove extra connector banks by tightening the Normal outer nodes.

I07_02 and I07_03 full Normal races took 420.971 and 370.855 seconds and remain failed timing evidence. I07_04 retains warning durations, crossing allowances and boarding/exit dwells while reducing travel/contact/closed delays and extending safe Fallaway/Sweep intervals. All pacing claims require fresh continuous three-lap Normal and Expert receipts on the same frozen inputs. Five independent Sol 6.1 High reviewers must each pass 8.5 with no blockers. Automated timing does not establish typical human race duration. No computer control, production replacement, Phase 3, whole-place save or publication. [Current packet](artifacts/keyboard-circuit/phase2/P2-I07-REVIEW-BRIEF.md).

Passing time cannot compensate for an unmarked whole-encounter shortcut. Final05's actual H08-refuge jump reached F01 despite a nominal rise above JumpHeight; preserve that failure. Final06 raises the finish another five studs and requires fresh actual shortcut attempts and both full timings. All four focused attempts now reject after legitimate checkpoint prerequisites; the prescribed Expert chain still passes all66landings across three laps. Keep focused staging separate from continuous race proof.

## Keyboard Circuit two laps and scoped archival — October 8, 2026

The owner chose Final06 as the base for two laps, retaining the full-race Normal 240–360-second and Expert 120–180-second targets. I08 expands node spacing horizontally by 1.5 and uses 8/8/8/10 precision caps across the four Expert cuts. Vertical heights, local encounters, movement settings, big-key shapes, pressing and audio remain unchanged. Necessary connector banks bridge the expanded gaps; added traversal supplies the pacing adjustment without artificial timing holds. Layout owns the lap count used by server progress, the start sign and client display.

The owner clarified archival to older Keyboard Circuit builds only. Preserve nine earlier courses, their sources, seventeen preparation/recovery holders and K01 in `ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008`; keep the current I08 course, latest K02 dependencies and unrelated maps available. Archival scripts are disabled. Net Workspace reduction is 40406 parts, not a measured FPS gain. Saved native I08 reopening and fresh rebuilding agree across 14028 descendants.

Fresh two-lap automated Normal/Expert runs complete in 290.541/123.313 continuous seconds, with ten ordered natural gates and zero recoveries each. Enrollment clocks are separate at 291.905/134.346 seconds. Human pacing, sound preference and twenty-racer/device performance remain unverified. Five fresh independent Sol 6.1 High reviews must each bind final freeze02 and pass 8.5 with zero blockers. [Current packet](artifacts/keyboard-circuit/phase2/P2-I08-REVIEW-BRIEF-01.md).

## Keyboard Circuit I09 Expert and checkpoint amendment — October 8, 2026

The owner reopens Phase 2 before acceptance: Expert should preserve more of the experience and Normal should remain worthwhile. The owner explicitly chooses experience preservation over the preceding Expert 120–180-second goal; two laps and Normal 240–360 seconds remain. Replace four district-wide cuts with two optional precision cuts: X03 after H02 and X02 after H06. Expert retains twelve of sixteen encounters, six moving mechanisms, both Enter sections and all four sound districts. The two chains use twenty-five smaller, staggered precision caps per lap with matching collision footprints over void. Main-route geometry, mechanism tuning, big-key art and audio are unchanged.

The owner selects four additional midpoint saves on existing permanent banks: H02/H04/H06/H08 exits become R1/R2/R3/R4. The recovery order has seven checkpoints plus F00 start; a verified grounded midpoint landing saves retry position without advancing the required main gate or lap. Reject future-district and backward saves. Keep twenty planned placements in each large start/CP bay and nine in each smaller midpoint; these placements do not establish twenty-racer capacity. Preserve the superseded brief/plan under `history/I09-before-expert-revision` and show the current I09 page first in the editable plan. All five original strict Sol 6.1 High judges need fresh independent candidate-specific scores of at least 8.5, with zero blockers. Owner acceptance and human timing remain separate.

## Keyboard Circuit I09 candidate03 sign and evidence correction — October 8, 2026

Candidate02 failed independent sign reviews: white ink on pale panels had poor contrast and Expert panels shielded checkpoint text. Candidate03 selects dark ink for pale panels, keeps white on purple and moves midpoint panels to the upstream bank edge facing across the bank. Signs remain noncolliding/nonquery. Main-route/precision geometry, motion tuning, ordinary movement, held-key behavior and audio are unchanged from02. Fourteen of sixteen source texts are identical after newline normalization; Course sign/identity and Layout identity account for the text differences. Eleven baseline art/audio/motion source texts remain identical after newline normalization. Exact byte hashes bind the current sources; no byte-identical claim is made after CRLF-to-LF preparation.

Keep seven checkpoints plus start and two optional cuts retaining12/16 encounters,6/8 moving mechanisms,both Enter sections and all four sound districts. The owner's experience-first Expert amendment remains authoritative. Current Normal target stays240–360seconds. No new Expert numeric window or guaranteed human savings is invented. Preserve candidate02 judgments/evidence in history and require all five independent current03 technical reviews on the same41-input freeze. Owner acceptance remains separate.

## Keyboard Circuit Phase 3 M01 — October 8, 2026

The owner accepted Phase 2 and authorized Phase 3 through delivery. Finish the existing I09 course with five hardware landmarks, individual fixed-bank circuit plates and district cases. Retain all gameplay geometry, sixteen accepted source texts, two laps, seven checkpoints plus start and two experience-preserving Expert cuts. Four new construction modules add editable static artwork; new parts have collision, touch, query and press disabled, with no per-frame artwork work. Shared lighting and unrelated courses remain unchanged.

The owner moved the accepted course uniformly to `(2222,330,-1158)` while absolute world attributes retained the former origin. Generate at the canonical accepted origin before translating, preserving precision landing poses exactly; translate only world points/frames and traversal markers. Preserve both original and moved native recoveries. The current F6 action targets M01, with its predecessor's global file retained in verified history. Require five fresh independent overall Sol 6.1 High judgments on the same113-input freeze; no Phase 2 score or average substitutes. [Phase 3 packet](artifacts/keyboard-circuit/phase3/P3-M01-REVIEW-BRIEF-01.md).

The final gate closes on repaired114-input freeze02. An Enter visibility audit coverage error was corrected before every final judgment; the map/gameplay sources and native geometry did not change. Five independent overall scores are8.6/8.7/8.8/8.7/8.7, zero blockers each. Post-review native comparison includes transparency/reflectance/anchored state and Part shapes, and confirms all23 installed source hashes. Owner Phase3 acceptance and human/crowd/device outcomes remain separate. [Completed map](artifacts/keyboard-circuit/phase3/P3-M01-FINAL-REPORT-01.md).


## Keyboard Circuit M02 visual pass — October 9, 2026

The owner commissions the HUD/overlap fixes, stronger useful signs, checkpoint sites and obstacle warnings, plus more/larger floating hardware. Three independent Sol6.1High reviewers replace the previous five; scoped helpers implement in parallel. M02 preserves two laps, seven saves plus start, two experience-preserving cuts and all eight mechanisms. Rebuild only O05's overlapping arms as two aligned extension cells per bank; leave the other 3,282 physical/press parts unchanged. Preserve M01 and older builds in the existing archive.

Eight numbered stations, lap finish, seventeen floating assemblies and seventeen state-driven warning boards complete the pass. The existing mechanism loop updates warnings with cached text signatures; Stop refreshes after reset attributes. Native full lift and all-board Stop/reset checks pass. Independent scores are 8.6/8.8/8.8, zero blockers, on the same 63-input freeze. [M02 handoff](artifacts/keyboard-circuit/phase3/P3-M02-FINAL-REPORT-01.md). Human acceptance and device/FPS outcomes remain separate.

## Keyboard Circuit M04 closing work — October 9, 2026

The owner approved M02 and clarified that Keyboard Archive is the actual skybox. Replace only the superseded M03 enclosure with six imported Sky faces, preserve the accepted course and owner warning poses, and retain all recovery history. The current closing commission authorizes six cosmetic effects and finite legend/shadow refinements; it does not authorize another route, timing, key/audio or global streaming redesign.

Apply the Archive profile through the supported F6 candidate lifecycle. Guard asynchronous readiness, lighting ownership, character and run identity; restore the captured profile on leave, restart, removal and death. Preload through a temporary typed Sky. Use one bounded client update loop and the existing key-entry subscription. Reconcile a fixed list of 97 named authoring anchors through the existing visibility tick until streaming completes, and resolve trace references when used. No per-key timers, extra world scan, dynamic lights or particle emitters are added.

Finite legend ranges reduce unlimited SurfaceGuis from 3,207 to 106; disabling nonessential artwork shadows reduces shadow casters from 1,623 to 502. Collision, query, press targets, ordinary movement and the accepted two-lap experience remain preserved. These counts and measured cosmetic callback work do not establish FPS or crowd/device performance. Freeze the changed candidate and require three fresh independent Sol 6.1 High judgments, each at least 8.5 with no blockers, then a fresh saved-state comparison. [Current closing commission](artifacts/keyboard-circuit/FINAL_TUNING_START.md).
# Keyboard Circuit M05 — October 9, 2026

The owner's basic-map request supersedes Keyboard Circuit's separate prototype enrollment, progress and HUD. M05 uses the existing shared race, checkpoint, recovery, results and UI services with two laps and eight ordinary checkpoints. A small course-local runtime retains moving mechanisms; its client only supplies the accepted key feedback and map ambience.

The owner approved removal of ten old Keyboard Circuit roots after verified native disk exports. One disabled latest baseline remains in DeveloperArchives; other maps and the shared palette stay in place. Brighter daytime lighting and seventeen Neon lethal parts replace the darker presentation. Owner placement is retained; stale stored world poses are aligned to the physical start bank. [Current evidence](artifacts/keyboard-circuit/phase3/P3-M05-REVIEW-BRIEF-01.md).

## Keyboard Circuit workflow retrospective — October 9, 2026

Keep the deeper Ideation, three-phase process, representative playable sample and independent candidate-specific reviews. The owner's reported 4–5x relative speed and 60–70% weekly-limit usage are rough impressions, not measured comparisons. The study of completed Creator turns found that M05 already used three implementation helpers and its final reviews occupied about five minutes of a 71-minute turn; no saving from this update is claimed.

The course starter now names the intended shared race flow, temporary preview limits, experience priorities and the requested environment medium. Ideation records duration-versus-encounter priorities and defining sample feedback. Creator plans useful independent helper outputs early, prepares verification alongside Studio work, checks shared flow at the beginning of Phase 2, verifies complete branch progression after relevant changes, uses fresh saved-source lifecycle checks and retains only needed live recovery copies. Removing existing roots still requires explicit authorization and verified recovery.

Preserve Course Creator Sol 6.1 Max, authorized-helper Sol 6.1 High defaults, the three-concept/twelve-reference package and each active job's owner-selected team and permissions. No new mandatory team, approval stage or model/Fast setting change. The newly reported Expert checkpoint defect remains the active Creator's repair; this workflow study does not certify the map.

[Keyboard Circuit evidence and timing study](artifacts/course-workflow-v3/FOURTH_RUN_LESSONS.md).
# Keyboard Circuit M06 — October 9, 2026

Expert choices must satisfy the same eight-checkpoint order as Normal. Their precision pads count as alternate contacts for the corresponding R1/R3 checkpoint, using the existing CheckpointService mechanism. Recovery stays on the permanent bank. Do not waive required progress, remove midpoint checkpoints or add prototype race logic to make shortcuts finishable.

## Keyboard Circuit completion — October 9, 2026

The owner's “Consider Keyboard Circuit complete” accepts all three phases and the installed M06 course, closing this commission. Earlier owner-acceptance holds are superseded. Retain the current implementation, recovery artifacts and recorded test limits; further changes need a new scoped request. [Accepted current state](artifacts/keyboard-circuit/COURSE_BRIEF.md).


## Course workflow quality and simplification — October 9, 2026

The owner approved adoption after the quality and instruction-overlap reviews. Agreed course quality takes priority over speed and usage within the requested scope. Preserve exact owner comparisons, inspect the weakest section during existing checks, and leave missing required phase evidence pending regardless of numerical review scores. Reviewers independently challenge coverage; the designated controller performs Studio checks.

Consolidate repeated recovery, Blender, starter and state guidance through existing canonical guides. Keep the three phases, twelve-reference default, model defaults, owner-selected teams and permission boundaries. The four revised guides are 293 words shorter overall.

Course Ideation confirmed adoption of all four guides and the [canonical Creator starter](FOCUSED_CREATOR_THREADS.md), then returned to standby. Independent document review and link, content and preservation checks passed. No gameplay, Studio or app-setting changes were part of this update.

## Moonlit Citadel first sample boundary — October 10, 2026

Follow the owner's Blender/daylight corrections: imported authored meshes define visible Gothic art; simple native contacts and a scoped Studio preview supply behavior. Final night waits for the final map. Direct approval authorizes the receipt-bound upload/import and scoped checks without computer use. Keep durable source, raw imports, prior models and unrelated work; do not publish or register a production course.

Use a separate unpublished local fixture after original Play automation stalled. Preview progress is local, ordered and server-controlled. Moving decks use ordinary floor velocity rather than repeatedly positioning riders; light itself does not cause recovery. The original fixture remains disabled and its shared Studio lobby/onboarding interactions are documented.

One fresh Sol6.1High review has no numerical gate. Its readiness judgment covers first owner critique only. Keep the appearance, short route timing and resource concerns explicit; required human/device/crowd evidence stays pending before broad expansion. Phase2/3 need separate authorization. [Current scope and result](artifacts/moonlit-citadel/phase1/MC_BL01_R05_FINAL_REPORT.md).

## Moonlit Citadel Phase 1 completion and early optimization — October 10, 2026

The owner's latest request authorizes finishing/improving the majority editable kit and existing sample. Their no-device reply replaces a fixed-device/FPS gate for this bounded pass. Keep future human pacing/audio/appearance, avatar and actual20-player validation explicit; do not infer finished-course acceptance or Phase2/3 authorization.

Optimize while the sample is small: simplify repeated geometry, preserve useful edit units/shared assets, count contacts/lights and avoid unchanged per-frame work. Recheck affected routes and safety. BL02 removes70.92% of placed triangles and42 MeshParts, with seven more shared IDs and five net extra colliders for window colors, small details and safe open returns. No CPU/FPS gain is inferred.

Keep ordinary floor physics and server-controlled recovery. Cache only stable hazard art per session; restart after art changes. Retain one controller and one fresh independent Sol6.1High integrated reviewer, at most two active including lead/nested work, no score gate. Preserve prior models/receipts/unrelated work. [Phase1 handoff](artifacts/moonlit-citadel/phase1/MC_BL02_R04_FINAL_REPORT.md).

## Moonlit Citadel Phase 1 owner acceptance — October 10, 2026

The owner accepts MC_P1_BL02_R04: “Phase 1 is an EASY Pass for me”, and praises the appearance improvements. This closes the Phase 1 commission. The owner will contact Ideation; do not message that chat or begin Phase 2/3 without its new commission.

The 70.92% result is fewer placed mesh triangles, not a measured FPS or general performance increase. Keep finished-course human pacing/audio/navigation, avatar range and actual20-player performance separate. This acceptance changes documentation only; preserve the reviewed candidate, receipts and independent judgment. Exact pre-acceptance frozen documentation is archived with the [acceptance record](artifacts/moonlit-citadel/phase1/MC_BL02_R04_owner_acceptance.md).

## Moonlit Citadel Phase 2 delivery — October 11, 2026

The owner-authorized [Phase 2 commission](artifacts/moonlit-citadel/PHASE2_START.md) supersedes the old Phase 1-only limit and two-agent limit. Build with the accepted Blender kit in daylight, shared server race/progress/recovery authority, one lead controlling Studio, up to three scoped helpers and three fresh independent final judgments without a numeric gate. Do not infer owner acceptance, Phase 3 or publication from those judgments.

Support the actual R15 profile tested at speed 16, jump height 7.2, slope 45 and gravity 196.2. Restore each trusted prior profile on lifecycle changes; do not inherit Phase 1's slope 89 as ordinary-avatar proof. Exclude other racers and accessory padding from false world/hazard contacts while retaining real wall/ceiling protection. Keep decorative counterweights noncolliding so they cannot provide an unintended platform.

Optimize as development proceeds, preserving useful routes and editability. FinalB removes 15 parts/colliders and four meshes from complete-course R01, but adds 9,936 triangles for route/catch repairs. Keep complete-course costs separate from the accepted P1 sample's 70.92% triangle reduction and from FPS. No fixed device/FPS gate was imposed.

Freeze FinalB's native/source identities, preserve full failed raw evidence and save native geometry separately from Git/Rojo. Creator's three judgments PASS, all six earlier full course trees and P1 bytes are preserved, and scene control is released to Ideation's separate review. Human/crowd/device and owner acceptance remain open. Future keep walls need the upper catch opening at x4021.5..4030.5,z2573.5..2582.5,top402, at the reserve's east edge; allow head/camera room. [Final report](artifacts/moonlit-citadel/phase2/MC_P2_C01_R04_FINAL_REPORT.md).

## Moonlit Citadel R05 assembly repair — October11,2026

Resolve Ideation V01/V02/V03 with one deterministic visual assembly pass at Build time. Retain all286 flat skin placements and432 physical walkable contacts; lower only182 decorative skins using seven0.012stud levels, rather than rebuild accepted shared meshes. Trim the11 intrusive decorative piers to0.95stud while preserving their tops; leave25 piers unchanged. Add14 visual BlockMesh insets without changing the complete Gothic-cased hazard's physical/query footprint. No per-frame code, new mesh/material/light or P1 upload is needed.

Keep exact canonical contact preservation separate from raw stored matrix equality:44 near-axis components normalize by at most8.742277657e-8. Explicitly accept only the two inherited Upper_Bay2/OutboardWeight2 stored pivot materializations; native PrimaryPart/PivotOffset/effective-pivot getters remain equal. Preserve the original strict-list failure and exact metadata observations.

Archive exact FinalB before installing R05 and refresh the same three independent judgments. Preserve earlier failures and scope unaffected runtime/route reuse through the full contact/Layout/Runtime proof. Capacity language is two complete two-bay service rounds/four individual bay windows. [Exact R05 packet](artifacts/moonlit-citadel/phase2/MC_P2_C01_R05_FINAL_HANDOFF.md).

## Shared obstacle palette V5 — October 11, 2026

Expand the shared library from 42 to 66 sets in a separate wing, preserving all existing models and the owner-controlled pivot. Keep native editable shapes, model instructions and append-only builders. Add local hinge offsets to the existing server motion controller and a small timed-platform module using the same active-course lifecycle. Preserve existing recovery authority and remote interfaces. A timed platform must not also be a touch hazard; its solid, warning and ghost states restore on reset. [Guide and settings](MANUAL_OBSTACLE_KIT.md).

## Moonlit Citadel R06 boundaries — October 11, 2026

Owner rejection reopens Phase2 gameplay despite R05 technical passes. Preserve signatures and optimized Blender assets. Add actual gaps, narrow/offset/rising transfers and visible red contacts through existing server recovery. Keep Normal longer/broader and Expert meaningfully shorter. Use three significant combined choice boards and route shape/color/arrows elsewhere.

All Studio work/testing must use Obby Tournament, with no computer use or new test windows. Six extra copies caused memory pressure and were closed. Root alone controls live Studio; at most three helpers/reviewers run concurrently. Exactly three independent Sol6.1 High judges must each score at least8.5/10 before closure. This replaces older no-numeric-gate wording for R06 only.

Course-only diagnostics may accommodate a separately recorded actual client preload failure only with exact Original Studio identity, actual Ready/Returning-racer server state and explicit limits. Leave arrival attributes/UI/controls and production code unchanged. Retain every actual race/body/movement/CP/Finish/recovery guard, save failures and disable/archive test tools before handoff. Arrival/input/camera/audio remain excluded.

Model counts/imported triangles are not FPS. Native checks and scores remain separate from owner acceptance, human pacing, devices and actual20-racer traffic. [Current target](artifacts/moonlit-citadel/phase2/revision06/REVIEW_TARGET.md).

Follow the existing CourseService editable-course handoff for Moonlit during Play to prevent duplicate colliders. Preserve the original Edit copy through normal Studio Stop. Owner's later arrow feedback replaces cue09 guidance: keep seven distinct fork exits, three existing combined boards, and supported landing strips; archive repeated course arrows and floor captions. Guidance11/source_map11/all15 production guards define the current target. Fit decorative cues inside actual playable contacts so color does not imply support over void.

Preserve cue09's failed seventh EEN with complete native/client originals. Correct only the measured diagnostic backward-momentum launch using bounded supported zero-Move braking, without changing hazard geometry, profile, goal tolerance or authoritative finish/recovery checks. Tools04 is separately source-bound; a fresh complete current run is required. Privileged native export reads genuine client-owned report instances, records actual MCP client/server origins, verifies exact transported native bytes and localhost readback, and keeps serialization separate from ordinary runtime scripts.
## Moonlit Citadel R06 closeout boundary — October 11, 2026

The owner requires Obby Tournament only, fewer arrows and each of exactly three independent Sol6.1 High reviewers at least8.5/10. Guidance11 retains seven fork arrows/three choice boards and adds no recurring guidance work. Each reviewer independently closes at8.6/10 after current native evidence and final restoration. Following the owner's request to finish quickly, use the completed course-focused checks and skip sixteen exhaustive lifecycle cases; preserve every failure. Keep the genuine artificial overhead protection limitation open instead of weakening its guard or expanding into an unrequested runtime rewrite. NormalEnd closes the owned native server/client windows, leaving Original in Edit with disabled diagnostic scripts. [R06 handoff](artifacts/moonlit-citadel/phase2/MC_P2_C01_R06_FINAL_HANDOFF.md). Owner acceptance, twenty-racer/device proof, Phase3 and publishing remain separate.

## Moonlit Citadel R07 gameplay and verification — October12,2026

Owner rejection supersedes the R06 technical pass. Visible reds are supported course hurdles/gates and use the existing server Runtime MoonlitHazard authority. Falling remains the original invisible recovery function; no duplicate timed system or new gameplay service is introduced.

Use longer separated causeways with purposeful gaps and broad refuges, and shorter Expert branches with narrow landings, rises, timed swings and precision exits. Keep seven meaningful arrows/three existing significant boards. Match the48-stud boarding collision to its visible stone skin. Stagger upper brace contacts and raise the post-lift landing to preserve actual R15 jump/body clearance.

Perform all live work in Original Obby Tournament. Reuse unchanged native proof by scope, add focused changed-section movement and negative shortcut controls, and retain failures. Exactly one set of three independent Sol6.1 ExtraHigh reviewers exceeds8.5; their technical pass is not owner acceptance, human fun/pacing, a fresh full Expert/all-eight sweep, real20-player or FPS proof. Stop after the relevant checks/review threshold pass; disable owned diagnostics and restore the original editing state.


## Moonlit Citadel P3 course revision and final night — October12,2026

The owner's [P3 commission](artifacts/moonlit-citadel/PHASE3_START.md) authorizes course changes despite Phase2 rejection, meaningful horizontal pacing, world completion and exactly five fresh Sol6.1 ExtraHigh judgments, each>=8.5/no material blockers. The same judges assess actual corrections; technical scores do not grant owner acceptance. Earlier Phase2-only/reviewer-count limits are historical.

Keep ordinary movement and all three signatures, both34-stud lifts/fourCPs/one-lap20-racer intent, on-course red obstacles and original invisible FallY277. Use the accepted optimized Blender kit plus the new world kit; architecture and seven arrows/three meaningful choice boards provide guidance. Apply course-local night only after daylight movement/views through the existing ambience controller, with verified restoration and no global editor-night change.

Source07/Build06 is bound by19 installed/durable mappings,1560 exact parts and retained native recovery. Source07 changes two catch inspection offsets only; exact unchanged geometry/main-route comparisons reuse valid05 race evidence rather than rerunning full suites. Disclose341580 known placed triangles and added world/course objects; do not turn geometry counts into FPS claims. The lead controls only original Obby Tournament, one Play at a time; no Computer Use, extra Studio, publishing, whole-place save or unrelated economy/DataStore/security changes.

[Sealed review inputs](artifacts/moonlit-citadel/phase3/MC_P3_FINAL_SEAL07.json). Human pacing/fun/camera/audio, actual20-racer behavior, device/FPS and final owner acceptance remain open.


## Moonlit P3 bounded close world08 — October12,2026

Reuse the accepted BL02/P3 templates and change only WorldPlan when correcting local architecture. Archive world/light groups and both course models before replacement; preserve all nonworld rows, other courses and P1. Budget adjustment400→440 world meshes supports actual near-route/Crown composition;08 uses424/250736tri. No new running system/light or full-course test is needed when exact native core comparison confirms unchanged gameplay and the unchanged full source guard screens new art.

Keep independent art rejection8.2 visible and repair the concrete unsupported Cloister assembly. Do not use runtime/navigation passes, documentation, renamed evidence or a target score to override a material finding. Same five judges reassess the revised installed course; owner acceptance remains separate.

## Moonlit P3 bounded support09 and final technical gate — October12,2026

Resolve the same art judge’s actual08 support defect with accepted BL02 piers. Nine shafts reachBaseY−30; three front shafts bear on existing fasciaY49.9 to keep lower traffic clear. Rear vault/roofZ184.5 puts feetZ168.2/200.8 outside the same route/view reserves. All12 native joins match within0.001stud. Only WorldPlan changes; core gameplay,18 other sources,lights/runtime remain unchanged. Cost08→09:16visual meshes/3040triangles. Internal world unit allowance rises180→188; mesh440/triangle260000 limits remain,actual187/440/253776. No new system or broad suite is warranted.

The same five independent Sol6.1 ExtraHigh judges each close above8.5 on Source09/Build8/seal09, without averaging/replacement. Retain earlier art rejections and failures. Stop at technical readiness for owner playthrough; owner acceptance,human pacing/fun/camera/audio,20 racers,avatars and device/FPS remain separate. [Final gate09](artifacts/moonlit-citadel/phase3/MC_P3_REVIEW_GATE09.json). No publication or automated whole-place save.

## Moonlit Citadel complete-map rework decisions — October 13, 2026

The [owner's latest rejection commission](artifacts/moonlit-citadel/PHASE3_REWORK_20261012.md) supersedes Source09/Build8, old ExtraHigh scores and the wall workaround. Repair route geometry/sequence, preserve recovery and signatures, and retire the rejected wall. Static scenery stays noncolliding/query-off/touch-off; no scenery obstruction replaces it. Easy manual per-piece editing is waived, while durable source, moving/gameplay separation and native recovery remain required.

Both branches retain the complete upper ride. Expert demand comes from narrow offset/rising transfers, directional turns, low hurdle combinations and timing; an easy early-board/early-exit skip is not the reward. Use equal physical centre endpoints and separate mechanism waits. The controlled gallery pair closes the timed-encounter reward concern only for its near-matched initial phase; retain the small wait-removed movement penalty and unproved all-phase/human reward.

Shared3's confirmed target landing requires a placement repair, not a test-label reinterpretation. Source30 changes only its authored surface point(-190,23,-126.5) to(-192,22.5,-126.5); collider/two skin CFrames move accordingly. Preserve the successful29 cut despite its later Failed label, then repeat the same trajectory on30 and verify legitimate fulls. The existing west-facing forward gate addresses accessory early anchoring without changing shared authority or strict body/order/freshness guards.

Foot coverage uses every full bottom bounding-rectangle corner against the actual authored convex octagonal mesh footprint and vertical occupancy. The older rectangular nine-sample method missed a real cut corner and cannot support current closure. The widened116-stud plinth and all96 exact checks close it; this remains art-support geometry proof, not collision/FPS proof.

Freeze Source30/Build24 with69 exact review inputs and18 original current pictures. Same five independent Sol6.1 High reviewers, separate from authors, each pass their scope at8.6/8.7/8.7/8.6/8.8 without material blockers. Keep the frozen packet immutable and seal final reports separately. Owner acceptance and human/crowd/device validation remain distinct. [Final handoff](artifacts/moonlit-citadel/phase3/rework-20261012/FINAL_HANDOFF_SOURCE30.md).


## Stud Garden optimization installation scope — October 13, 2026

Install the frozen three-module combined C01 through repository source and verify actual Studio synchronization. Reuse repeated collision calculations only within each hazard update, and cache formatted warning words within the captured controller state; preserve original collision reads/order, scene writes, timing and reset behavior.

Keep the allocation-only FruitMotion C02 separate because its offline timing is mixed. Reduced construction counts alone do not justify claiming a live speed/FPS improvement. Fresh baseline/installed behavior and native preservation checks passed for C01. [Installation record](artifacts/stud-garden-v2/optimization-20261012/installation-20261013/REPORT.md).


## October13,2026 - Moonlit grand keep and rural landscape

The owner requested a grander main tower and meaningful greenery, trees, hills and mounds. Preserve the accepted course and19arrows; replace repeated stone details and bare rock scenery with a dominant buttressed keep and connected low grassy terrain with outer wooded hills. New visible modules were authored in Blender and imported through the existing receipt workflow. Source48/Build42 is installed; native protection, occupied-space, source parity and recovery checks pass. Final day/night views and three settled sign/crown views are complete. The same five independent High reviewers pass the frozen Source48 candidate with no material blockers; all 89 input files remain unchanged. Owner Phase3 acceptance remains pending. [Current pass](artifacts/moonlit-citadel/phase3/tower-landscape-20261013/REPORT.md).

## Obby Tournament UI overhaul design — October 14, 2026

The owner approved the [UI overhaul design](artifacts/ui-overhaul-concepts-2026-10-13/BUILD_BRIEF.md). The player-facing name is Obby Tournament; "Classic Elevation" stays the repository codename. Sky Rush styles the lobby, voting, results, Shop, tournament intro and event end; the race screens use Sticker Smash shapes in Sky Rush colours and lettering. The arrival keeps its original dark-space shared stage, rebuilt with more motion, and uses the Star coin as its title emblem. One Star coin design is used everywhere. Keys stay visible beside Coins.

Arrival and Results show players' real 3D avatars, reusing the existing HumanoidDescription-to-R15 loaders. Live race place is presentation only, worked out on the client from existing checkpoint broadcasts; the server's finish placement stays official. Shop contents and prices, an overall champion, quests and course coin rules stay visible placeholders until the owner decides them. No economy, DataStore, purchase or race-rule change is part of this work.

Revision 2 (same day): the overhaul restyles the owner's new race-flow screens (Race options, first-visit guide, practice, watching, one-course vote, course preview, finish ticket, inactivity warning) and keeps their actions, button priority, camera leases and the course delivery handshake. The owner then approved a looks-only restyle of the server-built Grand Arcade arch screens, keeping results on screen while the next course loads (race timing unchanged), a Start racing button on the first-visit guide's last step, and Stud Garden as the fifth course that turns the opening vote into a 5-race event once it is race-eligible.

Build choices (October 20): Roblox UI cannot skew, so Sky Rush plates are white slanted 9-slice images tinted by gradients (`UiKit`, `assets/ui/race/make_sky_plates.py`); rows inside a plate start just inside its slanted edge. The old `UiTheme` stays for screens outside this job instead of being restyled. Desktop comes first; phone layouts wait for owner acceptance. Course coins, coin awards, Shop prices and the overall champion stay visible "?" placeholders. The practice area hides the lobby rail, capsule and card (the wallet stays), and entering it opens the line choice. Results sit above the lobby HUD and stay through loading until the next-course ticket appears (at most about 8 seconds) without changing `RaceConfig.ResultsDuration`. Best times on vote cards, your event placings and visit best place are remembered on the client for this visit only. Sound picks (Roblox-owned library sounds and default R15 emotes) await the owner's listening check.


## Moonlit Source49 enclosure candidate and personal review — October14,2026

Install connected fortress/ridge scenery around exact accepted Phase2. Blender18asset/53part ER01 native vertices match within0.000123stud; native487part plan and26source packet parity pass. Split terrain data into116152/96866character modules because Studio rejects scripts at200000characters;732168exact values/47122occupied rows verify no geometry change.

Gate remains open: layout8.6PASS,art8.2HOLD,navigationHOLD,other same original reviewers finishing. Cap triangle repair does not establish every rendered frame; broad floor color pop and valid panorama remain open. Owner requests Ideation personal review and restrained glass windows. Restore editor and yield camera/mutation ownership rather than marking completion. [Exact state](artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/HANDOFF_TO_IDEATION49.json).

## Stud Garden canonical names — October 14, 2026

Use Course_StudGarden as the native template name and CourseBuilders/StudGarden with Runtime as the course entry and SprinklerRuntime for the sprinkler. Existing pure tests use the project tests/StudGarden*.luau naming pattern. Developer labels use the CourseInfo display name.

Keep the existing stud_garden_v2 identity and revision/provenance fields so selection, timing, ambience and history retain their binding. Versioned assets/evidence/build recipes remain historical recovery paths; source implementations are preserved. [Current guide](STUD_GARDEN_EDITING.md) and [verified alignment](artifacts/stud-garden/alignment-20261014/REPORT.md).


## Race flow and portal practice — October 14, 2026

Race enrollment is explicit and lasts until a break. Official entry uses the current delivered character and restored-camera confirmation before cutoff. Finish history stays separate from current activity; visit comparisons are memory-only and bound to real course/route/revision identities. Watching uses one server-approved streaming focus with bounded loading and cleanup. No DataStore, economy, purchase or publishing change.

The owner removed Classic Circuit and Classic Point-to-Point. Four eligible courses currently use ordinary races; five finished eligible courses enable the five-course event. Practice belongs behind a portal in a separate area. The owner will build its course later; keep the starter basic. Preserve existing lobby/stage geometry and concurrent Stud Garden names. [Implementation and evidence](artifacts/game-flow-study-2026-10-02/REPORT.md).

## Course workflow reset after Moonlit — October 20, 2026

The owner's standard is better output and faster work. After reviewing Moonlit through the explicit Source57 acceptance, keep the accepted map closed and replace repeated workflow prose with decisions at the point of work: preserve intent and rejected approaches, prove ordinary sequences and the whole journey, judge the installed experience before scoring, and select verification from the actual change. Blender is again explicit as the primary custom-art tool.

Retain Phase 0, sequential references, three production phases, standing model defaults and owner-selected independent reviewers. Current status remains editable while review snapshots remain frozen. No new phase, mandatory team, app setting, gameplay change or performance claim follows from this update.

The Moonlit continuation chat was archived only after review and inactivity confirmation; archival was verified in a separate listing. Egg Rush remains on standby. [Findings, applied changes and limits](artifacts/course-workflow-v3/MOONLIT_REGRESSION_REVIEW.md).
