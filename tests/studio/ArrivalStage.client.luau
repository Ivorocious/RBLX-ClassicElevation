-- Run in a Play client with the chooser open. This uses temporary Studio profiles only.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local gui = game.Players.LocalPlayer.PlayerGui.Arrival
local backdrop = gui.Starfield
local choice = backdrop.Choice
local viewport = choice.SharedStage
local world = viewport.StageWorld
local checks = {}
local function check(value, name)
	assert(value, name)
	table.insert(checks, name)
end
check(choice.Visible, "Chooser is visible")
check(choice:FindFirstChild("CreateCard") == nil and choice:FindFirstChild("AvatarCard") == nil, "No enclosing cards")
check(world:FindFirstChild("SharedPlatform") ~= nil, "Both characters share one platform")
local dummy, avatar = world.BlankRacer, world:WaitForChild("YourAvatar", 15)
check(avatar ~= nil, "Account avatar loaded")
check(dummy.Head:FindFirstChildOfClass("Decal") == nil, "Creation dummy stays blank")
check(avatar.Humanoid:GetAppliedDescription().UseAvatarSettings, "Preview follows experience avatar rules")
local d, a = dummy.Head.CFrame, avatar.Head.CFrame
local star = backdrop.Star1.Position
task.wait(1.2)
local motion = backdrop.Motion.Text == "Motion on"
check((d ~= dummy.Head.CFrame) == motion, "Dummy respects motion toggle")
check((a ~= avatar.Head.CFrame) == motion, "Avatar respects motion toggle")
check((star ~= backdrop.Star1.Position) == motion, "Starfield respects motion toggle")
check((d.Position - dummy.Head.Position).Magnitude < 0.15, "Dummy motion is restrained")
check((a.Position - avatar.Head.Position).Magnitude < 0.15, "Avatar motion is restrained")
local maxWeldGap = 0
for _, joint in avatar:GetDescendants() do
	if joint:IsA("Weld") and joint.Name == "AccessoryWeld" and joint.Part0 and joint.Part1 then
		maxWeldGap = math.max(maxWeldGap, ((joint.Part0.CFrame * joint.C0).Position - (joint.Part1.CFrame * joint.C1).Position).Magnitude)
	end
end
check(maxWeldGap < 0.001, "Accessories follow animated joints")
local originalSize = backdrop.Size
local layouts = {}
local success, failure = pcall(function()
	for _, size in {Vector2.new(1360,779), Vector2.new(375,700), Vector2.new(667,375)} do
		backdrop.Size = UDim2.fromOffset(size.X, size.Y)
		task.wait(0.2)
		local origin = backdrop.AbsolutePosition
		local dock = choice.ActionDock
		local function contained(item)
			local p, s = item.AbsolutePosition-origin, item.AbsoluteSize
			return p.X >= -1 and p.Y >= -1 and p.X+s.X <= size.X+1 and p.Y+s.Y <= size.Y+1
		end
		check(contained(dock), tostring(size) .. " dock fits")
		check(contained(backdrop.Brand), tostring(size) .. " brand fits")
		check(dock.CreateRacer.AbsoluteSize.Y >= 44 and dock.UseAvatar.AbsoluteSize.Y >= 44, tostring(size) .. " touch targets")
		check(viewport.AbsolutePosition.Y+viewport.AbsoluteSize.Y <= dock.AbsolutePosition.Y, tostring(size) .. " stage clears actions")
		local reward = choice.GoldBonus
		check(reward.Parent == choice and reward.AbsolutePosition.Y+reward.AbsoluteSize.Y < dock.AbsolutePosition.Y, tostring(size) .. " reward is outside action bar")
		check(contained(choice.ChangeAnytime), tostring(size) .. " postscript fits footer")
		check(dock.CreateRacer.Text == "Create racer" and dock.UseAvatar.Text == "Use my avatar", tostring(size) .. " unified action labels")
		local panel = backdrop.ArrivalDialog.Panel
		check(contained(panel) and panel.Confirm.AbsoluteSize.Y >= 44, tostring(size) .. " dialog fits with touch targets")
		table.insert(layouts, {width=size.X,height=size.Y,dockHeight=dock.AbsoluteSize.Y})
	end
end)
backdrop.Size = originalSize
assert(success, failure)
return {passed=#checks,motion=motion,maxWeldGap=maxWeldGap,layouts=layouts}
