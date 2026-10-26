assert(game:GetService("RunService"):IsStudio(),"Studio evidence only")
local RunService=game:GetService("RunService")
local player=game.Players.LocalPlayer
local Recorder={}
local connection,frames,label,started,lastFrame=nil,{},"",0,nil
local binding="SoftLandingEvidenceRecorder"
function Recorder.Start(name)
	if connection then RunService:UnbindFromRenderStep(binding) end
	frames,label,started,lastFrame={},name,os.clock(),nil
	local completeAt,seenFlow=nil,false
	connection=true
	RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+2,function(dt)
		local camera=workspace.CurrentCamera
		local entrance=player.PlayerGui.Arrival.LobbyEntrance
		local hud=player.PlayerGui.LobbyUI.SafeArea
		local body=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local phase=player:GetAttribute("ArrivalTransitionPhase") or "Idle"
		if phase=="Logo" or phase=="Overview" then seenFlow=true end
		local delta,angle=0,0
		if lastFrame then delta=(camera.CFrame.Position-lastFrame.Position).Magnitude;local _,a=lastFrame:ToObjectSpace(camera.CFrame):ToAxisAngle();angle=math.deg(math.abs(a)) end
		lastFrame=camera.CFrame
		local frame={t=os.clock()-started,dt=dt,phase=phase,kind=camera.CameraType.Name,fov=camera.FieldOfView,
			p={camera.CFrame.X,camera.CFrame.Y,camera.CFrame.Z},delta=delta,angle=angle,
			title=entrance.Title.TextTransparency,audio=game.SoundService.ArrivalAmbient.Volume,
			blend=entrance:GetAttribute("CameraBlend"),ready=player:GetAttribute("OnboardingReady"),open=player:GetAttribute("ArrivalOpen"),
			input=hud:GetAttribute("InputReady"),movementBlocked=game.ContextActionService:GetAllBoundActionInfo().ArrivalMovement~=nil,anchored=body and body.Anchored,
			body=body and {body.Position.X,body.Position.Y,body.Position.Z},playing=game.SoundService.ArrivalAmbient.IsPlaying,
			alpha={hud.Currencies:GetAttribute("RevealAlpha"),hud.RaceStack.NextRace:GetAttribute("RevealAlpha"),hud.Menu:GetAttribute("RevealAlpha"),hud.RaceStack.QuestTicket:GetAttribute("RevealAlpha"),hud.Phase:GetAttribute("RevealAlpha")},
			offset={hud.Currencies:GetAttribute("RevealOffset"),hud.Menu:GetAttribute("RevealOffset"),hud.RaceStack.QuestTicket:GetAttribute("RevealOffset")}}
		table.insert(frames,frame)
		if seenFlow and phase=="Complete" and not completeAt then completeAt=os.clock() end
		if (completeAt and os.clock()-completeAt>.8) or os.clock()-started>45 then RunService:UnbindFromRenderStep(binding);connection=nil end
	end)
end
function Recorder.Read(first,last)
	local result={}
	for i=first or 1,math.min(last or #frames,#frames) do table.insert(result,frames[i]) end
	return {label=label,count=#frames,frames=result,running=connection~=nil}
end
function Recorder.Stop()
	if connection then RunService:UnbindFromRenderStep(binding);connection=nil end
end
return Recorder
