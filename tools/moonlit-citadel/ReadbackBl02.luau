local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local luau = require("@lune/luau")
local base = "docs/artifacts/moonlit-citadel/phase1/"
local model = roblox.deserializeModel(fs.readFile(base .. "MC_BL02_R04_native.rbxm"))[1]
local place = roblox.deserializePlace(fs.readFile(base .. "MC_BL02_isolated_test.rbxl"))
local root = place.Workspace.MoonlitCitadelPhase1_BL02
local library = roblox.deserializeModel(fs.readFile(base .. "MC_BL02_library_native.rbxm"))[1]
assert(model:GetAttribute("CandidateId") == "MC_P1_BL02_R04")
assert(#model:GetDescendants() == 1157)
assert(root:GetAttribute("CandidateId") == model:GetAttribute("CandidateId"))
assert(root:GetAttribute("RequestedArea") == "UpperSample")
assert(root:GetAttribute("PreviewEnabled") == false)
local scripts, localScripts, remotes = 0, 0, 0
for _, item in place:GetDescendants() do
    if item.ClassName == "Script" then scripts += 1 end
    if item.ClassName == "LocalScript" then localScripts += 1 end
    if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then remotes += 1 end
end
assert(scripts == 1 and localScripts == 1 and remotes == 0)
local sourceChecks = {
    {place.ReplicatedStorage.Config.MoonlitCitadelConfig, "src/ReplicatedStorage/Config/MoonlitCitadelConfig.luau"},
    {place.ServerStorage.CourseBuilders.MoonlitCitadel.PreviewSession, "src/ServerStorage/CourseBuilders/MoonlitCitadel/PreviewSession.luau"},
    {place.ServerScriptService.IsolatedMoonlitPreview, "tools/moonlit-citadel/isolated-preview.server.luau"},
    {place.StarterPlayer.StarterPlayerScripts.Controllers.MoonlitCitadelPreviewView, "src/StarterPlayer/StarterPlayerScripts/Controllers/MoonlitCitadelPreviewView.luau"},
}
for _, entry in sourceChecks do
    assert(entry[1].Source:gsub("\r\n", "\n") == fs.readFile(entry[2]):gsub("\r\n", "\n"), entry[2])
end
local fixtureProject = serde.decode("json", fs.readFile("tools/moonlit-citadel/isolated.project.json"))
local expectedDaylight = fixtureProject.tree.StarterPlayer.StarterPlayerScripts.IsolatedMoonlitDaylight["$properties"].Source
local savedDaylight = place.StarterPlayer.StarterPlayerScripts.IsolatedMoonlitDaylight.Source
assert(savedDaylight:gsub("\r\n", "\n") == expectedDaylight:gsub("\r\n", "\n"))
assert(luau.load(savedDaylight), "Saved daylight startup must parse")
assert(#library:GetChildren() == 29)
assert(#library:GetDescendants() == 84 and library:GetAttribute("ImportVerified") == true)
local result = {candidate = model:GetAttribute("CandidateId"), modelDescendants = #model:GetDescendants(),
    fixtureDescendants = #root:GetDescendants(), defaultArea = root:GetAttribute("RequestedArea"),
    previewEnabled = root:GetAttribute("PreviewEnabled"), serverScripts = scripts, localScripts = localScripts, remotes = remotes,
    matchingSources = #sourceChecks + 1, daylightStartupParsed = true, libraryUnits = #library:GetChildren(), libraryDescendants = #library:GetDescendants(),
    savedFileOnly = true, source = "Lune deserialize of saved native model, library and standalone place"}
fs.writeFile(base .. "MC_BL02_R04_saved_readback.json", serde.encode("json", result, true))
print(serde.encode("json", result))
