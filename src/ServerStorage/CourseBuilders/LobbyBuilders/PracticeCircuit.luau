--!strict
local Builder = {}

function Builder.Recipe(line: string): {any}
	if line == "Normal" then
		return {
			{x=17,z=-15,height=1.2,width=5,native="Collider299"},
			{x=16,z=-8,height=2.3,width=4.4,native="Collider300"},
			{x=12,z=-2,height=3.3,width=4.5,native="Collider301"},
			{x=5,z=1,height=4.2,width=4.6,native="Collider302"},
			{x=-3,z=1,height=4.8,width=4.6,native="Collider303"},
			{x=-10,z=-2,height=3.8,width=4.6,native="Collider304"},
			{x=-16,z=-8,height=2.5,width=4.6,native="Collider305"},
			{x=-17,z=-15,height=1.2,width=5,native="Collider306"},
			{x=-10,z=-17,height=2,width=5}, {x=-3,z=-17,height=2.6,width=5},
			{x=5,z=-17,height=2.6,width=5}, {x=12,z=-17,height=2,width=5},
		}
	end
	return {
		{x=17,z=5,height=1.2,width=3}, {x=17,z=12,height=4.3,width=2.8},
		{x=10,z=15,height=5,width=2.8}, {x=3,z=15,height=4.3,width=2.8},
		{x=-4,z=15,height=5,width=2.8}, {x=-11,z=15,height=4.3,width=2.8},
		{x=-18,z=12,height=5,width=2.8}, {x=-18,z=5,height=4.3,width=2.8},
		{x=-11,z=7,height=5,width=2.8}, {x=-4,z=7,height=4.3,width=2.8},
		{x=3,z=7,height=5,width=2.8}, {x=10,z=7,height=4.3,width=2.8},
	}
end

local function label(part: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RouteLabel"
	gui.Size = UDim2.fromOffset(150, 32)
	gui.StudsOffset = Vector3.new(0, 1.6, 0)
	gui.MaxDistance = 65
	gui.AlwaysOnTop = false
	gui.Parent = part
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 0.25
	textLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 32)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 15
	textLabel.Text = text
	textLabel.Parent = gui
end

local function portal(parent: Instance, name: string, position: Vector3, config: any, text: string): BasePart
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("PracticeRecipe", "PortalC01")
	for _, side in ipairs({-1, 1}) do
		local post = Instance.new("Part")
		post.Name = "PortalPost" .. side
		post.Anchored = true
		post.CanCollide = false
		post.Size = Vector3.new(0.7, config.PortalSize.Y, 0.7)
		post.Position = position + Vector3.new(side * config.PortalSize.X / 2, 0, 0)
		post.Material = Enum.Material.Neon
		post.Color = Color3.fromRGB(119, 177, 220)
		post.Parent = folder
	end
	local trigger = Instance.new("Part")
	trigger.Name = "PortalTrigger"
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Size = config.PortalSize
	trigger.Position = position
	trigger.Material = Enum.Material.Neon
	trigger.Color = Color3.fromRGB(119, 177, 220)
	trigger.Transparency = 0.6
	trigger.Parent = folder
	label(trigger, text)
	folder.Parent = parent
	return trigger
end

function Builder.Ensure(lobby: Instance, config: any, roomOverride: Instance?, worldOverride: Instance?): (Model?, string?, BasePart?)
	local world = worldOverride or workspace
	local existing = world:FindFirstChild(config.CircuitName)
	local oldPortal = lobby:FindFirstChild(config.LobbyPortalName)
	if existing then
		if existing:IsA("Model") and existing.ModelStreamingMode == Enum.ModelStreamingMode.Persistent
			and existing:GetAttribute("PracticeRecipe") == "PortalC01"
			and oldPortal and oldPortal:GetAttribute("PracticeRecipe") == "PortalC01" then
			for _, line in ipairs({"Normal", "Hard"}) do
				local lane = existing:FindFirstChild(line)
				local padCount = #Builder.Recipe(line)
				if not lane or lane:GetAttribute("PadCount") ~= padCount or lane:GetAttribute("LapCount") ~= config.Laps[line]
					or lane:GetAttribute("CheckpointCount") ~= padCount * config.Laps[line] - 1 then
					return nil, "The installed practice area needs its updated route tuning.", nil
				end
			end
			local trigger = oldPortal:FindFirstChild("PortalTrigger")
			if trigger and trigger:IsA("BasePart") then return existing, nil, trigger end
		end
		return nil, "A different practice area already occupies this name.", nil
	end
	if oldPortal then return nil, "A different lobby portal already occupies this name.", nil end
	local room = roomOverride or lobby
	if not roomOverride then
		for _, name in ipairs(config.NativeRoom.Path) do
			local child = room:FindFirstChild(name)
			if not child then return nil, "The accepted stepping-pad source is unavailable.", nil end
			room = child
		end
	end
	local originals = {}
	for _, point in ipairs(Builder.Recipe("Normal")) do
		if point.native then
			local native = room:FindFirstChild(point.native)
			local expected = config.NativeRoom.Center + Vector3.new(point.x, point.height, point.z)
			if not native or not native:IsA("BasePart") or not native.CanCollide
				or (native.Position + Vector3.new(0, native.Size.Y / 2, 0) - expected).Magnitude > config.NativePadPositionTolerance then
				return nil, "The accepted stepping pads differ from the verified source.", nil
			end
			originals[point.native] = native
		end
	end
	local center = config.Room.Center
	local half = config.Room.InteriorSize * 0.5
	for _, line in ipairs({"Normal", "Hard"}) do
		for _, point in ipairs(Builder.Recipe(line)) do
			if math.abs(point.x) + point.width / 2 > half.X or math.abs(point.z) + point.width / 2 > half.Z then
				return nil, "Practice pads do not fit the isolated floor.", nil
			end
		end
	end
	if #workspace:GetPartBoundsInBox(CFrame.new(center + Vector3.new(0, 12, 0)), config.AreaClearanceSize) > 0 then
		return nil, "The separate practice area is occupied; choose a clear origin.", nil
	end
	local circuit = Instance.new("Model")
	circuit.Name = config.CircuitName
	circuit.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	circuit:SetAttribute("PracticeRecipe", "PortalC01")
	circuit:SetAttribute("FloorY", center.Y)
	circuit:SetAttribute("Center", center)
	circuit:SetAttribute("InteriorSize", config.Room.InteriorSize)
	local floor = Instance.new("Part")
	floor.Name = "PracticeFloor"
	floor.Anchored = true
	floor.CanCollide = true
	floor.Size = config.FloorSize
	floor.Position = center - Vector3.new(0, config.FloorSize.Y / 2, 0)
	floor.Color = Color3.fromRGB(229, 223, 204)
	floor.Material = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Studs
	floor.Parent = circuit
	for _, edge in ipairs({{Vector3.new(72,3,0.5),Vector3.new(0,1.5,-31)},
		{Vector3.new(72,3,0.5),Vector3.new(0,1.5,31)},
		{Vector3.new(0.5,3,62),Vector3.new(-36,1.5,0)},
		{Vector3.new(0.5,3,62),Vector3.new(36,1.5,0)}}) do
		local rail = Instance.new("Part")
		rail.Name = "FloorEdgeRail"
		rail.Anchored = true
		rail.Size, rail.Position = edge[1], center + edge[2]
		rail.Color = Color3.fromRGB(119,177,220)
		rail.Parent = circuit
	end
	for _, line in ipairs({"Normal", "Hard"}) do
		local lane = Instance.new("Folder")
		lane.Name = line
		lane.Parent = circuit
		local points = Builder.Recipe(line)
		lane:SetAttribute("PadCount", #points)
		lane:SetAttribute("LapCount", config.Laps[line])
		lane:SetAttribute("CheckpointCount", #points * config.Laps[line] - 1)
		for position, point in ipairs(points) do
			local index = position - 1
			local name = if index == 0 then "Start" else "Checkpoint" .. index
			local part = Instance.new("Part")
			part.Name = name
			part.Anchored = true
			part.CanCollide = true
			if point.native then
				local native = originals[point.native]
				part.Size = native.Size
				part.Material, part.TopSurface, part.BottomSurface = native.Material, native.TopSurface, native.BottomSurface
				part.CFrame = CFrame.new(center + Vector3.new(point.x, point.height - part.Size.Y / 2, point.z)) * native.CFrame.Rotation
			else
				part.Size = Vector3.new(point.width, 0.6, point.width)
				part.Position = center + Vector3.new(point.x, point.height - 0.3, point.z)
				part.Material = Enum.Material.SmoothPlastic
				part.TopSurface = Enum.SurfaceType.Studs
				part.BottomSurface = Enum.SurfaceType.Smooth
			end
			part.Color = if line == "Normal" then Color3.fromRGB(107, 169, 118) else Color3.fromRGB(216, 148, 75)
			part:SetAttribute("PracticeLine", line)
			part:SetAttribute("PracticeIndex", index)
			part:SetAttribute("CopiedPadShape", point.native)
			part.Parent = lane
			label(part, if name == "Start" then line .. " · START / FINISH" else line .. " " .. index)
		end
	end
	local returnPortal = portal(circuit, "ReturnPortal", center + config.ReturnPortalOffset, config, "RETURN TO LOBBY")
	returnPortal:SetAttribute("PracticePortal", "Exit")
	circuit.Parent = world
	local entryPortal = portal(lobby, config.LobbyPortalName, config.LobbyPortalPosition, config, "ENTER PRACTICE PORTAL")
	entryPortal:SetAttribute("PracticePortal", "Enter")
	return circuit, nil, entryPortal
end

return Builder
