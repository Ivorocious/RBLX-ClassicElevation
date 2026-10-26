--!strict

local ServerStorage = game:GetService("ServerStorage")
local Builder = {}
local ORIGIN = CFrame.new(1565, 370, -790)

local function point(value): Vector3
	return Vector3.new(-value[1], value[3], value[2])
end

function Builder.Install(importName: string, data, modelName: string?)
	assert(game.PlaceId == 85558151074819, "Wrong place")
	local targetName = modelName or "Lobby"
	assert(not workspace:FindFirstChild(targetName), "Preserve the existing lobby before installing a revision")
	local source = require(script.Parent.Parent.AssetStorage).Folder("AssetImports"):FindFirstChild(importName)
	assert(source and source:IsA("Model"), "Insert the Blender model first")
	local model = source:Clone()
	model.Name = targetName
	local editable = Instance.new("Folder")
	editable.Name, editable.Parent = "Editable", model
	local groups, floors = {}, {}
	local floorNames = { Lower = "01_Lower", Arrival = "02_Arrival", Shops = "03_Shops", Podium = "04_Podium" }
	local function component(name: string?): Instance
		if not name then return model end
		if groups[name] then return groups[name] end
		local definition = data.components and data.components[name]
		local floorName = if definition then floorNames[definition.floor] else "05_Architecture"
		if not floors[floorName] then
			local floor = Instance.new("Folder")
			floor.Name, floor.Parent = floorName, editable
			floors[floorName] = floor
		end
		local group = Instance.new("Model")
		group.Name, group.Parent = name, floors[floorName]
		group:SetAttribute("EditableComponent", true)
		group:SetAttribute("MoveAsModel", "Move or rotate this whole model so its collision, seats and lights follow.")
		if definition then group.WorldPivot = ORIGIN * CFrame.new(point(definition.pivot)) end
		groups[name] = group
		return group
	end
	local markers = {}
	for _, part in model:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected script in asset")
		if part:IsA("MeshPart") then
			for _, key in { "Origin", "Right", "Up", "Forward" } do
				if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
			end
		end
	end
	for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing calibration marker " .. key) end
	local scale = 10 / (markers.Right.Position - markers.Origin.Position).Magnitude
	model:ScaleTo(model:GetScale() * scale)
	local sourceFrame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Origin.Position - markers.Right.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CFrame = ORIGIN * sourceFrame:ToObjectSpace(part.CFrame)
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
			local materialName = string.match(part.Name, "__([^_]+)__")
			local color = data.colors[materialName]
			if color then part.Color = Color3.new(color[1], color[2], color[3]) end
			part.Material = if materialName == "Glow" or materialName == "Lamp" or materialName == "Fire" or materialName == "Flame" then Enum.Material.Neon
				elseif materialName == "Gold" or materialName == "Silver" or materialName == "Bronze" then Enum.Material.Metal
				elseif materialName == "Blue" then Enum.Material.Fabric
				else Enum.Material.SmoothPlastic
			if part:IsA("MeshPart") then part.TextureID = ""; part.DoubleSided = true; part.RenderFidelity = Enum.RenderFidelity.Precise end
			if string.sub(part.Name, 1, 6) == "Marker" then
				part.Transparency, part.CanQuery, part.Locked = 1, false, true
			else
				local section = string.match(part.Name, "^(.-)__")
				part.Parent = component(section)
			end
		end
	end
	local colliders = Instance.new("Folder")
	colliders.Name, colliders.Parent = "WalkingSurfaces", model
	for index, definition in data.colliders do
		local part = Instance.new("Part")
		part.Name = string.format("Collider%03d", index)
		part.Size = Vector3.new(definition.s[1], definition.s[3], definition.s[2])
		part.CFrame = ORIGIN * CFrame.new(point(definition.p))
		part.Anchored, part.Transparency = true, 1
		part.CanCollide, part.CanTouch, part.CanQuery = true, false, true
		part.Locked = true
		part:SetAttribute("LobbyCollision", true)
		if definition.kind == "barrier" then part.Name = "InvisibleBarrier"; part:SetAttribute("InvisibleBarrier", true) end
		if definition.kind == "tree-trunk" then part.Name = "TreeTrunkCollider"; part:SetAttribute("LobbyTreeTrunk", true) end
		part.Parent = if data.colliderOwners then component(data.colliderOwners[index]) else colliders
	end
	local lamps = Instance.new("Folder")
	lamps.Name, lamps.Parent = "Lighting", model
	for index, position in data.lights do
		local part = Instance.new("Part")
		part.Name = "Lantern" .. index
		part.Size, part.CFrame = Vector3.one * 0.1, ORIGIN * CFrame.new(point(position))
		part.Anchored, part.Transparency = true, 1
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Locked = true
		part.Parent = if data.lightOwners then component(data.lightOwners[index]) else lamps
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Shadows = Color3.fromRGB(255, 204, 125), 0.65, 18, false
		if data.lightOwners and string.match(data.lightOwners[index], "^Lower_Ceiling_") then
			light.Color, light.Brightness, light.Range = Color3.fromRGB(255, 239, 211), .35, 28
		end
		light.Parent = part
	end
	local marker = Instance.new("Part")
	marker.Name, marker.Size, marker.CFrame = "LobbySpawnPadMarker", Vector3.one, ORIGIN * CFrame.new(point(data.spawn))
	marker.Anchored, marker.Transparency = true, 1
	marker.CanCollide, marker.CanTouch, marker.CanQuery = false, false, false
	marker.Parent = model
	model.PrimaryPart = marker
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name, spawnLocation.Size, spawnLocation.CFrame = "SpawnLocation", Vector3.new(10, .15, 10), marker.CFrame
	spawnLocation.Anchored, spawnLocation.CanCollide, spawnLocation.Transparency = true, false, 1
	spawnLocation.Neutral, spawnLocation.Duration, spawnLocation.Parent = true, 0, model
	local spectator = marker:Clone()
	spectator.Name, spectator.CFrame, spectator.Parent = "SpectatorPadMarker", ORIGIN * CFrame.new(point({20,-40,0})), model
	local seating = Instance.new("Folder")
	seating.Name, seating.Parent = "BenchSeats", model
	for index, position in data.seats or {} do
		local seat = Instance.new("Seat")
		seat.Name, seat.Size = "BenchSeat" .. index, Vector3.new(2.3, .2, 2)
		seat.CFrame = ORIGIN * CFrame.new(point(position)) * CFrame.Angles(0, math.rad(position[4] or 0), 0)
		seat.Anchored, seat.Transparency, seat.CanCollide, seat.CanTouch = true, 1, true, true
		seat.Locked = true
		seat.Parent = if data.seatOwners then component(data.seatOwners[index]) else seating
	end
	local podium = Instance.new("Model")
	podium.Name, podium.Parent = "Podium", model
	local slots = Instance.new("Folder")
	slots.Name, slots.Parent = "Slots", podium
	local names = { ["1"] = "First", ["2"] = "Second", ["3"] = "Third" }
	for _, tag in data.tags do
		if tag.kind ~= "podium" then continue end
		local slot = Instance.new("Model")
		slot.Name, slot.Parent = names[tag.rank], slots
		local display = marker:Clone()
		display.Name, display.CFrame, display.Parent = "DisplayMarker", ORIGIN * CFrame.new(point(tag.p)), slot
		display:SetAttribute("AvatarScale", tag.scale)
		local panel = marker:Clone()
		panel.Name, panel.Size = "Nameplate", Vector3.new(14, 5, .1)
		panel.CFrame, panel.Parent = ORIGIN * CFrame.new(point(tag.panel)), slot
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Front, Vector2.new(840,300), panel
		for index, name in {"WinnerName", "TimeLabel"} do
			local label = Instance.new("TextLabel")
			label.Name, label.BackgroundTransparency = name, 1
			label.Position, label.Size = UDim2.fromScale(.02,(index-1)*.5), UDim2.fromScale(.96,.48)
			label.Text = if index == 1 then "No result yet" else "—"
			label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(255,246,216), .5
			label.TextScaled, label.Font, label.Parent = true, Enum.Font.GothamBold, gui
		end
	end
	if groups.Monument then groups.Monument.Parent = podium end
	if groups.MonumentFinish then groups.MonumentFinish.Parent = podium end
	local returnZone = Instance.new("Part")
	returnZone.Name, returnZone.Size = "LobbyFallReturn", Vector3.new(150, 1, 140)
	returnZone.CFrame = ORIGIN * CFrame.new(0, -16, 0)
	returnZone.Anchored, returnZone.Transparency = true, 1
	returnZone.CanCollide, returnZone.CanQuery, returnZone.CanTouch = false, false, true
	returnZone.Parent = model
	model:SetAttribute("BlenderRevision", data.revision)
	model:SetAttribute("VisibleArchitecture", "Blender")
	model:SetAttribute("ComparisonOnly", false)
	model:SetAttribute("ManualEditing", true)
	model:SetAttribute("EditingRevision", 1)
	model.Parent = workspace
	return model
end

function Builder.EnsureTreeCollision(model: Model)
	local data = require(script.Parent.BlenderManifest)
	for index, definition in data.colliders do
		if definition.kind ~= "tree-trunk" then continue end
		local owner = data.colliderOwners[index]
		local group = model:FindFirstChild(owner, true)
		assert(group and group:IsA("Model"), "Missing editable tree " .. owner)
		if group:FindFirstChild("TreeTrunkCollider") then continue end
		local scale = group:GetScale()
		local offset = point(definition.p) - point(data.components[owner].pivot)
		local part = Instance.new("Part")
		part.Name = "TreeTrunkCollider"
		part.Size = Vector3.new(definition.s[1], definition.s[3], definition.s[2]) * scale
		part.CFrame = group:GetPivot() * CFrame.new(offset * scale)
		part.Anchored, part.Transparency, part.CastShadow = true, 1, false
		part.CanCollide, part.CanTouch, part.CanQuery = true, false, true
		part:SetAttribute("LobbyCollision", true)
		part:SetAttribute("LobbyTreeTrunk", true)
		part.Locked = true
		part.Parent = group
	end
end

function Builder.Ensure(): Model
	local existing = workspace:FindFirstChild("Lobby")
	if existing then
		Builder.EnsureTreeCollision(existing :: Model)
		return existing :: Model
	end
	return Builder.Install("SkycourtB10Import", require(script.Parent.BlenderManifest))
end

return Builder
