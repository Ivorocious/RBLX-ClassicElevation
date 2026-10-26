local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local manifest = serde.decode("json", fs.readFile(assert(process.args[1], "Provide a Phase2 readback manifest JSON")))
local candidate = assert(manifest.candidate)
local output = assert(manifest.output):gsub("\\", "/")
assert(output:match("^docs/artifacts/moonlit%-citadel/phase2/") and not output:find("%.%."), "Output must stay in the Phase2 evidence directory")
assert(not fs.isFile(output), "Preserve earlier readback results; choose a fresh output name")
local hashes = {}
local byteCounts = {}
assert(manifest.sources and #manifest.sources > 0, "Supply the saved-to-durable source mappings")
local function read(path)
	local bytes = fs.readFile(path)
	local hash = serde.hash("sha256", bytes)
	hashes[path] = hash
	byteCounts[path] = #bytes
	if manifest.hashes and manifest.hashes[path] then assert(manifest.hashes[path] == hash, "Frozen file hash changed: " .. path) end
	return bytes
end
local function at(root, path)
	for name in string.gmatch(path or "", "[^/]+") do root = assert(root:FindFirstChild(name), "Missing saved instance " .. path) end
	return root
end
local function model(path, rootPath)
	local roots = roblox.deserializeModel(read(path))
	assert(#roots == 1, "Expected one native root in " .. path)
	return at(roots[1], rootPath)
end
local native = model(assert(manifest.nativeModel), manifest.nativeRootPath)
local library = model(assert(manifest.library), manifest.libraryRootPath)
local place = roblox.deserializePlace(read(assert(manifest.standalone)))
local savedCourse = at(place, manifest.standaloneCoursePath or "Workspace/RaceCourse")
local fresh = model(assert(manifest.freshModel), manifest.freshRootPath)
local libraryCourse = at(library, assert(manifest.libraryCoursePath, "Name the actual saved library course"))
for _, root in {native, savedCourse, fresh, libraryCourse} do
	assert(root:GetAttribute("CandidateId") == candidate, "Saved candidate mismatch " .. root:GetFullName())
	assert(root:GetAttribute("CourseId") == "moonlit_citadel", "Wrong saved course ID")
end
local rootNormalizationReceipt = {}
for label, root in {native = native, fresh = fresh, standalone = savedCourse, library = libraryCourse} do
	local editableMarker = root:GetAttribute("ManualEditing")
	local expectedMarker = if manifest.rootMarkerExpectations then manifest.rootMarkerExpectations[label] else (if label == "standalone" then true else nil)
	assert(expectedMarker == nil or expectedMarker == true, "Only absent or explicitly true root markers may be declared")
	assert(editableMarker == expectedMarker, "Unexpected editable recovery root marker in " .. label)
	assert(root:GetAttribute("RuntimeActiveCourse") == nil, "Saved course retains an active runtime marker in " .. label)
	assert(root:GetAttribute("SourceCourseId") == nil, "Saved course retains a runtime source marker in " .. label)
	rootNormalizationReceipt[label] = {originalRootName = root.Name, manualEditingPresent = editableMarker ~= nil,
		manualEditingTrue = editableMarker == true, runtimeActiveCourseAbsent = true, sourceCourseIdAbsent = true,
		normalizedRootName = "ReadbackRoot", normalizeManualEditing = expectedMarker == true}
end
local function relative(item, root)
	local names = {}
	while item ~= root do
		local ordinal = 0
		for _, sibling in item.Parent:GetChildren() do
			if sibling.Name == item.Name and sibling.ClassName == item.ClassName then ordinal += 1 end
			if sibling == item then break end
		end
		table.insert(names, 1, item.Name .. "#" .. ordinal)
		item = item.Parent
	end
	return table.concat(names, "/")
end
local function index(root)
	local indexed = {}
	for _, item in root:GetDescendants() do indexed[relative(item, root)] = item end
	return indexed
end
local function near(a, b, tolerance, path)
	assert(math.abs(a - b) <= tolerance, "Pose/size mismatch " .. path .. ": " .. tostring(a) .. " / " .. tostring(b))
end
local function contentId(instance, legacy, current)
	local ok, value = pcall(function() return instance[legacy] end)
	if not ok then ok, value = pcall(function() return instance[current] end) end
	if not ok or value == nil then return "" end
	local raw = tostring(value)
	if raw == "" or raw:find("Content(None)", 1, true) then return "" end
	local asset = raw:match("rbxassetid://(%d+)") or raw:match("[?&]id=(%d+)")
	return if asset then "rbxassetid://" .. asset else raw
end
local fidelityCache = {}
local fidelityReads = {method = "Lune XML serializer RenderFidelity token and exact stored collision data", instances = 0,
	tokens = {}, getterErrors = {}, collisionFidelityEnumReadable = true, exactStoredCollisionData = true}
local function fidelity(instance, property)
	local values = fidelityCache[instance]
	if not values then
		-- CollisionFidelity may be derived by Studio; compare its stored collision data without guessing an enum.
		local xml = roblox.serializeModel({instance}, true)
		assert(xml:match('<Item class="([^"]+)"') == "MeshPart", "Serialized fidelity root is not a MeshPart")
		local properties = assert(xml:match("<Properties>(.-)</Properties>"), "Missing serialized MeshPart properties")
		values = {}
		for _, name in {"CollisionFidelity", "RenderFidelity"} do
			local raw = properties:match('<token name="' .. name .. '">(%d+)</token>')
			local ok, converted = pcall(function() return instance[name] end)
			if raw then
				values[name] = "token:" .. raw
				if ok then assert(converted.Value == tonumber(raw), "Serialized token and readable enum disagree: " .. name) end
			elseif name == "CollisionFidelity" then
				local physics = properties:match('<BinaryString name="PhysicsData">(.-)</BinaryString>')
				local physical = properties:match('<SharedString name="PhysicalConfigData">(.-)</SharedString>')
				assert(physics or physical, "No stored collision representation for " .. instance:GetFullName())
				local payload = "absent"
				if physical then
					local escaped = physical:gsub("(%W)", "%%%1")
					payload = assert(xml:match('<SharedString md5="' .. escaped .. '">(.-)</SharedString>'), "Missing physical configuration shared string")
				end
				values[name] = "stored-collision:" .. (physics or "absent"):gsub("%s", "") .. ":" .. payload:gsub("%s", "")
				if ok then values[name] ..= ":enum:" .. tostring(converted.Value) end
			else
				error("Missing stored RenderFidelity token " .. instance:GetFullName())
			end
			if not ok then
				fidelityReads.getterErrors[name] = tostring(converted)
				if name == "CollisionFidelity" then fidelityReads.collisionFidelityEnumReadable = false end
			end
			local histogram = fidelityReads.tokens[name] or {}
			local token = raw or "stored collision data; no serialized enum"
			histogram[token] = (histogram[token] or 0) + 1
			fidelityReads.tokens[name] = histogram
		end
		fidelityReads.instances += 1
		fidelityCache[instance] = values
	end
	return values[property]
end
local serializationCache = {}
local serializationDifferences = {}
local serializerNormalizationReceipt = {}
local function normalizedSerialization(root)
	if not serializationCache[root] then
		local serializedRoot = root
		if (root == native or root == fresh or root == savedCourse or root == libraryCourse) and root:GetAttribute("ManualEditing") == true then
			serializedRoot = root:Clone()
			serializedRoot:SetAttribute("ManualEditing", nil)
		end
		local originalXml = roblox.serializeModel({serializedRoot}, true)
		-- Use the same binary CFrame codec on both inputs, retaining the independent numeric pose checks.
		local canonicalRoots = roblox.deserializeModel(roblox.serializeModel({serializedRoot}))
		assert(#canonicalRoots == 1, "Unexpected canonical root count")
		local xml = roblox.serializeModel(canonicalRoots, true)
		local normalized, replacements = xml:gsub('<string name="Name">.-</string>', '<string name="Name">ReadbackRoot</string>', 1)
		assert(replacements == 1, "Missing serialized root name")
		serializationCache[root] = normalized
		serializerNormalizationReceipt[root] = {originalXmlSha256 = serde.hash("sha256", originalXml),
			binaryRoundtripXmlSha256 = serde.hash("sha256", xml), originalXmlBytes = #originalXml, binaryRoundtripXmlBytes = #xml,
			binaryCodecChangedRepresentation = originalXml ~= xml}
	end
	return serializationCache[root]
end
local function compare(expected, actual, label)
	local left, right = index(expected), index(actual)
	local counts = {instances = 0, parts = 0, meshes = 0, sources = 0}
	for path, a in left do
		local b = assert(right[path], "Missing " .. label .. "/" .. path)
		assert(a.ClassName == b.ClassName, "Class mismatch " .. path)
		counts.instances += 1
		for _, attribute in manifest.identityAttributes or {"Role", "CourseId", "CandidateId", "CheckpointIndex", "SourceAsset", "SourceMaterial"} do
			assert(a:GetAttribute(attribute) == b:GetAttribute(attribute), "Attribute mismatch " .. attribute .. ": " .. path)
		end
		if a:IsA("BasePart") then
			counts.parts += 1
			local av, bv = {a.CFrame:GetComponents()}, {b.CFrame:GetComponents()}
			for i = 1, 12 do near(av[i], bv[i], 0.0001, path) end
			for _, axis in {"X", "Y", "Z"} do near(a.Size[axis], b.Size[axis], 0.0001, path) end
			for _, property in {"Anchored", "CanCollide", "CanTouch", "CanQuery", "CollisionGroup", "Transparency", "Material", "Color", "CastShadow"} do
				assert(a[property] == b[property], "Property mismatch " .. property .. ": " .. path)
			end
			if a:IsA("MeshPart") then
				counts.meshes += 1
				local leftMesh, rightMesh = contentId(a, "MeshId", "MeshContent"), contentId(b, "MeshId", "MeshContent")
				assert(leftMesh ~= "" and leftMesh == rightMesh, "Mesh content mismatch " .. path)
				assert(contentId(a, "TextureID", "TextureContent") == contentId(b, "TextureID", "TextureContent"), "Texture content mismatch " .. path)
				for _, property in {"CollisionFidelity", "RenderFidelity"} do
					assert(fidelity(a, property) == fidelity(b, property), "Mesh mismatch " .. property .. ": " .. path)
				end
			end
		elseif a:IsA("LuaSourceContainer") then
			counts.sources += 1
			assert(a.Source:gsub("\r\n", "\n") == b.Source:gsub("\r\n", "\n"), "Embedded source mismatch " .. path)
			assert(luau.load(b.Source), "Saved source parse failed " .. path)
		elseif a:IsA("ObjectValue") then
			assert((a.Value == nil) == (b.Value == nil), "Object link presence mismatch " .. path)
			if a.Value then assert(relative(a.Value, expected) == relative(b.Value, actual), "Object link target mismatch " .. path) end
		elseif a:IsA("Light") then
			for _, property in {"Color", "Brightness", "Shadows", "Enabled", "Range"} do
				assert(a[property] == b[property], "Light mismatch " .. property .. ": " .. path)
			end
		end
		right[path] = nil
	end
	assert(next(right) == nil, "Extra saved instances in " .. label)
	local leftXml, rightXml = normalizedSerialization(expected), normalizedSerialization(actual)
	if leftXml ~= rightXml then
		local firstDifference = 1
		while firstDifference <= math.min(#leftXml, #rightXml) and leftXml:byte(firstDifference) == rightXml:byte(firstDifference) do firstDifference += 1 end
		table.insert(serializationDifferences, {passed = false, label = label,
			leftSha256 = serde.hash("sha256", leftXml), rightSha256 = serde.hash("sha256", rightXml), firstDifference = firstDifference,
			leftContext = leftXml:sub(math.max(1, firstDifference - 300), firstDifference + 500),
			rightContext = rightXml:sub(math.max(1, firstDifference - 300), firstDifference + 500)})
	end
	counts.normalizedSerializedSha256 = serde.hash("sha256", leftXml)
	counts.actualNormalizedSerializedSha256 = serde.hash("sha256", rightXml)
	counts.fullNormalizedSerializedTreeMatches = leftXml == rightXml
	counts.serializerNormalization = {expected = serializerNormalizationReceipt[expected], actual = serializerNormalizationReceipt[actual]}
	return counts
end
local comparisons = {native = compare(fresh, native, "native"), standalone = compare(native, savedCourse, "standalone"),
	library = compare(native, libraryCourse, "library")}
local previousCandidateChanges
if manifest.previousNativeModel then
	local previous = model(manifest.previousNativeModel, manifest.previousNativeRootPath)
	assert(previous:GetAttribute("CandidateId") == candidate and previous:GetAttribute("CourseId") == "moonlit_citadel", "Previous native candidate differs")
	assert(previous:GetAttribute("ManualEditing") == nil and previous:GetAttribute("RuntimeActiveCourse") == nil and previous:GetAttribute("SourceCourseId") == nil, "Previous native root has unexpected wrapper/runtime markers")
	local adjusted = previous:Clone()
	local changes = {}
	for _, stage in {"Lower", "Upper"} do
		for bay = 1, 2 do
			local path = "Obstacles/" .. stage .. "Mechanism/OutboardWeight" .. bay .. "/WeightContact"
			local before, expected, actual = at(previous, path), at(adjusted, path), at(native, path)
			assert(before:IsA("BasePart") and before.CanCollide == true and actual.CanCollide == false, "Expected one counterweight collider-to-visual change " .. path)
			assert(before:GetAttribute("Role") == "SolidBlocker" and actual:GetAttribute("Role") == "CounterweightVisual", "Unexpected counterweight role change " .. path)
			table.insert(changes, {path = path, property = "CanCollide", before = true, after = false})
			table.insert(changes, {path = path, attribute = "Role", before = before:GetAttribute("Role"), after = actual:GetAttribute("Role")})
			expected.CanCollide = false
			expected:SetAttribute("Role", "CounterweightVisual")
		end
	end
	local unchangedSurfaces = 0
	local previousIndex, nativeIndex = index(previous), index(native)
	for path, item in previousIndex do
		if item:IsA("BasePart") and item:GetAttribute("MCWalkable") == true then
			local other = assert(nativeIndex[path], "Walkable surface missing " .. path)
			assert(other:GetAttribute("MCWalkable") == true, "Walkable marker changed " .. path)
			unchangedSurfaces += 1
		end
	end
	assert(unchangedSurfaces == 432, "Expected all 432 original native walkable surfaces")
	previousCandidateChanges = {allowedChanges = changes, changedInstances = 4, changedFields = #changes, unchangedWalkableSurfaces = unchangedSurfaces,
		comparison = compare(adjusted, native, "previous-native-exact-four-weight-changes"), previousRootName = previous.Name,
		previousManualEditingAbsent = true, currentManualEditingTrue = native:GetAttribute("ManualEditing") == true,
		normalization = "Only the four explicitly checked WeightContact CanCollide and Role values are changed in an in-memory previous-native clone before strict full-tree comparison; saved inputs are never changed"}
end
local preservedCourses = {}
if manifest.preservedLibrary then
	local previous = model(manifest.preservedLibrary, manifest.preservedLibraryRootPath)
	assert(manifest.preservedCoursePaths and #manifest.preservedCoursePaths > 0, "Name the exact library courses to preserve")
	for _, path in manifest.preservedCoursePaths do
		preservedCourses[path] = compare(at(previous, path), at(library, path), "preserved-library/" .. path)
	end
end
local preservedAssets = {}
if manifest.preservedAssetModel then
	local original = model(manifest.preservedAssetModel, manifest.preservedAssetRootPath)
	local saved = at(place, assert(manifest.savedAssetPath, "Name the preserved native asset library path"))
	assert(original.Name == saved.Name, "Preserved native asset library root name changed")
	preservedAssets[manifest.savedAssetPath] = compare(original, saved, "preserved-phase1-asset-library")
end
local sources = {}
for _, entry in manifest.sources or {} do
	local saved = at(place, entry.instancePath)
	assert(saved:IsA("LuaSourceContainer"), "Source check points at a non-script")
	local durable = read(entry.sourcePath)
	if entry.sha256 then assert(hashes[entry.sourcePath] == entry.sha256, "Source mapping hash changed " .. entry.sourcePath) end
	assert(saved.Source:gsub("\r\n", "\n") == durable:gsub("\r\n", "\n"), "Saved source does not match durable file " .. entry.sourcePath)
	assert(luau.load(saved.Source), "Saved script does not compile " .. entry.instancePath)
	table.insert(sources, {instancePath = entry.instancePath, sourcePath = entry.sourcePath, sha256 = hashes[entry.sourcePath]})
end
local counts = {descendants = #native:GetDescendants(), baseParts = 0, meshParts = 0, colliders = 0, lights = 0,
	shadowedLights = 0, visibleShadowCasters = 0, materials = {}, meshIds = {}, textureIds = {}}
for _, item in native:GetDescendants() do
	if item:IsA("BasePart") then
		counts.baseParts += 1
		if item.CanCollide then counts.colliders += 1 end
		if item.Transparency < 1 and item.CastShadow then counts.visibleShadowCasters += 1 end
		counts.materials[tostring(item.Material)] = (counts.materials[tostring(item.Material)] or 0) + 1
	end
	if item:IsA("MeshPart") then
		counts.meshParts += 1
		local mesh, texture = contentId(item, "MeshId", "MeshContent"), contentId(item, "TextureID", "TextureContent")
		assert(mesh ~= "", "Saved mesh has no readable content identity")
		counts.meshIds[mesh] = (counts.meshIds[mesh] or 0) + 1
		if texture ~= "" then counts.textureIds[texture] = (counts.textureIds[texture] or 0) + 1 end
	end
	if item:IsA("Light") then counts.lights += 1; if item.Shadows then counts.shadowedLights += 1 end end
end
local result = {candidate = candidate, passed = #serializationDifferences == 0, source = manifest.verificationSource or "Saved native/library/standalone deserialize compared with independent fresh builder export",
	hashes = hashes, byteCounts = byteCounts, comparisons = comparisons, preservedCourses = preservedCourses, matchingSources = sources, resources = counts,
	nativeFreshOriginalBytesAgree = hashes[manifest.nativeModel] == hashes[manifest.freshModel] and byteCounts[manifest.nativeModel] == byteCounts[manifest.freshModel],
	meshFidelityVerification = fidelityReads,
	serializationDifferences = serializationDifferences,
	previousCandidateChanges = previousCandidateChanges,
	preservedAssets = preservedAssets,
	referenceModelKind = manifest.referenceModelKind or "independent fresh builder export",
	rootNormalizationReceipt = rootNormalizationReceipt,
	poseToleranceStuds = 0.0001, exactRolesAndProperties = true, savedFileOnly = true,
	rootNameNormalization = "Only course root Name and explicitly declared, validated ManualEditing=true root wrapper markers are normalized. RuntimeActiveCourse and SourceCourseId are validated absent. No descendant or other attribute normalization.",
	serializerNormalization = "Each read-only input subtree uses one identical Lune binary serialize/deserialize pass before full XML comparison. The binary codec can snap near-axis CFrame rotations; original BasePart CFrame and Size components are separately checked within 0.0001. All stored collision data are separately checked exactly without this codec pass.",
	limits = "CollisionFidelity enum cannot be read for every mesh in Lune; exact stored collision data and full normalized serialized trees are compared instead. Does not prove live Rojo agreement, traversal, multiplayer, FPS, human pacing, whole-place save or publication"}
fs.writeFile(output, serde.encode("json", result, true))
print(serde.encode("json", {candidate = candidate, passed = result.passed, output = output, comparisons = comparisons,
	preservedCourses = preservedCourses, matchingSourceCount = #sources, resources = counts, meshFidelityVerification = fidelityReads,
	serializationDifferenceCount = #serializationDifferences}, true))
assert(result.passed, "Full normalized serialized-tree comparison has " .. #serializationDifferences .. " mismatch(es); read the saved report")
