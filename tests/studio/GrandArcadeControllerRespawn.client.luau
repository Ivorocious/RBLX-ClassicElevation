if not game:GetService("RunService"):IsStudio() or game.PlaceId ~= 85558151074819 then return end
local player = game.Players.LocalPlayer
local Http = game:GetService("HttpService")
local receipt = Instance.new("StringValue")
receipt.Name, receipt.Parent = "Receipt", script
local report = {kind="Fresh production TournamentController in native solo Play; labelled synthetic preparation, actual authoritative death and respawn",checks={},failures={},phase="Starting"}
local function write() receipt.Value = Http:JSONEncode(report) end
local function check(name, passed, detail)
 table.insert(report.checks,{name=name,passed=passed==true,detail=detail})
 if not passed then table.insert(report.failures,name) end
 write()
end
local function waitFor(predicate, seconds)
 local deadline=os.clock()+seconds
 repeat task.wait(.05) until predicate() or os.clock()>deadline
 return predicate()
end
write()
local control = game.ReplicatedStorage.Remotes:WaitForChild("__LobbyFullControllerControl",20)
local ok, err = xpcall(function()
 local remotes=game.ReplicatedStorage.Remotes
 if player:GetAttribute("OnboardingReady")~=true or player:GetAttribute("ArrivalOpen")==true then
  task.wait(4)
  local reply=remotes:WaitForChild("StudioDevControl"):InvokeServer({action="OnboardingPreset",preset="Returning avatar"})
  check("Temporary returning preset accepted",reply.ok==true,reply.message)
  assert(reply.ok==true,"Temporary preset unavailable")
 end
 local Presentation=require(script.Parent.Controllers.TournamentPresentation)
 check("Production controller initialized",waitFor(function()return player.PlayerGui:FindFirstChild("TournamentVoting")~=nil end,10))
 assert(waitFor(function() return player:GetAttribute("OnboardingReady")==true and player:GetAttribute("ArrivalOpen")~=true end,60),"Arrival readiness timeout")
 local camera=workspace.CurrentCamera
 local initialFov=camera.FieldOfView
 report.initial={camera=camera.CameraType.Name,fov=initialFov,gold=player:GetAttribute("Gold")}
 check("Preparation started by native server fixture",control:InvokeServer("Start"))
 check("Production controller acquired camera and hid HUD",waitFor(function()return Presentation.IsActive() and camera.CameraType==Enum.CameraType.Scriptable and player.PlayerGui.LobbyUI.Enabled==false end,4))
 report.phase="Death"
 local character=player.Character
 local oldHumanoid=character.Humanoid
 check("Authoritative death accepted",control:InvokeServer("Death"))
 check("Death releases old camera and presentation",waitFor(function()return not Presentation.IsActive() and camera.CameraType==Enum.CameraType.Custom and not player.PlayerGui:FindFirstChild("TournamentStagePresentation") end,2))
 assert(waitFor(function()return player.Character~=character and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health>0 end,20),"Respawn timeout")
 check("Production controller resumes pending preparation for new character",waitFor(function()return Presentation.IsActive() and player:GetAttribute("TournamentPresentation")==true end,4))
 check("New character replaces the deceased humanoid",player.Character.Humanoid~=oldHumanoid and player.Character.Humanoid.Health>0)
 camera=workspace.CurrentCamera
 report.phase="Recovery"
 check("Terminal failure delivered through production controller",control:InvokeServer("Fail"))
 check("Full controller restores current camera and HUD",waitFor(function()camera=workspace.CurrentCamera;return not Presentation.IsActive() and camera.CameraType==Enum.CameraType.Custom and camera.CameraSubject==player.Character.Humanoid and player.PlayerGui.LobbyUI.Enabled and player:GetAttribute("TournamentPresentation")==false end,4))
 check("Saved FOV restored after complete lifecycle",camera.FieldOfView==initialFov,{before=initialFov,after=camera.FieldOfView})
 check("Real tournament snapshot restored",control:InvokeServer("Restore"))
 task.wait(.3)
 local glows=0
 for _,item in workspace.GrandArcade:GetDescendants() do if item.Name=="StageFocus" then glows+=1 end end
 local controls=require(player.PlayerScripts.PlayerModule):GetControls()
 check("Controls enabled and temporary stage visuals cleared",controls.controlsEnabled==true and glows==0 and not player.PlayerGui:FindFirstChild("TournamentStagePresentation"),{controlsEnabled=controls.controlsEnabled,glows=glows})
 report.final={camera=camera.CameraType.Name,subjectMatches=camera.CameraSubject==player.Character.Humanoid,hud=player.PlayerGui.LobbyUI.Enabled,health=player.Character.Humanoid.Health,gold=player:GetAttribute("Gold"),arrivalOpen=player:GetAttribute("ArrivalOpen"),active=Presentation.IsActive()}
 report.phase="Awaiting normal keyboard movement"
end,debug.traceback)
if not ok then table.insert(report.failures,tostring(err));pcall(function()control:InvokeServer("Restore")end)end
report.lifecycleComplete=true
write()
