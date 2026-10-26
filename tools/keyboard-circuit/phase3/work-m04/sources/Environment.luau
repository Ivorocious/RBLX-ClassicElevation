--!strict
local Art = require(script.Parent.EnvironmentParts)
local Landmarks = require(script.Parent.Landmarks)
local Environment = {}

local function fixedBank(base: BasePart, course: Model): boolean
	if not base.Parent:FindFirstChild("BankContact") then return false end
	local cursor = base.Parent
	while cursor ~= course do
		if cursor:GetAttribute("MechanismId") then return false end
		cursor = cursor.Parent
	end
	return base.Size.X >= 7 and base.Size.Z >= 7
end

local function plates(parent: Instance, course: Model)
	local group = Art.Model(parent, "IslandCircuitPlates")
	local banks, contacts = {}, {}
	for _, item in course:GetDescendants() do
		if item:IsA("BasePart") and item.Name == "Base" and fixedBank(item, course) then table.insert(banks, item) end
		if item:IsA("BasePart") and (item.Name == "BankContact" or item.Name == "KeyContact") and item.CanCollide then table.insert(contacts, item) end
	end
	local built, omitted = 0, {}
	for index, base in banks do
		local frame = base.CFrame * CFrame.new(0, -1.25, 0)
		local width, depth = base.Size.X - .4, base.Size.Z - .4
		local face = frame * CFrame.new(0, .47, 0)
		local pieces = {
			{"CircuitPlate", Vector3.new(width, .85, depth), frame, Art.Charcoal},
			{"LongTrace", Vector3.new(width * .67, .12, .65), face * CFrame.new(-width * .08, 0, depth * .29), Art.Trace},
			{"TraceTurn", Vector3.new(.65, .12, depth * .45), face * CFrame.new(width * .24, 0, depth * .08), Art.Trace},
			{"EdgeTrace", Vector3.new(.65, .65, depth * .58), frame * CFrame.new(width / 2 + .015, 0, -depth * .08), Art.Trace},
		}
		for _, x in {-1, 1} do
			table.insert(pieces, {"ChunkyBrace", Vector3.new(2.1, 3.5, 2.1), frame * CFrame.new(x * math.min(width * .34, 5.5), -2.8, 0) * CFrame.Angles(0, 0, math.rad(x * 28)), Art.Silver})
		end
		local clear = true
		for _, contact in contacts do
			local bodyFrame = contact.CFrame * CFrame.new(0, contact.Size.Y/2 + 4, 0)
			local bodySize = Vector3.new(contact.Size.X+3, 8, contact.Size.Z+3)
			for _, piece in pieces do
				if Art.Overlaps(bodyFrame, bodySize, piece[3], piece[2]) then clear = false; break end
			end
			if not clear then break end
		end
		-- Overlapping levels retain open headroom beneath the upper bank.
		if not clear then table.insert(omitted, base.Parent:GetFullName():sub(#course:GetFullName()+2)); continue end
		local unit = Art.Model(group, "Plate" .. index)
		unit:SetAttribute("HostBank", base.Parent:GetFullName():sub(#course:GetFullName() + 2))
		for _, piece in pieces do Art.Block(unit, piece[1], piece[2], piece[3], piece[4]) end
		unit.PrimaryPart = unit.CircuitPlate
		built += 1
	end
	group:SetAttribute("PlateCount", built)
	group:SetAttribute("OpenHeadroomBanks", table.concat(omitted, ";"))
end

local function districtLayers(parent: Instance, origin: Vector3)
	local group = Art.Model(parent, "DistrictLayers")
	local layers = {
		{"Creamy", Vector3.new(69, -6, -232), Vector3.new(40, 7, 10), -12},
		{"Creamy", Vector3.new(150, -4, -168), Vector3.new(26, 6, 10), 17},
		{"Thocky", Vector3.new(214, 4, -23), Vector3.new(29, 8, 12), -7},
		{"Thocky", Vector3.new(202, 8, 108), Vector3.new(28, 7, 12), 10},
		{"Clacky", Vector3.new(-83, 7, 228), Vector3.new(28, 8, 10), 12},
		{"Clacky", Vector3.new(-150, 8, 166), Vector3.new(28, 6, 10), -8},
		{"Clicky", Vector3.new(-232, -2, -37), Vector3.new(28, 8, 11), -10},
		{"Clicky", Vector3.new(-195, 5, -133), Vector3.new(30, 7, 11), 12},
	}
	for index, data in layers do
		local family, position, size, angle = data[1], data[2], data[3], data[4]
		local unit = Art.Model(group, family .. "Layer" .. index)
		local frame = CFrame.new(origin + position) * CFrame.Angles(0, math.rad(angle), 0)
		Art.Block(unit, "Housing", size, frame, Art.Charcoal)
		Art.Block(unit, "CaseLip", Vector3.new(size.X + .2, .8, size.Z + .2), frame * CFrame.new(0, size.Y / 2 - .1, 0), Art.Palette[family][1])
		for _, side in {-1, 1} do
			Art.Block(unit, "DistrictInsert", Vector3.new(size.X - 2, size.Y - 2, .6), frame * CFrame.new(0, 0, side * (size.Z / 2 + .05)), Art.Palette[family][2])
			Art.Block(unit, "CircuitTrace", Vector3.new(size.X * .54, .8, .7), frame * CFrame.new(-2, -size.Y * .14, side * (size.Z / 2 + .4)), Art.Trace)
			Art.Block(unit, "TraceReturn", Vector3.new(.8, size.Y * .54, .7), frame * CFrame.new(size.X * .2 - 2, size.Y * .08, side * (size.Z / 2 + .4)), Art.Trace)
		end
		unit.PrimaryPart = unit.Housing
	end
end

function Environment.Build(course: Model, origin: Vector3, template: MeshPart): Model
	local root = Art.Model(course, "MapEnvironment")
	root:SetAttribute("MapRevision", "KC_MAP_M04_01")
	root:SetAttribute("ArtworkPhysics", "Static, noncolliding, nontouching and nonquerying")
	Landmarks.Build(root, origin, template)
	plates(root, course)
	districtLayers(root, origin)
	return root
end

return Environment
