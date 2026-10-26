local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local geometryFingerprint = require("../Fingerprint")
local function fingerprint(root)
    local result = {geometry = geometryFingerprint(root), parts = 0, meshes = 0, colliders = 0, scripts = 0, instances = #root:GetDescendants()}
    for _, part in root:GetDescendants() do
        if part:IsA("BasePart") then
            result.parts += 1
            if part.CanCollide then result.colliders += 1 end
        end
        if part:IsA("MeshPart") then result.meshes += 1 end
        if part:IsA("LuaSourceContainer") then result.scripts += 1 end
    end
    return result
end
local V, C = roblox.Vector3, roblox.CFrame
local sourceCFrame = table.clone(C)
function sourceCFrame.lookAt(position, target, up)
    local forward = (target - position).Unit
    local side = forward:Cross(up or V.yAxis)
    if side.Magnitude < 1e-6 then side = forward:Cross(V.zAxis) end
    local right = side.Unit
    return C.fromMatrix(position, right, right:Cross(forward), -forward)
end
local function modelPivot(model)
    if model.PrimaryPart then return model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset end
    local ok, pivot = pcall(function() return model.WorldPivot end)
    return if ok then pivot else model.WorldPivotData or C.identity
end
roblox.implementMethod("Model", "GetPivot", modelPivot)
roblox.implementMethod("Model", "PivotTo", function(model, target)
    local delta = target * model:GetPivot():Inverse()
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then part.CFrame = delta * part.CFrame
        elseif part:IsA("Model") then part.WorldPivot = delta * modelPivot(part) end
    end
    model.WorldPivot = target
end)
local env = {}
for _, key in {"Instance", "Vector3", "Vector2", "Color3", "UDim2", "UDim", "Enum"} do env[key] = roblox[key] end
env.CFrame = sourceCFrame
local function load(path)
    return luau.load(fs.readFile(path), {environment = env, debugName = path})()
end
local base = "docs/artifacts/stud-garden-v2/refinement-20261005/"
local stage = process.args[1] or "r01"
local output = base .. stage
local root = roblox.deserializeModel(fs.readFile(base .. "native/sgv2-owner-c08-before-refinement.rbxm"))[1]
assert(fingerprint(root).geometry.hash == "4b2f6d3d", "Owner baseline differs")
local spec = serde.decode("json", fs.readFile(base .. "r01/botanical-manifest.json"))
local routeSpec = serde.decode("json", fs.readFile(base .. "reviews/ROUTE_PROPOSAL_MATH.json"))
local art
local draft = process.args[2] == "draft"
if draft then
    art = roblox.Instance.new("Model")
    art.Name = "BotanicalRefinement"
    art.WorldPivot = root:GetPivot()
    for _, row in spec.meshes do
        local lo, hi = V.new(unpack(row.exportBoundsRoblox[1])), V.new(unpack(row.exportBoundsRoblox[2]))
        local part = roblox.Instance.new("MeshPart")
        part.Name = row.name
        part.Size = hi - lo
        part.CFrame = C.new(root:GetPivot().Position + (lo + hi) / 2) * C.Angles(0, math.pi, 0)
        part.Color = roblox.Color3.fromHex(row.hex:sub(2))
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Material = roblox.Enum.Material.SmoothPlastic
        part:SetAttribute("Role", "Decoration")
        part:SetAttribute("DraftWithoutAsset", true)
        part.Parent = art
    end
else
    art = roblox.deserializeModel(fs.readFile(base .. "native/botanical-art-r01.rbxm"))[1]
    assert(#art:GetChildren() == #spec.meshes, "Imported mesh inventory differs")
end
local Kit = load("tools/stud-garden-v2/closing/NativeKit.luau")
local Route = load("tools/stud-garden-v2/closing/RoutePresentation.luau")(Kit)
local result = load("tools/stud-garden-v2/refinement/RefineCourse.luau")(root, Kit, Route, art, spec, routeSpec)
if stage == "r02" then load("tools/stud-garden-v2/refinement/FinalizeMetadata.luau")(root) end
root:SetAttribute("CandidateId", "SGV2_Refinement_" .. stage:upper())
root:SetAttribute("DraftWithoutAsset", if draft then true else nil)
root.WorldPivotData = root:GetPivot()
for _, part in root:GetDescendants() do
    assert(not part:IsA("LuaSourceContainer"), "Course geometry must not embed scripts")
    if part:IsA("BasePart") then assert(part.Anchored) end
    if part:IsA("Model") then part.WorldPivotData = part:GetPivot() end
end
fs.writeDir(output)
local before = fingerprint(root)
fs.writeFile(output .. "/candidate.rbxm", roblox.serializeModel({root}))
local roundtrip = roblox.deserializeModel(fs.readFile(output .. "/candidate.rbxm"))[1]
local after = fingerprint(roundtrip)
assert(before.geometry.hash == after.geometry.hash and before.parts == after.parts, "Offline roundtrip differs")
result.fingerprint = before
result.draftWithoutAsset = draft
fs.writeFile(output .. "/build-result.json", serde.encode("json", result))
print(serde.encode("json", {fingerprint = before, draftWithoutAsset = draft, walls = #result.walls, neonBars = result.neonBars}))
