--!strict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Comparable cost inventory runs in Edit only")
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local old = Storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses.KeyboardCircuit_P3_M02_01
local current = workspace.KeyboardCircuit_P3_M04_01
assert(old:GetAttribute("PrototypeRevision") == "KC_P3_M02_01" and current:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")

local function increment(totals: {[string]: number}, name: string)
	totals[name] = (totals[name] or 0) + 1
end

local function inside(item: Instance, group: Instance?): boolean
	return group ~= nil and item:IsDescendantOf(group)
end

local function legendClass(gui: SurfaceGui, model: Model): string
	local part = gui.Adornee or gui.Parent
	if gui.Name == "Legend" and part and part:IsA("BasePart") and typeof(part:GetAttribute("KeyLegend")) == "string" then
		if part:GetAttribute("Role") == "WalkableSkin" then
			if gui:FindFirstChild("DropWarning") then return "WarningKey" end
			if part.Name == "KeyTop" or math.max(part.Size.X, part.Size.Z) > 3.2 then return "SpecialKey" end
			return "OrdinaryKey"
		end
		if part:GetAttribute("MapArtwork") == true and not part:GetAttribute("Pressable") then return "DisplayKey" end
	end
	local environment = model:FindFirstChild("MapEnvironment")
	if environment and inside(gui, environment:FindFirstChild("HazardIndicators")) then return "HazardDisplay" end
	if environment and inside(gui, environment:FindFirstChild("Wayfinding")) then return "Wayfinding" end
	return "OtherPreserved"
end

local function inventory(model: Model)
	local result: any = {
		parts = 0, meshParts = 0, shadowParts = 0, pressTargets = 0, colliders = 0, queryParts = 0, touchParts = 0,
		artParts = 0, artMeshParts = 0, artShadowParts = 0, artUnanchored = 0, artCollision = 0, artTouch = 0, artQuery = 0, artPress = 0,
		surfaceGuis = 0, enabledSurfaceGuis = 0, unlimitedSurfaceGuis = 0, distances = {}, legendClasses = {},
		textLabels = 0, lights = 0, enabledLights = 0, particleEmitters = 0, enabledParticleEmitters = 0, beams = 0, trails = 0,
		scripts = 0, sourceBytes = 0, descendants = #model:GetDescendants(),
	}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			result.parts += 1
			if item:IsA("MeshPart") then result.meshParts += 1 end
			if item.CastShadow then result.shadowParts += 1 end
			if item:GetAttribute("Pressable") then result.pressTargets += 1 end
			if item.CanCollide then result.colliders += 1 end
			if item.CanQuery then result.queryParts += 1 end
			if item.CanTouch then result.touchParts += 1 end
			if item:GetAttribute("MapArtwork") == true then
				result.artParts += 1
				if item:IsA("MeshPart") then result.artMeshParts += 1 end
				if item.CastShadow then result.artShadowParts += 1 end
				if not item.Anchored then result.artUnanchored += 1 end
				if item.CanCollide then result.artCollision += 1 end
				if item.CanTouch then result.artTouch += 1 end
				if item.CanQuery then result.artQuery += 1 end
				if item:GetAttribute("Pressable") or item:GetAttribute("KCPress") then result.artPress += 1 end
			end
		elseif item:IsA("SurfaceGui") then
			result.surfaceGuis += 1
			if item.Enabled then result.enabledSurfaceGuis += 1 end
			assert(item.MaxDistance >= 0 and item.MaxDistance < math.huge, "Invalid GUI distance")
			if item.MaxDistance == 0 then result.unlimitedSurfaceGuis += 1 end
			increment(result.distances, tostring(item.MaxDistance))
			local class = legendClass(item, model)
			local row = result.legendClasses[class]
			if not row then
				row = {count = 0, enabled = 0, finite = 0, unlimited = 0, minimumFiniteDistance = math.huge, maximumFiniteDistance = 0, distances = {}}
				result.legendClasses[class] = row
			end
			row.count += 1
			if item.Enabled then row.enabled += 1 end
			if item.MaxDistance == 0 then row.unlimited += 1 else
				row.finite += 1
				row.minimumFiniteDistance = math.min(row.minimumFiniteDistance, item.MaxDistance)
				row.maximumFiniteDistance = math.max(row.maximumFiniteDistance, item.MaxDistance)
			end
			increment(row.distances, tostring(item.MaxDistance))
		elseif item:IsA("TextLabel") then result.textLabels += 1
		elseif item:IsA("PointLight") or item:IsA("SpotLight") or item:IsA("SurfaceLight") then
			result.lights += 1
			if item.Enabled then result.enabledLights += 1 end
		elseif item:IsA("ParticleEmitter") then
			result.particleEmitters += 1
			if item.Enabled then result.enabledParticleEmitters += 1 end
		elseif item:IsA("Beam") then result.beams += 1
		elseif item:IsA("Trail") then result.trails += 1
		elseif item:IsA("LuaSourceContainer") then result.scripts += 1; result.sourceBytes += #item.Source end
	end
	for _, row in result.legendClasses do if row.finite == 0 then row.minimumFiniteDistance = nil end end
	return result
end

local before, after = inventory(old), inventory(current)
assert(after.parts == 8808 and after.artParts == 1894 and after.pressTargets == 2989)
for _, name in {"pressTargets", "colliders", "queryParts", "touchParts"} do assert(before[name] == after[name], "Gameplay inventory changed: " .. name) end
assert(after.colliders == 282 and after.queryParts == 3289 and after.touchParts == 0)
assert(after.artCollision == 0 and after.artTouch == 0 and after.artQuery == 0 and after.artPress == 0 and after.artUnanchored == 0)
local limits = {OrdinaryKey = 120, SpecialKey = 180, DisplayKey = 64, WarningKey = 170}
for name, limit in limits do
	local row = assert(after.legendClasses[name], "Missing legend class: " .. name)
	assert(row.unlimited == 0 and row.maximumFiniteDistance <= limit, "Legend distance exceeds presentation budget: " .. name)
end
assert(after.legendClasses.HazardDisplay.count == 17, "Seventeen warning displays required")
local _, authoredHeartbeatCallbacks = current.SourceSnapshot.ArchiveEffects.Source:gsub("RunService%.Heartbeat:Connect", "")
assert(authoredHeartbeatCallbacks == 1, "One authored ArchiveEffects cosmetic Heartbeat callback expected")
local receipt = {
	passed = true, baseline = old.Name, candidate = current.Name, revision = current:GetAttribute("PrototypeRevision"), datamodel = "Edit",
	before = before, after = after, finiteLegendLimits = limits, partChangePercent = (after.parts / before.parts - 1) * 100,
	gameplayInventoryUnchanged = true,
	cosmeticRuntime = {
		authoredHeartbeatCallbacks = authoredHeartbeatCallbacks,
		measurement = "Source callback inventory only. Client update connections, rates, allocations and cleanup require EffectLifecycle/EffectDeath diagnostics in Play.",
		editLoopActive = false,
	},
	boundary = "Comparable native Edit hierarchy inventory for archived M02 and current M04. Art shadows, finite and unlimited GUI classes/distances, lights and particle emitters are counted directly. Source retains a bounded client cosmetic Heartbeat; this is not zero per-frame artwork work. No callback timing, draw calls, FPS, device memory, startup latency, batching or player performance claim. No instance mutation, camera/computer control, stored data or publication.",
}
shared.KCP3M04CostAudit01 = receipt
return Http:JSONEncode(receipt)
