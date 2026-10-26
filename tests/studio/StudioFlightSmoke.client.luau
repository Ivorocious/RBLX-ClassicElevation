-- Run as a temporary LocalScript in PlayerScripts during Studio Play.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient())

local player = Players.LocalPlayer
local flight = require(player.PlayerScripts.Controllers.StudioFlightController)
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local savedPivot = character:GetPivot()
local savedAutoRotate, savedPlatformStand = humanoid.AutoRotate, humanoid.PlatformStand
local savedAnchored = root.Anchored
local collisions = {}
for _, part in character:GetDescendants() do
	if part:IsA("BasePart") then collisions[part] = part.CanCollide end
end
local records = {}
local function record(name, passed, detail)
	table.insert(records, {name = name, passed = passed, detail = detail})
	assert(passed, name)
end

local ok, failure = xpcall(function()
	record("OffAtStartup", not flight.IsFlying())
	flight.Init()
	local guiCount = 0
	for _, gui in player.PlayerGui:GetChildren() do
		if gui.Name == "StudioFlightControls" then guiCount += 1 end
	end
	record("SingleGuiAfterRepeatedInit", guiCount == 1)
	root.Anchored = true
	record("AnchoredCharacterRejected", not flight.SetFlying(true) and not flight.IsFlying())
	root.Anchored = false
	character:PivotTo(CFrame.new(savedPivot.Position + Vector3.new(0, 350, 0)))
	record("Activation", flight.SetFlying(true) and flight.IsFlying())
	task.wait(0.2)
	local initialHeight = root.Position.Y
	task.wait(0.7)
	local heightDrift = math.abs(root.Position.Y - initialHeight)
	record("PhysicalHover", heightDrift < 0.5, {heightDrift = heightDrift})
	flight.SetFlying(false)
	record("NormalHumanoidRestored", humanoid.AutoRotate == savedAutoRotate and humanoid.PlatformStand == savedPlatformStand)
	record("FlightConstraintsRemoved", not root:FindFirstChild("StudioFlightVelocity")
		and not root:FindFirstChild("StudioFlightOrientation") and not root:FindFirstChild("StudioFlightAttachment"))
	task.wait(0.25)
	record("GravityResumed", root.AssemblyLinearVelocity.Y < -5, {verticalVelocity = root.AssemblyLinearVelocity.Y})
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	assert(flight.SetFlying(true))
	flight.SetFlying(false)
	record("NondefaultHumanoidFlagsRestored", not humanoid.AutoRotate and humanoid.PlatformStand)
	for part, canCollide in collisions do
		assert(part.CanCollide == canCollide, "Character collision changed")
	end
	record("CharacterCollisionPreserved", true)
end, debug.traceback)

flight.SetFlying(false)
humanoid.AutoRotate, humanoid.PlatformStand = savedAutoRotate, savedPlatformStand
character:PivotTo(savedPivot)
root.Anchored = savedAnchored
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
script:SetAttribute("Result", game.HttpService:JSONEncode({passed = ok, records = records, failure = if ok then nil else failure}))
