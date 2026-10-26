import json
from pathlib import Path

root = Path.cwd()
sources = json.loads((root / "docs/artifacts/keyboard-circuit/phase1/C08-source-package.json").read_text(encoding="utf-8"))

def quote(value):
    equals = ""
    while "]" + equals + "]" in value:
        equals += "="
    return "[" + equals + "[" + value + "]" + equals + "]"

literal = "{\n" + ",\n".join("[" + json.dumps(name) + "] = " + quote(value) for name, value in sources.items()) + "\n}"
body = '''
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local storage = game.ServerStorage
local prepared = storage.KeyboardCircuit_C08_Prepared
local candidate = workspace:FindFirstChild("KeyboardCircuit_P1_C08") or prepared.KeyboardCircuit_P1_C08
local kit = if candidate.Parent == workspace then storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01 else prepared.KeyboardCircuit_EditableKit_K01
candidate.SourceSnapshot.Session.Disabled = false
local previous = workspace:FindFirstChild("KeyboardCircuit_P1_C07") or storage.DeveloperArchives.KeyboardCircuitP1_Archives.KeyboardCircuit_P1_C07
local previousKit = if previous.Parent == workspace then storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01 else storage.DeveloperArchives.KeyboardCircuitP1_Archives.KeyboardCircuit_EditableKit_K01_C07_sources
local serialization = game:GetService("SerializationService")
shared.KCC08Exports = shared.KCC08Exports or {}
local function relative(v, root) return v:GetFullName():sub(#root:GetFullName() + 2) end
local function norm(s) return s:gsub("\\r\\n", "\\n") end
local function geometry(root)
    local rows = {}
    for _,v in root:GetDescendants() do
        if v:IsA("BasePart") then
            local cf = {v.CFrame:GetComponents()}
            for i,n in cf do cf[i] = string.format("%.4f", if math.abs(n) < .00005 then 0 else n) end
            table.insert(rows, relative(v, root) .. "|" .. tostring(v.Size) .. "|" .. table.concat(cf, ",") .. "|" .. tostring(v.Color) .. "|" .. tostring(v.Material) .. "|" .. tostring(v.CanCollide) .. "|" .. tostring(v.CanQuery) .. "|" .. tostring(v.CanTouch) .. "|" .. tostring(v.Transparency))
        end
    end
    table.sort(rows)
    return table.concat(rows, "\\n")
end
local function signature(root)
    local rows = {geometry(root)}
    for _,v in root:GetDescendants() do
        local path = relative(v, root)
        if v:IsA("LuaSourceContainer") then
            table.insert(rows, path .. "|" .. norm(v.Source) .. "|" .. (if v:IsA("BaseScript") then tostring(v.Disabled) else "module"))
        elseif v:IsA("TextLabel") then
            table.insert(rows, path .. "|" .. v.Text .. "|" .. tostring(v.Font) .. "|" .. tostring(v.TextColor3) .. "|" .. tostring(v.Position) .. "|" .. tostring(v.Size))
        elseif v:IsA("SurfaceGui") then
            table.insert(rows, path .. "|" .. tostring(v.CanvasSize) .. "|" .. tostring(v.Face) .. "|" .. tostring(v.Enabled) .. "|" .. tostring(v.AlwaysOnTop) .. "|" .. tostring(v.LightInfluence) .. "|" .. tostring(v.MaxDistance))
        end
    end
    table.sort(rows)
    return table.concat(rows, "\\n")
end
local function census(root, singleLegends)
    local out = {descendants = #root:GetDescendants(), parts = 0, meshes = 0, colliders = 0, lights = 0, sources = 0, legends = 0, welds = 0, links = 0}
    for _,v in root:GetDescendants() do
        if v:IsA("BasePart") then
            out.parts += 1
            if v:IsA("MeshPart") then out.meshes += 1 end
            if v.CanCollide then out.colliders += 1 end
            local legend = v:GetAttribute("KeyLegend")
            if legend then out.legends += 1; if singleLegends then assert(utf8.len(legend) == 1, "Multiple key symbols: " .. relative(v, root)) end end
        end
        if v:IsA("Light") then out.lights += 1 end
        if v:IsA("LuaSourceContainer") then out.sources += 1 end
        if v:IsA("WeldConstraint") then out.welds += 1; assert(v.Part0 and v.Part1 and v.Part0:IsDescendantOf(root) and v.Part1:IsDescendantOf(root)) end
        if v:IsA("ObjectValue") then out.links += 1; assert(v.Value and v.Value:IsDescendantOf(root)) end
        if v:IsA("PrismaticConstraint") then assert(v.Attachment0 and v.Attachment1 and v.Attachment0:IsDescendantOf(root) and v.Attachment1:IsDescendantOf(root)) end
    end
    return out
end
local sourceMatches = 0
for name, source in expected do
    local object
    if name == "ConfigSnapshot" then object = game.ReplicatedStorage.Config.KeyboardCircuitConfig
    elseif name == "KeyboardCircuitFeedback" or name == "KeyboardCircuitAudio" then object = game.StarterPlayer.StarterPlayerScripts.Controllers[name]
    elseif name == "KeyboardCircuitPreview" then object = game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview
    else object = storage.CourseBuilders.KeyboardCircuit[name] end
    assert(norm(object.Source) == norm(source), "Rojo source mismatch: " .. name)
    assert(loadstring(source), "Source compile failed: " .. name)
    sourceMatches += 1
end
assert(#storage.CourseBuilders.KeyboardCircuit:GetChildren() == 10)
for _,model in {candidate, kit} do
    assert(#model.SourceSnapshot:GetChildren() == 14)
    for _,source in model.SourceSnapshot:GetChildren() do assert(norm(source.Source) == norm(expected[source.Name]), "Snapshot mismatch: " .. source.Name) end
end
assert(geometry(candidate) == geometry(previous), "Candidate geometry differs from C07")
assert(geometry(kit) == geometry(previousKit), "Kit geometry differs from C07")
assert(candidate.S02_ThockySwitchworks.O04_EnterHairpin.EnterStem.KeyTop.Legend.Enabled and not candidate.S02_ThockySwitchworks.O04_EnterHairpin.EnterReturn.KeyTop.Legend.Enabled)
assert(kit.Surfaces.EnterL.Stem.KeyTop.Legend.Enabled and not kit.Surfaces.EnterL.Return.KeyTop.Legend.Enabled)
for name,model in {candidate = previous, kit = previousKit} do
    local saved = serialization:DeserializeInstancesAsync(shared.KCC08NativeBefore[name])[1]
    assert(signature(model) == signature(saved), "C07 owner changes detected: " .. name)
    saved:Destroy()
end
local probe = Instance.new("Model")
candidate.SourceSnapshot:Clone().Parent = probe
candidate.StudGardenV2:Clone().Parent = probe
local template = storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true)
require(probe.SourceSnapshot.Sample).Build(probe, Vector3.new(2300, 330, -1300), template)
require(probe.SourceSnapshot.RouteStudy).Build(probe, Vector3.new(2300, 330, -1850))
assert(signature(candidate) == signature(probe), "Candidate cannot be rebuilt from sources")
local kitParent = Instance.new("Folder")
local kitProbe = require(probe.SourceSnapshot.Kit).Build(kitParent, template)
kit.SourceSnapshot:Clone().Parent = kitProbe
assert(signature(kit) == signature(kitProbe), "Kit cannot be rebuilt from sources")
local report = {revision = "KC_P1_C08", sourceMatches = sourceMatches, builders = 10, snapshotSources = 14, unchangedGeometry = true, previousUnchanged = true, candidateRebuild = true, kitRebuild = true, oneVisibleSymbolPerJoinedKey = true, native = {}, preserved = {}}
for name,model in {C08 = candidate, KitC08 = kit, C07BeforeC08 = previous, KitC07BeforeC08 = previousKit} do
    local copy = model:Clone()
    if name == "KitC07BeforeC08" then copy.Name = "KeyboardCircuit_EditableKit_K01" end
    local bytes = serialization:SerializeInstancesAsync({copy})
    copy:Destroy()
    local reopened = serialization:DeserializeInstancesAsync(bytes)[1]
    assert(signature(model) == signature(reopened), "Native round-trip changed " .. name)
    local before, after = census(model, name == "C08" or name == "KitC08"), census(reopened, false)
    for key,value in before do assert(after[key] == value) end
    shared.KCC08Exports[name] = buffer.tostring(bytes)
    report.native[name] = {bytes = buffer.len(bytes), census = before, roundTrip = true}
    reopened:Destroy()
end
probe:Destroy()
kitParent:Destroy()
for name,model in {SGV2_Phase3_F04 = workspace.SGV2_Phase3_F04, Lobby = workspace.Lobby, GrandArcade = workspace.GrandArcade, ObstacleKit_Palette = workspace.ObstacleKit_Palette, CourseLibrary = storage.CourseLibrary} do report.preserved[name] = #model:GetDescendants() end
shared.KCC08Verification = report
return report
'''
(root / "tools/keyboard-circuit/VerifyC08.luau").write_text("--!strict\nlocal expected = " + literal + body, encoding="utf-8", newline="\n")
print(json.dumps({"sources": len(sources), "tool": "tools/keyboard-circuit/VerifyC08.luau"}))
