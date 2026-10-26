--!nonstrict
local MeshKit = require(script.Parent.Parent.MoonlitCitadel.MeshKit)
local Palette = require(script.Parent.Parent.MoonlitCitadel.Kit).Palette
local RouteHazards = {}

local function positive(value, name)
	assert(typeof(value) == "number" and value == value and value > 0 and value < math.huge, name .. " must be positive and finite")
	return value
end

local function resolve(root, path)
	local item = root
	for token in string.gmatch(path, "[^/]+") do item = item and item:FindFirstChild(token) end
	assert(item and item:IsA("BasePart") and item:GetAttribute("MCWalkable") == true, "Missing hazard support " .. path)
	return item
end

local function skinPost(parent, name, frame, height, depth)
	MeshKit.Place(parent, name, "MC_GuideIron", frame * CFrame.new(0, height / 2, depth / 2 + .13),
		Vector3.new(.28, height / 52, .28))
end

function RouteHazards.Build(course, layout, origin)
	local records = layout.RouteHazards or {}
	if #records == 0 then return end
	assert(not course.Obstacles:FindFirstChild("RouteHazards"), "Route hazards already built")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RouteHazards", course.Obstacles
	for _, data in records do
		assert(not folder:FindFirstChild(data.name), "Duplicate route hazard " .. data.name)
		assert(data.kind == "Hurdle" or data.kind == "CrenelWeave", "Unknown route hazard kind")
		local support = resolve(course, data.surfacePath)
		assert(typeof(data.frame) == "CFrame" and data.frame.UpVector.Y > .999, "Route hazard needs a level floor-top frame")
		assert(typeof(data.size) == "Vector3", "Route hazard needs lane width, height and depth")
		local width, height, depth = positive(data.size.X, "Lane width"), positive(data.size.Y, "Hazard height"), positive(data.size.Z, "Hazard depth")
		local frame = CFrame.new(origin) * data.frame
		local top = support.CFrame * CFrame.new(0, support.Size.Y / 2, 0)
		local point = top:PointToObjectSpace(frame.Position)
		assert(math.abs(point.Y) < .08 and math.abs(point.X) < support.Size.X / 2 and math.abs(point.Z) < support.Size.Z / 2,
			data.name .. " must stand on its declared floor")
		local supportWidth = math.abs(top.RightVector:Dot(frame.RightVector)) * support.Size.X
			+ math.abs(top.LookVector:Dot(frame.RightVector)) * support.Size.Z
		assert(width >= supportWidth - .05, data.name .. " lane must span its declared floor")
		assert(math.abs(frame.RightVector:Dot(frame.Position - top.Position)) < .05, data.name .. " must be centered across its floor")
		local centerX, centerY, contactWidth = 0, height / 2, width + .8
		if data.kind == "Hurdle" then
			centerY = positive(data.centerHeight or 1.6, "Hurdle center height")
			assert(height >= .8 and centerY - height / 2 >= .4 and centerY + height / 2 <= 3.2, "Hurdle must require a fair ordinary jump")
		else
			assert(height >= 2.4 and height <= 3.2, "Castle weave blocks must stay low and visible")
			local opening = positive(data.openingWidth, "Gate opening")
			assert(opening >= (if data.difficulty == "Expert" then 3.2 else 5) and opening < width, "Weave needs a supported body opening smaller than its lane")
			assert(data.side == -1 or data.side == 1, "Weave gate needs a closed side")
			contactWidth, centerX = width - opening + .8, data.side * (opening + .8) / 2
		end
		local unit = Instance.new("Model")
		unit.Name, unit.Parent = data.name, folder
		unit:SetAttribute("ObstaclePattern", if data.kind == "Hurdle" then "05_RedHurdles" else "CastleCrenelWeave")
		unit:SetAttribute("RouteHazardKind", data.kind)
		unit:SetAttribute("SupportPath", data.surfacePath)
		unit:SetAttribute("LaneWidth", width)
		local contact = Instance.new("Part")
		contact.Name, contact.Size = "RedContact", Vector3.new(contactWidth, height, depth)
		contact.CFrame = frame * CFrame.new(centerX, centerY, 0)
		contact.Anchored, contact.CanCollide, contact.CanQuery, contact.CanTouch = true, false, true, true
		contact.TopSurface, contact.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		contact.Color, contact.Material, contact.CastShadow = Palette.Red, Enum.Material.Neon, false
		contact:SetAttribute("Role", "VisibleRouteHazard")
		contact:SetAttribute("MoonlitHazard", true)
		contact.Parent, unit.PrimaryPart = unit, contact
		unit.WorldPivot = frame
		if data.kind == "Hurdle" then
			for _, side in {-1, 1} do skinPost(unit, "IronBrassPost" .. side, frame * CFrame.new(side * (width / 2 + .2), 0, 0), centerY + height / 2, depth) end
		else
			skinPost(unit, "IronBrassMount", frame * CFrame.new(centerX, 0, 0), height, depth)
		end
	end
end

return RouteHazards
