--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Runtime = require(game.ServerStorage.CourseBuilders.EggRush.Runtime)
local RaceConstants = require(game.ReplicatedStorage.Shared.RaceConstants)

local Service = {}
local services: any
local heartbeat: RBXScriptConnection? = nil
local controller: any = nil
local boundCourse: Model? = nil
local boundRaceId = ""
local retryAt = 0
local startFailure = ""
local profiles: { [Humanoid]: any } = {}
local MOVEMENT = table.freeze({ WalkSpeed = 16, UseJumpPower = false, JumpHeight = 7.2 })
local BODY_CONTACTS = { Head = true, Torso = true, UpperTorso = true, LowerTorso = true }
local BODY_CONTACT_PADDING = .5
local BODY_FORWARD_CLEARANCE = 1.25

-- Humanoid states reset body-part collision flags, so fit the existing collider instead.
local function fitBodyCollider(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	local collider = character:FindFirstChild("CollisionPart")
	if not root or not root:IsA("BasePart") or not collider or not collider:IsA("BasePart") then return nil end
	local joint: Weld? = nil
	for _, child in collider:GetChildren() do
		if child:IsA("Weld") and ((child.Part0 == collider and child.Part1 == root)
			or (child.Part1 == collider and child.Part0 == root)) then joint = child; break end
	end
	if not joint then return nil end
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	local function include(part: BasePart, padding: number, forwardClearance: number)
		local frame = root.CFrame:ToObjectSpace(part.CFrame)
		for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
			local p = frame * (part.Size * Vector3.new(x, y, z) / 2)
			low = Vector3.new(math.min(low.X, p.X - padding), math.min(low.Y, p.Y - padding), math.min(low.Z, p.Z - padding - forwardClearance))
			high = Vector3.new(math.max(high.X, p.X + padding), math.max(high.Y, p.Y + padding), math.max(high.Z, p.Z + padding))
		end end end
	end
	include(collider, 0, 0)
	for _, part in character:GetChildren() do
		-- Standard R15 jump animations lean the head forward of its standing bounds.
		if part:IsA("BasePart") and BODY_CONTACTS[part.Name] then include(part, BODY_CONTACT_PADDING, BODY_FORWARD_CLEARANCE) end
	end
	local saved = {part = collider, size = collider.Size, joint = joint, c0 = joint.C0, c1 = joint.C1}
	local relative = CFrame.new((low + high) / 2)
	collider.Size = high - low
	if joint.Part0 == collider then joint.C0 = relative:Inverse() * joint.C1
	else joint.C1 = relative:Inverse() * joint.C0 end
	return saved
end

local function isEligible(player: Player): boolean
	return player.Parent == Players
		and services.RaceService.IsRaceActive() == true
		and services.CourseService.GetActiveCourse() == boundCourse
		and services.RaceService.GetCurrentRaceId() == boundRaceId
		and services.PlayerRaceService.IsOfficialRacer(player) == true
		and services.PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function restoreProfile(humanoid: Humanoid, saved: any)
	local contact = saved.bodyCollider
	if contact and contact.part.Parent ~= nil and contact.joint.Parent ~= nil then
		contact.part.Size = contact.size
		contact.joint.C0, contact.joint.C1 = contact.c0, contact.c1
	end
	if humanoid.Parent ~= nil then
		humanoid.WalkSpeed, humanoid.UseJumpPower = saved.WalkSpeed, saved.UseJumpPower
		humanoid.JumpHeight, humanoid.JumpPower = saved.JumpHeight, saved.JumpPower
	end
end

local function clearBinding()
	if controller ~= nil then controller.Stop() end
	controller = nil
	for humanoid, saved in profiles do restoreProfile(humanoid, saved) end
	table.clear(profiles)
	boundCourse, boundRaceId = nil, ""
end

local function syncProfiles()
	local current: { [Humanoid]: boolean } = {}
	if controller ~= nil then
		for _, player in Players:GetPlayers() do
			if not isEligible(player) then continue end
			local character = player.Character
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			if not character or not humanoid or humanoid.Health <= 0 then continue end
			current[humanoid] = true
			if profiles[humanoid] == nil then
				profiles[humanoid] = {
					WalkSpeed = humanoid.WalkSpeed, UseJumpPower = humanoid.UseJumpPower,
					JumpHeight = humanoid.JumpHeight, JumpPower = humanoid.JumpPower,
					bodyCollider = if boundCourse and boundCourse:GetAttribute("FullBodyContacts") == true
						then fitBodyCollider(character) else nil,
				}
			end
			humanoid.WalkSpeed, humanoid.UseJumpPower, humanoid.JumpHeight = MOVEMENT.WalkSpeed, MOVEMENT.UseJumpPower, MOVEMENT.JumpHeight
		end
	end
	for humanoid, saved in profiles do
		if not current[humanoid] then restoreProfile(humanoid, saved); profiles[humanoid] = nil end
	end
end

function Service.Init(context: any)
	assert(heartbeat == nil, "Cannot replace EggRushService context while running")
	services = context.Services
end

function Service.Start()
	if heartbeat ~= nil then return end
	assert(RunService:IsServer(), "EggRushService must run on the server")
	assert(services ~= nil, "EggRushService.Init must run before Start")
	heartbeat = RunService.Heartbeat:Connect(function()
		if controller ~= nil and controller.Diagnostics().bound ~= true then clearBinding() end
		local course = services.CourseService.GetActiveCourse()
		local active = services.RaceService.IsRaceActive() == true
		local owned = course ~= nil and course:IsDescendantOf(Workspace)
			and course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true
		local raceId = services.RaceService.GetCurrentRaceId()
		local retaining = controller ~= nil and course == boundCourse and raceId == boundRaceId
		local target = if owned and raceId ~= "" and (active or retaining) then course else nil
		local targetRaceId = if target ~= nil then raceId else ""
		if target ~= boundCourse or targetRaceId ~= boundRaceId then
			clearBinding()
			if target ~= nil and active and os.clock() >= retryAt then
				local ok, result = pcall(Runtime.Start, target, isEligible, services.RespawnService.RecoverPlayer)
				if ok then
					controller, boundCourse, boundRaceId = result, target, targetRaceId
					startFailure, retryAt = "", 0
				else
					local message = tostring(result)
					if message ~= startFailure then warn("Egg Rush runtime could not start: " .. message) end
					startFailure, retryAt = message, os.clock() + 1
				end
			end
		end
		if controller ~= nil then
			if active then controller.Resume() else controller.Hold() end
		end
		syncProfiles()
	end)
end

function Service.Stop()
	if heartbeat ~= nil then heartbeat:Disconnect(); heartbeat = nil end
	clearBinding()
	startFailure, retryAt = "", 0
end

function Service.GetDiagnostics(): any
	local report = if controller ~= nil then controller.Diagnostics() else { bound = false }
	report.raceId = boundRaceId
	report.startFailure = startFailure
	report.movementProfiles = 0
	for _ in profiles do report.movementProfiles += 1 end
	report.movement = table.clone(MOVEMENT)
	report.gravity, report.expectedGravity = Workspace.Gravity, 196.2
	report.gravityMatches = math.abs(Workspace.Gravity - 196.2) < .01
	return report
end

return Service
