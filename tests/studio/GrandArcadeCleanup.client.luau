if not game:GetService('RunService'):IsStudio() then return end
local player=game.Players.LocalPlayer
local receipt=Instance.new('StringValue');receipt.Name,receipt.Parent='CleanupReceipt',script
local report={kind='Exact fresh presentation module in native solo Play; labelled synthetic preparation',checks={},failures={}}
local function write()receipt.Value=game:GetService('HttpService'):JSONEncode(report)end
local function check(name,ok)table.insert(report.checks,{name=name,passed=ok==true});if not ok then table.insert(report.failures,name)end;write()end
local ok,err=xpcall(function()
 local fresh=script.Parent.Controllers.TournamentPresentation:Clone();fresh.Name,fresh.Parent='FreshPresentation',script
 local presentation=require(fresh)
 local camera=workspace.CurrentCamera
 local fov=camera.FieldOfView
 local function start()
  local now=workspace:GetServerTimeNow()
  presentation.Start({preparation={token='CLEANUP_FIXTURE',index=1,courseId='NO_FIXTURE_COURSE',status='Presentation',startedAt=now,revealUntil=now+9}},function()end)
  task.wait(.3)
  check('Presentation owns the camera',presentation.IsActive() and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable)
 end
 camera.CameraType=Enum.CameraType.Custom;camera.FieldOfView=66
 start();presentation.Stop()
 check('Normal cancellation preserves type and FOV',camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==66)
 camera.CameraType=Enum.CameraType.Scriptable
 start();presentation.Stop()
 check('Abandoned Scriptable camera returns to normal control',camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==66)
 camera.CameraType=Enum.CameraType.Custom
 start()
 local character=player.Character
 game.ReplicatedStorage.Remotes.__LobbyDisplayCheckControl:InvokeServer('Death')
 task.wait(.2)
 check('Authoritative death clears camera and presentation',not presentation.IsActive() and player:GetAttribute('TournamentPresentation')==false and camera.CameraType==Enum.CameraType.Custom and not player.PlayerGui:FindFirstChild('TournamentStagePresentation'))
 local deadline=os.clock()+15
 repeat task.wait(.1)until player.Character~=character and player.Character and player.Character:FindFirstChildOfClass('Humanoid') or os.clock()>deadline
 task.wait(.4)
 camera=workspace.CurrentCamera
 check('Respawn stays usable with the new humanoid',player.Character~=character and player.Character.Humanoid.Health>0 and camera.CameraType==Enum.CameraType.Custom and camera.CameraSubject==player.Character.Humanoid and not presentation.IsActive())
 start()
 local previous=camera
 local replacement=Instance.new('Camera');replacement.Name='__CleanupReplacementCamera';replacement.CameraType=Enum.CameraType.Custom;replacement.CameraSubject=player.Character.Humanoid;replacement.Parent=workspace
 workspace.CurrentCamera=replacement
 task.wait(.2)
 check('Camera replacement clears ownership',not presentation.IsActive() and player:GetAttribute('TournamentPresentation')==false and not player.PlayerGui:FindFirstChild('TournamentStagePresentation'))
 if previous.Parent then workspace.CurrentCamera=previous;replacement:Destroy()else replacement.Name='Camera'end
 camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Custom;camera.FieldOfView=fov;camera.CameraSubject=player.Character.Humanoid
 local glows=0;for _,item in workspace.GrandArcade:GetDescendants()do if item.Name=='StageFocus' then glows+=1 end end
 task.wait(.2)
 check('HUD and stage cleanup restored',player.PlayerGui.LobbyUI.Enabled and glows==0)
end,debug.traceback)
if not ok then table.insert(report.failures,tostring(err))end
report.complete=true;write()
