-- Observe the actual controller; no timing hooks or synthetic animation.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("Arrival")
local dev = game.ReplicatedStorage.Remotes.StudioDevControl
assert(dev:InvokeServer({action="OnboardingPreset",preset="First visit"}).ok)
local deadline = os.clock()+20
repeat task.wait(.1) until player:GetAttribute("ArrivalPhase")=="Choice" or os.clock()>deadline
assert(gui.Starfield.Motion.Text=="Motion on", "Enable motion for this test")
local samples = {}
local connection = game:GetService("RunService").RenderStepped:Connect(function()
	local phase = player:GetAttribute("ArrivalTransitionPhase")
	if phase=="Logo" or phase=="LogoHold" then
		table.insert(samples,{time=os.clock(),phase=phase,source=gui.Starfield.Brand.Visible,
			y=gui.LobbyEntrance.Title.AbsolutePosition.Y,alpha=gui.LobbyEntrance.ElevationEmblem.ImageTransparency})
	end
end)
local ok, failure = pcall(function()
	local result = game.ReplicatedStorage.Remotes.ArrivalControl:InvokeServer({action="Save",mode="Avatar",operationId="title-flow-regression"})
	assert(result.ok, result.message)
	deadline = os.clock()+30
	repeat task.wait(.1) until player:GetAttribute("ArrivalTransitionPhase")=="Complete" or os.clock()>deadline
	assert(player:GetAttribute("ArrivalTransitionPhase")=="Complete", "Entrance completes")
end)
connection:Disconnect()
assert(ok,failure)
local firstY, lastY, holdStart, holdEnd
for _, sample in samples do
	assert(not sample.source, "Header cannot duplicate the moving title")
	if sample.phase=="Logo" then firstY=firstY or sample.y; lastY=sample.y end
	if sample.phase=="LogoHold" then
		holdStart=holdStart or sample.time; holdEnd=sample.time
		assert(sample.alpha==0, "Emblem remains fully visible during hold")
	end
end
assert(firstY and lastY and lastY>firstY+40, "Header travels towards centre")
assert(holdStart and holdEnd and holdEnd-holdStart>=1.5, "Logo has a readable minimum hold")
assert(player:GetAttribute("OnboardingReady"), "Entrance releases player after delivery")
return {firstY=firstY,lastY=lastY,logoHoldSeconds=holdEnd-holdStart,complete=true}
