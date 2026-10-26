--!strict
local AssetLibrary = {}

function AssetLibrary.Find(name: string): Instance?
	local libraries = game.ServerStorage:FindFirstChild("AssetLibraries")
	local shipwreck = if libraries then libraries:FindFirstChild("ShipwreckCove") else nil
	return if shipwreck then shipwreck:FindFirstChild(name) else nil
end

return AssetLibrary
