--!strict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Native recovery runs in Edit only")
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P3_M04_01")) :: Model
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")
assert(candidate:GetAttribute("Origin") == Vector3.new(2222, 330, -1158))
local archive = Storage.KeyboardCircuitPhase2Archive
local proofRoot = assert(archive:FindFirstChild("Phase3FinalTuning20261009"))
local durableSources = assert(proofRoot:FindFirstChild("M04Sources01"))
local proofName = "KCP3M04NativeRecovery02"
assert(not proofRoot:FindFirstChild(proofName), "Inspect the existing recovery receipt before retry")

local function relative(model: Instance, item: Instance): string
	return item:GetFullName():sub(#model:GetFullName() + 2)
end

local function numbers(...: number): string
	local values = {...}
	local result = {}
	for _, value in values do table.insert(result, string.format("%.3f", if math.abs(value) < .0005 then 0 else value)) end
	return table.concat(result, ",")
end

local function vector(value: Vector3): string return numbers(value.X, value.Y, value.Z) end
local function color(value: Color3): string return numbers(value.R, value.G, value.B) end
local function dim(value: UDim2): string return numbers(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset) end
local function reference(model: Instance, item: Instance?): string
	if not item then return "nil" end
	return if item:IsDescendantOf(model) then relative(model, item) else "EXTERNAL:" .. item:GetFullName()
end

local function attribute(value: any): string
	if typeof(value) == "CFrame" then return numbers(value:GetComponents()) end
	if typeof(value) == "Vector3" then return vector(value) end
	if typeof(value) == "Vector2" then return numbers(value.X, value.Y) end
	if typeof(value) == "Color3" then return color(value) end
	if typeof(value) == "number" then return numbers(value) end
	if typeof(value) == "NumberRange" then return numbers(value.Min, value.Max) end
	return tostring(value)
end

local function geometry(model: Model): {string}
	local rows = {}
	local objects = model:GetDescendants()
	table.insert(objects, model)
	for _, item in objects do
		local row = item.ClassName .. "|" .. (if item == model then "ROOT" else relative(model, item))
		if item:IsA("BasePart") then
			row ..= "|" .. numbers(item.CFrame:GetComponents()) .. "|" .. numbers(item.PivotOffset:GetComponents()) .. "|" .. vector(item.Size)
			row ..= "|" .. color(item.Color) .. "|" .. numbers(item.Transparency, item.Reflectance) .. "|" .. item.Material.Name .. "|" .. item.MaterialVariant
			row ..= "|" .. tostring(item.Anchored) .. "|" .. tostring(item.CanCollide) .. "|" .. tostring(item.CanTouch) .. "|" .. tostring(item.CanQuery) .. "|" .. tostring(item.CastShadow) .. "|" .. item.CollisionGroup
			if item:IsA("Part") then row ..= "|" .. item.Shape.Name end
			if item:IsA("MeshPart") then row ..= "|" .. item.MeshId .. "|" .. item.TextureID .. "|" .. item.CollisionFidelity.Name .. "|" .. item.RenderFidelity.Name end
		elseif item:IsA("Model") then
			row ..= "|PRIMARY:" .. reference(model, item.PrimaryPart)
		elseif item:IsA("GuiObject") then
			row ..= "|" .. dim(item.Position) .. "|" .. dim(item.Size) .. "|" .. numbers(item.AnchorPoint.X, item.AnchorPoint.Y, item.Rotation)
			row ..= "|" .. color(item.BackgroundColor3) .. "|" .. numbers(item.BackgroundTransparency, item.BorderSizePixel) .. "|" .. color(item.BorderColor3)
			row ..= "|" .. tostring(item.Visible) .. "|" .. tostring(item.ClipsDescendants) .. "|" .. tostring(item.Active) .. "|" .. tostring(item.AutomaticSize) .. "|" .. tostring(item.ZIndex) .. "|" .. tostring(item.LayoutOrder)
			if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
				row ..= "|" .. item.Text .. "|" .. item.Font.Name .. "|" .. item.FontFace.Family .. "|" .. item.FontFace.Weight.Name .. "|" .. item.FontFace.Style.Name
				row ..= "|" .. color(item.TextColor3) .. "|" .. color(item.TextStrokeColor3) .. "|" .. numbers(item.TextSize, item.TextTransparency, item.TextStrokeTransparency, item.LineHeight)
				row ..= "|" .. tostring(item.TextScaled) .. "|" .. tostring(item.TextWrapped) .. "|" .. tostring(item.RichText) .. "|" .. item.TextXAlignment.Name .. "|" .. item.TextYAlignment.Name
			end
		elseif item:IsA("SurfaceGui") then
			row ..= "|" .. tostring(item.Enabled) .. "|" .. item.Face.Name .. "|" .. item.SizingMode.Name .. "|" .. numbers(item.CanvasSize.X, item.CanvasSize.Y)
			row ..= "|" .. numbers(item.PixelsPerStud, item.LightInfluence, item.Brightness, item.ZOffset, item.MaxDistance) .. "|" .. tostring(item.AlwaysOnTop) .. "|" .. tostring(item.ClipsDescendants)
			row ..= "|ADORNEE:" .. reference(model, item.Adornee)
		elseif item:IsA("UITextSizeConstraint") then row ..= "|" .. numbers(item.MinTextSize, item.MaxTextSize)
		elseif item:IsA("UICorner") then row ..= "|" .. numbers(item.CornerRadius.Scale, item.CornerRadius.Offset)
		elseif item:IsA("UIStroke") then row ..= "|" .. color(item.Color) .. "|" .. numbers(item.Transparency, item.Thickness) .. "|" .. item.ApplyStrokeMode.Name .. "|" .. item.LineJoinMode.Name
		elseif item:IsA("ObjectValue") then row ..= "|VALUE:" .. reference(model, item.Value)
		elseif item:IsA("Vector3Value") then row ..= "|" .. vector(item.Value)
		elseif item:IsA("CFrameValue") then row ..= "|" .. numbers(item.Value:GetComponents())
		elseif item:IsA("StringValue") or item:IsA("NumberValue") or item:IsA("IntValue") or item:IsA("BoolValue") then row ..= "|" .. tostring(item.Value)
		elseif item:IsA("Attachment") then row ..= "|" .. numbers(item.CFrame:GetComponents())
		elseif item:IsA("Constraint") then
			row ..= "|" .. tostring(item.Enabled) .. "|" .. tostring(item.Visible) .. "|A0:" .. reference(model, item.Attachment0) .. "|A1:" .. reference(model, item.Attachment1)
			if item:IsA("PrismaticConstraint") then
				row ..= "|" .. item.ActuatorType.Name .. "|" .. tostring(item.LimitsEnabled) .. "|" .. numbers(item.LowerLimit, item.UpperLimit, item.TargetPosition, item.Speed, item.ServoMaxForce, item.MotorMaxForce, item.LinearResponsiveness)
			elseif item:IsA("HingeConstraint") then
				row ..= "|" .. item.ActuatorType.Name .. "|" .. tostring(item.LimitsEnabled) .. "|" .. numbers(item.LowerAngle, item.UpperAngle, item.TargetAngle, item.AngularSpeed, item.AngularVelocity, item.ServoMaxTorque, item.MotorMaxTorque, item.AngularResponsiveness)
			end
		elseif item:IsA("WeldConstraint") then row ..= "|" .. tostring(item.Enabled) .. "|P0:" .. reference(model, item.Part0) .. "|P1:" .. reference(model, item.Part1)
		end
		local attributes, names = item:GetAttributes(), {}
		for name in attributes do table.insert(names, name) end
		table.sort(names)
		for _, name in names do row ..= "|A:" .. name .. ":" .. typeof(attributes[name]) .. ":" .. attribute(attributes[name]) end
		table.insert(rows, row)
	end
	table.sort(rows)
	return rows
end

local function sourceMatch(left: Instance, right: Instance): {string}
	local failures, count = {}, 0
	for _, item in left:GetChildren() do
		count += 1
		local other = right:FindFirstChild(item.Name)
		if not other or other.ClassName ~= item.ClassName or not item:IsA("LuaSourceContainer") or not other:IsA("LuaSourceContainer") or item.Source ~= other.Source then table.insert(failures, item.Name) end
	end
	if count ~= 28 or #right:GetChildren() ~= 28 then table.insert(failures, "source count differs from 28") end
	return failures
end

local function resources(model: Model)
	local counts = {parts = 0, pressTargets = 0, colliders = 0, queryParts = 0, touchParts = 0, artParts = 0, sourceSnapshots = #model.SourceSnapshot:GetChildren()}
	for _, item in model:GetDescendants() do
		if not item:IsA("BasePart") then continue end
		counts.parts += 1
		if item:GetAttribute("Pressable") then counts.pressTargets += 1 end
		if item.CanCollide then counts.colliders += 1 end
		if item.CanQuery then counts.queryParts += 1 end
		if item.CanTouch then counts.touchParts += 1 end
		if item:GetAttribute("MapArtwork") then counts.artParts += 1 end
	end
	return counts
end

local expected = {parts = 8808, pressTargets = 2989, colliders = 282, queryParts = 3289, touchParts = 0, artParts = 1894, sourceSnapshots = 28}
local currentCounts = resources(candidate)
for name, value in expected do assert(currentCounts[name] == value, "Candidate count changed: " .. name) end
assert(#sourceMatch(candidate.SourceSnapshot, durableSources) == 0, "Installed snapshot differs from durable M04Sources01")
assert(candidate.SourceSnapshot:FindFirstChild("ArchiveSkyConfig") and candidate.SourceSnapshot:FindFirstChild("WarningPlacements"), "Sky configuration and owner warning poses must be durable")
assert(#candidate.MapEnvironment.HazardIndicators:GetChildren() == 17, "All owner warning boards must remain present")
assert(not candidate.SourceSnapshot.Session.Disabled, "Active candidate session must remain enabled")
local preserved = {}
for _, course in archive.TwoLapCleanup20261008.OlderCourses:GetChildren() do
	for _, item in course:GetDescendants() do if item:IsA("BaseScript") then assert(item.Disabled, "Older course scripts must be inert") end end
	table.insert(preserved, course.Name)
end
assert(#preserved == 16 and table.find(preserved, "KeyboardCircuit_P3_M02_01") and table.find(preserved, "KeyboardCircuit_P3_M03_01"), "M02, M03 and their older recovery courses must stay archived")
table.sort(preserved)
local active = {}
for _, course in workspace:GetChildren() do if course:IsA("Model") and course.Name:find("KeyboardCircuit", 1, true) then table.insert(active, course.Name) end end
assert(#active == 1 and active[1] == candidate.Name, "Expected one active Keyboard Circuit")

local serialization, encoding = game:GetService("SerializationService"), game:GetService("EncodingService")
local blob = serialization:SerializeInstancesAsync({candidate})
local proof = Instance.new("Folder")
proof.Name, proof.Parent = proofName, proofRoot
proof:SetAttribute("KCOwnedPhase3Preparation", true)
local objects = serialization:DeserializeInstancesAsync(blob)
assert(#objects == 1 and objects[1]:IsA("Model"))
local reopened = objects[1] :: Model
for _, item in reopened:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
reopened.Parent = proof
local fresh = durableSources:Clone()
fresh.Name = "FreshBuilderSources"
for _, item in fresh:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
fresh.Parent = proof
local rebuildParent = Instance.new("Folder")
rebuildParent.Name, rebuildParent.Parent = "RebuiltCourse", proof
local template = assert(Storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true)) :: MeshPart
local rebuilt = require(fresh.Map).Build(rebuildParent, candidate:GetAttribute("Origin"), template)
local copied = fresh:Clone()
copied.Name, copied.Parent = "SourceSnapshot", rebuilt

local function compare(left: Model, right: Model)
	local a, b, differences, external = geometry(left), geometry(right), {}, {}
	for index = 1, math.max(#a, #b) do if a[index] ~= b[index] and #differences < 12 then table.insert(differences, {index = index, left = a[index], right = b[index]}) end end
	local failures = sourceMatch(left.SourceSnapshot, right.SourceSnapshot)
	for _, item in right:GetDescendants() do
		if item:IsA("BaseScript") then assert(item.Disabled, "Recovery scripts must remain inert") end
		local function check(value: Instance?, property: string)
			if value and not value:IsDescendantOf(right) then table.insert(external, relative(right, item) .. "." .. property) end
		end
		if item:IsA("ObjectValue") then check(item.Value, "Value") end
		if item:IsA("SurfaceGui") then check(item.Adornee, "Adornee") end
		if item:IsA("Constraint") then check(item.Attachment0, "Attachment0"); check(item.Attachment1, "Attachment1") end
		if item:IsA("WeldConstraint") then check(item.Part0, "Part0"); check(item.Part1, "Part1") end
		if item:IsA("Model") then check(item.PrimaryPart, "PrimaryPart") end
	end
	local counts = resources(right)
	local countFailures = {}
	for name, value in expected do if counts[name] ~= value then table.insert(countFailures, name) end end
	return {passed = #a == #b and #differences == 0 and #failures == 0 and #external == 0 and #countFailures == 0, leftCount = #a, rightCount = #b, differences = differences, sourceFailures = failures, externalReferences = external, counts = counts, countFailures = countFailures}
end

local function hex(value: string): string return (value:gsub(".", function(char) return string.format("%02x", string.byte(char)) end)) end
local receipt = {
	candidate = candidate.Name, revision = candidate:GetAttribute("PrototypeRevision"), courseBytes = buffer.len(blob), proof = proof:GetFullName(), sourceHolder = durableSources:GetFullName(),
	roundTrip = compare(candidate, reopened), freshSourceRebuild = compare(candidate, rebuilt), preserved = preserved, active = active, expectedCounts = expected,
	nativeSha256 = hex(buffer.tostring(encoding:ComputeBufferHash(blob, Enum.HashAlgorithm.Sha256))),
	boundary = "Native engine serialization/reopening and fresh-identity rebuild from M04Sources01. Root/instance attributes, poses, geometry, art, physics/shadows, mesh identity/fidelity, GUI layouts/fonts/colors/draw ranges, internal references, constraints and 28 complete source byte strings compared. Numeric properties use .001 precision, with signed zero normalized. Recovery BaseScripts intentionally disabled; this Disabled difference is excluded from geometry equivalence. Owned proof in ServerStorage only; no owner-Play interruption, camera/computer control, whole-place save or publication.",
}
shared.KCP3M04NativeExport02 = buffer.tostring(encoding:Base64Encode(encoding:CompressBuffer(blob, Enum.CompressionAlgorithm.Zstd, 3)))
receipt.compressedBase64Chars = #shared.KCP3M04NativeExport02
receipt.passed = receipt.roundTrip.passed and receipt.freshSourceRebuild.passed
shared.KCP3M04RecoveryReceipt02 = receipt
assert(receipt.passed, Http:JSONEncode(receipt))
return Http:JSONEncode(receipt)
