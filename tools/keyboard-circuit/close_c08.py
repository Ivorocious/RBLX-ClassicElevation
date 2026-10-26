from pathlib import Path

root = Path.cwd()
install = (root / "tools/keyboard-circuit/InstallCandidateC08.luau").read_text(encoding="utf-8")
prefix = install.split('assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818')[0]
helpers = "local function relative" + install.split("local function relative", 1)[1].split("for name,model in {C08 = candidate, KitC08 = kit, C07BeforeC08 = previous, KitC07BeforeC08 = previousKit}", 1)[0]
body = '''
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and not game:GetService("RunService"):IsRunning())
assert(shared.KCC08FinalLaunch.pending == false and shared.KCC08FinalLaunch.ok == true)
local storage = game.ServerStorage
local archive = storage.DeveloperArchives.KeyboardCircuitP1_Archives
local candidate, kit = workspace.KeyboardCircuit_P1_C08, storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01
local previous, previousKit = archive.KeyboardCircuit_P1_C07, archive.KeyboardCircuit_EditableKit_K01_C07_sources
local serialization = game:GetService("SerializationService")
HELPERS
for name,model in {C08 = candidate, KitC08 = kit, C07BeforeC08 = previous, KitC07BeforeC08 = previousKit} do
    local saved = serialization:DeserializeInstancesAsync(buffer.fromstring(shared.KCC08Exports[name]))[1]
    assert(signature(model) == signature(saved), "Frozen model changed: " .. name)
    saved:Destroy()
end
local matches = 0
for name,source in expected do
    local object
    if name == "ConfigSnapshot" then object = game.ReplicatedStorage.Config.KeyboardCircuitConfig
    elseif name == "KeyboardCircuitFeedback" or name == "KeyboardCircuitAudio" then object = game.StarterPlayer.StarterPlayerScripts.Controllers[name]
    elseif name == "KeyboardCircuitPreview" then object = game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview
    else object = storage.CourseBuilders.KeyboardCircuit[name] end
    assert(norm(object.Source) == norm(source), "Rojo source changed: " .. name)
    for _,model in {candidate, kit} do assert(norm(model.SourceSnapshot[name].Source) == norm(source), "Snapshot changed: " .. name) end
    matches += 1
end
assert(candidate:GetAttribute("CandidateRevision") == "KC_P1_C08")
assert(kit:GetAttribute("Revision") == "KC_KIT_C08_01")
assert(candidate.SourceSnapshot.Session.Disabled == false and kit.SourceSnapshot.Session.Disabled == true)
assert(candidate.SourceSnapshot.KeyboardCircuitPreview.Disabled == true and kit.SourceSnapshot.KeyboardCircuitPreview.Disabled == true)
assert(#storage.CourseBuilders.KeyboardCircuit:GetChildren() == 10)
local feedbackCount, previewCount = 0, 0
for _,x in game.StarterPlayer.StarterPlayerScripts.Controllers:GetChildren() do if x.Name == "KeyboardCircuitFeedback" then feedbackCount += 1 end end
for _,x in game.StarterPlayer.StarterPlayerScripts:GetChildren() do if x.Name == "KeyboardCircuitPreview" then previewCount += 1 end end
assert(feedbackCount == 1 and previewCount == 1)
local preserved = {}
for name,model in {SGV2_Phase3_F04 = workspace.SGV2_Phase3_F04, Lobby = workspace.Lobby, GrandArcade = workspace.GrandArcade, ObstacleKit_Palette = workspace.ObstacleKit_Palette, CourseLibrary = storage.CourseLibrary} do
    assert(#model:GetDescendants() == shared.KCC08Verification.preserved[name], "Unrelated hierarchy changed: " .. name)
    preserved[name] = #model:GetDescendants()
end
local o,cam = shared.KCC08OwnerCamera, workspace.CurrentCamera
local current, original, cameraError = {cam.CFrame:GetComponents()}, {o.cf:GetComponents()}, 0
for i,value in current do cameraError = math.max(cameraError, math.abs(value - original[i])) end
assert(cameraError < .00001 and cam.Focus == o.focus and cam.FieldOfView == o.fov)
assert(cam.CameraType == o.kind or cam.CameraType == Enum.CameraType.Fixed)
local report = {revision = "KC_P1_C08", studioMode = "Edit", sourceMatches = matches, snapshotSources = 14, builders = 10, feedbackCount = feedbackCount, previewCount = previewCount, fourFrozenModelsMatch = true, candidateSessionDisabled = candidate.SourceSnapshot.Session.Disabled, kitSessionDisabled = kit.SourceSnapshot.Session.Disabled, ownerViewRestoredWithinTolerance = true, cameraMaxComponentError = cameraError, cameraKind = tostring(cam.CameraType), ownerRequestedCameraKind = tostring(o.kind), cameraBoundary = "Studio settled the restored Scriptable camera to Fixed and normalized its rotation; position, Focus and FOV are restored.", fov = cam.FieldOfView, preserved = preserved, preparedFolderChildren = #storage.KeyboardCircuit_C08_Prepared:GetChildren(), wholePlaceSaved = false, published = false, passed = true}
shared.KCC08Closing = report
return report
'''.replace("HELPERS", helpers)
(root / "tools/keyboard-circuit/CloseC08.luau").write_text(prefix + body, encoding="utf-8", newline="\n")
print("Prepared C08 final state check")
