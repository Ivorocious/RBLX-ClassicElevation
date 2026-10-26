# First arrival

The approved [Shared Stage B concept](artifacts/arrival/shared-stage-concept.png) is implemented as native Roblox UI with one 3D stage. It has no welcome heading or enclosing character cards. Players choose **Create racer** or **Use my avatar** from a shared ivory action bar while the rest of the place loads. This is an arrival overlay, not a Lighting or skybox change; the lobby and every course keep their own appearance. [Current Studio view](artifacts/arrival/shared-stage-live.jpg).

The starter creator offers four hair styles, six skin tones and eight colors each for the top and legs. The left character always shows a blank gray dummy. The right character loads the player's Roblox appearance. Viewport models are separate from playable characters. Custom looks apply only inside this experience and reapply after respawn; they do not change the player's Roblox account avatar or inventory.

Creating and saving a racer grants **100 Gold once**. Choosing the Roblox avatar preserves the later bonus. **My racer** in the lobby’s left rail reopens the choice and creator. The separate floating Edit racer pill is suppressed; queued players cannot open the creator. Previously completed players automatically load their saved choice and enter the lobby; further returning-player UX is intentionally deferred.

## Shared avatar rules

Avatar Settings are saved for the experience in Studio, separately from Rojo source. Keep R15 Only, custom height 5.5 studs, Single Collider 2 × 3 × 1 studs, **Use parts** for hit/touch detection, and Standard R15 animation packs. Body parts, build, clothing and accessories remain player choice. Oversized accessories use Scale with 25% bounds padding on each axis. Accessory sounds and VFX are disabled; emissives remain enabled. These rules apply throughout the experience, unlike each course's lighting.

`RacerAppearance`, server appearance application and viewport descriptions explicitly set `HumanoidDescription.UseAvatarSettings = true`; otherwise generated/reapplied descriptions bypass these defaults. Keep the existing movement tuning: WalkSpeed 16 and JumpHeight 7.2, with UseJumpPower disabled. Preserve body-part touch detection: the short movement collider alone does not contact the floor while standing, which can miss foot-operated triggers. This standardizes movement collision, not every visual body part's hazard detection bounds.

When creating a separate Roblox experience, copy these native settings there; a Rojo build alone does not carry them across. To check either path, use F6 → Returning avatar / Returning racer, then Respawn.

## Files and tuning

Use the **UI Labs** plugin (Arrival folder of the **Obby Tournament** storybook) to inspect the chooser, creator and confirmation/error cards in Edit mode. The stories draw the game's own `ArrivalScreen`. [Preview guide](UI_PREVIEW.md).

- `ReplicatedFirst/ArrivalBoot`: immediate dark cover while client scripts arrive.
- `OnboardingController`: player state, controls, audio and server requests. `ArrivalScreen` / `ArrivalView`: shared chooser/creator layout, star drift, viewport framing and focus.
- `ArrivalStage`: one studded platform, shared lighting/camera, two characters and restrained idle poses. Supports Motor6D and AnimationConstraint joints, with accessory welds following their bodies.
- `OnboardingService`: profile loading, validated choices, appearance application, movement hold and Studio presets.
- `ArrivalProfile`: pure profile validation and reward transitions.
- `RacerAppearance`: constructs descriptions from approved configuration options.
- `OnboardingConfig`: reward, palette, hair asset whitelist, DataStore name and ambient sound.
- `assets/onboarding/make_ambient.py`: reproducible original 32-second ambient loop. Its upload receipt records asset `83623533219361`, owned by this place's creator.

Sound and motion toggles last for the current session. The starfield uses 78 small UI objects and pauses its updates when closed or reduced motion is enabled. Only the lobby and chosen character are preloaded; courses are not loaded by the entrance, and no fabricated percentage is used. The dark boot cover hands off to the profile-loading state, with Retry for profile read failures. Avatar preview downloads do not block choosing a path.

The shared stage updates at most 30 times per second while the chooser is visible. Characters have separate breathing, weight-shift and head-glance timing; focus adds a small eased turn. Motion off restores a still pose and freezes the coin and stars. Opening the editor or entering the lobby suspends stage updates. No animation assets or extra uploads are required. The large Studio developer toggle hides during arrival, but F6 still opens its panel. A newer arrival event takes precedence over a late initial state response.

## Saved data and server rules

Published servers use DataStore `ArrivalProfiles_v1`, key `Player_<UserId>`. Schema version 1 contains completion, selected mode, optional custom look, Gold balance, creation-bonus claim, revision and last successful operation ID. This is the first saved profile / Gold balance in the repository; there is no shop or spending system yet.

`UpdateAsync` saves the appearance choice and reward claim together. It reads the latest stored value, rejects stale revisions, preserves unknown fields, and recognizes retries of the last successful operation. Repeated custom saves or switching back and forth cannot award the bonus again. An existing invalid/future profile blocks entry instead of being replaced with an empty one. Failed reads block writes. Failed saves retain the open chooser and can be retried with the same operation ID. A save that succeeds but whose appearance cannot be delivered remains saved; retrying delivery cannot grant another bonus.

There is no client-supplied reward amount, balance, user ID or asset ID. `Gold` on the Player is a server-set display attribute. Future purchases/rewards must use the same authoritative profile writer or an explicit migration; do not overwrite this record from another service.

`OnboardingReady` is set only by the server. New/loading/editing players are excluded from eligible/queued/starting racers and late-race/spectate requests. Their current character is held still until a saved appearance is applied. Lobby customization is rejected during a race or countdown. Returning a player to the lobby clears their staging formation so developer presets cannot be pulled back to the start pen.

## Remote contract

Both remotes live under `ReplicatedStorage/Remotes`, created by the service at startup.

- `ArrivalControl` RemoteFunction: `{action="State"}`, `{action="Edit"}`, `{action="Cancel"}`, `{action="Retry"}`, or `{action="Save",mode="Avatar"|"Custom",look={hair,skin,top,legs}?,operationId=string}`, and `{action="Arrived",token=string}`.
- Responses: `{ok,message?,phase,profile?,studio,preset?,delivery?}`. Phases are `Loading`, `LoadError`, `Choice`, `Entering`, `Ready`.
- `ArrivalChanged` RemoteEvent: server-to-client state updates with the same response shape.
- Mutations have a 0.4-second per-player cooldown and an in-flight guard. Appearance choices require bounded integer indices with no extra keys. Operation IDs are 8–64 alphanumeric/hyphen characters. Only completed profiles may cancel back to their saved look; Edit requires Lobby status.
- Existing `StudioDevControl`: `{action="OnboardingPreset",preset=whitelistedName}`. This path is Studio-only on the server.

## Developer testing

Studio always uses temporary in-memory profiles and never opens the production DataStore. Each fresh Play starts as a new visitor. Press **F6**, then scroll to **ARRIVAL — TEMPORARY TEST PROFILES**:

| Preset | Result |
| --- | --- |
| First visit | Empty profile, open chooser, 0 Gold |
| Returning avatar | Completed own-avatar profile, enters lobby |
| Returning racer | Completed custom profile, 100 Gold, enters lobby |
| Bonus available | Completed own-avatar profile reopened with bonus available |
| Bonus claimed | Custom profile reopened with bonus already claimed |
| Slow loading | Eight seconds of loading before the chooser |
| Load failure | Read error; Retry clears the simulated failure |
| Save failure | Next save fails once; retry can complete normally |

Presets change only the selected player's temporary profile and return that player to the lobby. They do not erase production progress. Existing round/map/teleport controls remain available above and below the presets.

## Verification and limits

`tests/ArrivalProfile.luau` covers reward eligibility, idempotent retries, repeat saves, switching modes, malformed appearances, unsupported profiles and returning profiles. `tests/studio/Arrival.client.luau` exercises the real Play remotes and server state rather than initializing a second service in the MCP command environment.

Studio verification: 19 pure profile checks and 26 live remote checks passed. Actual Create/Save clicks completed the flow; movement resumed with 100 Gold. Own-avatar selection, later creation, repeat claims, appearance after respawn, all tested return/error/slow states passed. The actual server service reported zero eligible, queued or started racers while onboarding was open. Mute set audio volume to zero and reduced motion stopped star positions. The 32-second sound loaded and played.

Final checks also passed entry into a City Run race, rejection of customization during racing, and a first-visit reset during the race: the player returned to Lobby, stopped being an official racer, and could neither spectate nor enter late while the chooser was open. Bonus-available and Cancel restored the previous profile without granting Gold. The 26 live checks passed again after the server/staging corrections.

Native UI bounds passed at 1360×779, 375×700 and 667×375. The final layout function was extracted from source and exercised against the running UI after adjusting the canvas size; this is a layout simulation, not physical-device evidence. It checks screen/card containment, touch-target heights, option/save separation, and footer/error separation. [Landing screenshot](artifacts/arrival/desktop.png) and [loaded creator](artifacts/arrival/creator.png) show the implementation. The initial new ReplicatedFirst script was mirrored from the repository into the connected Studio tree; its permanent mapping is in `default.project.json`.

Published DataStore round trips, real multiple-player sessions, physical-phone input and controller navigation still require testing before publishing. Local profile tests and Studio's temporary data do not prove live DataStore access. Rojo build and source compilation are recorded in the playtest notes.

## Shared-stage interaction refinement

The native coin has a layered bevel, milled edge and raised E emblem. Its reward label follows the coin above the creation side; claimed bonuses hide both. The ivory action dock uses aligned labels and an inset pressed state. Hover, gamepad selection and touch activation highlight the matching floor. Each new focus triggers a 2.5-second greeting with two diminishing hops, body sway, head tilt and an oversized wave, then returns to idle. Stable projected character targets support model hover and clicking as well as the action bar. Motion off suppresses greetings while keeping selection feedback. Change anytime is a quiet footer postscript.

Confirmation appears before committing the own-avatar choice or a finished custom racer. Opening the editor remains immediate. Confirmation and save errors use a compact cream ticket with only the useful question/message and action buttons; transport errors do not claim that a write definitely failed. Retry keeps the exact appearance payload and operation ID. The dialog prevents repeated confirmation, contains gamepad selection, and supports Escape / controller B to dismiss when not saving. New developer presets close stale dialogs.


## Lobby entrance

First-time save enters `Entering`, with movement and race eligibility still held. `ArrivalDelivery` retains the lobby for that player and sends its bounds, spawn position, part count and a per-delivery token. `ArrivalTransition` begins warming that lobby while the chooser is open. It waits for all expected parts and successful `ContentProvider:PreloadAsync` callbacks on the actual lobby instances, then checks character visuals and a collidable floor beneath the player. Bare mesh IDs must not be passed as generic preload strings: Studio reported failures for those while all 690 actual-instance requests succeeded.

The six-piece elevation mark was authored with Blender 5.2. `assets/onboarding/create_arrival_emblem.py` saves `assets/onboarding/entrance/ElevationEmblem.blend` and exports `ArrivalEmblemGenerated.luau`. Roblox renders those six native parts inside a ViewportFrame; no asset upload is needed. The logo resolves into a vertical reveal of the real lobby. A curved camera approach ends behind the character, fades the arrival music, restores the HUD and releases control. Motion off uses short fades without the camera flight. Lighting and map ambience remain owned by the existing map systems.

`Arrived` accepts only the current Entering session token, a living character and proximity to the assigned lobby spawn; it grants no currency. Client delivery acknowledgement is a presentation readiness signal, not security proof that a modified client downloaded assets. Reward/save rules are unchanged. A timeout or failed fetch retains the gate and exposes Retry without re-saving the profile. A new developer preset cancels stale camera/loading work.

Additional F6 presets: **Lobby entrance**, **Slow lobby delivery** (eight-second overview hold), **Lobby delivery failure** (one failed attempt; Retry recovers). They remain temporary Studio profiles. `tests/studio/ArrivalTransition.client.luau` checks holding, completion, invalid acknowledgements and cancellation; the existing arrival regression suite waits for the new entrance before testing later customization.

Roblox API references: [instance streaming](https://create.roblox.com/docs/workspace/streaming), [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider). Loading proof covers the lobby and character, not every course or later avatar asset change.


### Title continuity refinement

The entrance replaces the header in the same screen position, using its existing one-line text and size. It travels and grows into the central emblem over 0.9 seconds, holds fully visible for 1.6 seconds even with cached assets, then reveals the lobby over 1.1 seconds. Only one title is visible. Timing lives in OnboardingConfig.Entrance. Motion off uses a brief central fade instead of title travel. Cancellation restores the header; tests/studio/ArrivalTitle.client.luau measures the actual RenderStepped animation and minimum hold.

### Coordinated landing — October 1, 2026

The approach interpolates position and rotation separately to avoid a sharp turn when a look-at target crosses the camera. It samples Roblox's actual player camera orbit, zoom and FOV behind the title. During the final .7 seconds, the scripted camera blends into the native camera while title and music fade. HUD artwork warms with the lobby; the staggered reveal begins after valid arrival acknowledgement and overlaps the end of the fade. Client movement and HUD actions release after the reveal settles. A delayed acknowledgement safely postpones HUD entry.

Returning visits use a short title/native-camera presentation without the overview flight. Motion off uses short fades and stationary HUD positions. Mute is read from the current preference on every entry; completion does not restore an old volume.

New delivery tokens cancel older work. Respawn or camera replacement releases camera ownership and exposes Retry while keeping entry held. Retry rebuilds the current character/camera delivery without saving again. Existing server token validation, profile writes, Gold and race gates remain unchanged.

Local Studio checks passed slow loading with actual W input, invalid/stale tokens, same-preset replacement, cancellation back to the chooser, respawn during Overview with actual Retry, muted/reduced entry, returning entry and a race starting during Handoff. [Clean frame records and native evidence](artifacts/soft-landing-2026-10-01/r4/index.html). The official screenshot tool changes the Play camera mode, so camera/control measurements use a separate run without captures. Forced missing/late acknowledgements, respawn during Settling/Failed, physical devices and production remain unverified edges.

## UI overhaul (October 2026)

The arrival choice keeps its shared dark-space stage. The title reads "OBBY TOURNAMENT" with the Star coin emblem (placed from a direct text measurement); the gray placeholder racer stands straight and waves without clipping its head; the unchosen racer is dimmed by a soft-edged screen shade. The first-visit guide is opt-in through Show me around and now uses `VisitCoachView` (see [Race flow](RACE_FLOW.md)); its stop rules are unchanged.
