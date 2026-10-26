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
local proof = assert(proofRoot:FindFirstChild(proofName), "Final native recovery must exist")

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


local options = assert(shared.KCP3M04PostReviewOptions, "Exact reviewed freeze options required")
assert(type(options.sourceFreezeSha256) == "string" and #options.sourceFreezeSha256 == 64)
assert(type(options.nativeSha256) == "string" and #options.nativeSha256 == 64)
local reopened = assert(proof:FindFirstChild(candidate.Name)) :: Model
local rebuilt = assert(proof.RebuiltCourse:FindFirstChild(candidate.Name)) :: Model
local live, recovery, fresh = geometry(candidate), geometry(reopened), geometry(rebuilt)
local differences = {}
for index = 1, math.max(#live, #recovery, #fresh) do
 if live[index] ~= recovery[index] or live[index] ~= fresh[index] then
  if #differences < 12 then table.insert(differences, {index=index,live=live[index],recovery=recovery[index],rebuilt=fresh[index]}) end
 end
end
local sourceFailures = sourceMatch(candidate.SourceSnapshot, durableSources)
local active, preserved, inert = {}, {}, true
for _, item in workspace:GetChildren() do
 if item:IsA("Model") and item.Name:find("KeyboardCircuit",1,true) then table.insert(active,item.Name) end
end
for _, course in archive.TwoLapCleanup20261008.OlderCourses:GetChildren() do
 table.insert(preserved,course.Name)
 for _, item in course:GetDescendants() do if item:IsA("BaseScript") and not item.Disabled then inert=false end end
end
table.sort(active);table.sort(preserved)
local unrelated = {}
for _, name in {"Lobby","GrandArcade","SGV2_Phase3_F04","ObstacleKit_Palette"} do
 local model=assert(workspace:FindFirstChild(name),"Unrelated model missing: "..name)
 local parts=0
 for _,item in model:GetDescendants() do if item:IsA("BasePart") then parts+=1 end end
 unrelated[name]={descendants=#model:GetDescendants(),parts=parts}
end
local receipt = {
 candidate=candidate.Name,revision=candidate:GetAttribute("PrototypeRevision"),editRunning=RunService:IsRunning(),
 sourceFreezeSha256=options.sourceFreezeSha256,nativeSha256=options.nativeSha256,
 geometryRows=#live,recoveryRows=#recovery,rebuildRows=#fresh,
 differences=differences,sourceFailures=sourceFailures,sources=#candidate.SourceSnapshot:GetChildren(),
 activeCourses=active,inertOlderCourses=#preserved,archivedScriptsDisabled=inert,
 origin={candidate:GetAttribute("Origin").X,candidate:GetAttribute("Origin").Y,candidate:GetAttribute("Origin").Z},
 unrelated=unrelated,resources=resources(candidate),
 boundary="Fresh read-only Edit comparison against retained final engine round-trip and fresh-source rebuild. Complete canonical geometry/attributes/internal references and source bytes; .001 numeric precision. No live hierarchy, source, computer or camera changes.",
}
receipt.passed=not receipt.editRunning and #live==16738 and #live==#recovery and #live==#fresh and #differences==0 and #sourceFailures==0 and receipt.sources==28 and #active==1 and active[1]==candidate.Name and #preserved==16 and inert
shared.KCP3M04PostReviewReceipt=receipt
assert(receipt.passed,Http:JSONEncode(receipt))
return Http:JSONEncode(receipt)
