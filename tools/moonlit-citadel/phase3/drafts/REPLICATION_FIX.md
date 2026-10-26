# Native client course readiness

October 12, 2026. Changed draft `TestClient.luau` only. No native driver, production source, Studio model or game state was edited by this helper.

The pre-movement `Actual shared Finish trigger missing` failure is consistent with server-to-client model replication, rather than a server course without Finish. `CourseService.spawnCourseRecord` destroys the old runtime RaceCourse and parents a complete server clone into Workspace. Its descendants need not arrive on the client together with the observer's player attribute. Before this repair, `Probe.Run` accepted the observer's Racing state, immediately found a same-name client RaceCourse, and called Start, which immediately required Finish.

`NativeServer.Prepare` creates a route packet; it does not provide a countdown or readiness option. Native Restart calls the real `RestartRace` action. `RaceService.RestartInspectionRound` sets `devStartRaceNowRequested=true`; its round loop then uses zero intermission and skips Countdown. There is no production RoundService module in this repository; RaceService owns this loop. A fixed sleep after release would consume the genuine 1.5-second entry window.

The repaired wait loop repeatedly resolves the current client model instead of waiting on a captured old model. Continuous trials require a different observer race ID and a different actual RaceCourse instance from those captured when Run is armed. The model must match the observer path, candidate, SourceCourseId and RuntimeActiveCourse attributes. Actual Start, Finish, four named checkpoint triggers and every distinct packet support path, including both bay deck paths, must be present with their expected physical properties before Start is called.

The chosen race ID is then bound into Start's existing progress guard. Observer age is checked, and fresh continuous entry uses `raceElapsed + max(0, now-observedAt) <= 1.5`. This only tightens freshness; it does not move the race start, rewrite progress, create timing credit or permit a late start. Readiness that misses this window fails the trial. The existing 90-second outer wait and cancellation remain bounded.

Focus trials can use the existing race and model, skip the continuous fresh-release limit, and retain the original packet/source/race/checkpoint/age checks on their one placement receipt. This branch was inspected in source; it has not been rerun natively by this helper. Humanoid movement, exact deck support, route nodes, checkpoint order, four official splits and actual Finish.Touched requirements are unchanged.

Successful and failed records now contain `replicatedReadiness`: previous/current race IDs, previous/chosen model paths, actual object-replacement result, distinct support count, first missing path, wait duration after the first eligible release sample, total armed wait and actual release age. These distinguish model readiness delay from a traversal failure.

Use the existing sequence: Prepare a new packet, arm client Run and confirm ClientWaitingPacket, then invoke native Restart. A continuous Run armed after Restart now waits for a later fresh race by design. Focus retains its existing PlaceFocus sequence. Do not retry within an already-running continuous race or relax the 1.5-second limit.

The changed file passed the existing one-file source compiler:

```powershell
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase2/CompilePacket.luau tools/moonlit-citadel/phase3/drafts/TestClient.luau
```

SHA-256: `8293aa405661cc1c4c842c63a1fcbb35d0ead7846c6cb3546996f525d369ea38`. Native replication and traversal remain for root's fresh installed helpers.
