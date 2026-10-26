if not game:GetService('RunService'):IsStudio() then return end
local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local folder=Instance.new('Folder')
folder.Name,folder.Parent='PrivateRemotes',script
local remote=Instance.new('RemoteEvent')
remote.Name,remote.Parent='RaceResultsUpdated',folder
local receipt=Instance.new('StringValue')
receipt.Name,receipt.Parent='Receipt',script
local report={kind='Studio native service and geometry checks; result data uses a private ResultsService fixture',checks={},failures={},walk=nil}
local function check(name,ok)table.insert(report.checks,{name=name,passed=ok==true});if not ok then table.insert(report.failures,name)end end
local function write()receipt.Value=Http:JSONEncode(report)end
write()
local ok,err=xpcall(function()
 local owner=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
 local started=os.clock()
 repeat task.wait(.2)until owner.Character and owner.Character:FindFirstChildOfClass('Humanoid') or os.clock()-started>20
 task.wait(2)
 local controls=Instance.new('RemoteFunction')
 controls.Name,controls.Parent='__LobbyNativeCheckControl',game.ReplicatedStorage.Remotes
 local originalGate=owner:GetAttribute('TournamentCourseReady')
 local revision=1000000
 local snapshot
 controls.OnServerInvoke=function(player,action)
  if player~=owner then return false end
  if action=='PendingCourse' then owner:SetAttribute('TournamentCourseReady',false);return true end
  if action=='Restore' then owner:SetAttribute('TournamentCourseReady',originalGate);return true end
  if action=='Presentation' then
   snapshot={revision=revision,tournamentId='NATIVE_CONTROLLER_TEST',phase='Racing',catalog={},lineup={},raceIndex=1,results={},preparation={token='NATIVE_CONTROLLER_TEST',index=1,courseId='NO_FIXTURE_COURSE',status='Presentation',startedAt=workspace:GetServerTimeNow(),revealUntil=workspace:GetServerTimeNow()+9}}
   owner:SetAttribute('TournamentCourseReady',false)
  elseif action=='ReadyReplay' and snapshot then
   snapshot.preparation.status='Ready';owner:SetAttribute('TournamentCourseReady',true)
  elseif action=='Fail' and snapshot then
   snapshot.preparation.status='Failed';owner:SetAttribute('TournamentCourseReady',originalGate)
  elseif action=='ResetSnapshot' then
   snapshot=require(script.Parent.TournamentService).GetSnapshot(owner)
   owner:SetAttribute('TournamentCourseReady',originalGate)
  else return false end
  revision+=1;snapshot.revision=revision
  game.ReplicatedStorage.Remotes.TournamentChanged:FireClient(owner,snapshot)
  return true
 end
 local course=require(script.Parent.CourseService)
 local catalog=course.GetEligibleCourses()
 report.catalog={}
 for _,row in catalog do table.insert(report.catalog,{id=row.courseId,name=row.displayName})end
 check('Actual catalog has four eligible courses',#catalog==4)
 local stage=workspace.GrandArcade
 check('Idle stage reflects actual catalog',stage:GetAttribute('EligibleCourseCount')==#catalog and stage:GetAttribute('ResolvedLineup')==false)
 local labels={}
 for i=1,5 do labels[i]=stage.Displays['Bay'..i].Plaque.Display.Title.Text end
 report.idleLabels=labels
 check('Idle has no fabricated race order',not table.concat(labels,' '):find('RACE 5',1,true))
 local results=require(script.FixtureResults)
 results.Init({})
 local activity=require(script.FixtureActivity)
 activity.Init({Services={ResultsService=results}})
 activity.Start()
 local boards=workspace.Lobby.LobbyAmenities.Records
 boards.SessionWins.Display.Heading.Text='SESSION WINS · TEST'
 boards.LatestRace.Display.Heading.Text='LATEST RACE · TEST'
 check('Session qualifier is honest',boards.SessionWins.Display.Subtitle.Text=='This server')
 check('Empty boards are explicit',boards.SessionWins.Display.Empty.Visible and boards.LatestRace.Display.Empty.Visible)
 local resultStart=workspace:GetServerTimeNow()
 results.StartRace('native-record-1','city_run','PointToPoint',resultStart,'City Run V3',1,1)
 results.RegisterActiveRacers({owner})
 results.RecordFinish(owner,12.345)
 results.SetRaceDuration(20)
 check('Completed result captured once',activity.RecordCompletedRace())
 check('Duplicate completed result rejected',not activity.RecordCompletedRace())
 local wins=boards.SessionWins.Display
 local latest=boards.LatestRace.Display
 check('Only actual official winner gains one session win',wins.Row1.Visible and wins.Row1.Racer.Text==owner.DisplayName and wins.Row1.Value.Text=='1' and not wins.Row2.Visible)
 check('Latest uses real course and rounded finish',latest.Subtitle.Text=='City Run V3' and latest.Row1.Visible and latest.Row1.Value.Text=='00:12.35' and not latest.Row2.Visible)
 report.populatedRecords={winner=wins.Row1.Racer.Text,wins=wins.Row1.Value.Text,course=latest.Subtitle.Text,time=latest.Row1.Value.Text}
 results.StartRace('native-record-2','shipwreck_cove','Circuit',resultStart+1,'Shipwreck Cove',3,1)
 results.SetRaceDuration(30)
 check('A completed race with no finishes captured',activity.RecordCompletedRace())
 check('Empty latest keeps course without made-up winner',latest.Subtitle.Text=='Shipwreck Cove' and latest.Empty.Visible and not latest.Row1.Visible and wins.Row1.Value.Text=='1')
 require(script.Parent.LobbyActivityService).Start()
 boards.SessionWins.Display.Heading.Text='SESSION WINS'
 boards.LatestRace.Display.Heading.Text='LATEST RACE'
 check('Real boards restored after fixture',latest.Empty.Visible and wins.Empty.Visible)
 report.gold=owner:GetAttribute('Gold')
 if workspace.Lobby:FindFirstChild('GrandArcadeConnection')then
  local walkingDeadline=os.clock()+60
  repeat task.wait(.1)until owner:GetAttribute('OnboardingReady')==true and owner:GetAttribute('ArrivalOpen')~=true and owner.Character and owner.Character:FindFirstChildOfClass('Humanoid') and owner.Character:FindFirstChildOfClass('Humanoid').WalkSpeed>0 or os.clock()>walkingDeadline
  assert(owner:GetAttribute('OnboardingReady')==true and owner:GetAttribute('ArrivalOpen')~=true,'Wait for ordinary movement settings before walking')
  report.walk=require(script.Walk).Run();for _,route in report.walk.routes do check('Round trip X '..route.x,route.passed and route.jumpDisabled and route.health>0)end;check('Three native round trips',#report.walk.routes==3)
 end
end,debug.traceback)
if not ok then table.insert(report.failures,tostring(err))end
report.complete=true
write()
