--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local ConfigFolder = game:GetService("ReplicatedStorage").Config
local RaceConfig = require(ConfigFolder.RaceConfig)
local profiles: { [string]: any } = {}
for _, module in { ConfigFolder.ClassicAscentAmbienceConfig, ConfigFolder.CityRunAmbienceConfig, ConfigFolder.ShipwreckAmbienceConfig, ConfigFolder.StudGardenAmbienceConfig } do
	local config = require(module)
	profiles[config.CourseId] = config
end
local activeProfile: any = nil
local sky: Sky? = nil
local createdSky = false
local savedSky: { [string]: any }? = nil
local saved: { [string]: any }? = nil
local savedAtmosphere: { [string]: any }? = nil
local atmosphere: Atmosphere? = nil
local createdAtmosphere = false
local savedEffects: {any} = {}
local hiddenState: {[Instance]: {[string]: any}} = {}
local hiddenConnection: RBXScriptConnection? = nil
local hiddenRoots: {[string]: boolean} = {}
local correction = Instance.new("ColorCorrectionEffect")
correction.Name = "CourseColor"
correction.Enabled = false
correction.Parent = Lighting

local function hideProperty(object: Instance, property: string, value: any)
	local state = hiddenState[object]
	if not state then
		state = {}
		hiddenState[object] = state
	end
	if state[property] == nil then state[property] = (object :: any)[property] end
	(object :: any)[property] = value
end

local function hideObject(object: Instance)
	if object:IsA("BasePart") then
		hideProperty(object, "LocalTransparencyModifier", 1)
	elseif object:IsA("GuiObject") then
		hideProperty(object, "Visible", false)
	elseif object:IsA("LayerCollector") or object:IsA("BillboardGui") or object:IsA("SurfaceGui")
		or object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")
		or object:IsA("Light") or object:IsA("Highlight") then
		hideProperty(object, "Enabled", false)
	elseif object:IsA("Decal") or object:IsA("Texture") then
		hideProperty(object, "Transparency", 1)
	end
end

local function hideBranch(root: Instance)
	hideObject(root)
	for _, descendant in root:GetDescendants() do hideObject(descendant) end
end

local function restoreHidden()
	if hiddenConnection then hiddenConnection:Disconnect(); hiddenConnection = nil end
	for object, properties in hiddenState do
		for property, value in properties do
			pcall(function() (object :: any)[property] = value end)
		end
	end
	table.clear(hiddenState)
	table.clear(hiddenRoots)
end

local function hideOutOfBounds(config: any)
	for _, name in config.HideWorkspaceRoots or {} do hiddenRoots[name] = true end
	for name in hiddenRoots do
		local root = workspace:FindFirstChild(name)
		if root then hideBranch(root) end
	end
	hiddenConnection = workspace.DescendantAdded:Connect(function(object)
		local root = object
		while root.Parent and root.Parent ~= workspace do root = root.Parent end
		if root.Parent == workspace and hiddenRoots[root.Name] then hideBranch(object) end
	end)
end

local function setActive(config: any?)
	if config == activeProfile then return end
	restoreHidden()

	-- Restore the baseline before switching maps so one map never becomes another's fallback.
	if saved then
		for _, entry in savedEffects do
			if entry.created then entry.object:Destroy()
			else
				for key, value in entry.properties do entry.object[key] = value end
			end
		end
		table.clear(savedEffects)
		for key, value in pairs(saved) do (Lighting :: any)[key] = value end
		if atmosphere and createdAtmosphere then
			atmosphere:Destroy()
		elseif atmosphere and savedAtmosphere then
			for key, value in pairs(savedAtmosphere) do (atmosphere :: any)[key] = value end
		end
		if sky and createdSky then
			sky:Destroy()
		elseif sky and savedSky then
			for key, value in pairs(savedSky) do (sky :: any)[key] = value end
		end
		correction.Enabled = false
		sky, savedSky = nil, nil
		atmosphere, savedAtmosphere = nil, nil
		saved = nil
	end

	activeProfile = config
	if not config then return end
	if config.HideWorkspaceRoots then hideOutOfBounds(config) end
	local lightingObject: any = Lighting
	local originalLighting: {[string]: any} = {}
	saved = originalLighting
	for key, value in pairs(config.Lighting) do
		originalLighting[key] = lightingObject[key]
		lightingObject[key] = value
	end
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	createdAtmosphere = atmosphere == nil
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "CourseHaze"
		atmosphere.Parent = Lighting
	end
	local atmosphereObject: any = atmosphere
	local originalAtmosphere: {[string]: any} = {}
	savedAtmosphere = originalAtmosphere
	for key, value in pairs(config.Atmosphere) do
		originalAtmosphere[key] = atmosphereObject[key]
		atmosphereObject[key] = value
	end
	sky = Lighting:FindFirstChildOfClass("Sky")
	createdSky = sky == nil
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "CourseSky"
		sky.Parent = Lighting
	end
	local skyObject: any = sky
	local originalSky: {[string]: any} = {}
	savedSky = originalSky
	for key, value in pairs(config.Sky) do
		originalSky[key] = skyObject[key]
		skyObject[key] = value
	end
	for key, value in pairs(config.ColorCorrection) do (correction :: any)[key] = value end
	correction.Enabled = true
	for className, properties in config.Effects or {} do
		local effect: any = Lighting:FindFirstChildOfClass(className)
		local created = effect == nil
		if not effect then
			effect = Instance.new(className)
			effect.Name = "Course" .. className
			effect.Parent = Lighting
		end
		local original: {[string]: any} = {}
		for key, value in properties do
			original[key] = effect[key]
			effect[key] = value
		end
		table.insert(savedEffects, {object=effect, created=created, properties=original})
	end
end

local elapsed = 0
local warmed = setmetatable({}, {__mode="k"})
local function warmMist(object: Instance)
	if not object:IsA("ParticleEmitter") or not object.Enabled or warmed[object] then return end
	local count = object:GetAttribute("PrewarmParticles")
	if typeof(count) ~= "number" then return end
	warmed[object] = true
	object:Emit(count)
end
workspace.DescendantAdded:Connect(function(object)
	if object:IsA("ParticleEmitter") then task.defer(warmMist,object) end
end)
for _,object in ipairs(workspace:GetDescendants()) do warmMist(object) end
local function isInsideModel(position: Vector3, name: string): boolean
	local model = workspace:FindFirstChild(name)
	if not model or not model:IsA("Model") then return false end
	local frame, size = model:GetBoundingBox()
	local point = frame:PointToObjectSpace(position)
	local half = size / 2 + RaceConfig.LobbyAmbiencePadding
	return math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z
end

local function isInsideExcludedArea(position: Vector3, config: any): boolean
	if isInsideModel(position, RaceConfig.LobbyModelName) then return true end
	for _, name in config.ExcludeWorkspaceRoots or {} do
		if isInsideModel(position, name) then return true end
	end
	return false
end

RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed < 0.5 then return end
	elapsed = 0
	-- Wait until the selected course has restored its lighting before resuming another profile.
	if typeof(player:GetAttribute("KCArchiveLightingOwner")) == "string" then return end
	local selectedName = player:GetAttribute("KCPhase2Candidate")
	local selected = if typeof(selectedName) == "string" then workspace:FindFirstChild(selectedName) else nil
	if selected and selected:IsA("Model") and selected:GetAttribute("KCArchiveAmbience") == true
		and selected:GetAttribute("KCPhase2PreviewEnabled") == true then
		setActive(nil)
		script:SetAttribute("KCArchiveYielded", selected.Name)
		return
	end
	script:SetAttribute("KCArchiveYielded", nil)
	local course = workspace:FindFirstChild("RaceCourse")
	local info = course and course:FindFirstChild("CourseInfo")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local start = course and course:FindFirstChild("Start")
	local config = if info then profiles[info:GetAttribute("CourseId")] else nil
	local active = config ~= nil and root ~= nil and root:IsA("BasePart")
		and player:GetAttribute("ArrivalOpen") ~= true
		and not isInsideExcludedArea(root.Position, config)
		and start ~= nil and start:IsA("BasePart")
		and (root.Position - start.Position).Magnitude < config.ActivationDistance
	setActive(if active then config else nil)
end)
