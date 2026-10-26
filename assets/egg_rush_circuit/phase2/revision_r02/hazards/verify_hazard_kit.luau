local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local assets = "assets/egg_rush_circuit/phase2/revision_r02/hazards/"
local manifest = serde.decode("json", fs.readFile(assets .. "candidate_h02/hazard_manifest.json"))
local modulePath = "src/ServerStorage/CourseBuilders/EggRush/RestartP2/HazardKit.luau"
local kit = luau.load(fs.readFile(modulePath), {
	debugName = modulePath,
	environment = {
		Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Color3 = roblox.Color3,
		Enum = roblox.Enum, Instance = roblox.Instance,
	},
})()
local V, CF = roblox.Vector3.new, roblox.CFrame.new
local parent = roblox.Instance.new("Folder")
local frame = CF(18, 4, -9) * roblox.CFrame.Angles(.1, .4, -.2)
local cases = {false, .75, 1, V(2, .5, 1.25)}
local models, parts, lethal = 0, 0, 0

for key, template in manifest.templates do
	for _, scale in cases do
		local model = kit.Create(parent, key, frame, if scale == false then nil else scale)
		local factor = if typeof(scale) == "number" then V(scale, scale, scale) elseif typeof(scale) == "Vector3" then scale else V(1, 1, 1)
		assert(model.Name == key and model.Parent == parent, key .. " model")
		assert(#model:GetChildren() == template.partCount, key .. " count")
		assert(model:GetAttribute("ERMechanism") == nil, key .. " motion is supplied by course")
		for _, data in template.parts do
			local part = assert(model:FindFirstChild(data.name), data.name)
			local position = V(table.unpack(data.position)) * factor
			local size = V(table.unpack(data.size)) * factor
			local matrix = data.rotationMatrix
			local expected = frame * CF(position.X, position.Y, position.Z, table.unpack(matrix))
			assert((part.Size - size).Magnitude < 1e-4, data.name .. " size " .. tostring(part.Size) .. " expected " .. tostring(size))
			local actualValues, expectedValues = {part.CFrame:GetComponents()}, {expected:GetComponents()}
			for index, value in expectedValues do
				assert(math.abs(actualValues[index] - value) < 1e-4, data.name .. " frame")
			end
			assert(part.Anchored and not part.CanCollide and not part.CanTouch, data.name .. " contact flags")
			assert(part.CanQuery == data.lethal and part:GetAttribute("ERLethal") == data.lethal, data.name .. " lethal flags")
			assert(part.Material == roblox.Enum.Material[data.material], data.name .. " material")
			assert(part.Color == roblox.Color3.fromRGB(table.unpack(data.color)), data.name .. " color")
			if data.lethal then
				assert(data.paletteRole == "Hot" and part.Material == roblox.Enum.Material.Neon, data.name .. " red danger")
				lethal += 1
			end
			parts += 1
		end
		models += 1
	end
end

local report = {
	build = manifest.build, status = "passed", templates = 4, modelsCreated = models,
	partsChecked = parts, lethalPartsChecked = lethal,
	checks = {"Luau compilation", "manifest parity", "translated and rotated frame", "default/numeric/vector scale", "contact/query/material flags"},
	evidence = "Offline Lune API and part-data check; not a Studio movement, contact, appearance, or performance result.",
}
fs.writeFile(assets .. "candidate_h02/api_check.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", report))
