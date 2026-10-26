if not game:GetService('RunService'):IsStudio() then return end
local player=game.Players.LocalPlayer
local receipt=Instance.new('StringValue')
receipt.Name,receipt.Parent='Receipt',script
local report={kind='Native client gates and labelled local stage previews; not a five-course live tournament',checks={},failures={}}
local function write()receipt.Value=game:GetService('HttpService'):JSONEncode(report)end
local function check(name,ok)table.insert(report.checks,{name=name,passed=ok==true});if not ok then table.insert(report.failures,name)end;write()end
local ok,err=xpcall(function()
 task.wait(4)
 local remotes=game.ReplicatedStorage.Remotes
 local reply=remotes.StudioDevControl:InvokeServer({action='OnboardingPreset',preset='Returning avatar'})
 check('Existing temporary returning preset accepted',reply.ok==true)
 local Onboarding=require(script.Parent.Controllers.OnboardingController)
 local prompt=workspace.Lobby.LobbyAmenities.Shops.Style.Interaction.EditRacer
 local controls=remotes:WaitForChild('__LobbyNativeCheckControl',10)
 local arrivalDeadline=os.clock()+40
 repeat task.wait(.1)until Onboarding.CanOpenRacer() and prompt.Enabled or os.clock()>arrivalDeadline
 report.arrival={phase=player:GetAttribute('ArrivalPhase'),open=player:GetAttribute('ArrivalOpen'),transition=player:GetAttribute('ArrivalTransitionPhase')}
 check('Ready lobby enables same editor gate',Onboarding.CanOpenRacer() and prompt.Enabled)
 controls:InvokeServer('PendingCourse');task.wait(.5)
 check('Pending course disables prompt and editor gate',not prompt.Enabled and not Onboarding.CanOpenRacer())
 local rejected=remotes.ArrivalControl:InvokeServer({action='Edit'})
 check('Server rejects pending course editor',rejected.ok==false)
 controls:InvokeServer('Restore');task.wait(.5)
 check('Prompt returns after pending gate clears',prompt.Enabled and Onboarding.CanOpenRacer())
 local Preview=require(script.Parent.Controllers.StudioGrandArcadePreview)
 local Presentation=require(script.Parent.Controllers.TournamentPresentation)
 local camera=workspace.CurrentCamera
 local fov=camera.FieldOfView
 for _,entry in {{'Opening',9.7},{'Next',3.7},{'Failure',9.7},{'Slow',15.7}}do
  check(entry[1]..' preview accepted',Preview.Open(entry[1]))
  local deadline=os.clock()+8
  repeat task.wait(.1)until Presentation.IsActive() or os.clock()>deadline
  check(entry[1]..' takes camera/input ownership',Presentation.IsActive() and player:GetAttribute('TournamentPresentation')==true and camera.CameraType==Enum.CameraType.Scriptable)
  task.wait(entry[2])
  check(entry[1]..' restores camera and input ownership',not Presentation.IsActive() and player:GetAttribute('TournamentPresentation')==false and camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==fov)
 end
 Preview.Open('Opening');task.wait(.5);Preview.Close();task.wait(.2)
 check('Manual cancellation restores presentation state',not Presentation.IsActive() and not player:GetAttribute('TournamentPresentation'))
 controls:InvokeServer('Presentation');task.wait(.6)
 check('Actual controller starts pending presentation',Presentation.IsActive() and player:GetAttribute('TournamentPresentation'))
 controls:InvokeServer('ReadyReplay');task.wait(.2);Presentation.Stop();task.wait(.2)
 controls:InvokeServer('ReadyReplay');task.wait(.6)
 check('Actual controller does not replay completed Ready result snapshot',not Presentation.IsActive() and not player:GetAttribute('TournamentPresentation'))
 player:SetAttribute('ArrivalOpen',true);task.wait(.1);player:SetAttribute('ArrivalOpen',false);task.wait(.3)
 check('Arrival attribute does not replay a completed Ready token',not Presentation.IsActive())
 controls:InvokeServer('PendingCourse');task.wait(.6)
 check('Late pending readiness gate resumes delivery',Presentation.IsActive() and player:GetAttribute('TournamentPresentation'))
 controls:InvokeServer('Fail');task.wait(.3)
 check('Failure releases actual controller camera ownership',not Presentation.IsActive() and camera.CameraType==Enum.CameraType.Custom)
 controls:InvokeServer('ResetSnapshot');task.wait(.3)
 check('Real four-course snapshot and editor restored',not Presentation.IsActive() and Onboarding.CanOpenRacer() and prompt.Enabled)
 report.gold=player:GetAttribute('Gold')
end,debug.traceback)
if not ok then table.insert(report.failures,tostring(err))end
report.complete=true
write()
