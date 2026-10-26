from pathlib import Path

root = Path.cwd()
verification = (root / "tools/keyboard-circuit/VerifyC08.luau").read_text(encoding="utf-8")
prefix = verification.split('assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())')[0]
helpers = "local function relative" + verification.split("local function relative", 1)[1].split("local function census", 1)[0]
body = '''
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and not game:GetService("RunService"):IsRunning())
assert(shared.KCC08Verification and shared.KCC08Verification.previousUnchanged)
local storage = game.ServerStorage
local archive = storage.DeveloperArchives.KeyboardCircuitP1_Archives
local prepared = storage.KeyboardCircuit_C08_Prepared
local candidate, kit = prepared.KeyboardCircuit_P1_C08, prepared.KeyboardCircuit_EditableKit_K01
local previous, previousKit = workspace.KeyboardCircuit_P1_C07, storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01
assert(not workspace:FindFirstChild("KeyboardCircuit_P1_C08"))
assert(not archive:FindFirstChild("KeyboardCircuit_P1_C07"))
assert(not archive:FindFirstChild("KeyboardCircuit_EditableKit_K01_C07_sources"))
local serialization = game:GetService("SerializationService")
HELPERS
for name,model in {C08 = candidate, KitC08 = kit, C07BeforeC08 = previous, KitC07BeforeC08 = previousKit} do
    local saved = serialization:DeserializeInstancesAsync(buffer.fromstring(shared.KCC08Exports[name]))[1]
    assert(signature(model) == signature(saved), "Frozen model changed: " .. name)
    saved:Destroy()
end
for name,source in expected do
    local object
    if name == "ConfigSnapshot" then object = game.ReplicatedStorage.Config.KeyboardCircuitConfig
    elseif name == "KeyboardCircuitFeedback" or name == "KeyboardCircuitAudio" then object = game.StarterPlayer.StarterPlayerScripts.Controllers[name]
    elseif name == "KeyboardCircuitPreview" then object = game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview
    else object = storage.CourseBuilders.KeyboardCircuit[name] end
    assert(norm(object.Source) == norm(source), "Rojo source changed: " .. name)
end
local preserved = {}
for name,model in {SGV2_Phase3_F04 = workspace.SGV2_Phase3_F04, Lobby = workspace.Lobby, GrandArcade = workspace.GrandArcade, ObstacleKit_Palette = workspace.ObstacleKit_Palette, CourseLibrary = storage.CourseLibrary} do
    assert(#model:GetDescendants() == shared.KCC08Verification.preserved[name], "Unrelated hierarchy changed: " .. name)
    preserved[name] = #model:GetDescendants()
end
previous.Parent = archive
previousKit.Name = "KeyboardCircuit_EditableKit_K01_C07_sources"
previousKit.Parent = archive
candidate.Parent = workspace
kit.Parent = storage.CourseAssetKits
assert(candidate.SourceSnapshot.Session.Disabled == false)
assert(kit.SourceSnapshot.Session.Disabled == true)
local report = {revision = "KC_P1_C08", candidate = candidate:GetFullName(), kit = kit:GetFullName(), archivedCandidate = previous:GetFullName(), archivedKit = previousKit:GetFullName(), preserved = preserved, deletedExistingInstances = 0, published = false, passed = true}
shared.KCC08Installed = report
return report
'''.replace("HELPERS", helpers)
(root / "tools/keyboard-circuit/InstallCandidateC08.luau").write_text(prefix + body, encoding="utf-8", newline="\n")
print("Prepared guarded C08 handoff")
