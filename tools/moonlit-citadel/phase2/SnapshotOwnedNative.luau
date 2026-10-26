local function snapshot(path, label)
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	assert(type(label) == "string" and label:match("^%w+$"))
	local item = game
	for name in path:gmatch("[^/]+") do item = assert(item:FindFirstChild(name), path) end
	local parent
	if RunService:IsClient() then
		local player = game.Players.LocalPlayer
		local allowed = item:IsDescendantOf(player.PlayerGui) or item:IsDescendantOf(player.PlayerScripts)
			or item:IsDescendantOf(game.ReplicatedStorage.MoonlitPhase2Tools)
		assert(allowed and item.Name:match("^MC_P2_C01_R06_"), "Actual owned R06 client evidence only")
		parent = player.PlayerGui
	else
		assert(RunService:IsServer() and item:IsDescendantOf(game.ServerStorage.MoonlitPhase2Evidence)
			and item.Name:match("^MC_P2_C01_R06_"), "Actual owned R06 server evidence only")
		parent = game.ServerStorage.MoonlitPhase2Evidence
	end
	assert(item:IsA("Folder"))
	local savedServerReport = RunService:IsServer() and item:IsDescendantOf(game.ServerStorage.MoonlitPhase2Evidence)
		and type(item:GetAttribute("JSONBytes")) == "number" and item:GetAttribute("JSONBytes") > 0
	assert(item:GetAttribute("OwnedMoonlitTest") == true or item:GetAttribute("OwnedCatchRunner") == item.Name
		or type(item:GetAttribute("CreatedBy")) == "string" or savedServerReport, "Retain actual diagnostic ownership")
	local name = "MC_P2_R06_RawExport_" .. label
	assert(not parent:FindFirstChild(name), "Preserve earlier export")
	local S, E = game:GetService("SerializationService"), game:GetService("EncodingService")
	local bytes = S:SerializeInstancesAsync({item})
	local hash = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256)
	local hex = {}
	for i = 0, buffer.len(hash) - 1 do table.insert(hex, string.format("%02x", buffer.readu8(hash, i))) end
	local raw = buffer.tostring(E:Base64Encode(bytes))
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("OwnedMoonlitTest", true)
	folder:SetAttribute("SourcePath", item:GetFullName())
	folder:SetAttribute("NativeBytes", buffer.len(bytes))
	folder:SetAttribute("NativeSha256", table.concat(hex))
	folder:SetAttribute("Base64Chunks", math.ceil(#raw / 16000))
	for offset = 1, #raw, 16000 do
		local chunk = Instance.new("StringValue")
		chunk.Name = string.format("Base64_%03d", math.ceil(offset / 16000))
		chunk.Value = raw:sub(offset, offset + 15999)
		chunk.Parent = folder
	end
	folder.Parent = parent
	return {folder = folder:GetFullName(), source = item:GetFullName(), bytes = buffer.len(bytes),
		sha256 = table.concat(hex), chunks = math.ceil(#raw / 16000), attributes = item:GetAttributes()}
end
return snapshot
