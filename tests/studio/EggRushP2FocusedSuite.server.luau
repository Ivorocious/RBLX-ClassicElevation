--!nonstrict
local RS, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId==85558151074819)
local tag="EggRush_P2_C03_Focused"
assert(game:GetService("StudioTestService"):GetTestArgs().tag==tag)
local templates=assert(Storage:FindFirstChild("ERP2FocusedTemplates"))
local report=Instance.new("StringValue")
report.Name,report.Parent="ERP2FocusedSuiteReport",Storage
report:SetAttribute("State","Running")
local out={tag=tag,stages={},limits="Bounded focused initial placements and explicit Studio inspection preparation; not normal entry, whole-race pacing or20-player proof"}
local function persist()report.Value=Http:JSONEncode(out)end
local function waitFor(predicate,seconds,message)
 local deadline=os.clock()+seconds
 repeat task.wait(.1) until predicate()or os.clock()>deadline
 assert(predicate(),message)
end
local ok,failure=xpcall(function()
 local C=require(game.ServerScriptService.Services.CourseService)
 local R=require(game.ServerScriptService.Services.RaceService)
 local O=require(game.ServerScriptService.Services.OnboardingService)
 local P=require(game.ServerScriptService.Services.PlayerRaceService)
 local E=require(game.ServerScriptService.Services.EggRushService)
 waitFor(function()return #game.Players:GetPlayers()==2 end,25,"Two actual players did not join")
 for _,player in game.Players:GetPlayers()do
  if player:GetAttribute("OnboardingReady")~=true then
   local success,message=O.SetStudioPreset(player,"Returning racer")
   assert(success,message)
  end
 end
 waitFor(function()for _,p in game.Players:GetPlayers()do if p:GetAttribute("OnboardingReady")~=true then return false end end;return true end,30,"Focused Studio preset did not arrive")
 assert(C.SelectCourseForStudio("egg_rush_circuit"))
 R.SetInspectionUnlimitedTime(true)
 assert(R.ApplyStudioAction("RestartRace"))
 waitFor(function()
  if not R.IsRaceActive()or not E.GetDiagnostics().bound then return false end
  for _,p in game.Players:GetPlayers()do if not P.IsOfficialRacer(p)then return false end end
  return true
 end,35,"Official focused race did not start")
 assert(C.GetActiveCourse():GetAttribute("CandidateId")=="ER_P2_R01_C03")
 workspace:SetAttribute("ERP2OwnedTestTag",tag)
 out.fixture={raceId=R.GetCurrentRaceId(),unlimitedRaceDuration=R.IsInspectionUnlimitedTime(),sharedMechanismClockUntouched=true,
  note="Unlimited race deadline prevents authoring pauses from ending independent bounded cases; it does not change or validate target race times"}
 local cases={
  {template="Hazards",name="ERP2Hazards",result="EggRushP2HazardWaitsReport",command={stage="All"},seconds=190,userId=-1},
  {template="Branches",name="ERP2Branches",result="EggRushP2BranchesReport",command={action="Run"},seconds=250},
  {template="Traffic",name="ERP2ShellClose",result="ERP2ShellCloseReport",command={stage="ShellClose"},seconds=90},
  {template="Traffic",name="ERP2ShellLate",result="ERP2ShellLateReport",command={stage="ShellLate"},seconds=90},
  {template="Traffic",name="ERP2TraySplit",result="ERP2TraySplitReport",command={stage="TraySplit"},seconds=90},
  {template="Traffic",name="ERP2TrayLate",result="ERP2TrayLateReport",command={stage="TrayLate"},seconds=90},
 }
 for _,case in cases do
  local actor=templates[case.template]:Clone()
  actor.Name=case.name
  actor:SetAttribute("OwnedStudioTestTag",tag)
  actor:SetAttribute("OwnedTestTag",tag)
  actor:SetAttribute("ExpectedCandidate","ER_P2_R01_C03")
  actor:SetAttribute("ReportName",case.result)
  if case.userId then actor:SetAttribute("UserId",case.userId)end
  actor.Disabled=false
  actor.Parent=game.ServerScriptService
  waitFor(function()return Storage:FindFirstChild(case.result)~=nil end,8,"Focused report did not initialize: "..case.name)
  local result=Storage[case.result]
  waitFor(function()return result:GetAttribute("State")=="Ready"end,8,"Focused test did not become ready: "..case.name)
  local stage={name=case.name,report=case.result,started=workspace:GetServerTimeNow()}
  table.insert(out.stages,stage);persist()
  result:SetAttribute("Command",Http:JSONEncode(case.command))
  waitFor(function()local state=result:GetAttribute("State");return state=="Complete"or state=="Failed"end,case.seconds,"Controller did not stop; do not start another actor")
  stage.state,stage.finished=result:GetAttribute("State"),workspace:GetServerTimeNow();persist()
  task.wait(1)
 end
end,debug.traceback)
out.ok,out.failure=ok,if ok then nil else failure
persist();report:SetAttribute("State",if ok then "Complete"else"Failed")
