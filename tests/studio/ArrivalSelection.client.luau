-- Run with the chooser visible in Studio; selection exercises the same focus handlers as gamepad navigation.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local gui = player.PlayerGui.Arrival.Starfield
local choice, selection = gui.Choice, game:GetService("GuiService")
local world = choice.SharedStage.StageWorld
local motion = gui.Motion.Text == "Motion on"
local previous = selection.SelectedObject
local checks = 0
local function check(value, message) assert(value, message); checks += 1 end
local ok, failure = pcall(function()
	for index, button in {choice.ActionDock.CreateRacer, choice.ActionDock.UseAvatar} do
		selection.SelectedObject = nil
		task.wait(2.8)
		local rig = if index == 1 then world.BlankRacer else world.YourAvatar
		local root = rig:FindFirstChild("HumanoidRootPart") or rig.Torso
		local arm = rig:FindFirstChild("RightArm") or rig.RightUpperArm
		local before = root.CFrame:ToObjectSpace(arm.CFrame)
		local rootY = root.Position.Y
		selection.SelectedObject = button
		task.wait(0.65)
		check(choice.SharedStage:GetAttribute("FocusedChoice") == index, "Correct stage side is focused")
		check(world.SharedPlatform["SelectionLight" .. index].Transparency < 0.5, "Selected floor lights")
		check(world.SharedPlatform["SelectionLight" .. (3-index)].Transparency == 1, "Other floor stays unlit")
		check(button:GetAttribute("Pressed") and button.Position.Y.Offset == 7, "Selected action presses down")
		check(if motion then root.Position.Y-rootY > 0.04 else math.abs(root.Position.Y-rootY) < 0.001, "Greeting adds a controlled full-body bounce")
		local after = root.CFrame:ToObjectSpace(arm.CFrame)
		local _, angle = before:ToObjectSpace(after):ToAxisAngle()
		check(if motion then math.abs(angle) > 0.5 else math.abs(angle) < 0.001, "Greeting respects motion preference")
		task.wait(2.1)
		local _, settled = before:ToObjectSpace(root.CFrame:ToObjectSpace(arm.CFrame)):ToAxisAngle()
		check(math.abs(settled) < 0.15, "Greeting returns to quiet idle")
	end
end)
selection.SelectedObject = previous
assert(ok, failure)
return {passed=checks,motion=motion}
