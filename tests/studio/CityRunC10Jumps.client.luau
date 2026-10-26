-- Temporary LocalScript; teleports only establish each probe's starting position.
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character.HumanoidRootPart
local course = workspace.RaceCourse
local controls = require(player.PlayerScripts.PlayerModule):GetControls()
local flight = require(player.PlayerScripts.Controllers.StudioFlightController)
local saved = character:GetPivot()
local records, movement, requestJump = {}, Vector3.zero, false
local raycast = RaycastParams.new()
raycast.FilterType = Enum.RaycastFilterType.Include
raycast.FilterDescendantsInstances = { course }
raycast.RespectCanCollide = true

local function awaitCondition(predicate, seconds, message)
	local deadline = os.clock() + seconds
	repeat RunService.Heartbeat:Wait() until predicate() or os.clock() > deadline
	assert(predicate(), message)
end

local function standingPart()
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .3), 0), raycast)
	return hit and hit.Instance
end

local function jumpTo(name, direction, targetModel)
	movement, requestJump = direction, true
	awaitCondition(function() return humanoid.FloorMaterial == Enum.Material.Air end, .5, name .. " did not leave the ground")
	requestJump = false
	awaitCondition(function() return humanoid.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Y < 2 end,
		1, name .. " did not land")
	movement = Vector3.zero
	awaitCondition(function()
		local p = standingPart()
		return p and (p == targetModel or p:IsDescendantOf(targetModel)) and humanoid.FloorMaterial ~= Enum.Material.Air
	end, .35, name .. " did not settle on the expected landing")
	local landed = standingPart()
	table.insert(records, { name = name, landing = landed:GetFullName(), position = tostring(root.Position) })
end

local ok, failure = xpcall(function()
	assert(RunService:IsStudio() and RunService:IsClient() and course:GetAttribute("CityRunRevision") == "C10")
	assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01)
	assert(math.abs(workspace.Gravity - 196.2) < .01 and not root.Anchored)
	flight.SetFlying(false)
	controls:Disable()
	RunService:BindToRenderStep("C10JumpProbe", Enum.RenderPriority.Character.Value + 1, function()
		humanoid:Move(movement, false)
		humanoid.Jump = requestJump
	end)
	local obstacles = course.Obstacles.C10Obstacles
	local entry = course.Obstacles.WalkingSurfaces.StationMain_01_01.StationMain_01_01
	character:PivotTo(CFrame.new(3833, entry.Position.Y + .5 + humanoid.HipHeight + root.Size.Y / 2 + .3, 83))
	root.AssemblyLinearVelocity = Vector3.zero
	awaitCondition(function() return humanoid.FloorMaterial ~= Enum.Material.Air end, 2, "Entry setup failed")
	jumpTo("StationEntryToOuterLane", Vector3.new(.8, 0, .6), obstacles.StationCrumble_Row01_Lane3)
	local first = obstacles.StationCrumble_Row01_Lane2:FindFirstChildWhichIsA("BasePart")
	character:PivotTo(CFrame.new(first.Position + Vector3.new(0, first.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .3, 0)))
	root.AssemblyLinearVelocity = Vector3.zero
	awaitCondition(function() return standingPart() == first and humanoid.FloorMaterial ~= Enum.Material.Air end, 2, "First tile setup failed")
	for row = 1, 9 do
		local tile = obstacles[string.format("StationCrumble_Row%02d_Lane2", row)]:FindFirstChildWhichIsA("BasePart")
		movement = Vector3.new(0, 0, 1)
		awaitCondition(function() return root.Position.Z >= tile.Position.Z + 1.25 end, .5, "Could not reach tile takeoff edge")
		local target = if row < 9 then obstacles[string.format("StationCrumble_Row%02d_Lane2", row + 1)]
			else course.Obstacles.WalkingSurfaces.StationMain_01_06
		jumpTo("CrumbleRow" .. row .. "To" .. (if row < 9 then tostring(row + 1) else "Exit"), Vector3.new(0, 0, 1), target)
	end
	local surface = course.Obstacles.WalkingSurfaces.RoofMainEntry_00_01
	local hurdle = obstacles.Hurdle_RoofMainEntry_00_01:FindFirstChildWhichIsA("BasePart")
	local top = hurdle.Position.Y - hurdle.Size.Y / 2
	character:PivotTo(CFrame.new(hurdle.Position.X, top + humanoid.HipHeight + root.Size.Y / 2 + .2, hurdle.Position.Z - 3))
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(.25)
	awaitCondition(function() local p = standingPart(); return p and p:IsDescendantOf(surface) and humanoid.FloorMaterial ~= Enum.Material.Air end, 2, "Hurdle setup failed")
	local before = character:GetAttribute("RecoveryUntil") or 0
	jumpTo("NormalJumpOverNewHurdle", Vector3.new(0, 0, 1), surface)
	assert((character:GetAttribute("RecoveryUntil") or 0) <= before, "Hurdle jump touched the hazard")
	local expert = course.Obstacles.WalkingSurfaces.X03_01_01.X03_01_01
	character:PivotTo(CFrame.new(expert.Position.X, expert.Position.Y + .5 + humanoid.HipHeight + root.Size.Y / 2 + .3,
		expert.Position.Z))
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(.25)
	awaitCondition(function() return standingPart() == expert and humanoid.FloorMaterial ~= Enum.Material.Air end, 2, "Expert setup failed")
	movement = Vector3.new(0, 0, 1)
	awaitCondition(function() return root.Position.Z >= expert.Position.Z + 2.8 end, .5, "Expert takeoff setup failed")
	before = character:GetAttribute("RecoveryUntil") or 0
	jumpTo("ExpertRisePastNewEdgePatch", Vector3.new(0, 0, 1), course.Obstacles.WalkingSurfaces.X03_01_02)
	assert((character:GetAttribute("RecoveryUntil") or 0) <= before, "Expert jump touched the new edge hazard")
end, debug.traceback)

RunService:UnbindFromRenderStep("C10JumpProbe")
humanoid:Move(Vector3.zero, false)
humanoid.Jump = false
character:PivotTo(saved)
root.AssemblyLinearVelocity = Vector3.zero
controls:Enable()
script:SetAttribute("Result", game.HttpService:JSONEncode({ passed = ok, records = records,
	failure = if ok then nil else failure, walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
	method = "Real client Humanoid movement and jumps with flight off, normal gravity, and imported collision",
	limitation = "Outer-lane entry, one complete crumble lane, one hurdle and one expert rise; not a human full-course or multiplayer traversal" }))
