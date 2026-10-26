local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase3/work-m03/"
local frozenNative = "docs/artifacts/keyboard-circuit/phase3/KC_P3_M02_01_Native.rbxm"
local output = prefix .. "ResourceStudy01.json"
local compiled = {}
for _, file in {"PresentationBudget.luau", "Wayfinding.luau"} do
	luau.load(fs.readFile(prefix .. "sources/" .. file), {debugName = file})
	table.insert(compiled, file)
end
local environment = {}
for key, value in roblox do environment[key] = value end
local budget = luau.load(fs.readFile(prefix .. "sources/PresentationBudget.luau"), {environment = environment})()
local course = roblox.deserializeModel(fs.readFile(frozenNative))[1]
local before, guis = {}, {}
local originalCounts = {parts = 0, pressTargets = 0, colliders = 0, queryParts = 0, touchParts = 0, shadowParts = 0, artParts = 0}
for _, item in course:GetDescendants() do
	if item:IsA("BasePart") then
		before[item] = {pose = item.CFrame, size = item.Size, anchored = item.Anchored, collide = item.CanCollide, query = item.CanQuery, touch = item.CanTouch, color = item.Color, transparency = item.Transparency, material = item.Material, attributes = item:GetAttributes(), shadow = item.CastShadow}
		originalCounts.parts += 1
		if item:GetAttribute("Pressable") then originalCounts.pressTargets += 1 end
		if item:GetAttribute("MapArtwork") then originalCounts.artParts += 1 end
		if item.CanCollide then originalCounts.colliders += 1 end
		if item.CanQuery then originalCounts.queryParts += 1 end
		if item.CanTouch then originalCounts.touchParts += 1 end
		if item.CastShadow then originalCounts.shadowParts += 1 end
	elseif item:IsA("SurfaceGui") then
		local parent = item.Adornee or item.Parent
		table.insert(guis, {gui = item, oldDistance = item.MaxDistance, enabled = item.Enabled, part = parent, position = if parent and parent:IsA("BasePart") then parent.CFrame.Position else nil})
	end
end
local study = serde.decode("json", fs.readFile("docs/artifacts/keyboard-circuit/phase3/P3-M02-label-distance-study-01.json"))
local function eligibility(): {any}
	local samples = {}
	for _, sample in study.samples do
		local eye = roblox.Vector3.new(table.unpack(sample.position))
		local allBefore, allAfter, enabledBefore, enabledAfter, changedBefore, changedAfter = 0, 0, 0, 0, 0, 0
		for _, record in guis do
			if not record.position then continue end
			local distance = (record.position - eye).Magnitude
			local wasEligible = record.oldDistance == 0 or distance <= record.oldDistance
			local isEligible = record.gui.MaxDistance == 0 or distance <= record.gui.MaxDistance
			if wasEligible then allBefore += 1 end
			if isEligible then allAfter += 1 end
			if wasEligible and record.enabled then enabledBefore += 1 end
			if isEligible and record.enabled then enabledAfter += 1 end
			if record.oldDistance ~= record.gui.MaxDistance then
				if wasEligible then changedBefore += 1 end
				if isEligible then changedAfter += 1 end
			end
		end
		table.insert(samples, {origin = sample.origin, position = sample.position, allBefore = allBefore, allAfter = allAfter, enabledBefore = enabledBefore, enabledAfter = enabledAfter, changedBefore = changedBefore, changedAfter = changedAfter})
	end
	return samples
end
local report = budget.Apply(course)
local assertions, preservedWarnings, preservedCriticalPanels, changedShadows = 0, 0, 0, 0
local shadowSections = {}
for part, state in before do
	assert(part.CFrame == state.pose and part.Size == state.size and part.Color == state.color and part.Transparency == state.transparency and part.Material == state.material, "Visible gameplay geometry changed: " .. part.Name)
	assert(part.Anchored == state.anchored and part.CanCollide == state.collide and part.CanQuery == state.query and part.CanTouch == state.touch, "Gameplay physics changed: " .. part.Name)
	for name, value in state.attributes do assert(part:GetAttribute(name) == value, "Gameplay attribute changed: " .. part.Name .. "." .. name) end
	for name in part:GetAttributes() do assert(state.attributes[name] ~= nil, "Gameplay attribute added: " .. part.Name .. "." .. name) end
	if part.CastShadow ~= state.shadow then
		assert(part:GetAttribute("MapArtwork") and not part:GetAttribute("Pressable") and not part.CanCollide and not part.CanQuery and not part.CanTouch, "Unsafe shadow change")
		changedShadows += 1
		local section = part
		while section.Parent and section.Parent ~= course.MapEnvironment do section = section.Parent end
		shadowSections[section.Name] = (shadowSections[section.Name] or 0) + 1
	end
	assertions += 3
end
for _, record in guis do
	local gui, part = record.gui, record.part
	assert(gui.Enabled == record.enabled, "GUI availability changed")
	if gui.Name == "HazardDisplay" or (part and part:GetAttribute("Role") == "Lethal") then
		assert(gui.MaxDistance == record.oldDistance, "Critical warning distance changed")
		preservedWarnings += 1
	end
	if gui:IsDescendantOf(course.MapEnvironment.Wayfinding) then
		assert(gui.MaxDistance == record.oldDistance, "Checkpoint distance changed")
		preservedCriticalPanels += 1
	end
end
local second = budget.Apply(course)
assert(second.boundedGuis == 0 and second.disabledArtShadows == 0, "Applying the budget twice changed its result")
roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * (model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset):Inverse()
	for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end end
end)
local placements = luau.load(fs.readFile(prefix .. "sources/WarningPlacements.luau"), {environment = environment})()
placements.Apply(course, roblox.Vector3.new(2222, 330, -1158))
local warningStacks = {}
for _, sign in course.MapEnvironment.HazardIndicators:GetChildren() do
	if sign:GetAttribute("IndicatorKind") ~= "Foundry" and sign:GetAttribute("IndicatorKind") ~= "Domino" then continue end
	local host = sign.SourceMechanism.Value.EntryBank.BankContact
	local eye = host.CFrame.Position + roblox.Vector3.new(0, host.Size.Y / 2 + .45 + 4.5, 0)
	local delta = sign.PrimaryPart.CFrame.Position - eye
	local horizontal = math.sqrt(delta.X * delta.X + delta.Z * delta.Z)
	table.insert(warningStacks, {name = sign.Name, safeBankEye = {eye.X, eye.Y, eye.Z}, heightAboveEye = delta.Y, horizontalDistance = horizontal, upwardAngleDegrees = math.deg(math.atan2(delta.Y, horizontal)), distance = delta.Magnitude})
end
table.sort(warningStacks, function(a, b) return a.name < b.name end)
local results = {
	status = "passed",
	compiled = compiled,
	frozenNativeSha256 = serde.hash("sha256", fs.readFile(frozenNative)),
	limits = budget.Limits,
	beforeCounts = originalCounts,
	budget = report,
	changedShadows = changedShadows,
	shadowSavingsBySection = shadowSections,
	preservedWarningGuis = preservedWarnings,
	preservedCheckpointGuis = preservedCriticalPanels,
	geometryAndPhysicsAssertions = assertions,
	distanceEligibilitySamples = eligibility(),
	preservedWarningStackStudy = warningStacks,
	boundary = "Offline application to the frozen native M02 copy. Positions are the eight native recovery eye points used by Ideation. Counts include all configured SurfaceGuis; enabled counts exclude intentionally disabled joined-cap GUI. Distances use GUI host centers only, excluding camera offsets, face angle, frustum, occlusion, rendering, readability and device/FPS measurements. M03 archive/effect additions are not included; final native integration must measure them separately.",
}
fs.writeFile(output, serde.encode("json", results, true))
print(serde.encode("json", {status = results.status, budget = report, unchangedPhysicalParts = originalCounts.parts, output = output}, true))
