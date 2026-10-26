assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client only")
local player=game.Players.LocalPlayer
shared.MCPreviewLight=require(game.StarterPlayer.StarterPlayerScripts.Controllers.MoonlitCitadelPreviewView).Start()
game:GetService("RunService"):BindToRenderStep("MoonlitProbeMove",Enum.RenderPriority.Input.Value+1,function()
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local body=character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not body then return end
	local goal=shared.MCGoal
	if goal then
		local delta=Vector3.new(goal.X-body.Position.X,0,goal.Z-body.Position.Z)
		humanoid:Move(if delta.Magnitude>1.1 then delta.Unit else Vector3.zero,false)
	end
end)
return "Ordinary movement driver installed; daylight view active"
