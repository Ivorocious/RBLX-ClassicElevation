--!strict
local Art = require(script.Parent.EnvironmentParts)
local Parts = require(script.Parent.Parts)
local Layout = require(script.Parent.Layout)
local Wayfinding = {}

local Ink = Color3.fromRGB(24, 31, 39)
local Paper = Color3.fromRGB(250, 247, 231)
local NormalAccent = Color3.fromRGB(110, 203, 172)
local ExpertAccent = Color3.fromRGB(153, 113, 206)

type Body = {frame: CFrame, size: Vector3}
type Scene = {bodies: {Body}, artwork: {BasePart}}

local function decorate(part: BasePart)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CastShadow = false
	part:SetAttribute("Pressable", false)
	part:SetAttribute("Role", "MapArtwork")
	part:SetAttribute("MapArtwork", true)
	part:SetAttribute("KCWayfinding", true)
end

local function block(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3): Part
	local part = Art.Block(parent, name, size, frame, color)
	decorate(part)
	return part
end

local function sceneFor(course: Model): Scene
	local scene: Scene = {bodies = {}, artwork = {}}
	for _, item in course:GetDescendants() do
		if not item:IsA("BasePart") then continue end
		if item.CanCollide and (item.Name == "BankContact" or item.Name == "KeyContact") then
			table.insert(scene.bodies, {
				frame = item.CFrame * CFrame.new(0, item.Size.Y / 2 + 4, 0),
				size = Vector3.new(item.Size.X + 3.6, 8, item.Size.Z + 3.6),
			})
		end
		if item:GetAttribute("MapArtwork") and item.Transparency < .9 then table.insert(scene.artwork, item) end
	end
	return scene
end

local function intersects(part: BasePart, eye: Vector3, target: Vector3): boolean
	local origin = part.CFrame:PointToObjectSpace(eye)
	local delta = part.CFrame:VectorToObjectSpace(target - eye)
	local low, high = .001, .999
	for _, axis in {"X", "Y", "Z"} do
		local half = part.Size[axis] / 2
		if math.abs(delta[axis]) < .00001 then
			if math.abs(origin[axis]) > half then return false end
		else
			local a, b = (-half - origin[axis]) / delta[axis], (half - origin[axis]) / delta[axis]
			low, high = math.max(low, math.min(a, b)), math.min(high, math.max(a, b))
			if low > high then return false end
		end
	end
	return true
end

local function bodyClear(scene: Scene, frame: CFrame, size: Vector3): boolean
	for _, body in scene.bodies do
		if Art.Overlaps(frame, size, body.frame, body.size) then return false end
	end
	return true
end

local function findMount(scene: Scene, host: BasePart, width: number, height: number, recovery: Model?): CFrame
	local surface = host.CFrame * CFrame.new(0, Parts.PressDepth + host.Size.Y / 2, 0)
	local centerHeight = height / 2 + 1.5
	local eyes = {}
	for _, point in {
		Vector3.new(-host.Size.X / 2 + 1, 4.5, 0),
		Vector3.new(-host.Size.X * .3, 4.5, -host.Size.Z * .3),
		Vector3.new(-host.Size.X * .3, 4.5, host.Size.Z * .3),
		Vector3.new(host.Size.X * .3, 4.5, -host.Size.Z * .3),
		Vector3.new(host.Size.X * .3, 4.5, host.Size.Z * .3),
	} do table.insert(eyes, surface:PointToWorldSpace(point)) end
	if recovery then
		local contact = recovery.BankContact :: BasePart
		local spawn = contact:GetAttribute("SpawnCFrame") :: CFrame
		local rows, columns = contact:GetAttribute("SlotRows") or 4, contact:GetAttribute("SlotColumns") or 5
		for row = 1, rows do for column = 1, columns do
			table.insert(eyes, (spawn * CFrame.new((column-(columns+1)/2)*(contact:GetAttribute("SlotSpacingX") or 4.5),1.2,(row-(rows+1)/2)*(contact:GetAttribute("SlotSpacingZ") or 4))).Position)
		end end
	end
	for _, side in {-1, 1} do
		for _, distance in {width / 2 + 3.5, width / 2 + 6.5, width / 2 + 9.5, width / 2 + 13.5} do
			for _, along in {1, 5, -3, 14, 22} do
				local center = surface:PointToWorldSpace(Vector3.new(along, centerHeight, side * (host.Size.Z / 2 + distance)))
				local target = surface:PointToWorldSpace(Vector3.new(-host.Size.X / 2, centerHeight, 0))
				local frame = CFrame.lookAt(center, target)
				local size = Vector3.new(width + .8, height + .8, 2.1)
				local clear = bodyClear(scene, frame, size)
				if clear then
					for _, art in scene.artwork do
						if Art.Overlaps(frame, size, art.CFrame, art.Size + Vector3.one * .5) then clear = false; break end
					end
				end
				if clear then
					for _, eye in eyes do
						for _, offset in {Vector3.zero, Vector3.new(-width * .43, height * .35, -.2), Vector3.new(width * .43, height * .35, -.2), Vector3.new(-width * .43, -height * .35, -.2), Vector3.new(width * .43, -height * .35, -.2)} do
							for _, art in scene.artwork do
								if intersects(art, eye, frame:PointToWorldSpace(offset)) then clear = false; break end
							end
							if not clear then break end
						end
						if not clear then break end
					end
				end
				if clear then return frame end
			end
		end
	end
	error("No clear wayfinding mount beside " .. host:GetFullName())
end

local function textLine(gui: SurfaceGui, existing: TextLabel?, name: string, text: string, y: number, height: number, large: boolean, ink: Color3): TextLabel
	local label = existing or Instance.new("TextLabel")
	label.Name, label.Text, label.Font = name, text, Enum.Font.GothamBold
	label.Position, label.Size = UDim2.fromScale(.06, y), UDim2.fromScale(.88, height)
	label.BackgroundTransparency, label.TextColor3 = 1, ink
	label.TextScaled, label.TextWrapped, label.TextStrokeTransparency = true, true, 1
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	label.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = if large then 34 else 26, if large then 96 else 54, label
	return label
end

local function panel(part: BasePart, parent: Instance, frame: CFrame, size: Vector3, title: string, body: string, footer: string, paper: boolean?)
	assert(not part.CanCollide, "Only existing artwork may be restyled")
	part.Parent, part.CFrame, part.Size = parent, frame, size
	part.Color, part.Material = if paper then Paper else Ink, Enum.Material.SmoothPlastic
	decorate(part)
	local ink = if paper then Ink else Paper
	for _, gui in part:GetChildren() do
		if not gui:IsA("SurfaceGui") then continue end
		gui.CanvasSize, gui.SizingMode = Vector2.new(size.X * 100, size.Y * 100), Enum.SurfaceGuiSizingMode.FixedSize
		gui.LightInfluence, gui.AlwaysOnTop, gui.Enabled = 0, false, true
		gui.ZOffset, gui.MaxDistance = .015, 100
		local existing = gui:FindFirstChildOfClass("TextLabel") :: TextLabel?
		textLine(gui, existing, "Title", title, .05, .22, false, ink)
		textLine(gui, nil, "Meaning", body, .3, .4, true, ink)
		if footer ~= "" then textLine(gui, nil, "Detail", footer, .77, .18, false, ink) end
	end
	part:SetAttribute("WayfindingText", title .. " | " .. body .. (if footer ~= "" then " | " .. footer else ""))
end

local function numberPanel(part: BasePart, parent: Instance, frame: CFrame, size: Vector3, ordinal: number)
	panel(part, parent, frame, size, if ordinal == 0 then "START" else "SAVE", string.format("%02d", ordinal), if ordinal == 0 then "2 LAPS" else "/ " .. Layout.CheckpointCount, true)
	for _, gui in part:GetChildren() do
		if not gui:IsA("SurfaceGui") then continue end
		for _, label in gui:GetChildren() do
			if label:IsA("TextLabel") then label.TextXAlignment = Enum.TextXAlignment.Center end
		end
		local body = gui:FindFirstChild("Meaning") :: TextLabel
		body.Position, body.Size = UDim2.fromScale(.06, .27), UDim2.fromScale(.88, .43)
		local limit = body:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint
		limit.MaxTextSize = 190
	end
end

local function case(parent: Model, frame: CFrame, width: number, height: number, accent: Color3, pole: BasePart)
	local back = block(parent, "HardwareCase", Vector3.new(width + .6, height + .6, 1.2), frame * CFrame.new(0, 0, .75), Art.Charcoal)
	back.Material = Enum.Material.Metal
	parent.PrimaryPart = back
	for _, side in {-1, 1} do
		block(parent, "SilverSide", Vector3.new(.3, height + .3, .35), frame * CFrame.new(side * (width / 2 + .12), 0, -.02), Art.Silver)
		block(parent, "SilverEdge", Vector3.new(width + .3, .3, .35), frame * CFrame.new(0, side * (height / 2 + .12), -.02), Art.Silver)
	end
	block(parent, "FamilyInsert", Vector3.new(width - .8, .4, .4), frame * CFrame.new(0, height / 2 + .36, .08), accent)
	local bottom = frame.Position.Y - height / 2
	pole.Parent, pole.Size = parent, Vector3.new(1.3, 3.1, 1.3)
	pole.CFrame, pole.Color, pole.Material = frame * CFrame.new(0, -height / 2 - 1.5, .8), Art.Charcoal, Enum.Material.Metal
	decorate(pole)
	block(parent, "SocketFoot", Vector3.new(4.6, .8, 3), frame * CFrame.new(0, -height / 2 - 2.7, .8), Art.Charcoal)
	parent:SetAttribute("CaseBottomY", bottom)
end

local function collar(scene: Scene, parent: Model, host: BasePart, accent: Color3)
	local cf = host.CFrame * CFrame.new(0, Parts.PressDepth + host.Size.Y / 2, 0)
	local omitted = 0
	for _, side in {-1, 1} do
		for _, piece in {
			{name = "BankEdge", size = Vector3.new(host.Size.X + 1.8, .55, .8), frame = cf * CFrame.new(0, -1, side * (host.Size.Z / 2 + .5))},
			{name = "BankEnd", size = Vector3.new(.8, .55, host.Size.Z + .8), frame = cf * CFrame.new(side * (host.Size.X / 2 + .5), -1, 0)},
		} do
			if bodyClear(scene, piece.frame, piece.size) then block(parent, piece.name, piece.size, piece.frame, accent) else omitted += 1 end
		end
		for _, z in {-1, 1} do
			local frame = cf * CFrame.new(side * (host.Size.X / 2 + .5), -1.65, z * (host.Size.Z / 2 + .5))
			local size = Vector3.new(2.2, 1.4, 2.2)
			if bodyClear(scene, frame, size) then
				local corner = block(parent, "SocketCorner", size, frame, Art.Charcoal)
				corner.Material = Enum.Material.Metal
			else omitted += 1 end
		end
	end
	parent:SetAttribute("OmittedTrimForHeadroom", omitted)
end

local function departureArrow(scene: Scene, parent: Model, host: BasePart, target: Vector3, color: Color3, name: string)
	local surface = host.CFrame * CFrame.new(0, Parts.PressDepth + host.Size.Y / 2, 0)
	local direction = (target - surface.Position) * Vector3.new(1, 0, 1)
	assert(direction.Magnitude > .01, "Arrow needs an actual departure")
	direction = direction.Unit
	local localDirection = surface:VectorToObjectSpace(direction)
	local reach = math.min(if math.abs(localDirection.X) > .001 then host.Size.X / 2 / math.abs(localDirection.X) else math.huge, if math.abs(localDirection.Z) > .001 then host.Size.Z / 2 / math.abs(localDirection.Z) else math.huge)
	local center = surface.Position + direction * (reach + 2.8) - Vector3.yAxis * 1.1
	local frame = CFrame.lookAt(center, center + direction)
	local pieces = {
		{name = "Stem", size = Vector3.new(.65, .18, 3.2), frame = frame},
		{name = "TipLeft", size = Vector3.new(.65, .18, 2), frame = frame * CFrame.new(-.55, 0, -1.2) * CFrame.Angles(0, math.rad(-45), 0)},
		{name = "TipRight", size = Vector3.new(.65, .18, 2), frame = frame * CFrame.new(.55, 0, -1.2) * CFrame.Angles(0, math.rad(45), 0)},
	}
	for _, piece in pieces do if not bodyClear(scene, piece.frame, piece.size) then return end end
	local arrow = Art.Model(parent, name)
	arrow:SetAttribute("Direction", direction)
	arrow:SetAttribute("Target", target)
	arrow:SetAttribute("Meaning", name)
	for _, piece in pieces do block(arrow, piece.name, piece.size, piece.frame, color) end
end

local function endpoint(unit: Model, departing: boolean): BasePart
	local direct = unit:FindFirstChild("BankContact")
	if direct then return direct :: BasePart end
	local bank = assert(unit:FindFirstChild(if departing then "ExitBank" else "EntryBank") or unit:FindFirstChild(if departing then "Exit" else "Entry"))
	return bank.BankContact :: BasePart
end

local function departureWords(host: BasePart, target: Vector3): string
	local direction = host.CFrame:PointToObjectSpace(target)
	local ahead = if direction.X < -1 then "BACK" else "AHEAD"
	if math.abs(direction.Z) < 1 then return ahead end
	return ahead .. (if direction.Z > 0 then " RIGHT" else " LEFT")
end

function Wayfinding.Build(course: Model, origin: Vector3, _template: MeshPart): Model
	local environment = assert(course:FindFirstChild("MapEnvironment"), "Build the environment before wayfinding")
	local existing = environment:FindFirstChild("Wayfinding")
	if existing then return existing :: Model end
	local scene = sceneFor(course)
	local group = Art.Model(environment, "Wayfinding")
	group:SetAttribute("WayfindingRevision", "KC_WAYFINDING_M02_01")
	group:SetAttribute("Origin", origin)
	group:SetAttribute("Purpose", "Static sign cases and permanent checkpoint identity")
	local units: {[string]: Model} = {}
	for _, unit in course.Districts:GetDescendants() do
		if unit:IsA("Model") and unit:GetAttribute("SequenceId") then units[unit:GetAttribute("SequenceId")] = unit end
	end
	for _, bay in course.CheckpointBays:GetChildren() do units[bay.Name] = bay :: Model end
	local nextFamilies = {F00 = "CREAMY", CP1 = "THOCKY", CP2 = "CLACKY", CP3 = "CLICKY"}
	local siteCount, reused = 0, 0
	for _, id in {"F00", "R1", "CP1", "R2", "CP2", "R3", "CP3", "R4"} do
		local recovery = course.RecoveryPads[id]
		local reference = recovery:FindFirstChild("HostContact") :: ObjectValue?
		local host = if reference then reference.Value :: BasePart else course.CheckpointBays[id].BankContact :: BasePart
		local hostBank = host.Parent :: Model
		local marker = assert(hostBank:FindFirstChild("RecoveryMarker"))
		local flag, pole = marker.Flag :: BasePart, marker.Pole :: BasePart
		local mainPanel = assert(hostBank:FindFirstChild(if reference then "MidpointCheckpointSign" else "RecoverySign")) :: BasePart
		local branch
		for _, candidate in Layout.Branches do if candidate.recovery == id then branch = candidate; break end end
		local ordinal = if id == "F00" then 0 elseif reference then assert(tonumber(id:sub(2))) * 2 - 1 else Layout.CheckpointOrdinals[id]
		local family = hostBank:GetAttribute("KeyFamily") or Layout.Nodes[id][4]
		local width, height = if branch then 15.4 else 11.2, if branch then 8.2 elseif id == "F00" then 7.6 else 5.2
		local frame = findMount(scene, host, width, height, recovery)
		local site = Art.Model(group, "CheckpointStation_" .. id)
		site:SetAttribute("SaveIdentity", ordinal)
		site:SetAttribute("Display", if ordinal == 0 then "START" else tostring(ordinal) .. "/" .. Layout.CheckpointCount)
		site:SetAttribute("HostBank", hostBank:GetFullName():sub(#course:GetFullName() + 2))
		site:SetAttribute("MountFrame", frame)
		local hostLink = Instance.new("ObjectValue")
		hostLink.Name, hostLink.Value, hostLink.Parent = "ArtworkHost", host, site
		marker.Parent = site
		case(site, frame, width, height, Parts.Palette[family][2], pole)
		collar(scene, site, host, Parts.Palette[family][2])
		if branch then
			numberPanel(flag, site, frame * CFrame.new(-5.9, 0, -.15), Vector3.new(3, 7.2, .22), ordinal)
			panel(mainPanel, site, frame * CFrame.new(2, 2.7, -.15), Vector3.new(10.5, 1.9, .22), "CHECKPOINT", "LAND TO SAVE", "")
			local expertUnit = assert(course.ExpertRoutes:FindFirstChild(branch.id .. "_" .. branch.family .. "Cut")) :: Model
			local normal = units[branch.from].NormalAlternative :: BasePart
			local expert = expertUnit.ExpertCommitment :: BasePart
			local index = assert(table.find(Layout.Main, branch.from))
			local normalTarget = endpoint(units[Layout.Main[index + 1]], false).CFrame.Position
			local expertTarget = expertUnit.PrecisionLanding1.KeyContact.CFrame.Position
			panel(normal, site, frame * CFrame.new(2, .25, -.15), Vector3.new(10.5, 2.4, .22), "NORMAL", "WIDE KEYS", departureWords(host, normalTarget) .. " · FULL ROUTE")
			panel(expert, site, frame * CFrame.new(2, -2.45, -.15), Vector3.new(10.5, 2.4, .22), "EXPERT", "SMALL KEYS", departureWords(host, expertTarget) .. " · SHORTER · HARDER JUMPS")
			block(site, "NormalInsert", Vector3.new(.25, 2.3, .35), frame * CFrame.new(-3.48, .25, -.16), NormalAccent)
			block(site, "ExpertInsert", Vector3.new(.25, 2.3, .35), frame * CFrame.new(-3.48, -2.45, -.16), ExpertAccent)
			departureArrow(scene, site, host, normalTarget, NormalAccent, "NormalDeparture")
			departureArrow(scene, site, host, expertTarget, ExpertAccent, "ExpertDeparture")
			normal:SetAttribute("DepartureTarget", normalTarget)
			expert:SetAttribute("DepartureTarget", expertTarget)
			reused += 2
		else
			local offset = if id == "F00" then -1.15 else 0
			numberPanel(flag, site, frame * CFrame.new(-3.6, offset, -.15), Vector3.new(3, 4.2, .22), ordinal)
			panel(mainPanel, site, frame * CFrame.new(1.7, offset, -.15), Vector3.new(6.8, 4.2, .22), if id == "F00" then "START" else "CHECKPOINT", if id == "F00" then "2 LAPS" elseif reference then "LAND TO SAVE" else "CROSS TO SAVE", if nextFamilies[id] then "NEXT: " .. nextFamilies[id] else string.upper(family))
			if id == "F00" then
				local title = course.CheckpointBays.F00.StartLapFinish :: BasePart
				panel(title, site, frame * CFrame.new(0, 2.5, -.15), Vector3.new(10.2, 1.8, .22), "KEYBOARD CIRCUIT", "7 CHECKPOINTS", "")
				reused += 1
			end
		end
		siteCount += 1
		reused += 3
	end
	local finish = course.CheckpointBays.F01 :: Model
	local finishMarker = finish.RecoveryMarker
	local finishHost = finish.BankContact :: BasePart
	local finishFrame = findMount(scene, finishHost, 10.6, 5.2)
	local finishSite = Art.Model(group, "LapFinishStation")
	finishMarker.Parent = finishSite
	case(finishSite, finishFrame, 10.6, 5.2, Parts.Palette.Clicky[2], finishMarker.Pole :: BasePart)
	panel(finishMarker.Flag :: BasePart, finishSite, finishFrame * CFrame.new(0, 0, -.15), Vector3.new(9.6, 4.2, .22), "LAP FINISH", "BACK TO START", "FOLLOW THE KEY BANKS")
	finishSite:SetAttribute("Purpose", "Final passing gate; no recovery save")
	group:SetAttribute("CheckpointStations", siteCount)
	group:SetAttribute("ChoiceStations", #Layout.Branches)
	group:SetAttribute("ReusedParts", reused + 2)
	return group
end

return Wayfinding
