local fs, serde, roblox, process = require("@lune/fs"), require("@lune/serde"), require("@lune/roblox"), require("@lune/process")
local input, output = table.unpack(process.args)
local expectedName = process.args[3] or "MC_P2_C01_R06_Verification"
assert(expectedName:match("^MC_P2_C01_R06_%w+$"))
assert(input and output and not fs.isDir(output), "Native client snapshot and fresh output directory required")
local bytes = fs.readFile(input)
local roots = roblox.deserializeModel(bytes)
assert(#roots == 1 and roots[1].Name == expectedName)
local folder = roots[1]
assert(folder:GetAttribute("OwnedMoonlitTest") == true)
fs.writeDir(output)
local result = {input = input, nativeSha256 = serde.hash("sha256", bytes), attributes = folder:GetAttributes(), reports = {}}
for _, name in {"Suite", "Airborne", "Trial"} do
	local chunks = assert(folder:GetAttribute(name .. "Chunks"))
	local values = {}
	for index = 1, chunks do
		local item = assert(folder:FindFirstChild(name .. string.format("_%03d", index)))
		assert(item:IsA("StringValue")); values[index] = item.Value
	end
	local raw = table.concat(values)
	assert(#raw == folder:GetAttribute(name .. "Bytes"))
	local data = serde.decode("json", raw)
	assert(data.candidate == "MC_P2_C01_R06")
	fs.writeFile(output .. "/" .. name .. ".json", raw)
	table.insert(result.reports, {name = name, bytes = #raw, sha256 = serde.hash("sha256", raw), state = data.state})
end
fs.writeFile(output .. "/extraction.json", serde.encode("json", result, true))
print(serde.encode("json", result, true))
