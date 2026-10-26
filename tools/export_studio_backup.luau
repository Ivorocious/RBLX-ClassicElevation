local Export = {}

local function fingerprint(roots)
	local result = { instances = 0, parts = 0, scripts = 0, sourceBytes = 0, hash = 0, classes = {} }
	local function add(text)
		local h = 0
		for index = 1, #text do h = (h * 31 + string.byte(text, index)) % 4294967296 end
		result.hash = (result.hash + h) % 4294967296
	end
	local function visit(object, path)
		if not object.Archivable then return end
		result.instances += 1
		result.classes[object.ClassName] = (result.classes[object.ClassName] or 0) + 1
		add(path .. "|" .. object.ClassName)
		for key, value in object:GetAttributes() do add(path .. "/@" .. key .. "=" .. tostring(value)) end
		if object:IsA("BasePart") then
			result.parts += 1
			for _, key in {"CFrame", "Size", "Color", "Material", "Transparency", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CollisionGroup"} do
				add(path .. "/" .. key .. "=" .. tostring(object[key]))
			end
		end
		if object:IsA("MeshPart") then add(path .. "/Mesh=" .. object.MeshId .. "/Texture=" .. object.TextureID) end
		if object:IsA("LuaSourceContainer") then
			result.scripts += 1
			result.sourceBytes += #object.Source
			add(path .. "/Source=" .. object.Source)
		end
		for _, child in object:GetChildren() do visit(child, path .. "/" .. child.Name) end
	end
	for _, root in roots do visit(root, root.Name) end
	return result
end

function Export.Run(roots, filename)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Edit mode required")
	assert(game.PlaceId == 85558151074819, "Wrong experience")
	assert(string.match(filename, "^[a-z0-9%-]+%.rbxm$"), "Invalid backup filename")
	local serializer = game:GetService("SerializationService")
	local http = game:GetService("HttpService")
	local priorHttp = http.HttpEnabled
	local restored = nil
	local ok, result = xpcall(function()
		local before = fingerprint(roots)
		local data = serializer:SerializeInstancesAsync(roots)
		local body = buffer.tostring(data)
		local url = "http://127.0.0.1:8768/" .. filename
		http.HttpEnabled = true
		local response = http:RequestAsync({Url=url, Method="POST", Headers={["Content-Type"]="application/octet-stream"}, Body=body})
		assert(response.Success, "Backup write failed: " .. response.StatusCode)
		local readback = http:GetAsync(url, true)
		assert(readback == body, "Saved bytes differ from native serialization")
		restored = serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
		local after = fingerprint(restored)
		assert(before.instances == after.instances and before.parts == after.parts and before.scripts == after.scripts
			and before.sourceBytes == after.sourceBytes and before.hash == after.hash, "Restored model fingerprint differs")
		for class, count in before.classes do assert(after.classes[class] == count, "Restored class counts differ") end
		return {receipt=http:JSONDecode(response.Body), fingerprint=before, verified=true}
	end, debug.traceback)
	if restored then for _, object in restored do object:Destroy() end end
	http.HttpEnabled = priorHttp
	assert(ok, result)
	return result
end

return Export
