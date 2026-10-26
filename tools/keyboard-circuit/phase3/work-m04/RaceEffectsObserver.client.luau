--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient())
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P3_M04_01
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")
local route = assert(shared.KCP2I09RaceOptions).routeChoice
assert(route == "normal" or route == "expert")
local receipt = {candidate = candidate.Name, revision = "KC_P3_M04_01", routeChoice = route, running = true, passed = false,
 samples = {}, waves = {}, lapSweeps = 0, maxSweepContactLevel = 0, failures = {},
 boundary = "Read-only native cosmetic observation during the ordinary two-lap traversal. Real nearby key-entry diagnostics, actual pooled bar heights, USB lap-sweep state and bounded pools. One temporary 10Hz fixture observer; not FPS, audio preference, device or multiplayer proof."}
for _, family in {"Creamy","Thocky","Clacky","Clicky"} do receipt.waves[family] = {maxOwnEntries=0, minHeight=math.huge, maxHeight=0} end
shared.KCP3M04RaceEffectsObserver = receipt
local began, nextSample, accumulated, tracked = os.clock(), os.clock(), 0, nil
local connection
local function stop()
 if connection then connection:Disconnect(); connection=nil end
 receipt.running=false
 receipt.elapsedSeconds=os.clock()-began
 for family,row in receipt.waves do
  if row.minHeight==math.huge then row.minHeight=0 end
  if row.maxOwnEntries<=0 or row.maxHeight-row.minHeight<=.05 then table.insert(receipt.failures, family .. " lacks actual key-reactive bar motion") end
 end
 if receipt.lapSweeps~=2 or receipt.maxSweepContactLevel<=.6 then table.insert(receipt.failures,"Two real lap sweeps and visible contact sweep required") end
 if not tracked or not tracked.passed then table.insert(receipt.failures,"Matching complete two-lap traversal required") end
 receipt.passed=#receipt.failures==0
end
connection=RunService.Heartbeat:Connect(function(delta)
 accumulated+=delta
 if accumulated<.1 then return end
 accumulated=0
 local race=shared.KCP2I09Race
 if not tracked and race and race.active and race.routeChoice==route then tracked=race end
 if os.clock()-began>660 then table.insert(receipt.failures,"Observer timeout");stop();return end
 if not tracked then return end
 local probes=player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
 local world=workspace:FindFirstChild("KeyboardCircuitArchiveVisuals")
 if not probes or not world then table.insert(receipt.failures,"Selected effect resources disappeared");stop();return end
 local row=probes.Diagnostics:Invoke()
 if row.updateConnections~=1 or row.entryConnections~=1 or row.localPartCount>101 or row.restoreFailures~=0 then table.insert(receipt.failures,"Effects resource/ownership bound changed");stop();return end
 for family,state in row.waveStates do receipt.waves[family].maxOwnEntries=math.max(receipt.waves[family].maxOwnEntries,state.ownEntries) end
 receipt.lapSweeps=math.max(receipt.lapSweeps,row.lapSweeps)
 for _,part in world:GetChildren() do
  if not part:IsA("BasePart") then continue end
  if part:GetAttribute("ArchiveEffectKind")=="WaveBar" then
   local family=part:GetAttribute("ArchiveEffectFamily")
   local sample=receipt.waves[family]
   if sample then sample.minHeight=math.min(sample.minHeight,part.Size.Y);sample.maxHeight=math.max(sample.maxHeight,part.Size.Y) end
  elseif part:GetAttribute("ArchiveEffectKind")=="USBContact" and row.lapSweeps>0 and part.LocalTransparencyModifier==0 then
   receipt.maxSweepContactLevel=math.max(receipt.maxSweepContactLevel,1-part.Transparency)
  end
 end
 if os.clock()>=nextSample or not tracked.active then
  nextSample=os.clock()+5
  table.insert(receipt.samples,{elapsed=os.clock()-began,completedLaps=row.completedLaps,lapSweeps=row.lapSweeps,localEntries=row.localEntries,
   tracePulses=row.tracePulses,localPartCount=row.localPartCount,waveBarCount=row.waveBarCount,underlightCount=row.underlightCount,
   readiness=row.readiness,skyApplied=row.skyApplied,waveStates=row.waveStates})
 end
 receipt.finalDiagnostics=row
 if not tracked.active and row.lapSweeps==2 then stop() end
end)
return game.HttpService:JSONEncode({started=true,routeChoice=route,receipt="shared.KCP3M04RaceEffectsObserver"})
