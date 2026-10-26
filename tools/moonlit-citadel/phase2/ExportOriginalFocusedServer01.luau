return function(port, label)
local Run, H, E, S = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("EncodingService"), game:GetService("SerializationService")
assert(Run:IsStudio() and Run:IsRunning() and Run:IsServer() and game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
assert(#game.Players:GetPlayers() == 2 and game.Players:GetPlayerByUserId(-1) and game.Players:GetPlayerByUserId(-2))
assert(type(port) == "number" and port % 1 == 0 and port > 0 and port < 65536 and H.HttpEnabled == false)
local tools, scripts = game.ReplicatedStorage.MoonlitPhase2Tools, game.ServerScriptService
assert(tools:GetAttribute("R06RuntimePhase") == "Complete" and tools:GetAttribute("R06RuntimeMode") == "PrivateResetOnly")
assert(scripts.R06NewRed:GetAttribute("NewRedState") == "Complete")
local contactState = scripts.R06ContactDriver13:GetAttribute("DriverState")
assert(contactState == "Complete" or contactState == "Failed", "Preserve a genuine terminal contact result")
assert((label == "failure01" and contactState == "Failed") or (label == "complete01" and contactState == "Complete"))
local function hash(bytes)
	local digest, values = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
	for index = 0, buffer.len(digest) - 1 do values[#values + 1] = string.format("%02x", buffer.readu8(digest, index)) end
	return table.concat(values)
end
local expected = {R06RuntimeCore = "cfea207886637e53f793403424a15a59c1155ac8ddc4bb17952a8e742d762cd2", R06NewRed = "8a30079b662efc1e052bb19cc8d384a17bfb0d7cc9deac2abe99c3537dfdf094", R06ContactDriver11 = "17e7ac1becd45b1a68938584cc3dc8dcb921b20661290c664f3a791c1966722a", R06ContactDriver12 = "8720e8421c91971dfa1961ad69074f2626f0f5200433fbccc6f461adf91733d5", R06ContactDriver13 = "caefc8625e94344633fe586f6e2c985b59adb154e69cb72bf910fa6b5c93bb43"}
for name, sha in expected do assert(hash(buffer.fromstring(scripts[name].Source)) == sha and scripts[name]:GetAttribute("OwnedMoonlitTest") == true) end
local root = assert(game.ServerStorage:FindFirstChild("MoonlitPhase2Evidence"))
for _, child in root:GetChildren() do
	if not child.Name:match("^MC_P2_C01_R06_") then
		assert(child.Name:match("^MC_[a-f0-9]+$") and #child.Name == 35 and child:GetAttribute("JSONBytes"))
		local parts = {}
		for index = 1, assert(child:GetAttribute("JSONChunks")) do parts[index] = assert(child:FindFirstChild(string.format("JSON_%03d", index))).Value end
		local raw = table.concat(parts)
		assert(#raw == child:GetAttribute("JSONBytes"))
		local report = H:JSONDecode(raw)
		assert(report.candidate == "MC_P2_C01_R06" and report.caseId == child.Name, "Export only this course's actual contact reports")
	end
end
local originals, rawBytes, rawCount = {}, 0, 0
for _, value in root:GetDescendants() do
	if value:IsA("StringValue") then originals[value] = value.Value; rawBytes += #value.Value; rawCount += 1 end
end
assert(rawBytes > 0 and rawBytes < 24000000)
local bytes = S:SerializeInstancesAsync({root})
local sha = hash(bytes)
assert(buffer.len(bytes) >= 32 and buffer.len(bytes) < 24000000 and buffer.tostring(bytes):sub(1,8) == "<roblox!")
local file = "MC_P2_R06_focused_native2_server_" .. label .. ".rbxm"
local url = "http://127.0.0.1:" .. port .. "/" .. file
local ok, result = xpcall(function()
	H.HttpEnabled = true
	local posted = H:RequestAsync({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
	assert(posted.Success and posted.StatusCode == 200)
	local receipt = H:JSONDecode(posted.Body)
	assert(receipt.bytes == buffer.len(bytes) and receipt.sha256 == sha and receipt.path:gsub("\\", "/"):lower() == "c:/users/ivorr/robloxdevelopment/projectclassicelevation/docs/artifacts/moonlit-citadel/phase2/" .. file:lower())
	local fetched = H:RequestAsync({Url = url, Method = "GET"})
	assert(fetched.Success and fetched.StatusCode == 200 and fetched.Body == buffer.tostring(bytes))
	return receipt
end, debug.traceback)
H.HttpEnabled = false
for value, raw in originals do assert(value.Parent and value.Value == raw, "Original report changed during export") end
assert(H.HttpEnabled == false)
return H:JSONEncode({ok = ok, failure = not ok and tostring(result) or nil, receipt = ok and result or nil, at = workspace:GetServerTimeNow(), actualServerMCP = true, sourcePath = root:GetFullName(), sourcePins = expected, rawBytes = rawBytes, rawStringValues = rawCount, nativeBytes = buffer.len(bytes), nativeSha256 = sha, contactState = contactState, privateResetOnly = true, exhaustiveBoundariesSkipped = true, exactNativeReadback = ok, originalRawPreserved = true, httpRestored = true, nativeProof = false})
end
