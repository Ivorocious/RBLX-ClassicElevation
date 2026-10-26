# Finish diagnosis, October 19

The existing finish plane can miss a legitimate crown arrival because its height and width cover only part of the supported player space. The proposed fix changes one Layout value: `FinishGate.size` from `(22,6,24)` to `(28,12,24)`. Nothing has been installed.

The lead's fresh native inspection matches current source: the crown floor is at local Y150, spans X[-26,10] and Z[-44,-16], and the inward finish plane is X=-5. Current gate coverage is only Y150..156 and Z[-41,-19]. `ForwardGate.Crossed` checks the root's position at the instant it crosses that plane. It does not finish a player who lands beyond the plane after a rejected crossing. Re-entering from the east and crossing inward again can therefore appear to fix the failure; falling is not itself required by the code.

Two source-bound synthetic approaches reproduce the symptom using the unchanged actual `CheckpointService` module:

- A supported straight-west jump from the last stone, followed by a walk on the crown, crosses at root(-5,153.181,-42.429). It lands on the crown around X5.981 before crossing. The old gate rejects this ordinary standing height because its north edge ends at Z=-41.
- A normal jump from crown foot(-2,150,-30), moving west at speed16, crosses at root Y159.698. The old gate rejects the crossing because it ends at Y156. Landing later does not create another crossing.

Both finish with the proposed gate. Its Y150..162 envelope covers the observed standing-root offset3.181 plus configured jump height7.2 with1.619 studs spare. Its width matches the crown floor. The X=-5 plane, inward direction, bottom height, depth, noncolliding trigger behavior and every race validation stay the same. `RouteBuilder` already derives the new centre from half the height, and `Coverage` already validates against Layout, so neither needs editing.

Historical directed passes do not contradict this defect: the authored last transfer targets crown foot(8.95,150,-37.87), then explicitly walks toward the centre(-8,150,-30). That brings the root inside the narrow strip before it crosses. The required final-gap jump itself ends east of the finish plane.

`finish-diagnostic.json` records14 direct gate cases,15 unchanged CheckpointService harness cases, and2 sampled ballistic approaches. Tests retain missing/out-of-order checkpoint rejection, official racer/status/active-race requirements, living character, recovery immunity, fresh character/race samples, duplicate-finish prevention, speed cap, stale-sample denial and backward denial. Every other exported Layout data value in `Layout.proposed.luau` matches current source exactly.

These are offline source and synthetic-motion results, not native physics or proof of the owner's exact movement. The lead must reproduce the miss in Play before applying the draft, then repeat the changed approaches and focused negative checks. `FinishProbe.luau` is a syntax-checked passive helper: `Probe.Start(player, activeCourse, existingServices, seconds)` returns `Result()` and `Stop()`. It observes the server's existing services and records root/plane coordinates, gate decision, current checkpoint, official/status/alive/immunity state. It does not move a player, change progress, mutate the gate, or write Instances. Run it only through the lead's existing Play test context.

Reproduction command:

```powershell
.\.tools\lune-0.10.5\lune.exe run tools/moonlit-citadel/phase3/repair-20261019/finish/DiagnoseFinish.luau
```

`finish-volume.patch` and `finish-patch-proposal.json` bind the exact one-line draft to the inspected production source hash. Production and native Studio remain unchanged by this work.
