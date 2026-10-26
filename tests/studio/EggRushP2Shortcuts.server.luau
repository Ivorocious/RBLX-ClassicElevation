--!nonstrict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819)
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = "ERP2ShortcutReport", Storage
stored:SetAttribute("State", "Ready")
local Course = require(game.ServerScriptService.Services.CourseService)
local Race = require(game.ServerScriptService.Services.RaceService)
local PlayerRace = require(game.ServerScriptService.Services.PlayerRaceService)
local Results = require(game.ServerScriptService.Services.ResultsService)
local Traversal = require(Storage.CourseBuilders.EggRush.NativeTraversal)
local used = false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local command = Http:JSONDecode(stored:GetAttribute("Command"))
 if command.action ~= "ShellApproach" then return end
 used = true
 task.spawn(function()
  stored:SetAttribute("State", "Running")
  local report = {phase = 2, test = "Tempting Shellworks approach skips", cases = {}, checkpointWrites = 0,
   method = "Actual avatar jumps with listed initial placements, unchanged contact/movement and live shared runtime",
   limits = "Focused reachability attempts, not a full lap, supported normal entry, exhaustive shortcuts or multiplayer proof"}
  local player, root, humanoid, originalOwner, originalAuto
  local ok, failure = xpcall(function()
   local course = assert(Course.GetActiveCourse())
   assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned"))
   report.candidateId, report.pacingRevision = course:GetAttribute("CandidateId"), course:GetAttribute("PacingRevision")
   player = assert(game.Players:GetPlayers()[1])
   local character = assert(player.Character)
   root, humanoid = character.HumanoidRootPart, character:FindFirstChildOfClass("Humanoid")
   originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
   local raceId = Race.GetCurrentRaceId()
   local immunityDeadline = os.clock() + 4
   while (character:GetAttribute("RecoveryUntil") or 0) > workspace:GetServerTimeNow() do
    assert(os.clock() < immunityDeadline, "Recovery immunity did not expire")
    RunService.Heartbeat:Wait()
   end
   local approach = course.Obstacles.S3_ShellApproach
   for _, target in {approach.S3_ShellApproach_003, approach.S3_ShellApproach_004} do
    local from = approach.S3_ShellApproach_001
    local before = Results.GetPlayerResult(player).falls or 0
    local result = Traversal.Run(course, player, {{part = from}, {part = target}}, {placeAtStart = true, pace = false,
     guard = function()
      assert(player.Character == character and humanoid.Health > 0 and Course.GetActiveCourse() == course
       and Race.IsRaceActive() and Race.GetCurrentRaceId() == raceId and PlayerRace.IsOfficialRacer(player), "Focused context changed")
      assert((Results.GetPlayerResult(player).falls or 0) == before, "Actual recovery occurred")
      return true
     end})
    table.insert(report.cases, {from = from:GetFullName(), to = target:GetFullName(), initialPlacement = true,
     bypassedRedHop = result.ok, actualFalls = (Results.GetPlayerResult(player).falls or 0) - before, result = result})
    if (Results.GetPlayerResult(player).falls or 0) > before then break end
   end
  end, debug.traceback)
  if root and root.Parent then
   humanoid:Move(Vector3.zero, false); humanoid.Jump = false
   if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
  end
  report.ok, report.failure = ok, if ok then nil else failure
  stored.Value = Http:JSONEncode(report)
  stored:SetAttribute("State", if ok then "Complete" else "Failed")
 end)
end)
