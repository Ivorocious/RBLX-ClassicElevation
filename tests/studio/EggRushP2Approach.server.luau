--!nonstrict
local RS, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId == 85558151074819)
assert(game:GetService("StudioTestService"):GetTestArgs().tag == script:GetAttribute("OwnedTestTag"))
local Course = require(game.ServerScriptService.Services.CourseService)
local Race = require(game.ServerScriptService.Services.RaceService)
local PlayerRace = require(game.ServerScriptService.Services.PlayerRaceService)
local Results = require(game.ServerScriptService.Services.ResultsService)
local Traverse = require(Storage.CourseBuilders.EggRush.NativeTraversal)
assert(not Storage:FindFirstChild("ERP2ApproachReport"))
local reportValue = Instance.new("StringValue")
reportValue.Name, reportValue.Parent = "ERP2ApproachReport", Storage
reportValue:SetAttribute("State", "Ready")
local used = false
reportValue:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 used = true
 task.spawn(function()
  reportValue:SetAttribute("State", "Running")
  local report = {cases = {}, initialPlacements = 0, checkpointWrites = 0,
   method = "Actual fitted-avatar jumps on shared live course at16/7.2; focused initial placements declared per attempt",
   limits = "One driver and centerline attempts; not exhaustive corner reachability, normal whole-course flow or multiplayer proof"}
  local player, root, human, auto, owner
  local ok, failure = xpcall(function()
   local course = assert(Course.GetActiveCourse())
   assert(course:GetAttribute("Phase") == 2 and course:GetAttribute("FullBodyContacts"))
   report.candidate = course:GetAttribute("CandidateId")
   player = assert(game.Players:GetPlayers()[1])
   local char = assert(player.Character)
   root, human = char.HumanoidRootPart, char.Humanoid
   auto, owner = root:GetNetworkOwnershipAuto(), root:GetNetworkOwner()
   local raceId = Race.GetCurrentRaceId()
   local pads, cp = course.Obstacles.S3_ShellApproach, course.Obstacles.CP2_Pocket
   local all = {{part = cp}}
   for i=1,4 do table.insert(all, {part=pads[string.format("S3_ShellApproach_%03d",i)]}) end
   table.insert(all, {part=course.Obstacles.Shell_ForkWait})
   local cases = {{name="IntendedPrefix",points=all},
    {name="CP2To002",points={{part=cp},{part=pads.S3_ShellApproach_002}}},
    {name="001To003",points={{part=pads.S3_ShellApproach_001},{part=pads.S3_ShellApproach_003}}},
    {name="001To004",points={{part=pads.S3_ShellApproach_001},{part=pads.S3_ShellApproach_004}}}}
   for _, case in cases do
    local deadline = os.clock()+6
    repeat RS.Heartbeat:Wait() until (char:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow() or os.clock()>deadline
    assert((char:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow(), "Recovery immunity did not expire")
    local before = Results.GetPlayerResult(player).falls or 0
    report.initialPlacements += 1
    local result = Traverse.Run(course,player,case.points,{placeAtStart=true,pace=false,guard=function()
     assert(Course.GetActiveCourse()==course and Race.IsRaceActive() and Race.GetCurrentRaceId()==raceId
      and PlayerRace.IsOfficialRacer(player) and player.Character==char and human.Health>0,"Focused test context changed")
     assert((Results.GetPlayerResult(player).falls or 0)==before,"Actual recovery occurred")
     return true
    end})
    table.insert(report.cases,{name=case.name,result=result,falls=(Results.GetPlayerResult(player).falls or 0)-before})
    reportValue.Value=Http:JSONEncode(report)
    if case.name=="IntendedPrefix" then assert(result.ok,"Intended approach failed: "..tostring(result.failure)) end
   end
  end,debug.traceback)
  if root and root.Parent then
   human:Move(Vector3.zero,false);human.Jump=false
   if auto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end
  end
  report.ok, report.failure = ok, if ok then nil else failure
  reportValue.Value=Http:JSONEncode(report)
  reportValue:SetAttribute("State",if ok then "Complete" else "Failed")
 end)
end)
