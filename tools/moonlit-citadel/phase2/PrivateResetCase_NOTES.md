# R04 private reset diagnostic

`PrivateResetCase.luau` is a test-only ModuleScript. Install identical copies at `ServerStorage/MoonlitPhase2Tools/PrivateResetCase` and `ReplicatedStorage/MoonlitPhase2Tools/PrivateResetCase`. It guards unpublished running Studio (place/universe zero), R04, exactly the actual R15 players -1/-2, authoritative arrival readiness, inactive prior tools and no active native driver. Keep the existing ServerProbe progress bridge running. Stop the contact and boundary suites and their client watchers before using this module.

The lead alone installs and runs this tool in the isolated fixture. Do not install into the published experience. Source SHA256: `f1a60e5155fd0891206d52ac6a8582a3e0d3d56636d6828cdc6ed2faf0a680ce`.

On **each actual native client**, start the passive watcher first; it returns immediately and waits up to 60 seconds for the server transport:

```luau
local test = require(game.ReplicatedStorage.MoonlitPhase2Tools.PrivateResetCase)
test.ClientWatch({authorizedPassiveNative = true})
return test.ClientCurrent()
```

Then on the **native server**, start the diagnostic; it also returns immediately:

```luau
local tools = game.ServerStorage.MoonlitPhase2Tools
local test = require(tools.PrivateResetCase)
test.Start(require(tools.TrialControl).Services(), {authorizedControlledNative = true})
return test.Status()
```

Poll `test.Status()` for compact state, failure, reset result, cleanup and evidence path. `test.Current()` retains the complete server report; avoid returning its large contents through MCP. `test.Stop()` requests bounded failure/cleanup. Client `ClientCurrent()` reports watcher state and its local evidence path. Client execution belongs in the actual local client context; server PlayerScripts are not an installation route. If using a LocalScript template, the lead clones/enables it within each actual client's PlayerScripts through client execution.

The server creates one uniquely owned RemoteEvent under existing `ReplicatedStorage/Remotes`. Only actual original callers, owner, nonce, case, race and allowed response kinds are accepted. Client response chunks are ordered 16,000-byte pieces, maximum 900,000 bytes/60 chunks. The transport accepts observation only; clients cannot request a reset, change a profile or credit progress. It becomes inactive on cleanup and is retained, along with the raw evidence. No unrelated object is deleted.

The test performs these bounded checks:

- `TrialControl.Restart()` creates a fresh real shared official CP0/f0 Racing session. Both actual client observers acknowledge the new race before placement.
- `MoonlitCitadelService.Stop()` legitimately disconnects the normal binding and restores its captured profiles/transforms. The diagnostic captures the real current values of WalkSpeed, UseJumpPower, JumpHeight, JumpPower and MaxSlopeAngle.
- It assigns distinct trusted test profiles: player -1 requests 13/true/6.1/41/39; player -2 requests 14/true/6.2/42/40, in that field order. The **actual native stored values after assignment** become the exact known fresh-binding baseline. Requested values and previous real values are retained separately. Configuration number checks allow only `1e-5` for native property float storage; restoration to the captured native baseline and real previous values remains exact.
- It calls the actual `ServerStorage.CourseBuilders.MoonlitCitadelCourse.Runtime.Start(course, eligible, recover)` and keeps its returned controller. Eligibility matches the normal service: actual active race/course/raceId, official racer and shared Racing status. The recovery wrapper records and forwards the real `RespawnService.RecoverPlayer` callback without changing its arguments or result. Results/falls and checkpoint data come from the actual shared server services.
- Controlled placement puts player -1 at the actual Lower Bay1 Deck center and player -2 at the actual GateCourt Contact center. Measured current body corners, all 15 R15 body parts plus root, level contact and .375 clearance are required. There is no predicted route traversal, forced rider displacement, altered geometry, gravity or contact tolerance.
- The server waits for a real Rising phase, one actual passenger and actual carriedSteps, then requires three recent actual support samples from each existing passive `ContactCases.ObserveClient` observer. It calls the returned `controller.Reset()` while that rising rider is still present.
- In the same synchronous call sequence, it checks accepted reset, elapsed exactly zero, two actual accepted `MoonlitRuntimeReset` callbacks with force false, both fall counts 0 to 1 and CP0 unchanged, all 11 original car/weight/lantern transforms within .0001 per component, collidable car contact velocities restored within .0001, LowDwell and zero passengers. Callback-time checkpoint targets and the real roots before/after recovery are recorded; earlier occupancy-dependent preflight targets are kept separately.
- It watches one complete actual Lower Bay1 cycle plus one second (all four phases required). Every server body sample must report the actual player as NetworkOwner. Server checks retain real Gate ray support, floor, normal >=.95, CP0/f1, active movement profile, root drift under .6, and real checkpoint target bounds. All car passengers remain zero and cumulative carryProbes/carriedSteps do not increase. Physical footing is mandatory in both actual owning-client full traces: Gate support, floor, normal >=.95, absolute foot gap <=.6, root drift <.6, sample gaps <=.6 and complete window coverage .35. No ownership, motion or tolerance is changed.
- Cleanup calls private Stop, verifies exact known baseline restoration, attempts restoration of each original Humanoid's real previous values independently even after failure, then independently restarts the normal service and requires its actual binding, both supported R15 racers and normal movement profile. Real previous values are restored **before** normal rebinding; the active normal service subsequently applies the course profile as designed.

Server evidence is `ServerStorage/MoonlitPhase2Evidence/MC_P2_C01_R04_PrivateReset_<owner>`: compact `StatusJSON`, exact full `ClientRaw_1`, `ClientRaw_2` and `ServerRaw` folders. Client original traces and watcher reports also remain in each local PlayerScripts evidence folder. Every raw folder declares JSONBytes/JSONChunks and retains full 60,000-byte StringValue chunks. Failures attempt bounded original client retrieval before cleanup; when a failed transport cannot deliver a trace, its local raw folder remains and requires a separate native client export. Missing traces remain a failure, never a pass.

`Reset()` deliberately keeps the active course movement profile; profile restoration is verified through the returned controller's real `Stop()` during cleanup. This does not expose or claim the normal service's old private stored profile. A destroyed original Humanoid cannot be restored or compared; it is an explicit failure. Recovery refusal, physical support disagreement, unexpected falls, source/API mismatch, missed rising readiness or cleanup failure are retained. Clock/mechanism counters are cumulative, so only elapsed resets; counter deltas are checked accordingly. The source/install receipt must separately bind the executed native source. This targeted Lower Bay1 test does not prove every bay, character replacement, continuous traversal, twenty racers, pacing or FPS.

The failed native privateReset01 report is preserved separately. It records accepted Reset, exact transform/velocity restoration and two real callbacks, then stops about 1.12 seconds after Reset because the server view of idle player -2 has root Y304/foot gap1 while that player's own client is at Y302.999969/foot gap−.0000305 on the actual Gate. That attempt does not prove the complete cycle. The test retains every raw server support/gap measurement and compares each post-settle server observation against the nearest owning-client sample within .35 seconds. `serverClientFootingComparisons` records both roots/gaps, measured time difference, actual network owner and whether the server gap meets the client footing bound; `serverFootingDiscrepancySamples` counts disagreements. This can prove actual owning-client footing alongside server recovery/carry state, but does not claim identical server/client root height.

The source passed the existing Lune parser (11 scoped files including this explicit module), logged in `MC_P2_C01_R04_private_reset_compile02.log`. The lead's finalB native02 run and independent raw verification passed: a 15.064555-second complete cycle, 166 retained server samples, both original owning-client traces, 252 paired comparisons, exact profile restoration and normal service rebinding. Native02 had no post-settle foot-gap tolerance disagreement; server/client heights differed only by .000030517578125. See `docs/artifacts/moonlit-citadel/phase2/evidence/extracted-private-reset02-finalB/validated01/REPORT.md` and its hash-bound receipt. The executed live source/fixture binding remains a separate installation receipt.

```powershell
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase2/Compile.luau tools/moonlit-citadel/phase2/PrivateResetCase.luau
```
