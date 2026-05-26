# Bugs

Track known bugs and regressions here.

## Open

- None currently recorded.

## Fixed

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
