# Bugs

Track known bugs and regressions here.

## Open

- None currently recorded.

## Fixed

### Racers could leave staging, then be teleported back at the starting signal

**Status:** Fixed in Classic Ascent version 3.

Staging now occurs once during Intermission. A protected start pen and exit gate keep racers safe before Racing. The gate opens without moving healthy staged characters again. Verified with free movement, forward collision, escape recovery, queued respawn and transition checks.


### Active racer respawns in lobby after falling

**Status:** Fixed

**Steps to Reproduce:** During `Racing`, fall through `FallZone_Main` far enough for Roblox to kill
the character.

**Expected:** The official racer returns to `RaceCourse.Start` or the latest completed checkpoint.

**Actual:** The character could respawn at the lobby spawn while the race was still active.

**Notes:** Fixed by making `RespawnService` only consume fall cooldown after an actual pivot and by
adding a `Humanoid.Died`/`CharacterAdded` fallback that returns active official racers to their
checkpoint respawn after a void death.

## Template

### Bug Title

**Status:** Open

**Steps to Reproduce:** TBD.

**Expected:** TBD.

**Actual:** TBD.

**Notes:** TBD.
## Classic Ascent v4 — 2026-09-05

- Fixed normal hazard death delays/default-spawn flash by recovering the existing
  live character directly. Unexpected reset/real death still uses Roblox respawn.
- Fixed malformed camp roof, preserved manual sign angles/heights, removed the
  Switchback lava and Skyline red seams, and concealed falling-rock sources.
- Intermission uses the prior on-course staging flow. Lobby return expectations are
  deferred to the upcoming lobby rebuild at the user's request.
- Open validation: human v4 timing, slippery-floor feel, cover effectiveness and
  20-player crowd/performance. No full-course v4 automation was run.

## Classic Ascent v6 - 2026-09-06

- Open: river log idle carry needs manual acceptance. Native physics replaced forced rider teleports, and walking/jumping are possible, but focused automated idle samples showed about 4.6 studs of relative drift for 4.6 studs of log travel. Do not mark the river movement issue fully resolved until standing, walking, jumping and wrap behavior pass in Studio. See [v6 handoff](CLASSIC_ASCENT_V6.md).

## Classic Ascent v7 - 2026-09-06

- Fixed late-arriving river foam discovery after course replacement; moving foam was observed on the client.
- River bank overlap and log density were revised. All 40 logs moved in a server sample. Rider carry remains open: the short automated placement triggered recovery and did not establish standing/walking/jumping acceptance. See [v7 handoff](CLASSIC_ASCENT_V7.md).
