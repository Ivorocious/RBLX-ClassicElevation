# Lobby UI

## Current: UI overhaul (October 2026)

The lobby is rebuilt in the Sky Rush look from the [UI overhaul brief](artifacts/ui-overhaul-concepts-2026-10-13/BUILD_BRIEF.md); the sections after this one record earlier revisions. `UiKit` holds the shared palette, fonts, sticker and slanted Sky plates (9-slice images), buttons, chips, motion and sounds. `LobbyView` builds the rail (Shop, My racer, Records, Settings), the phase capsule with a draining dial, the Coins/Keys wallet (Keys always visible; "+" opens the Shop), the next-race card from `LobbyPresentation.Card` (Start racing / You're in with a YOU'RE IN! stamp, Take a break, Race options, Watch racers, Practice), activity toasts and the Records/Settings dialog. `ShopView` is a placeholder (Get Keys and Finish styles; every Buy says "Coming soon"; no purchases). `PortalMarker` floats a "Practice portal" sign over the lobby portal on this client only.

In the practice area the rail, phase capsule, next-race card and toasts hide (the wallet stays) so the practice screens own the screen; `RaceFlowController` sets the local `PracticeRoom` attribute for this. Quests stay out of the HUD; their code is kept for later.

October 2 phase/wallet correction: Lobby and Map vote use the same illustrated clock, white capsule, navy lettering and desktop placement through `PhaseCapsule`. Coins and Keys share one white strip with contained, equally sized artwork and separate changing values. Runtime popup shade still covers the full viewport while HUD controls use the device safe area. Start a fresh Play session after source changes. The updated Edit-preview plugin needs one Studio restart if its toolbar was already loaded.

The approved [October 2 reference](artifacts/ui-voting-concepts-2026-10-02/01-refined-hud.png) puts captioned coin/key counters at the top-right, one phase capsule at the top-center, and a compact course/status card with wide Race options below the counters. Empty quests use a slim native lilac strip. Shop, My racer, Records and Settings retain the accepted left-rail artwork. The phase capsule now uses the accepted voting clock artwork. Text and balances remain separate. [Current phase/wallet comparison](artifacts/phase-wallet-2026-10-02/phase-wallet-comparison.png).

`LobbyView` and `LobbyIcons` build the UI; `PhaseCapsule` builds the shared top-middle display for Lobby and `GalleryVotingView`. Both phase timers use its 900 by 550 desktop threshold, independently of the Voting panel layout. `LobbyPresentation` formats balances, timers and state copy; `LobbyUiController` handles presentation and panels. `RaceUiController` forwards existing server messages and binds existing actions. The same builders power the Edit preview. [Intermediate window checks](artifacts/phase-consistency-followup-2026-10-02/README.md).

The lobby HUD waits for completed arrival and appears for Lobby/Queued players while waiting, between races or resetting. A player in the lobby during an active race gets one Race options entry point. Countdown, racing, spectating, finish choices and results retain their existing screens. The old personal-summary panel yields while this lobby HUD is visible.

Only a server-reported Queued status says “You’re in.” An unqueued player sees “Not queued yet.” Held Studio lobbies say “Lobby open / Explore.” Timers and course information come from received race messages. Race options uses the existing Spectate and Late run remotes; there is no new Join/Queue action. An unanswered choice becomes retryable after six seconds only if the race and player status remain unchanged. A newer request cannot be cleared by an older callback.

My racer opens the existing saved-look chooser and is unavailable while queued. Gold reads the server-owned player attribute; an unknown balance shows an em dash. Keys, Shop and Quests show honest unavailable/empty states. Records keeps up to 20 valid official finishes from the latest populated session result, not global or persistent records. Settings changes lobby text size and local world shadows for this session.

Modal panels contain selection focus and disable background selection. Keyboard navigation is implemented for Tab/Shift+Tab, arrows, Enter/Space and close actions. Native Enter/Down and focus restoration passed. Roblox’s test input tool cannot send protected Tab/Escape/B keys; those need a hands-on check. Compact layouts keep targets at least 44 pixels tall and preserve text clearance.

## Preview and checks

Current phase/wallet checks: 339 native container assertions across five sizes, 52 pure presentation checks, five source compiles and both Rojo builds passed. Fresh normal Play loaded both clocks and wallet icons; native Coins/Keys clicks and larger text passed. All four changed game modules match Studio. The strict scoped reviewer scored 9.2/10 with no material blockers. [Evidence and limits](artifacts/phase-wallet-2026-10-02/README.md). The checks below record earlier revisions.

Preview the lobby in Edit mode with the **UI Labs** plugin: the Lobby folder of the **Obby Tournament** storybook has the HUD in four states plus the Shop, Settings, Records, Coins and Race options panels, all from sample data. It never supplies live player data. [Preview guide](UI_PREVIEW.md).

Previous R4 refinement: sculpted blue race-panel tab with curved caps and a white facet; softer colored bevels/edges and faint surface lighting; taller SourceSansBold lettering; a chunky diamond key overlapping its badge; warmer bag outline and coin facets; roomier desktop navigation. 148 game/plugin sources compiled; game and plugin Rojo builds passed; 88 native Edit-preview checks and 63 Play client UI checks passed. All four changed game modules matched repository and Studio source. All11 image labels loaded in Edit and Play. Four course names, countdown and race labels fit with larger text at three container sizes. Earlier normal native Play clicks and 32 pure presentation checks are recorded in previous revisions; the presentation module is unchanged.

R5 removes the white side facet and cyan curved decorations from Next race, retaining the rounded blue tab. The new image is uploaded, source-synced and loaded in native Edit preview. The game build and148 source compiles passed. This change only replaces panel artwork; race actions and data are unchanged. [Native panel check](artifacts/hud-reference-2026-10-01/r5/race-edge-native.jpg).

The owner accepted the R5 Shop, coin and key style and authorized completing the set. R6 installs those exact images plus My racer, Records, Settings/Race options, clock, queued check and View all arrow. Native frames normalize visible pixel bounds so transparent padding does not shrink symbols or crowd labels; text and changing values remain separate. The small clock and arrow were simplified after strict review. The final reviewer passed the family in native desktop and compact containers. [Complete set](artifacts/hud-reference-2026-10-01/r6/icon-family.png), [sprites and prompts](artifacts/hud-reference-2026-10-01/r6/README.md), [strict review](artifacts/hud-reference-2026-10-01/r6/review.md).

R6 passed148 game/plugin source compiles, both focused test-source compiles, the game Rojo build and88 final native Edit-preview checks. All14 nonempty image labels loaded, including all nine icon kinds; the changed source matched Studio. Portrait375×700 and landscape667×320 container captures confirm icon/text clearance. This artwork-only change did not require a fresh Play session.

The independent reviewer judged R4 lighter and more approachable than R3, with no final visual regression or blocker. No new numerical score was requested. This is a visual judgment of the sample-state native Edit HUD, separate from functional tests and owner acceptance. [Historical R4 review](artifacts/hud-reference-2026-10-01/r4/review.md).

Compact checks resize real UI containers; they are not physical-phone evidence. Physical phone/controller input, multiplayer, real network failures and published saving remain unverified. No gameplay backend, progression or economy changes were made for this revision.

[Current native image](artifacts/hud-reference-2026-10-01/r6/native-desktop-final.jpg), [verification](artifacts/hud-reference-2026-10-01/r6/verification.json), [source and asset manifest](artifacts/hud-reference-2026-10-01/r6/source-manifest.json), [editable Figma specification through R2](https://www.figma.com/design/xmfVLaBWKD9yY1Jm79ImSc?node-id=3-143). Current PNG assets and ImageGen prompts are saved locally; panel SVG sources remain editable. Earlier functional evidence remains in the Air × Pop artifact folders; its old visual score does not establish fidelity to this new reference.

## Manual check

1. In Edit, open the preview. Try Lobby, Settings, Records, Race options and both phone sizes; Refresh should show source edits.
2. In Play, use My racer and cancel back. Check Records, larger text, shadows, popup close and keyboard/controller focus.
3. Start a race with F6. Check HUD handoff and the visible lobby. Return to Lobby during a race, then try Spectate or Late run.
4. On a physical phone, check both orientations, scrolling, touch targets and clearance from movement/jump controls.

## Soft Landing R4 — October 1, 2026

The accepted R6 icons remain unchanged. Long course names wrap within their own column; format and buttons move below the measured title height. Larger text and short landscape layouts preserve at least 44-pixel targets. Softer lobby-only finishes reduce layered highlights and shadows. Idle Explore/Studio preview are quiet text; unknown Keys remains a subdued dash. Empty quests uses a compact ticket without progress controls; Reference HUD retains its explicitly labelled populated sample.

The same controller builds the HUD while the central title is visible. Currency/race, navigation and quests reveal in that order during the final camera/audio fade, with 0/.08/.18-second starts, .3-second easing and 16-pixel offsets. Inputs stay locked until the whole reveal settles. Ordinary updates apply the current reveal time rather than restarting it; race screens can take over during this sequence.

[Native comparison and timing evidence](artifacts/soft-landing-2026-10-01/r4/index.html). 270 native layout checks, 88 Edit-preview checks, 32 presentation checks, 149 source compiles, four focused check-source compiles and both builds passed. Eight changed game sources matched Studio. Actual Settings/larger text, race start during Handoff, Results and retained Lobby passed. Independent scores for the same frozen source: visual 9.0, motion 9.1, behavior 9.0; each passed with no blockers.

Phone views are resized native containers. Physical-device/controller input, multiplayer, real network failure, production saving and broader performance remain outside this evidence.

## Currency and popup spacing — October 1, 2026

The coin is centered and enlarged slightly to cover the slot's upper-left corner. Currency badges now sit near the top of the safe area. Modal shade extends across the full viewport, including the strip behind Roblox's top menu; HUD controls keep their safe-area layout. The Edit preview shade stays within its preview container.

149 source compiles, the game build and 33 fresh-source native layout checks passed. Desktop modal review found no blockers. Backdrop close and Settings open/close passed in the running Play session, with raised spacing preserved. That session started before these edits, so its current GUI received the same layout as a temporary refresh; the repository modules remain the permanent change. [Checks](artifacts/currency-modal-2026-10-01/checks.json), [native modal](artifacts/currency-modal-2026-10-01/native-modal.jpg).
