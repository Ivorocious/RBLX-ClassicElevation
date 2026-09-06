# River finish and Skyline tuning — 2026-09-06

`AscentRiverFinishPass` revision 1 extends the accepted altitude-revision-2 course.
The authored candidate remains local to Studio; no place was published.

## Behavior

- Player camera maximum: 30 studs, stored in the Rojo project.
- River water continues beyond the existing playable boundaries. New scenery has
  no collision or touch behavior; the original collidable boundaries remain.
- Logs travel from +88 to -88 studs across each stream. Opaque crags enclose both
  full reset positions. Every first cycle starts at its hidden endpoint.
- Five staggered logs per stream preserve arrival frequency: approximately 6.85
  seconds between logs, compared with 6.8 seconds previously. Speed remains
  68/13 studs per second. There are 100 logs across 20 streams, with two centers
  per stream inside the playable corridor in the accepted preview.
- Checkpoint 002 and its decorative ground are shortened to 13 studs to clear
  the first log sweep. The 19 checkpoints and other section layouts remain.
- Section 09 has 48 non-checkpoint pads and matching supports shortened by 0.5
  studs in their forward dimension. Curved paths mean the resulting gap change
  varies. The largest measured projected gap is 8.079 studs, up about 0.506.
- Cyan ice and darker supports improve landing contrast. Three decorative ice
  spires and the entrance sign are moved outward to clear the opening.

## Verified in Studio

- Static module: 20 streams, 100 logs, 180 sampled route/bank overlap checks with
  no intersection; 250 continuation parts without collision/touch behavior;
  collidable boundaries found on both sides of all 20 streams; 19 checkpoints.
- Endpoint concealment: 14,400 ray samples covered eight corners of both reset
  positions from 45 nearby camera offsets per stream. Every ray hit the opaque
  continuation before reaching the endpoint.
- Live server cycle check: 72 seconds, 208 resets, 210 starts, zero transitions
  inside the visible portion of the river. Observed log velocity was 5.23 studs
  per second. Client and server player camera caps were both 30.
- The Valley S06-to-S07 jump passed using client-owned normal movement, a takeoff
  about 0.35 studs before the source edge, and a grounded landing inside S07.
  Recorded landing: (1603.154, 218.756, -1134.553). No landing teleport was used.
  Early server test attempts did not settle correctly; a center launch fell short.
  Releasing movement after the successful landing later slid off the ice. This
  verifies one edge jump, not safe stopping or a complete lane traversal.
- Rojo 7.7.0 build and `git diff --check` passed. The reconnected Studio session
  received the repository source; the river module matched exactly.

## Review boundaries

Three independent Terra High reviewers took their own screenshots from different
player-relevant angles. Ratings concern the requested changes. The older straight
river-bank layout remains visible and would require a separate redesign.

Final requested-change ratings: river 8.6/10, Skyline 8.2/10, and combined
presentation 8.2/10. All three exceed 8. The combined reviewer explicitly separates
the inherited river grid from this pass; these are not whole-course quality scores.

These checks do not establish human timing, touch controls, multiplayer behavior,
or completion times. Manually play the river at maximum zoom, ride a log near each
boundary, and try all three Section 09 lanes on keyboard and touch.

## Repeat the checks

Run `ClassicAscentRiverFinish.Run(model)` from `tests/studio` against an Edit-mode
workspace candidate. Run `ClassicAscentRiverMotion.Run()` through a temporary
server Script during an active Studio race. Direct MCP module calls use a separate
module state and cannot observe the running race services correctly.
`ClassicAscentSkylineJump.client.luau` runs as a temporary LocalScript in
PlayerScripts during a race. It sets up S06, waits for grounded stability, and
uses normal movement and jumping to reach S07.
