# R04 native boundary cases

This is a new test-only ModuleScript. Lune parsing passed; native behavior is pending the lead's installation and test. This helper used no live Studio or Blender control and changed no production source. Run only after the native contact driver and all route/contact observers are terminal.

Install this exact file as `ServerStorage.MoonlitPhase2Tools.BoundaryCases` and an identical copy at `ReplicatedStorage.MoonlitPhase2Tools.BoundaryCases`. The server uses existing `TrialControl`, `ContactCases` and actual shared services. It requires unpublished Studio Play place/universe zero, R04 active `Workspace.RaceCourse`, exactly the original actual Players -1/-2, authoritative `OnboardingReady=true` and `ArrivalPhase="Ready"`, and no active contact case or driver transport. Keep ServerProbe running: all progress/falls/finish readings come from its fresh shared-services bridge and the real server services. The client independently checks local `ArrivalOpen=false` and both authoritative ready attributes, and requires ClientProbe/ClientSuite/ContactCases to be inactive. No client evidence can credit authoritative progress. No new RemoteEvent is created.

Start the native client watcher on each actual local client before the server suite. PlayerScripts exists only locally. Run the following in each client's native evaluation and return a small status rather than the function handle:

```lua
local cases = require(game.ReplicatedStorage.MoonlitPhase2Tools.BoundaryCases)
cases.ClientWatch({authorizedNativeMovement=true, durationSeconds=1100})
return {state=cases.ClientCurrent().state, path=cases.ClientCurrent().evidencePath}
```

Then, on the actual server:

```lua
local tools = game.ServerStorage.MoonlitPhase2Tools
local cases = require(tools.BoundaryCases)
cases.Start(require(tools.TrialControl).Services(), {authorizedControlledNative=true})
return cases.Status()
```

The default is the six Normal waits `NormalWaitBefore1/2/3`, `NormalWaitAfter1/2/3`, and three central `ExpertBefore1/2/3` islands. Each tests the center plus four usable edges computed from every actual R15 body corner, with the existing 0.375-stud body margin. Every position runs for at least two actual longest lantern periods (R04: 6 seconds each), checks runtime elapsed coverage and observed angles below -30/above +30 degrees for every lantern, keeps actual support/foot-gap/normal/body-footprint checks, and requires no body/cage overlap, fall or checkpoint credit. Raw observations include all actual visible CageAndCore parts and actual enabled PointLight distance/range exposures; light exposure is recorded, not assumed or required at every safe wait. This is a dynamic safety test for the actual avatar, not a duplicate static twenty-body occupancy test or a full swept-volume mathematical proof.

Use `names={...}` for a bounded nonduplicate targeted subset of up to 20 names. `Preview()` returns the valid names. Default waits contain about nine minutes of measurements plus settling and actual shared-start time. Optional `ExpertAfter1/2/3` tests the other three island contacts separately. Other targeted cases are:

| Name | Required native observation |
| --- | --- |
| `RedAdjacent` | Explicit measured actual red/stand plan; 3 seconds clear visible body overlap, actual support, CP0/f0, measured positive body-box separation no more than 2 studs. |
| `JumpDeparture` | Actual Lower Bay1 sole rider on a rising deck; native client sets Humanoid.Jump once; actual Jumping/Freefall + Air + no deck ray support for at least two samples; passenger zero and unchanged carriedSteps across consecutive airborne samples. No root movement is forced during measurement. |
| `CP04Bypass` | Controlled CP0 body placement at actual CP04; real engine Touched and actual body overlap must occur; real shared logic must retain CP0/f0 and reject credit. |
| `CrownBypass` | Controlled actual crown contact placement before Finish; native client walks in the actual Finish.LookVector direction for at most 1.25 seconds; the same primary ForwardGate.Crossed function witnesses a continuous native crossing while shared CP0/f0/unfinished remain unchanged. |
| `StopStart` | Fresh restored profile baseline captured from the same surviving Humanoid; actual sole rider/rising mechanism; public MoonlitCitadelService.Stop restores the baseline and stops the actual deck; actual Start rebinds, with the body parked on actual GateCourt and no stale passenger. |
| `Restart` | Direct actual TrialControl.Restart/RestartRace while a rider is on a rising car; samples observe surviving original profile restoration during shared unload; fresh real race/course, staged CP0/f0, old deck gone and no stale passenger. |
| `MapExit` | Actual shared HoldLobby while mechanisms/rider are active; original surviving profile restored, real Lobby status, old course/deck gone and runtime unbound. |
| `CharacterReplacement` | Actual Humanoid.Health=0/Died, native automatic new Player.Character, shared real CP0/f1 recovery at its actual checkpoint respawn target, new configured movement profile and no old deck support/passenger. Original Humanoid profile comparison is recorded while readable; an unobserved restoration fails the case and remains explicitly unproven. |

Example targeted server options:

```lua
{authorizedControlledNative=true, names={"JumpDeparture","CP04Bypass","CrownBypass","StopStart","Restart","CharacterReplacement","MapExit"}}
```

RedAdjacent needs separately measured native paths, supplied as Luau rather than a guessed world position:

```lua
{authorizedControlledNative=true, names={"RedAdjacent"}, redAdjacent={
    measuredSafeStand=true, redPath=verifiedRelativeRedPath,
    standPath=verifiedRelativeStandingContactPath,
    standOffset=measuredLocalHorizontalOffset
}}
```

The three variables above are required operator measurements, not supplied defaults. The server validates all actual instances, dimensions, avatar bounds and physical evidence. It does not find a different stand or turn a missing witness into success. For example RouteBuilder authors the visible opening red block at `Obstacles/ArchResets/OpeningGapReset/NeonRedContact`; the lead must still verify a safe adjacent actual standing contact/offset. An operator's measuredSafeStand flag alone proves nothing.

Each case starts through the real shared restart with both native racers staged Racing CP0/f0. Placement/death/Stop/Start/Restart/HoldLobby are explicitly controlled diagnostic actions. They are not continuous traversal, ordinary arrival, twenty-client, human pacing, device or FPS proof. CP04/crown cases test shared checkpoint/finish rejection at the destination; geometric route inaccessibility still requires the route/bypass review. `Runtime.controller.Reset()` is private and not exposed by MoonlitCitadelService, so this tool does not call it or label public shared RestartRace as a private controller reset. That exact requirement remains open unless the lead supplies an already supported public caller. Historical pre-session movement profiles are private; restoration checks use the observed restored surviving profile followed by a fresh legitimate service binding.

`Current()` keeps the full report in memory; `Status()` returns compact state/path/error. Server evidence is retained under `ServerStorage.MoonlitPhase2Evidence/MC_P2_C01_R04_Boundary_<guid>/Case_<index>_<name>` plus `Failure_<index>_<name>` and `SuiteRaw`. Each folder has JSONBytes/JSONChunks and complete 60,000-byte `JSON_001` onward chunks. Wait reports keep all five position traces. ClientWatch keeps its full actual state/action trace in a uniquely marked local PlayerScripts folder and writes complete chunks when stopped/timed out; retrieve that separately and bind its owner/action race/case records to the server report. It is not silently merged into server proof. There is no trace truncation/downsampling.

One failure stops the suite and retains the original case failure. Fresh races have a 35-second deadline, active-deck waits 16 seconds, replacement 20 seconds, and the total suite 1,200 seconds. Only driver-owned action attributes/connections and BoundaryActive markers are cleared. No unrelated object is deleted and no race-end action runs on cleanup. `MapExit` deliberately leaves the real shared lobby; other failures leave the actual last test state, including a stopped mechanism if that failed. The lead uses existing public shared recovery actions as needed. `Stop()` requests a bounded server stop; call `ClientStop()` separately on each actual client to retain and stop its local watcher. Start a fresh client watcher for each suite owner.

Parse command:

```powershell
.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase2/Compile.luau tools/moonlit-citadel/phase2/BoundaryCases.luau
```

Final Lune parse passed (11 files including the new module and existing default fixture scope). BoundaryCases.luau SHA-256 `becb412e2dd7e614f49927b6fa02efd234566a93f7af1d4db7c66408d433221c`. The server/client arrival distinction and final-position assert varargs were audited; actual Players and selected case entries are bound before array/insertion use. Native case outcomes remain pending.
