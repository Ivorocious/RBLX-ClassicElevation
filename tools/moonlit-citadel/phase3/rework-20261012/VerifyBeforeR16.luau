local fs, roblox, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local base = 'docs/artifacts/moonlit-citadel/phase3/rework-20261012/'
local bytes = fs.readFile(base .. 'rw10_before_r16_models.rbxm')
local receipt = serde.decode('json', fs.readFile(base .. 'rw10_before_r16_models.rbxm.receipt.json'))
assert(#bytes == receipt.bytes and serde.hash('sha256', bytes) == receipt.sha256)
local roots = roblox.deserializeModel(bytes)
assert(#roots == 2)
local rows = {}
for _, model in roots do
	assert(model.Name == 'Course_MoonlitCitadel' and model:GetAttribute('SourceRevision') == 25 and model:GetAttribute('BuildRevision') == 21)
	assert(model:GetAttribute('SourcePacketHash') == '46f75f64541dd1f4b4dc59f38e69916a84d4548416031640ef696a1a02575410')
	local parts, meshes, colliders = 0, 0, 0
	for _, item in model:GetDescendants() do
		if item:IsA('BasePart') then parts += 1; if item:IsA('MeshPart') then meshes += 1 end; if item.CanCollide then colliders += 1 end end
	end
	assert(parts == 1549 and meshes == 1278 and colliders == 143)
	assert(math.abs(model.Obstacles.SharedArches.Causeway_4_2.Contact.CFrame.Position.Y - 317.5) < .001)
	assert(math.abs(model.Obstacles.SharedArches.Causeway_4_3.Contact.CFrame.Position.Y - 312.5) < .001)
	table.insert(rows, {parts = parts, meshes = meshes, colliders = colliders, descendants = #model:GetDescendants()})
end
fs.writeFile(base .. 'rw10_before_models_verified_r16.json', serde.encode('json', {hash = receipt.sha256, models = rows, verified = true}))
print(serde.encode('json', {models = rows, verified = true}))
