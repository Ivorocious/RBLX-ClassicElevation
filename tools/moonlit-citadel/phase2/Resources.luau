local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local base = "docs/artifacts/moonlit-citadel/"
local baselinePath = process.args[3] or base .. "phase2/MC_P2_C01_R01_native.rbxm"
local inputPath = process.args[1] or baselinePath
local outputPath = process.args[2] or inputPath:gsub("%.rbxm$", "_resources.json")
assert(outputPath ~= inputPath and outputPath ~= baselinePath, "Output must not replace a native model")
local libraryPath = base .. "phase1/MC_BL02_library_native.rbxm"
local samplePath = base .. "phase1/MC_BL02_R04_native.rbxm"
local manifestPath = "assets/moonlit_citadel/bl02/manifest.json"
local manifestBytes = fs.readFile(manifestPath)
local manifest = serde.decode("json", manifestBytes)
local buildReceipt = serde.decode("json", fs.readFile("assets/moonlit_citadel/bl02/build_receipt.json"))
local uploadReceipt = serde.decode("json", fs.readFile("assets/moonlit_citadel/bl02/upload_receipt.json"))
local libraryReceipt = serde.decode("json", fs.readFile(libraryPath .. ".receipt.json"))
local libraryBytes = fs.readFile(libraryPath)
local library = roblox.deserializeModel(libraryBytes)[1]
assert(serde.hash("sha256", libraryBytes) == libraryReceipt.sha256, "Native library hash differs from its receipt")
assert(serde.hash("sha256", manifestBytes) == buildReceipt.files["manifest.json"].sha256, "Manifest hash differs from its build receipt")
assert(uploadReceipt.state == "complete" and tostring(uploadReceipt.assetId) == "138009529483104", "Approved BL02 upload receipt required")
assert(uploadReceipt.sha256 == buildReceipt.files["MC_BL02_library.fbx"].sha256, "Uploaded FBX differs from build receipt")
assert(serde.hash("sha256", fs.readFile("assets/moonlit_citadel/bl02/MC_BL02_library.fbx")) == uploadReceipt.sha256, "FBX hash differs from upload receipt")
assert(library:GetAttribute("ImportVerified") == true and library:GetAttribute("SourceSHA256") == uploadReceipt.sha256, "Native import provenance differs")
assert(tostring(library:GetAttribute("OpenCloudAssetId")) == tostring(uploadReceipt.assetId), "Native import asset ID differs")

local function property(instance, legacy, current)
	local ok, value = pcall(function() return instance[legacy] end)
	if not ok and current then ok, value = pcall(function() return instance[current] end) end
	return if ok then value else nil
end

local function contentId(value)
	if value == nil then return nil end
	local raw = tostring(value)
	if raw == "" or raw:find("Content(None)", 1, true) then return nil end
	local asset = raw:match("rbxassetid://(%d+)") or raw:match("[?&]id=(%d+)")
	return if asset then "rbxassetid://" .. asset else raw
end

local function meshId(part)
	return contentId(property(part, "MeshId", "MeshContent")) or ""
end

local function key(asset, material)
	return asset .. "|" .. material
end

local assetTriangles, exports, expectedByAsset = {}, {}, {}
for _, asset in manifest.assets do
	assert(assetTriangles[asset.asset] == nil, "Duplicate manifest asset")
	assetTriangles[asset.asset] = asset.geometry.triangles
end
for _, part in manifest.export_parts do
	local partKey = key(part.asset, part.material)
	assert(exports[partKey] == nil and assetTriangles[part.asset], "Duplicate or unknown export component")
	exports[partKey] = part
	expectedByAsset[part.asset] = expectedByAsset[part.asset] or {}
	expectedByAsset[part.asset][partKey] = true
end
for asset, expected in expectedByAsset do
	local triangles = 0
	for partKey in expected do triangles += exports[partKey].triangles end
	assert(triangles == assetTriangles[asset], asset .. " component sum differs from asset geometry")
end

local meshMapping, knownMeshIds, componentCount = {}, {}, 0
for _, unit in library:GetChildren() do
	local asset = unit:GetAttribute("MCEditUnit")
	assert(typeof(asset) == "string" and assetTriangles[asset], "Unknown native library edit unit")
	for _, part in unit:GetDescendants() do
		if not part:IsA("MeshPart") then continue end
		local partKey = key(part:GetAttribute("SourceAsset"), part:GetAttribute("SourceMaterial"))
		local expected = assert(exports[partKey], "Unknown native library component")
		assert(expected.asset == asset and expected.name == part.Name and not meshMapping[partKey], "Native library component overcount or identity mismatch")
		local id = meshId(part)
		assert(id ~= "", "Library mesh has no readable identity")
		meshMapping[partKey] = { meshId = id, asset = asset, material = expected.material, name = expected.name, triangles = expected.triangles }
		knownMeshIds[id] = true
		componentCount += 1
	end
end
for partKey in exports do assert(meshMapping[partKey], "Native library is missing " .. partKey) end
assert(componentCount == #manifest.export_parts, "Native library component count differs from manifest")

local function nearestUnit(instance, root)
	local ancestor = instance.Parent
	while ancestor and ancestor ~= root do
		if typeof(ancestor:GetAttribute("MCEditUnit")) == "string" then return ancestor end
		ancestor = ancestor.Parent
	end
	return nil
end

local function increment(counts, name)
	counts[name] = (counts[name] or 0) + 1
end

local function uniqueCount(values)
	local count = 0
	for _ in values do count += 1 end
	return count
end

local function audit(path, scope)
	local bytes = fs.readFile(path)
	local model = assert(roblox.deserializeModel(bytes)[1], "Missing native root")
	local report = {path = path, sha256 = serde.hash("sha256", bytes), root = model.Name,
		candidate = model:GetAttribute("CandidateId"), scope = scope, counts = {
			descendants = #model:GetDescendants(), baseParts = 0, meshParts = 0, colliders = 0,
			touchParts = 0, queryParts = 0, visibleParts = 0, invisibleParts = 0, unanchoredParts = 0,
			shadowFlags = 0, visibleShadowCasters = 0, invisibleShadowFlags = 0,
			lights = 0, enabledLights = 0, shadowedLights = 0, enabledShadowedLights = 0,
			placedTriangles = 0, editUnits = 0,
		}, materials = {}, meshIds = {}, textureIds = {}, assets = {}, issues = {}, unknownMeshIds = {}, visibleShadowsByAsset = {}}
	local units = {}
	local function issue(reason, instance)
		table.insert(report.issues, {reason = reason, path = instance:GetFullName()})
	end
	local function texture(value)
		local id = contentId(value)
		if id then increment(report.textureIds, id) end
	end
	for _, instance in model:GetDescendants() do
		local editUnit = instance:GetAttribute("MCEditUnit")
		if typeof(editUnit) == "string" then
			report.counts.editUnits += 1
			units[instance] = {asset = editUnit, parts = {}}
			if not assetTriangles[editUnit] then issue("Unknown MCEditUnit", instance) end
			report.assets[editUnit] = report.assets[editUnit] or {placements = 0, meshParts = 0, placedTriangles = 0}
			report.assets[editUnit].placements += 1
		end
	end
	for _, instance in model:GetDescendants() do
		local counts = report.counts
		if instance:IsA("BasePart") then
			counts.baseParts += 1
			if instance.CanCollide then counts.colliders += 1 end
			if instance.CanTouch then counts.touchParts += 1 end
			if instance.CanQuery then counts.queryParts += 1 end
			if not instance.Anchored then counts.unanchoredParts += 1 end
			local visible = instance.Transparency < 1
			if visible then counts.visibleParts += 1 else counts.invisibleParts += 1 end
			increment(report.materials, tostring(instance.Material))
			if instance.CastShadow then
				counts.shadowFlags += 1
				if visible then
					counts.visibleShadowCasters += 1
					increment(report.visibleShadowsByAsset, tostring(instance:GetAttribute("SourceAsset") or "Native contacts/scenery"))
				else counts.invisibleShadowFlags += 1 end
			end
		end
		if instance:IsA("MeshPart") then
			counts.meshParts += 1
			local id = meshId(instance)
			increment(report.meshIds, id)
			texture(property(instance, "TextureID", "TextureContent"))
			if not knownMeshIds[id] then table.insert(report.unknownMeshIds, {meshId = id, path = instance:GetFullName()}) end
			local unit = nearestUnit(instance, model)
			if not unit then issue("Mesh is outside an MCEditUnit", instance); continue end
			local record = units[unit]
			local sourceAsset, sourceMaterial = instance:GetAttribute("SourceAsset"), instance:GetAttribute("SourceMaterial")
			if typeof(sourceAsset) ~= "string" or typeof(sourceMaterial) ~= "string" then issue("Mesh has no component provenance", instance); continue end
			local partKey = key(sourceAsset, sourceMaterial)
			increment(record.parts, partKey)
			local mapped = meshMapping[partKey]
			if not mapped or mapped.asset ~= record.asset or mapped.meshId ~= id or mapped.name ~= instance.Name then
				issue("Mesh component or MeshID differs from verified library", instance)
				continue
			end
			counts.placedTriangles += mapped.triangles
			local asset = report.assets[record.asset]
			asset.meshParts += 1
			asset.placedTriangles += mapped.triangles
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			texture(property(instance, "Texture", "TextureContent"))
		elseif instance:IsA("SurfaceAppearance") then
			for _, name in {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"} do texture(property(instance, name, name .. "Content")) end
		end
		if instance:IsA("Light") then
			counts.lights += 1
			if instance.Enabled then counts.enabledLights += 1 end
			if instance.Shadows then counts.shadowedLights += 1 end
			if instance.Enabled and instance.Shadows then counts.enabledShadowedLights += 1 end
		end
	end
	for unit, record in units do
		for partKey in expectedByAsset[record.asset] or {} do
			if record.parts[partKey] ~= 1 then issue("Component missing or overcounted: " .. partKey, unit) end
		end
		for partKey in record.parts do
			if not (expectedByAsset[record.asset] or {})[partKey] then issue("Unexpected unit component: " .. partKey, unit) end
		end
	end
	local weighted = 0
	for asset, record in report.assets do
		record.weightedManifestTriangles = (assetTriangles[asset] or 0) * record.placements
		weighted += record.weightedManifestTriangles
	end
	report.counts.weightedManifestTriangles = weighted
	report.counts.uniqueMeshes, report.counts.uniqueTextures, report.counts.uniqueMaterials = uniqueCount(report.meshIds), uniqueCount(report.textureIds), uniqueCount(report.materials)
	report.triangleMappingComplete = #report.issues == 0 and #report.unknownMeshIds == 0 and weighted == report.counts.placedTriangles
	report.triangleScope = "Placed imported MeshPart geometry only; native primitives, collision hulls, renderer LOD and FPS are excluded. If mapping is incomplete, placedTriangles is a known-component subtotal."
	return report
end

local course = audit(inputPath, "Complete Phase 2 course")
local baseline = if inputPath == baselinePath then course else audit(baselinePath, "Complete Phase 2 baseline")
assert(course.candidate:match("^MC_P2_") and baseline.candidate:match("^MC_P2_"), "Inputs must be Phase 2 complete-course candidates")
local delta = {}
for name, value in course.counts do delta[name] = value - baseline.counts[name] end
local result = {
	input = course, completeCourseBaseline = baseline, completeCourseDelta = delta,
	phase1SampleSeparate = audit(samplePath, "Phase 1 asset/traversal sample; not a complete-course baseline"),
	verifiedLibrary = {path = libraryPath, sha256 = libraryReceipt.sha256, sourceFBXSha256 = uploadReceipt.sha256,
		assetId = uploadReceipt.assetId, creatorUserId = uploadReceipt.request.creationContext.creator.userId,
		manifestPath = manifestPath, manifestSha256 = serde.hash("sha256", manifestBytes),
		componentCount = componentCount, unitCount = #library:GetChildren(), meshMapping = meshMapping},
	libraryInventory = audit(libraryPath, "Verified reusable library; not placed course geometry"),
	limits = "Saved native models only. No new Studio physics, multiplayer, device, rendering or timing evidence. Complete-course deltas compare Phase 2 inputs only; the Phase 1 sample is listed separately.",
}
fs.writeFile(outputPath, serde.encode("json", result, true))
print(serde.encode("json", {output = outputPath, candidate = course.candidate, counts = course.counts,
	mappingComplete = course.triangleMappingComplete, issues = #course.issues, unknownMeshIds = #course.unknownMeshIds, delta = delta}))
