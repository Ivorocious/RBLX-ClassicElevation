--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local View=require(script.Parent.GalleryVotingView)
local Presentation=require(script.Parent.TournamentPresentation)
local Flow=require(script.Parent.RaceFlowController)
local Kit=require(script.Parent.UiKit)
local RacePresentation=require(script.Parent.RacePresentation)
local Controller={}
function Controller.Init()
 local player=Players.LocalPlayer
 local folder=game.ReplicatedStorage:WaitForChild("Remotes")
 local changed=folder:WaitForChild("TournamentChanged") :: RemoteEvent
 local getState=folder:WaitForChild("GetTournamentState") :: RemoteFunction
 local submit=folder:WaitForChild("SubmitMapVotes") :: RemoteFunction
 local ready=folder:WaitForChild("TournamentStageReady") :: RemoteEvent
 local gui=Instance.new("ScreenGui")
 gui.Name,gui.ResetOnSpawn,gui.DisplayOrder,gui.Enabled="TournamentVoting",false,30,false
 gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.Parent=player:WaitForChild("PlayerGui")
 local canvas=Instance.new("CanvasGroup")
 canvas.Name,canvas.Size,canvas.BackgroundTransparency,canvas.Parent="Fade",UDim2.fromScale(1,1),1,gui
 local state: any=nil
 local revision=-1
 local picks,search={},""
 local pending,confirmed,dirty,hidden=false,false,false,false
 local message=""
 local requestVersion=0
 local ui: any
 local function render()
  if not state then return end
  gui.Enabled=state.phase=="Voting" and not hidden and player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalOpen")~=true
  if player:GetAttribute("VoteOpen")~=gui.Enabled then player:SetAttribute("VoteOpen",gui.Enabled) end
  if not gui.Enabled then return end
  View.Render(ui,{catalog=state.catalog,picks=picks,search=search,
   timeLeft=math.max(0,(state.deadline or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()),
   duration=state.duration,phase=state.phase,pending=pending,confirmed=confirmed,message=message})
 end
 ui=View.Create(canvas,{
  Search=function(value) search=value;render() end,
  Hide=function() hidden=true;render() end,
  Select=function(id)
   if pending then return end
   local index=table.find(picks,id)
   if index then table.remove(picks,index) else picks={id} end
   dirty,confirmed=true,false;render()
  end,
  Remove=function(id)
   if pending then return end
   local index=table.find(picks,id);if index then table.remove(picks,index) end
   dirty,confirmed=true,false;render()
  end,
  Confirm=function()
   if not state or pending or state.phase~="Voting" or #picks~=1 then return end
   pending=true;requestVersion+=1
   local version,id,selection=requestVersion,state.tournamentId,table.clone(picks)
   render()
   task.delay(6,function()
    if pending and requestVersion==version then pending=false;requestVersion+=1;message="Couldn't confirm. Try again.";render() end
   end)
   task.spawn(function()
    local ok,reply=pcall(function() return submit:InvokeServer({tournamentId=id,requestId=version,picks=selection}) end)
    if requestVersion~=version or not state or state.tournamentId~=id or state.phase~="Voting" then return end
    pending=false
    confirmed=ok and typeof(reply)=="table" and reply.ok==true
    if confirmed then dirty=false;message="" else message=if ok and typeof(reply)=="table" then reply.message or "Couldn't confirm." else "Couldn't confirm. Try again." end
    render()
   end)
  end,
 })
 local function accept(payload)
  if typeof(payload)~="table" or typeof(payload.revision)~="number" or payload.revision<revision then return end
  local previous=state
  revision=payload.revision
  for _,row in payload.catalog or {} do row.name=RacePresentation.CourseName(row.name) end
  payload.courseDisplayName=RacePresentation.CourseName(payload.courseDisplayName)
  state=payload
  if not previous or previous.tournamentId~=state.tournamentId then
   picks,search,hidden,dirty,confirmed={},"",false,false,false
   requestVersion+=1;pending=false
  end
  if state.phase=="Voting" then
   canvas.GroupTransparency=0
   if not dirty and not pending then picks=table.clone(state.picks or {}) end
   render()
  else
   if gui.Enabled then
    TweenService:Create(canvas,TweenInfo.new(.25),{GroupTransparency=1}):Play()
    task.delay(.25,function() if state and state.phase~="Voting" then gui.Enabled=false end end)
   else gui.Enabled=false end
   requestVersion+=1;pending=false
  end
  Flow.HandleTournament(payload)
 end
 -- The vote closing outside render (phase change, Hide) must also give the lobby back.
 gui:GetPropertyChangedSignal("Enabled"):Connect(function() player:SetAttribute("VoteOpen",gui.Enabled) end)
 changed.OnClientEvent:Connect(accept)
 player.CharacterAdded:Connect(function(character)
  task.spawn(function()
   local humanoid=character:WaitForChild("Humanoid",5)
   if humanoid and state and state.preparation and state.phase=="Racing" then accept(state) end
  end)
 end)
 for _,name in {"OnboardingReady","ArrivalOpen","TournamentCourseReady"} do
  player:GetAttributeChangedSignal(name):Connect(function()
   render()
   if state and state.phase=="Racing" then accept(state) end
  end)
 end
 local elapsed=0
 RunService.Heartbeat:Connect(function(dt) elapsed+=dt;if elapsed>.2 then elapsed=0;render() end end)
 task.spawn(function()
  for _=1,3 do
   local ok,payload=pcall(function() return getState:InvokeServer() end)
   if ok and typeof(payload)=="table" then accept(payload);return end
   task.wait(1)
  end
 end)
 -- Hide remains reversible without submitting or changing the server ballot.
 local launcher=Instance.new("ScreenGui")
 launcher.Name,launcher.ResetOnSpawn,launcher.DisplayOrder,launcher.ZIndexBehavior="MapVoteLauncher",false,31,Enum.ZIndexBehavior.Sibling
 launcher.Parent=player.PlayerGui
 local reopen=Kit.SkyButton(launcher,"ReopenMapVote","Map vote",UDim2.fromOffset(170,54),UDim2.new(.5,-85,1,-72),function() hidden=false;render() end,"Primary",20)
 RunService.Heartbeat:Connect(function()
  reopen.Visible=state~=nil and state.phase=="Voting" and hidden and player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalOpen")~=true
 end)
end
return Controller
