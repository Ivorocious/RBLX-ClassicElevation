local fs, process, roblox, serde = require("@lune/fs"), require("@lune/process"), require("@lune/roblox"), require("@lune/serde")
local input, output, expectedName = table.unpack(process.args)
assert(input and output and expectedName and expectedName:match("^MC_P2_C01_R06_[%w_]+$"))
assert(not fs.isDir(output), "Preserve earlier extraction")
local bytes = fs.readFile(input)
local roots = roblox.deserializeModel(bytes)
assert(#roots == 1 and roots[1].Name == expectedName)
local root = roots[1]
assert((root:IsA("Folder") or root:IsA("StringValue")) and root:GetAttribute("OwnedMoonlitTest") == true)
local records, planned = {}, {}
local function safe(name) assert(name:match("^[%w_%-]+$")); return name end
local function write(path, raw, nativePath)
	assert(not planned[path], "Duplicate native report output")
	planned[path] = raw
	local ok, decoded = pcall(serde.decode, "json", raw)
	table.insert(records, {file = path, nativePath = nativePath, bytes = #raw,
		sha256 = serde.hash("sha256", raw), json = ok, state = ok and type(decoded) == "table" and decoded.state or nil})
end
local function visit(folder, path)
	local children, byName = folder:GetChildren(), {}
	for _, child in children do assert(not byName[child.Name]); byName[child.Name] = child end
	local groups = {}
	for attribute, count in folder:GetAttributes() do
		local prefix = attribute:match("^(.-)Chunks$")
		if prefix then
			local expectedBytes = folder:GetAttribute(prefix .. "Bytes")
			if prefix == "JSON" and not expectedBytes then expectedBytes = folder:GetAttribute("JSONBytes") end
			assert(type(count) == "number" and count >= 1 and count <= 999 and count % 1 == 0 and type(expectedBytes) == "number")
			local pieces = {}
			for i = 1, count do
				local child = assert(byName[prefix .. string.format("_%03d", i)], "Missing native chunk " .. prefix)
				assert(child:IsA("StringValue")); groups[child] = true; table.insert(pieces, child.Value)
			end
			local raw = table.concat(pieces); assert(#raw == expectedBytes)
			write(path .. "/" .. safe(prefix) .. ".json", raw, path)
		end
	end
	if folder:GetAttribute("JSONBytes") and not folder:GetAttribute("JSONChunks") then
		local pieces = {}; local count = 0
		for name in byName do local n = name:match("^JSON_(%d%d%d)$"); if n then count = math.max(count, tonumber(n)) end end
		assert(count >= 1 and count <= 999)
		for i = 1, count do local child = assert(byName[string.format("JSON_%03d", i)]); assert(child:IsA("StringValue")); table.insert(pieces, child.Value); groups[child] = true end
		local raw = table.concat(pieces); assert(#raw == folder:GetAttribute("JSONBytes")); write(path .. "/JSON.json", raw, path)
	end
	for _, child in children do
		if groups[child] then continue end
		if child:IsA("Folder") then visit(child, path .. "/" .. safe(child.Name))
		elseif child:IsA("StringValue") then write(path .. "/" .. safe(child.Name) .. ".txt", child.Value, path .. "/" .. child.Name)
		else error("Unexpected native diagnostic child " .. child.ClassName) end
	end
end
if root:IsA("StringValue") then write(safe(root.Name) .. ".json", root.Value, root.Name)
else visit(root, safe(root.Name)) end
assert(#records > 0)
fs.writeDir(output)
for path, raw in planned do
	local destination = output .. "/" .. path
	local parent = destination:match("^(.*)/[^/]+$")
	if not fs.isDir(parent) then fs.writeDir(parent) end
	fs.writeFile(destination, raw)
end
local receipt = {nativePath = input, nativeSha256 = serde.hash("sha256", bytes), nativeBytes = #bytes,
	rootName = root.Name, rootAttributes = root:GetAttributes(), reports = records}
fs.writeFile(output .. "/extraction.json", serde.encode("json", receipt, true))
print(serde.encode("json", receipt, true))
