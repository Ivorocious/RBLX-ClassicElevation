--!nonstrict
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelAssemblyConfig)
local Assembly = {}

local function decorativeParts(model, update)
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			assert(not item.CanCollide and not item.CanQuery and not item.CanTouch, "Assembly expects decorative parts")
			update(item)
		end
	end
end

local function radius(contact, axis)
	return math.abs(contact.CFrame.RightVector:Dot(axis)) * contact.Size.X / 2
		+ math.abs(contact.CFrame.LookVector:Dot(axis)) * contact.Size.Z / 2
end

local function overlaps(first, second)
	local difference = second.Position - first.Position
	for _, axis in {first.CFrame.RightVector, first.CFrame.LookVector, second.CFrame.RightVector, second.CFrame.LookVector} do
		if math.abs(difference:Dot(axis)) >= radius(first, axis) + radius(second, axis) - .001 then return false end
	end
	return true
end

local function flatFloorLayers(course)
	local floors = {}
	for _, contact in course.Obstacles:GetDescendants() do
		if contact:IsA("BasePart") and contact:GetAttribute("MCWalkable") == true
			and contact.CFrame.UpVector.Y > .999999 and contact.Parent:FindFirstChild("StoneSkin") then
			table.insert(floors, {contact = contact, skin = contact.Parent.StoneSkin,
				top = contact.Position.Y + contact.Size.Y / 2, layer = 0, path = contact:GetFullName()})
		end
	end
	table.sort(floors, function(a, b) return a.path < b.path end)
	local layered, maximum = 0, 0
	for index, floor in floors do
		local used = {}
		for previous = 1, index - 1 do
			local other = floors[previous]
			if math.abs(floor.top - other.top) < .0001 and overlaps(floor.contact, other.contact) then used[other.layer] = true end
		end
		while used[floor.layer] do floor.layer += 1 end
		assert(floor.layer <= Config.MaximumFloorLayer, "Too many overlapping floor skins")
		if floor.layer > 0 then
			local offset = Vector3.new(0, -floor.layer * Config.FloorLayerStep, 0)
			decorativeParts(floor.skin, function(item) item.CFrame += offset end)
			floor.skin.WorldPivot += offset
			layered += 1
		end
		maximum = math.max(maximum, floor.layer)
	end
	return layered, maximum
end

local function visualTop(contact)
	local skin = contact.Parent:FindFirstChild("StoneSkin")
	local maximum = 0
	if skin then
		for _, item in skin:GetDescendants() do
			if not item:IsA("BasePart") then continue end
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local corner = item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
				maximum = math.max(maximum, contact.CFrame:PointToObjectSpace(corner).Y - contact.Size.Y / 2)
			end end end
		end
	end
	contact:SetAttribute("VisualTopOffset", maximum)
end

function Assembly.Apply(course)
	assert(course:GetAttribute("VisualAssemblyApplied") ~= true, "Visual assembly already applied")
	local layered, maximum = flatFloorLayers(course)
	local redCount = 0
	for _, contact in course:GetDescendants() do
		if not contact:IsA("BasePart") then continue end
		if contact:GetAttribute("MCWalkable") == true then visualTop(contact) end
		if contact:IsA("Part") and contact:GetAttribute("MoonlitHazard") == true then
			assert(contact.CanQuery and contact.Transparency < 1 and not contact:FindFirstChildOfClass("DataModelMesh"))
			if contact:GetAttribute("Role") ~= "VisibleRouteHazard" then
				local visual = Instance.new("BlockMesh")
				visual.Name, visual.Scale, visual.Parent = "RedVisualInset", Config.RedRenderScale, contact
			end
			redCount += 1
		end
	end
	assert(redCount >= 21, "Build the visible hurdles and upright gates on their course supports")
	course:SetAttribute("LayeredFloorUnits", layered)
	course:SetAttribute("MaximumFloorVisualLayer", maximum)
	course:SetAttribute("VisibleRouteHazards", redCount)
	course:SetAttribute("VisualAssemblyApplied", true)
end

return Assembly
