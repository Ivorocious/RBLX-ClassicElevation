local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local root = "docs/artifacts/moonlit-citadel/phase2/"
local place = roblox.deserializePlace(fs.readFile(root .. "MC_P2_C01_R01_current_sources.rbxl"))
local pack = roblox.Instance.new("Folder")
pack.Name = "MoonlitPhase2SharedSources_02"
for _, serviceName in {"ServerStorage", "ReplicatedStorage", "ServerScriptService"} do
	local section = roblox.Instance.new("Folder")
	section.Name, section.Parent = serviceName, pack
	for _, child in place:GetService(serviceName):GetChildren() do child:Clone().Parent = section end
end
local scripts = roblox.Instance.new("Folder")
scripts.Name, scripts.Parent = "StarterPlayerScripts", pack
for _, child in place:GetService("StarterPlayer").StarterPlayerScripts:GetChildren() do child:Clone().Parent = scripts end
local output = root .. "MC_P2_C01_R01_install_sources_02.rbxm"
assert(not fs.isFile(output), "Preserve previous install packet")
fs.writeFile(output, roblox.serializeModel({pack}))
print(serde.encode("json", {path = output, descendants = #pack:GetDescendants()}))
