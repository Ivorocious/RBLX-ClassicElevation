-- Run after tools/export_studio_backup.luau, replacing its final return so fingerprint is in scope.
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Expected place in Edit mode")
local storage = game:GetService("ServerStorage")
local archive = assert(storage:FindFirstChild("Archive"), "Archive missing")
local ascent = assert(storage.CourseLibrary:FindFirstChild("Course_ClassicAscentPointToPoint"), "Ascent missing")
local archivePrint, ascentPrint = fingerprint({archive}), fingerprint({ascent})
assert(archivePrint.instances == 106646 and archivePrint.hash == 1286923888, "Archive changed since verified export")
assert(ascentPrint.instances == 5994 and ascentPrint.hash == 598301510, "Ascent changed since verified export")
assert(string.find(game.ReplicatedStorage.Config.CourseConfig.Source, "AutoBuildClassicAscent = false", 1, true), "Auto-build still enabled")
assert(string.find(game.ServerScriptService.Services.CourseService.Source, "if CourseConfig.AutoBuildClassicAscent then", 1, true), "Guard not synced")
local retained = {}
for _, root in {workspace.Course_CityRun, workspace.Lobby} do
    for _, part in root:GetDescendants() do
        if part:IsA("BasePart") then retained[part] = {part.CFrame, part.Size} end
    end
end
local countBefore = #game:GetDescendants()
archive:Destroy()
ascent:Destroy()
local checked = 0
for part, original in retained do
    assert(part:IsDescendantOf(workspace) and part.CFrame == original[1] and part.Size == original[2], "Retained geometry changed")
    checked += 1
end
return game:GetService("HttpService"):JSONEncode({
    before=countBefore, after=#game:GetDescendants(), removed=archivePrint.instances+ascentPrint.instances,
    retainedPartsUnchanged=checked, cityRunVersion=workspace.Course_CityRun:GetAttribute("MapVersion"),
    palettePresent=storage.DeveloperAssets:FindFirstChild("ObstacleKit_Palette") ~= nil,
    archiveGitCommit="c1f85b1", offlineArchive="archive/retired-maps-2026-09-22",
})
