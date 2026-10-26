--!nonstrict
local Test = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- This checks actual trigger, lap and recovery behavior; setup placements do not prove a raced route.
function Test.Run(expectedCandidate)
 assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server required")
 local services = {}
 for _,name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "RespawnService"} do
  services[name] = require(game.ServerScriptService.Services[name])
 end
 local player = assert(Players:GetPlayers()[1], "One actual player required")
 assert(#Players:GetPlayers() == 1, "One-client focused test required")
 local course = assert(services.CourseService.GetActiveCourse())
 assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("CandidateId") == expectedCandidate, "Expected active candidate required")
 assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
  and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Prepare a fresh actual official race first")
 local character = assert(player.Character)
 local root = assert(character:FindFirstChild("HumanoidRootPart"))
 local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
 assert(not root.Anchored and humanoid.WalkSpeed == 16, "Ordinary walking profile required")
 local raceId = services.RaceService.GetCurrentRaceId()
 local began, movement, connection = os.clock(), Vector3.zero, nil
 local owner, ownerAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 local report = {candidate=expectedCandidate, ok=false, cases={}, placements={}, method="Actual CP contacts after declared setup placements; ordinary server-owned walking through the real finish gate; actual RespawnService recovery", limits={"No complete raced route or game-feel proof", "Client movement must be isolated by the caller during this bounded test", "No direct checkpoint, lap or result writes"}}
 local function progress()
  local result = assert(services.ResultsService.GetPlayerResult(player))
  return {lap=result.currentLap, nextCheckpoint=result.nextCheckpointIndex,
   latest=services.CheckpointService.GetLatestCheckpointIndex(player), lapTimes=table.clone(result.lapTimes or {}),
   splits=#(result.checkpointSplits or {}), status=services.PlayerRaceService.GetPlayerStatus(player)}
 end
 local function guard()
  assert(os.clock()-began < 75 and player.Character == character and humanoid.Health > 0, "Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId, "Actual course or race changed")
 end
 local function waitFor(predicate, seconds, message)
  local deadline=os.clock()+seconds
  repeat
   guard()
   if predicate() then return end
   RunService.Heartbeat:Wait()
  until os.clock() >= deadline
  assert(predicate(), message)
 end
 local function check(name, value, details)
  table.insert(report.cases, {name=name,ok=value,details=details})
  assert(value,name)
 end
 local function setup(name, ground)
  movement=Vector3.zero
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  character:PivotTo(CFrame.new(at)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{name=name,position={at.X,at.Y,at.Z}})
  waitFor(function() return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Setup did not settle")
 end
 local function gateGround(z)
  local at=course.Finish.CFrame:PointToWorldSpace(Vector3.new(0,0,z))
  return Vector3.new(at.X,course.Start.Position.Y+course.Start.Size.Y/2,at.Z)
 end
 local function walkTo(target)
  waitFor(function()
   local delta=(target-root.Position)*Vector3.new(1,0,1)
   local reached=delta.Magnitude<.4 and humanoid.FloorMaterial~=Enum.Material.Air
   movement=if reached then Vector3.zero else delta.Unit
   return reached
  end,3,"Actual gate walk did not reach endpoint")
  movement=Vector3.zero
 end
 local ok,failure=xpcall(function()
  local initial=progress()
  check("Fresh race starts at Start with lap1",initial.lap==1 and initial.nextCheckpoint==1 and initial.latest==0 and initial.splits==0 and next(initial.lapTimes)==nil,initial)
  root:SetNetworkOwner(nil)
  connection=RunService.PreSimulation:Connect(function() humanoid:Move(movement,false);humanoid.Jump=false end)
  setup("Initial incomplete forward gate",gateGround(3))
  walkTo(gateGround(-3))
  local incomplete=progress()
  check("Start crossing before ordered CPs awards no lap",incomplete.lap==1 and incomplete.latest==0 and next(incomplete.lapTimes)==nil,incomplete)
  for lap=1,3 do
   for index=1,4 do
    local pocket=course.Obstacles["CP"..index.."_Pocket"]
    setup("Lap"..lap.." actual CP"..index.." setup",pocket.Position+pocket.CFrame.UpVector*pocket.Size.Y/2)
    waitFor(function() return services.CheckpointService.GetLatestCheckpointIndex(player)==index end,2,"Actual ordered checkpoint touch not accepted")
   end
   check("Lap"..lap.." ordered contacts",progress().splits==lap*4,progress())
   waitFor(function() return (character:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow() end,3,"Actual recovery immunity did not expire")
   setup("Lap"..lap.." reverse gate",gateGround(-3))
   walkTo(gateGround(3))
   local reverse=progress()
   check("Lap"..lap.." reverse crossing rejected",reverse.lap==lap and reverse.latest==4 and reverse.lapTimes[lap]==nil,reverse)
   walkTo(gateGround(-3))
   waitFor(function() return progress().lapTimes[lap]~=nil end,2,"Forward gate did not record lap")
   local after=progress()
   if lap<3 then
    check("Lap"..lap.." advances once and resets checkpoint to Start",after.lap==lap+1 and after.nextCheckpoint==1 and after.latest==0 and after.lapTimes[lap+1]==nil,after)
    local expected=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
    check("Lap"..lap.." actual recovery accepted",services.RespawnService.RecoverPlayer(player,"R03LapStartCheck"),{expected={expected:GetComponents()}})
    waitFor(function() return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Recovery did not settle")
    local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
    local support=Workspace:Raycast(root.Position,Vector3.new(0,-9,0),ray)
    check("Lap"..lap.." recovery stands on Start",support and support.Instance==course.Start,{support=support and support.Instance:GetFullName(),position={root.Position.X,root.Position.Y,root.Position.Z},progress=progress()})
   else
    check("Third forward crossing finishes actual racer",after.status=="Finished" and #after.lapTimes==3 and after.splits==12,after)
   end
  end
  report.ok=true
 end,debug.traceback)
 if connection then connection:Disconnect() end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then
  if ownerAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end
 end
 report.seconds,report.complete,report.failure=os.clock()-began,true,if not ok then tostring(failure) else nil
 report.final=progress()
 report.inputConnectionRemoved=true
 report.networkOwnershipRestored=true
 return report
end

return Test
