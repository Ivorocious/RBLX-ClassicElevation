--!nonstrict
return function()
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local oldHash = "6d33c1f88b23bd0e2840a5ecec163fe09d581a087f8c0c76b52e2ba50c5dca8a"
	local newHash = "89934f953faa5060b4bc5ed7d0747f998003a85117c99caf7f4afa644812c3d7"
	assert(workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash") == newHash)
	local scripts = {game.ServerScriptService.MoonlitPhase3NativeServer, game.StarterPlayer.StarterPlayerScripts.MoonlitPhase3NativeClient}
	for _, item in scripts do
		assert(item:GetAttribute("OwnedMoonlitTest") and item:GetAttribute("RunNativeCommands") and item.Enabled)
		assert(item.Source:find('local CANDIDATE = "MC_P3_REWORK_R03"', 1, true))
	end
	for _, root in {game.ServerStorage, game.ReplicatedStorage} do
		assert(root.MoonlitPhase3Tools:GetAttribute("OwnedMoonlitTest") and root.MoonlitPhase3Tools:GetAttribute("SourceHash") == oldHash)
	end
	local recovery = game.ServerStorage.MoonlitP3ReworkRecovery
	assert(not recovery:FindFirstChild("TestBindingBefore13"))
	local archive = Instance.new("Folder"); archive.Name, archive.Parent = "TestBindingBefore13", recovery
	for _, item in scripts do
		local copy = item:Clone(); copy.Enabled = false; copy:SetAttribute("RunNativeCommands", false); copy.Parent = archive
		local before = item.Source
		local after, count = before:gsub('local CANDIDATE = "MC_P3_REWORK_R03"', 'local CANDIDATE = "MC_P3_REWORK_R04"')
		assert(count == 1)
		item.Source = after
		assert(item.Enabled and item:GetAttribute("RunNativeCommands") and item.Source == after)
	end
	for _, root in {game.ServerStorage, game.ReplicatedStorage} do root.MoonlitPhase3Tools:SetAttribute("SourceHash", newHash) end
	return game.HttpService:JSONEncode({ok = true, candidate = "MC_P3_REWORK_R04", sourceHash = newHash,
		newCommands = false, enableFlagsChanged = false, helpersUpdated = 2, priorSourcesPreserved = true})
end
