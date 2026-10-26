if not game:GetService('RunService'):IsStudio() then return end
local stage=require(script.Parent.GrandArcadeService)
local originalStage=stage
local tournament=require(script.Parent.TournamentService)
local activity=require(script.Parent.LobbyActivityService)
local ready=game.ReplicatedStorage.Remotes:WaitForChild('__LobbyDisplayCheckControl')
local recordsFixture
local snapshot
local revision=2000000
local originalGate=game.Players:GetPlayers()[1]:GetAttribute('TournamentCourseReady')
ready.OnServerInvoke=function(player,action)
 local owner=game.Players:GetPlayers()[1]
 if player~=owner then return false end
 if action=='Death' then
  owner.Character.Humanoid.Health=0
  return true
 elseif action=='ControllerStart' then
  snapshot={revision=revision,tournamentId='NATIVE_CLEANUP_TEST',phase='Racing',catalog={},lineup={},raceIndex=1,results={},preparation={token='NATIVE_CLEANUP_'..revision,index=1,courseId='NO_FIXTURE_COURSE',status='Presentation',startedAt=workspace:GetServerTimeNow(),revealUntil=workspace:GetServerTimeNow()+9}}
  owner:SetAttribute('TournamentCourseReady',false)
  revision+=1
  game.ReplicatedStorage.Remotes.TournamentChanged:FireClient(owner,snapshot)
  return true
 elseif action=='ControllerFail' or action=='ControllerRestore' then
  if action=='ControllerFail' then snapshot.preparation.status='Failed'
  else snapshot=tournament.GetSnapshot(owner) end
  owner:SetAttribute('TournamentCourseReady',originalGate)
  revision+=1;snapshot.revision=revision
  game.ReplicatedStorage.Remotes.TournamentChanged:FireClient(owner,snapshot)
  return true
 elseif action=='FreshService' then
  local fresh=script.Parent.GrandArcadeService:Clone()
  fresh.Name,fresh.Parent='FreshGrandArcadeService',script
  stage=require(fresh)
  stage.Init({Services={}})
  return true
 elseif action=='AppearanceDiagnostic' then
  local step='description'
  local ok,result=pcall(function()
   local description=owner.Character.Humanoid:GetAppliedDescription()
   step='accessories'
   description.HatAccessory,description.HairAccessory,description.FaceAccessory='','',''
   description.NeckAccessory,description.ShouldersAccessory,description.FrontAccessory,description.BackAccessory,description.WaistAccessory='','','','',''
   step='create'
   local model=game.Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
   description:Destroy()
   step='strip'
   for _,item in model:GetDescendants() do
    if item:IsA('LuaSourceContainer') or item:IsA('Accessory') or item:IsA('Humanoid') or item:IsA('Motor6D') then item:Destroy()
    elseif item:IsA('BasePart') then item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false end
   end
   step='scale'
   model:ScaleTo(.55)
   local count=#model:GetDescendants()
   model:Destroy()
   return count
  end)
  return {ok=ok,step=step,result=tostring(result)}
 elseif action=='Stage' or action=='StaleAppearance' then
  local data=tournament.GetSnapshot(owner)
  local courses={}
  for _,row in data.catalog do table.insert(courses,row.id)end
  courses[5]=courses[1]
  local results={}
  for i=1,5 do
   local finishers={}
   for rank=1,3 do table.insert(finishers,{userId=if i==5 then 0 else owner.UserId,placement=rank,displayName=if rank==1 then 'LongDisplayNameForReadabilityCheck' else 'Display Test '..rank})end
   results[i]={finishers=finishers}
  end
  data.tournamentId,data.lineup,data.results,data.phase='NATIVE_DISPLAY_TEST',courses,results,'Results'
  stage.Render(data)
  if action=='StaleAppearance' then
   stage.Render(tournament.GetSnapshot(owner))
   return true
  end
  workspace.GrandArcade:SetAttribute('DisplayFixture',true)
  for i=1,5 do workspace.GrandArcade.Displays['Bay'..i].Plaque.Display.Title.Text='DISPLAY TEST '..i end
  return true
 elseif action=='Records' then
  local result={raceId='NATIVE_RECORDS_VISUAL',courseId='city_run',courseDisplayName='City Run V3',startedAt=workspace:GetServerTimeNow(),duration=90,placements={}}
  for i=1,5 do table.insert(result.placements,{userId=owner.UserId+i,displayName=if i==1 then 'LongDisplayNameForReadabilityCheck' else 'Display Test '..i,status='Finished',official=true,placement=i,finishTime=12.345+i})end
  recordsFixture=require(script.Parent.__LobbyNativeChecks.FixtureActivity)
  recordsFixture.Init({Services={ResultsService={GetCurrentRaceResult=function()return result end}}});recordsFixture.Start()
  local captured=recordsFixture.RecordCompletedRace()
  local boards=workspace.Lobby.LobbyAmenities.Records
  boards.SessionWins.Display.Heading.Text='SESSION WINS · TEST';boards.LatestRace.Display.Heading.Text='LATEST RACE · TEST'
  return captured
 elseif action=='Restore' then
  stage.Render(tournament.GetSnapshot(owner));originalStage.Render(tournament.GetSnapshot(owner));workspace.GrandArcade:SetAttribute('DisplayFixture',nil)
  activity.Start()
  local boards=workspace.Lobby.LobbyAmenities.Records
  boards.SessionWins.Display.Heading.Text='SESSION WINS';boards.LatestRace.Display.Heading.Text='LATEST RACE'
  return true
 end
 return false
end
