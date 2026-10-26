-- Local coordination fixture: fake course adapter, real server/client remotes. No real maps, results or profile writes.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local started=os.clock()
repeat task.wait(.1) until player.Character and player.Character:FindFirstChildOfClass("Humanoid") or os.clock()-started>10
local root=Instance.new("Folder");root.Name="GrandArcadeCoordinatorFixture";root.Parent=ReplicatedStorage
local receipt=Instance.new("StringValue");receipt.Name="Receipt";receipt.Parent=root
local report={kind="Native server/client coordinator fixture with a fake course adapter",checks={},failures={}}
local function check(name,value)
 table.insert(report.checks,{name=name,passed=value==true})
 if value~=true then table.insert(report.failures,name) end
end
local savedReady=player:GetAttribute("OnboardingReady")
local savedGate=player:GetAttribute("TournamentCourseReady")
player:SetAttribute("OnboardingReady",true)
local function finish()
 player:SetAttribute("OnboardingReady",savedReady);player:SetAttribute("TournamentCourseReady",savedGate)
 receipt.Value=game:GetService("HttpService"):JSONEncode(report)
end
local ok,err=pcall(function()
 local remotes=Instance.new("Folder");remotes.Name="Remotes";remotes.Parent=root
 for _,row in {{"TournamentChanged","RemoteEvent"},{"GetTournamentState","RemoteFunction"},{"SubmitMapVotes","RemoteFunction"},{"TournamentStageReady","RemoteEvent"}} do
  local remote=Instance.new(row[2]);remote.Name,remote.Parent=row[1],remotes
 end
 local module=script:WaitForChild("FixtureService")
 local service=require(module)
 local geometry=Instance.new("Folder");geometry.Name="GrandArcadeCoordinatorStartFixture";geometry.Parent=workspace
 local start=Instance.new("Part");start.Name,start.Size,start.CFrame,start.Anchored,start.CanCollide="Start",Vector3.new(1,1,1),CFrame.new(0,-100,0),true,false;start.Parent=geometry
 local eligible={};for i=1,5 do table.insert(eligible,{courseId="fixture_"..i,displayName="Fixture "..i}) end
 local activeId=""
 local loadMode="Fast"
 local commits,loads=0,0
 local renderedAt: number?=nil
 remotes.TournamentStageReady.OnServerEvent:Connect(function(_,payload)
  if payload.step=="FixtureConnected" then root:SetAttribute("ClientConnected",true)
  elseif payload.step=="Rendered" then renderedAt=os.clock() end
 end)
 local course={GetEligibleCourses=function() return eligible end,GetStartPart=function() return start end,GetActiveCourseId=function() return activeId end}
 course.LoadTournamentCourse=function(id,isCurrent)
  loads+=1
  check("render before loader "..loads,renderedAt~=nil)
  if loadMode=="Slow" then task.wait(.65) else task.wait(.03) end
  if not isCurrent() then return false end
  activeId=id;commits+=1;return true
 end
 service.Init({Services={CourseService=course,GrandArcadeService={Render=function()end,IsAvailable=function()return true end}}})
 service.Start()
 local clientDeadline=os.clock()+10
 repeat task.wait(.05) until root:GetAttribute("ClientConnected")==true or os.clock()>=clientDeadline
 check("fixture client connected",root:GetAttribute("ClientConnected")==true)
 root:SetAttribute("Mode","Ready")
 for index=1,5 do
  renderedAt=nil
  local prepared,id=service.PrepareNextCourse()
  check("ready race "..index,prepared and id~=nil)
  local snap=service.GetSnapshot(player)
  check("race index "..index,snap.raceIndex==index and #snap.lineup==5)
  check("gate ready "..index,player:GetAttribute("TournamentCourseReady")==true)
  service.BindRace("race-"..index,id)
  check("stale result "..index,not service.CaptureRace({raceId="old",courseId=id,placements={}}))
  check("capture "..index,service.CaptureRace({raceId="race-"..index,courseId=id,placements={{userId=player.UserId,name=player.Name,displayName=player.DisplayName,status="Finished",official=true,placement=1,finishTime=12},
   {userId=999,name="DNF",status="DNF",official=true,placement=2,finishTime=15}}}))
  snap=service.GetSnapshot(player)
  check("only official finisher "..index,#snap.results[index].finishers==1)
  service.AbortPreparation();check("reset clears gate "..index,player:GetAttribute("TournamentCourseReady")==nil)
  service.CompleteRace()
 end
 local completed=service.GetSnapshot(player)
 check("five distinct retained result records",completed.phase=="Complete" and #completed.results==5)
 table.remove(eligible)
 service.PrepareNextCourse()
 check("catalog drop keeps results",#service.GetSnapshot(player).results==5)
 table.insert(eligible,{courseId="fixture_5",displayName="Fixture 5"})
 service.Cancel();root:SetAttribute("Mode","NoRender")
 local prepared=service.PrepareNextCourse()
 check("no render bounded failure",not prepared and service.GetSnapshot(player).preparation.status=="Failed")
 check("failure clears gates",player:GetAttribute("TournamentCourseReady")==nil)
 root:SetAttribute("Mode","NoReady")
 prepared=service.PrepareNextCourse()
 check("no readiness bounded failure",not prepared and service.GetSnapshot(player).preparation.status=="Failed")
 root:SetAttribute("Mode","Ready");loadMode="Slow"
 local before=commits
 prepared=service.PrepareNextCourse()
 check("load deadline fails",not prepared and service.GetSnapshot(player).preparation.status=="Failed")
 task.wait(.7)
 check("timed out worker cannot commit",commits==before)
 loadMode="Fast"
 prepared=service.PrepareNextCourse()
 check("recover after timeout",prepared==true)
 service.AbortPreparation()
 root:SetAttribute("Mode","Ready");loadMode="Slow";before=commits
 task.delay(.16,service.Cancel)
 prepared=service.PrepareNextCourse()
 check("cancel returns without advancing",prepared==false)
 task.wait(.7)
 check("cancelled worker cannot commit",commits==before)
 service.Cancel()
 geometry:Destroy()
end)
if not ok then table.insert(report.failures,tostring(err)) end
finish()
