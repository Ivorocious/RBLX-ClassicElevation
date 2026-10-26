local function snapshot(label, sourceName)
	assert(game.PlaceId == 0 and game.GameId == 0 and game.RunService:IsRunning() and game.RunService:IsClient())
	assert(label:match("^%w+$"))
	local playerGui = game.Players.LocalPlayer.PlayerGui
	sourceName = sourceName or "MC_P2_C01_R06_Verification"
	assert(sourceName:match("^MC_P2_C01_R06_%w+$"))
	local source = assert(playerGui:FindFirstChild(sourceName))
	assert(source:GetAttribute("OwnedMoonlitTest") and (source:GetAttribute("State") == "Complete" or source:GetAttribute("State") == "Failed"))
	local name = "MC_P2_R06_RawExport_" .. label
	assert(not playerGui:FindFirstChild(name), "Preserve previous raw export")
	local S, E = game:GetService("SerializationService"), game:GetService("EncodingService")
	local bytes = S:SerializeInstancesAsync({source})
	local hash = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256)
	local hex = {}
	for index = 0, buffer.len(hash) - 1 do hex[#hex + 1] = string.format("%02x", buffer.readu8(hash, index)) end
	local encoded = buffer.tostring(E:Base64Encode(bytes))
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = name, playerGui
	for offset = 1, #encoded, 16000 do
		local chunk = Instance.new("StringValue")
		chunk.Name, chunk.Value, chunk.Parent = string.format("Base64_%03d", math.ceil(offset / 16000)), encoded:sub(offset, offset + 15999), folder
	end
	folder:SetAttribute("NativeBytes", buffer.len(bytes))
	folder:SetAttribute("NativeSha256", table.concat(hex))
	folder:SetAttribute("Base64Chunks", math.ceil(#encoded / 16000))
	folder:SetAttribute("OwnedMoonlitTest", true)
	return {folder = name, bytes = buffer.len(bytes), sha256 = table.concat(hex), chunks = math.ceil(#encoded / 16000), state = source:GetAttribute("State")}
end
return snapshot
