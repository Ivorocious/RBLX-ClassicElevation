--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Wayfinding = {}
local Environment = require(script.Parent.EnvironmentPlan)
local LibraryName = "MoonlitCitadel_P3Rework_RW01Library"
local Colors = {
	Shared = Color3.fromRGB(246, 240, 214),
	Normal = Color3.fromRGB(242, 225, 155),
	Expert = Color3.fromRGB(205, 167, 244),
	Return = Color3.fromRGB(224, 225, 231),
}
local Ink = Color3.fromRGB(28, 35, 48)
local Tag = "MoonlitWayfinding"
local v = Vector3.new
local Labels = {
	E1_StoneArch = {"WEST ARCHES", "INNER PRECISION"},
	E2_Lantern = {"WIDE LANTERN PATH", "NARROW LANTERN PATH"},
	E3_UpperLift = {"EAST GALLERY", "WEST PRECISION"},
}

local function findContact(course, path)
	local item = course
	for name in string.gmatch(path, "[^/]+") do
		item = item:FindFirstChild(name)
		assert(item, "Missing wayfinding contact: " .. path)
	end
	assert(item:IsA("BasePart") and item:GetAttribute("MCWalkable") == true,
		"Wayfinding needs a fixed walkable contact: " .. path)
	return item
end

local function surfacePoint(contact, offset)
	offset = offset or Vector3.zero
	local visualTop = math.max(0, contact:GetAttribute("VisualTopOffset") or 0)
	return contact.CFrame:PointToWorldSpace(Vector3.new(offset.X, contact.Size.Y / 2 + offset.Y + visualTop + .04, offset.Z))
end

local function directionFrame(contact, point, target)
	local up = contact.CFrame.UpVector
	local direction = target - point
	direction -= up * direction:Dot(up)
	assert(direction.Magnitude > .05, "Wayfinding target must have a forward direction: " .. contact:GetFullName() .. " -> " .. tostring(target))
	direction = direction.Unit
	return CFrame.fromMatrix(point, direction:Cross(up).Unit, up, -direction)
end

local function part(parent, name, size, frame, color, role)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, frame
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, false, false, false
	item.CastShadow, item.Material, item.Color = false, Enum.Material.SmoothPlastic, color
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item:SetAttribute("Role", "DecorativeWayfinding")
	item:SetAttribute("GuidanceKind", role)
	CollectionService:AddTag(item, Tag)
	item.Parent = parent
	return item
end

local function textOn(item, face, text, color, pixelsPerStud, richText)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = if face == Enum.NormalId.Back then "StaticLetteringBack" else "StaticLettering", face
	gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, pixelsPerStud or 40
	gui.AlwaysOnTop, gui.LightInfluence, gui.MaxDistance = false, 0, 90
	gui.Active, gui.Parent = false, item
	local textLabel = Instance.new("TextLabel")
	textLabel.Name, textLabel.Size = "Legend", UDim2.fromScale(.94, .90)
	textLabel.Position, textLabel.AnchorPoint = UDim2.fromScale(.5, .5), Vector2.new(.5, .5)
	textLabel.BackgroundTransparency, textLabel.TextColor3 = 1, color
	textLabel.Text, textLabel.Font = text, Enum.Font.GothamBold
	textLabel.RichText = richText == true
	textLabel.TextScaled, textLabel.TextWrapped = true, true
	textLabel.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 12, 74, textLabel
end

local function floorArrow(folder, name, contact, offset, target, mode)
	local library = assert(game.ServerStorage.CourseAssetKits:FindFirstChild(LibraryName))
	return Environment.PlaceSolidArrow(folder, library, name, contact, surfacePoint(contact, offset), target, mode)
end

local function lip(folder, name, contact, offset, target, mode, kind)
	local frame = directionFrame(contact, surfacePoint(contact, offset), target)
	local width = math.min(contact.Size.X, contact.Size.Z, if mode == "Expert" then 4 else 6)
	local right = contact.CFrame:VectorToObjectSpace(frame.RightVector)
	local forward = contact.CFrame:VectorToObjectSpace(frame.LookVector)
	local halfX, halfZ, depth = contact.Size.X / 2 - .12, contact.Size.Z / 2 - .12, .28
	if math.abs(right.X) > .001 then width = math.min(width, (halfX * 2 - math.abs(forward.X) * depth) / math.abs(right.X)) end
	if math.abs(right.Z) > .001 then width = math.min(width, (halfZ * 2 - math.abs(forward.Z) * depth) / math.abs(right.Z)) end
	assert(width > .2, "Landing trim needs a supported footprint: " .. contact:GetFullName())
	local extentX = math.abs(right.X) * width / 2 + math.abs(forward.X) * depth / 2
	local extentZ = math.abs(right.Z) * width / 2 + math.abs(forward.Z) * depth / 2
	local center = contact.CFrame:PointToObjectSpace(frame.Position)
	local travelX, travelZ = math.max(0, halfX - extentX), math.max(0, halfZ - extentZ)
	center = Vector3.new(math.clamp(center.X, -travelX, travelX), center.Y,
		math.clamp(center.Z, -travelZ, travelZ))
	frame = CFrame.fromMatrix(contact.CFrame:PointToWorldSpace(center), frame.RightVector, frame.UpVector, -frame.LookVector)
	local trim = part(folder, name, Vector3.new(width, .035, depth), frame * CFrame.new(0, .028, 0), Colors[mode], kind)
	trim:SetAttribute("SourceContact", contact:GetFullName())
end

local function plaque(folder, name, origin, data)
	local frame = CFrame.lookAt(origin + data.center, origin + data.faceTarget, Vector3.yAxis)
	local board = part(folder, name, data.size, frame, Ink, "DecisionSign")
	textOn(board, Enum.NormalId.Front, data.front, Colors.Shared, 42, true)
	textOn(board, Enum.NormalId.Back, data.back, Colors.Shared, 42, true)
	part(folder, name .. "Trim", Vector3.new(data.size.X, .12, .18), frame * CFrame.new(0, -1.57, -.04),
		Colors.Shared, "DifficultyTrim")
end

local function nodeKey(node)
	return node.path .. ":" .. tostring(node.offset or Vector3.zero)
end

local function collectRoutes(layout)
	local result = {}
	for _, choices in {{false, false, false}, {true, false, false}, {false, true, false}, {false, false, true}} do
		table.insert(result, layout.GetRoute(choices, {1, 2}))
	end
	table.insert(result, layout.GetRoute({false, false, true}, {1, 1}))
	return result
end

local function inferredForks(routes)
	local normal, result = routes[1], {}
	local demands = {"NARROW TURNING JUMPS", "AIMED JUMPS + TIMING", "RAISED BRACE + TIMING"}
	for branch = 1, 3 do
		local expert, common = routes[branch + 1], 0
		for index = 1, math.min(#normal, #expert) do
			if nodeKey(normal[index]) ~= nodeKey(expert[index]) then break end
			common = index
		end
		assert(common > 0 and normal[common + 1] and expert[common + 1], "Missing explicit Normal/Expert fork")
		local approach, n, e = normal[common], normal[common + 1], expert[common + 1]
		local fork = {name = "E" .. branch, approachPath = approach.path, approachOffset = approach.offset,
			normalPath = n.path, normalOffset = n.offset, expertPath = e.path, expertOffset = e.offset, demand = demands[branch]}
		if branch == 3 and string.find(e.path, "UpperBrace/", 1, true) then
			fork.expertPaths = {e.path, (string.gsub(e.path, "UpperBrace/", "UpperBraceMirror/"))}
		end
		table.insert(result, fork)
	end
	return result
end

local function jumpGuidance(folder, course, routes)
	local uses, jumps, order = {}, {}, {}
	for routeIndex, route in routes do
		for _, node in route do
			if node.kind ~= "Ride" then
				local key = nodeKey(node)
				uses[key] = uses[key] or {}
				uses[key][routeIndex] = true
			end
		end
		for index, node in route do
			local previous = route[index - 1]
			if node.kind ~= "Jump" or not previous or previous.kind == "Ride" then continue end
			local key = nodeKey(previous) .. ">" .. nodeKey(node)
			if jumps[key] then continue end
			jumps[key] = {from = previous, to = node}
			table.insert(order, key)
		end
	end
	local marked = 0
	for index, key in order do
		local jump = jumps[key]
		local from, to = findContact(course, jump.from.path), findContact(course, jump.to.path)
		local role, toRole = from:GetAttribute("Role"), to:GetAttribute("Role")
		local unitName, groupName = from.Parent.Name, from.Parent.Parent.Name
		local firstInChain = string.match(unitName, "^Landing_") or string.match(unitName, "Terrace$")
			or role == "SafeRefuge" or role == "FixedWaitingArea" or role == "BranchApproach" or role == "StartCapacity"
		local importantTransfer = role == "TimedCrossing" or toRole == "TimedCrossing" or string.find(groupName, "UpperBrace", 1, true)
		if not firstInChain and not importantTransfer then continue end
		local departure, landing = surfacePoint(from, jump.from.offset), surfacePoint(to, jump.to.offset)
		local fromUses, toUses = uses[nodeKey(jump.from)], uses[nodeKey(jump.to)]
		local shared = true
		for routeIndex = 1, #routes do
			if not fromUses[routeIndex] or not toUses[routeIndex] then shared = false; break end
		end
		local mode = if shared then "Shared" elseif fromUses[1] and toUses[1] then "Normal" else "Expert"
		local name = "Jump" .. index
		lip(folder, name .. "Landing", to, jump.to.offset, landing + (landing - departure), mode, "LandingTrim")
		marked += 1
	end
	return marked, #order
end

local function applyForks(folder, course, forks)
	local origin = course:GetAttribute("Origin")
	for _, fork in forks do
		local approach = findContact(course, fork.approachPath)
		local targets = {normal = findContact(course, fork.normalPath), expert = findContact(course, fork.expertPath)}
		local label = assert(Labels[fork.name])
		local localCenter = approach.CFrame:PointToObjectSpace(surfacePoint(approach))
		local signPoint = approach.CFrame:PointToWorldSpace(Vector3.new(0, localCenter.Y + 4.1, approach.Size.Z / 2 + 1.4))
		plaque(folder, fork.name .. "ChoiceSign", origin, {
			center = signPoint - origin, faceTarget = signPoint - origin + Vector3.zAxis * 10, size = v(12, 3.4, .15),
			front = '<font color="#F2E19B">NORMAL · ' .. label[1] .. '</font>\n'
				.. '<font color="#CDA7F4">EXPERT · ' .. label[2] .. '</font>',
			back = '<font color="#F2E19B">NORMAL · ' .. label[1] .. '</font>\n'
				.. '<font color="#CDA7F4">EXPERT · ' .. label[2] .. '</font>',
		})
		for _, choice in {{"normal", "Normal", fork.normalOffset}, {"expert", "Expert", fork.expertOffset}} do
			local target = surfacePoint(targets[choice[1]], choice[3])
			local direction = approach.CFrame:VectorToObjectSpace(target - approach.Position) * Vector3.new(1, 0, 1)
			assert(direction.Magnitude > .1, "Fork commitment must leave its decision floor")
			floorArrow(folder, fork.name .. choice[2] .. "Choice", approach, direction.Unit * 5, target, choice[2])
		end
	end
end

local function applyMarkers(folder, course, layout)
	for _, marker in layout.Wayfinding.Markers do
		local contact = findContact(course, marker.path)
		local target = if marker.targetPath then surfacePoint(findContact(course, marker.targetPath), marker.targetOffset)
			else course:GetAttribute("Origin") + marker.targetPoint
		floorArrow(folder, marker.name, contact, if marker.kind == "Board" then v(0, 0, -5) else Vector3.zero, target, marker.mode)
	end
	local start = findContact(course, "Obstacles/Gate/GateCourt/Contact")
	local route = layout.GetRoute({false, false, false}, {1, 2})
	for _, node in route do
		if node.path ~= "Obstacles/Gate/GateCourt/Contact" then
			floorArrow(folder, "StartOnward", start, v(0, 0, -7), surfacePoint(findContact(course, node.path), node.offset), "Shared")
			break
		end
	end
end

function Wayfinding.Apply(course, layout)
	assert(course:IsA("Model") and typeof(layout.GetRoute) == "function", "Course and Layout required")
	local decoration = course:FindFirstChild("Decoration")
	assert(decoration, "Build Decoration before Wayfinding")
	local prior = decoration:FindFirstChild("Wayfinding")
	if prior then
		assert(prior:IsA("Folder") and prior:GetAttribute("WayfindingVersion") == 13
			and prior:GetAttribute("BuildComplete") == true, "Existing Wayfinding is not this completed build")
		return prior
	end
	local folder = Instance.new("Folder")
	folder.Name = "Wayfinding"
	folder:SetAttribute("WayfindingVersion", 13)
	CollectionService:AddTag(folder, Tag)
	local routes = collectRoutes(layout)
	local config = layout.Wayfinding or {}
	-- Build off-tree so a failed contract does not leave a partial course assembly.
	local markedJumps, jumps = jumpGuidance(folder, course, routes)
	applyForks(folder, course, config.Forks or inferredForks(routes))
	applyMarkers(folder, course, layout)
	folder:SetAttribute("JumpCount", jumps)
	folder:SetAttribute("MarkedJumpCount", markedJumps)
	folder:SetAttribute("BuildComplete", true)
	folder.Parent = decoration
	course:SetAttribute("WayfindingApplied", true)
	return folder
end

return Wayfinding
