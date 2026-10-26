--!nonstrict
local RS, S, H = game:GetService("RunService"), game.ServerStorage, game.HttpService
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId == 85558151074819)
local Race = require(game.ServerScriptService.Services.RaceService)
local Course = require(game.ServerScriptService.Services.CourseService)
local Players = require(game.ServerScriptService.Services.PlayerRaceService)
local expected = assert(script:GetAttribute("ExpectedCandidate"))
assert(not game.ReplicatedStorage:FindFirstChild("ERP2CloseoutControl"))
local control = Instance.new("StringValue")
control.Name, control.Parent = "ERP2CloseoutControl", game.ReplicatedStorage
local receipt = Instance.new("StringValue")
receipt.Name, receipt.Parent = "ERP2CloseoutReport", S
local out = {candidateId=expected, oneStudio=true, oneClient=true, stages={},
 method="Natural arrival/Join/vote/delivery/countdown, continuous races and supported Break/retry. StartEvent only releases the Studio authoring-preview hold.",
 avatarPlacements=0, checkpointWrites=0, profilePresets=0, clockWrites=0}
local function publish() receipt.Value=H:JSONEncode(out) end
local function waitFor(predicate, seconds, message)
 local deadline=os.clock()+seconds
 repeat RS.Heartbeat:Wait() until predicate() or os.clock()>=deadline
 assert(predicate(),message)
end
receipt:SetAttribute("State","Running")
control:SetAttribute("Phase","Preparing")
local ok, failure=xpcall(function()
 assert(#game.Players:GetPlayers()==1 and not Course.IsInspectionMode() and not Race.IsInspectionUnlimitedTime())
 waitFor(function() return S:FindFirstChild("EggRushP2FlowReport")~=nil end,10,"Flow observer did not initialize")
 assert(Race.ApplyStudioAction("StartEvent"),"Could not release authoring-preview hold")
 local observer=assert(S:FindFirstChild("EggRushP2FlowReport"))
 observer:SetAttribute("Command",H:JSONEncode({action="Observe"}))
 control:SetAttribute("Phase","ArrivalAndEntry")
 local previous
 for _,line in {"Normal","Expert"} do
  waitFor(function()
   local player=game.Players:GetPlayers()[1]
   local course=Course.GetActiveCourse()
   return player and Race.IsRaceActive() and Players.IsOfficialRacer(player) and Players.GetPlayerStatus(player)=="Racing"
    and Race.GetCurrentRaceId()~=previous and course and course:GetAttribute("CandidateId")==expected
  end,150,"Natural admission failed before "..line)
  previous=Race.GetCurrentRaceId()
  local runner=assert(S:FindFirstChild("ERP2Closeout"..line.."Report"))
  assert(runner:GetAttribute("State")=="Ready","Continuous runner was already used")
  local row={line=line,raceId=previous,started=workspace:GetServerTimeNow()}
  table.insert(out.stages,row)
  control:SetAttribute("Phase",line.."Running")
  task.wait(.5)
  runner:SetAttribute("Command",H:JSONEncode({action="Run",line=line}))
  publish()
  waitFor(function() return table.find({"Complete","Failed"},runner:GetAttribute("State"))~=nil end,460,"Continuous runner exceeded its bound")
  row.state,row.finished=runner:GetAttribute("State"),workspace:GetServerTimeNow()
  row.manifest=H:JSONDecode(runner.Value)
  publish()
  assert(row.state=="Complete","Continuous "..line.." failed; preserve its report")
  if line=="Normal" then control:SetAttribute("Phase","FinishAndRetry") end
 end
 control:SetAttribute("Phase","BreakAfterFinish")
 local player=game.Players:GetPlayers()[1]
 waitFor(function() return Players.GetPlayerStatus(player)=="Lobby" and not Players.IsEnrolled(player) end,30,"Supported final Break did not settle")
 assert(observer:GetAttribute("State")=="Complete","Ordinary flow/finish/retry observer did not complete")
 out.complete=true
end,debug.traceback)
out.ok,out.failure=ok,if ok then nil else failure
publish()
receipt:SetAttribute("State",if ok then "Complete" else "Failed")
control:SetAttribute("Phase",if ok then "Complete" else "Failed")
