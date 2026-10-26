local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local folder = "assets/egg_rush_circuit/phase2/chicken_r05/candidate_a02/"
local manifest = serde.decode("json", fs.readFile(folder .. "manifest.json"))
local source = "src/ServerStorage/CourseBuilders/EggRush/RestartP2/ChickenKit.luau"
local kit = luau.load(fs.readFile(source), {
	debugName = source,
	environment = {
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		Instance = roblox.Instance,
	},
})()
local V, CF = roblox.Vector3.new, roblox.CFrame.new
local frame = CF(12, 6, -31) * roblox.CFrame.Angles(.15, .8, -.25)
local parent = roblox.Instance.new("Folder")
local models, parts, lethals, wedges = 0, 0, 0, 0
assert(manifest.build == "ER_CHICKEN_R05_A02")
assert(manifest.templates.Body.partCount == 25 and manifest.templates.Head.partCount == 22 and manifest.templates.Feet.partCount == 10)
assert(manifest.attachments.bodyFront == "+X" and manifest.attachments.headFront == "-Z")
assert(V(table.unpack(manifest.attachments.beakTip)) == V(0, -2, -10))
assert(V(table.unpack(manifest.attachments.headNeck)) == V(0, -5, 3))
assert(V(table.unpack(manifest.attachments.shoulder)) == V(18, 25, 0))
assert(manifest.attachments.neckLinkLength == 6 and manifest.attachments.neckWidth == 9)
for key, template in manifest.templates do
	for _, factorValue in { false, .8, 1, V(1.2, .9, .75) } do
		local model = kit.Create(parent, key, frame, if factorValue == false then nil else factorValue)
		local factor = if typeof(factorValue) == "number" then V(factorValue, factorValue, factorValue)
			elseif typeof(factorValue) == "Vector3" then factorValue else V(1, 1, 1)
		assert(model.Parent == parent and model.Name == key and #model:GetChildren() == template.partCount)
		for _, data in template.parts do
			local part = assert(model:FindFirstChild(data.name))
			local at = V(table.unpack(data.position)) * factor
			local expected = frame * CF(at.X, at.Y, at.Z, table.unpack(data.rotationMatrix))
			assert((part.Size - V(table.unpack(data.size)) * factor).Magnitude < .0001)
			local actualValues, expectedValues = { part.CFrame:GetComponents() }, { expected:GetComponents() }
			for i, value in expectedValues do
				assert(math.abs(actualValues[i] - value) < .0001)
			end
			assert(part.Anchored and not part.CanCollide and not part.CanTouch)
			assert(part.CanQuery == data.lethal and part:GetAttribute("ERLethal") == data.lethal)
			assert(part.Material == roblox.Enum.Material[data.material])
			assert(part.Color == roblox.Color3.fromRGB(table.unpack(data.color)))
			assert(part.ClassName == if data.primitive == "Wedge" then "WedgePart" else "Part")
			if data.primitive == "Wedge" then
				assert(data.vertices == 6 and data.triangles == 8)
				wedges += 1
			end
			if data.lethal then
				assert(key == "Head" and part.Name == "Beak" and data.paletteRole == "Hot")
				lethals += 1
			end
			parts += 1
		end
		if key == "Head" then
			local beak = model.Beak
			local actualTip = beak.CFrame:PointToWorldSpace(V(0, -beak.Size.Y / 2, -beak.Size.Z / 2))
			local expectedTip = frame:PointToWorldSpace(V(table.unpack(manifest.attachments.beakTip)) * factor)
			assert((actualTip - expectedTip).Magnitude < .0001)
			assert((beak.CFrame.LookVector - frame.LookVector).Magnitude < .0001)
		end
		models += 1
	end
end
assert(parts == 228 and wedges == 60 and lethals == 4)
local report = {
	build = manifest.build,
	status = "passed",
	models = models,
	partsChecked = parts,
	wedgePiecesChecked = wedges,
	lethalPiecesChecked = lethals,
	checks = {
		"Luau compile",
		"manifest transform and scale parity",
		"native primitive class, size, color, material and contact flags",
		"visible red wedge Beak is the only lethal piece",
		"physical wedge tip and fixed attachment contract",
	},
	boundary = "Offline source/API proof; native Wedge orientation and contacts remain for Studio",
}
fs.writeFile(folder .. "api_check.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", report))
