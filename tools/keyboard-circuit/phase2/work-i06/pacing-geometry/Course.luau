--!strict
local Parts = require(script.Parent.Parts)
local Layout = require(script.Parent.Layout)
local StaticPatterns = require(script.Parent.StaticPatterns)
local Mechanisms = require(script.Parent.Mechanisms)
local Surroundings = require(script.Parent.Surroundings)
local Course = {}
local recoveryOffsets = Layout.RecoveryOffsets

local function overlapsLanding(point: Vector3, contact: BasePart): boolean
	local localPoint = contact.CFrame:PointToObjectSpace(point)
	local right, back = contact.CFrame.RightVector, -contact.CFrame.LookVector
	local halfX = 1.2 * (math.abs(right.X) + math.abs(right.Z))
	local halfZ = 1.2 * (math.abs(back.X) + math.abs(back.Z))
	return math.abs(localPoint.X) < contact.Size.X / 2 + halfX and math.abs(localPoint.Z) < contact.Size.Z / 2 + halfZ
end
local mechanisms = {H01 = "ShiftWindows", H02 = "Seesaws", H03 = "Fallaway", H04 = "Foundry", H05 = "Lift", H06 = "Shuttle", H07 = "Sweep", H08 = "Domino"}

local function sign(parent: Instance, name: string, cf: CFrame, text: string, color: Color3)
	local part = Parts.Block(parent, name, Vector3.new(9, 3, .3), cf, color, false)
	for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
		Parts.Legend(part, text, face, Color3.new(1, 1, 1))
	end
	for _, gui in part:GetChildren() do if gui:IsA("SurfaceGui") then gui.CanvasSize = Vector2.new(768, 256) end end
	return part
end

function Course.Build(parent: Instance, origin: Vector3, template: MeshPart): Model
	local root = Parts.Model(parent, "KeyboardCircuit_P2_C01")
	root:SetAttribute("CourseId", "keyboard-circuit-phase2")
	root:SetAttribute("CandidateRevision", "KC_P2_C01")
	root:SetAttribute("KCPhase2Revision", "KC_P2_C01")
	root:SetAttribute("Phase2Only", true)
	root:SetAttribute("KCPhase2PreviewEnabled", true)
	root:SetAttribute("KCPhase2SessionEnabled", true)
	root:SetAttribute("KCPhase2RunId", 1)
	root:SetAttribute("Origin", origin)
	root:SetAttribute("CapacityAssumption", Layout.WorkingCapacity)
	root:SetAttribute("RequiredLaps", Layout.TargetLaps)
	root:SetAttribute("TargetRaceSecondsMin", Layout.TargetRaceSeconds[1])
	root:SetAttribute("TargetRaceSecondsMax", Layout.TargetRaceSeconds[2])
	root:SetAttribute("TargetExpertRaceSecondsMin", Layout.TargetExpertRaceSeconds[1])
	root:SetAttribute("TargetExpertRaceSecondsMax", Layout.TargetExpertRaceSeconds[2])
	local districts = Parts.Model(root, "Districts")
	local links = Parts.Model(root, "RouteLinks")
	local experts = Parts.Model(root, "ExpertRoutes")
	local gates = Instance.new("Folder")
	gates.Name, gates.Parent = "Gates", root
	local pads = Instance.new("Folder")
	pads.Name, pads.Parent = "RecoveryPads", root
	local units, frames = {}, {}
	for _, district in Layout.Districts do
		local section = Parts.Model(districts, district.id .. "_" .. district.name)
		section:SetAttribute("SectionId", district.id)
		section:SetAttribute("KeyFamily", district.family)
		section:SetAttribute("RecoveryCheckpoint", district.recovery)
		for _, id in district.sequences do
			local cf = Layout.NodeFrame(id, origin)
			frames[id] = cf
			local method = mechanisms[id]
			local unit = if method then Mechanisms[method](section, template, cf, {recovery = district.recovery}) else StaticPatterns.Build(section, id, template, cf, district.family)
			unit:SetAttribute("SectionId", district.id)
			unit:SetAttribute("RecoveryCheckpoint", district.recovery)
			units[id] = unit
		end
	end
	local checkpoints = Parts.Model(root, "CheckpointBays")
	for _, id in {"F00", "CP1", "CP2", "CP3", "F01"} do
		local cf = Layout.NodeFrame(id, origin)
		local family = Layout.Nodes[id][4]
		frames[id] = cf
		local bay = Parts.Bank(checkpoints, id, template, cf, if id == "F00" then 30 else 24, 24, family, "SPACE")
		Parts.Support(bay, cf, 9, Parts.Palette[family][2])
		bay:SetAttribute("GateId", id)
		bay:SetAttribute("EntryPosition", cf:PointToWorldSpace(Vector3.new(-10, 0, 0)))
		bay:SetAttribute("ExitPosition", cf:PointToWorldSpace(Vector3.new(10, 0, 0)))
		units[id] = bay
		local heading = cf.RightVector
		local gate = Parts.Block(gates, id, Vector3.new(28, 7, .35), CFrame.lookAt(cf.Position + Vector3.new(0, 3.5, 0), cf.Position + Vector3.new(0, 3.5, 0) + heading), Parts.Charcoal, false)
		gate.Transparency = 1
		gate:SetAttribute("Role", "OrderedProgressGate")
		gate:SetAttribute("ForwardDirection", heading)
		Parts.CheckpointFlag(bay, cf * CFrame.new(-3, 0, -12), id)
		if id ~= "F01" then
			local offset = recoveryOffsets[id] or Vector3.new(0, 0, 23)
			local padCf = cf * CFrame.new(offset)
			local recovery = Parts.Bank(pads, id, template, padCf, 20, 16, family, "Ctrl")
			recovery:SetAttribute("RecoveryGate", id)
			Parts.Support(recovery, padCf, 8, Parts.Palette[family][2])
			local contact = recovery.BankContact
			contact:SetAttribute("Role", "SafeRefuge")
			contact:SetAttribute("RecoveryGate", id)
			contact:SetAttribute("TopPosition", padCf.Position)
			contact:SetAttribute("SpawnCFrame", CFrame.lookAt(padCf.Position + Vector3.new(0, 3.3, 0), padCf.Position + Vector3.new(0, 3.3, 0) + heading))
		end
	end
	sign(units.F00, "StartLapFinish", frames.F00 * CFrame.new(0, 6, -14), "KEYBOARD CIRCUIT\n3 LAPS", Parts.Palette.Creamy[2])
	local routeEdges = Instance.new("Folder")
	routeEdges.Name, routeEdges.Parent = "RouteEdges", root
	local function endpointContact(unit: Model, departing: boolean): BasePart
		local direct = unit:FindFirstChild("BankContact")
		if direct then return direct :: BasePart end
		local bank = assert(unit:FindFirstChild(if departing then "ExitBank" else "EntryBank") or unit:FindFirstChild(if departing then "Exit" else "Entry"))
		return bank.BankContact :: BasePart
	end
	local function projectedExtent(contact: BasePart, direction: Vector3): number
		local localDirection = contact.CFrame:VectorToObjectSpace(direction)
		return math.abs(localDirection.X) * contact.Size.X / 2 + math.abs(localDirection.Z) * contact.Size.Z / 2
	end
	local function connect(fromId: string, toId: string)
		local from, to = units[fromId], units[toId]
		local fromContact, toContact = endpointContact(from, true), endpointContact(to, false)
		local a = fromContact.CFrame.Position + Vector3.new(0, Parts.PressDepth + fromContact.Size.Y / 2, 0)
		local b = toContact.CFrame.Position + Vector3.new(0, Parts.PressDepth + toContact.Size.Y / 2, 0)
		local edge = Instance.new("Folder")
		edge.Name, edge.Parent = fromId .. "_to_" .. toId, routeEdges
		for name, value in {From = from, To = to} do local reference = Instance.new("ObjectValue"); reference.Name, reference.Value, reference.Parent = name, value, edge end
		local distance = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
		local family = to:GetAttribute("KeyFamily") or from:GetAttribute("KeyFamily")
		local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		if delta.Magnitude < .01 then delta = frames[toId].RightVector end
		local direction = delta.Unit
		local fromExtent = projectedExtent(fromContact, direction)
		local toExtent = projectedExtent(toContact, direction)
		local clearDistance = distance - fromExtent - toExtent
		local count = math.max(0, math.ceil((clearDistance - 4.5) / (15.4 + 4.5)))
		if count == 0 then return end
		local maximumWidth = math.min(15.4, (clearDistance - (count + 1)) / count)
		local cells = math.clamp(math.floor((maximumWidth + .2) / Parts.KeyPitch), 1, 6)
		local width = cells * Parts.KeyPitch - .2
		local gap = (clearDistance - count * width) / (count + 1)
		assert(gap >= 1 and gap <= 4.5, "Inspect connector spacing " .. edge.Name)
		for index = 1, count do
			local along = fromExtent + gap + width / 2 + (index - 1) * (width + gap)
			local position = a:Lerp(b, along / distance)
			local cf = CFrame.fromMatrix(position, direction, Vector3.yAxis, direction:Cross(Vector3.yAxis))
			local bank = Parts.Bank(links, edge.Name .. "_" .. index, template, cf, cells * 2, 10, family, "→")
			bank:SetAttribute("FromSequence", fromId)
			bank:SetAttribute("ToSequence", toId)
			bank:SetAttribute("ConnectorGap", gap)
			Parts.Support(bank, cf, 7, Parts.Palette[family][2])
		end
	end
	for index, id in Layout.Main do connect(id, Layout.Main[index % #Layout.Main + 1]) end
	for _, branch in Layout.Branches do
		local unit = Parts.Model(experts, branch.id .. "_" .. (if branch.id == "X01" then "SwitchSpine" else "BracketCut"))
		unit:SetAttribute("ExpertId", branch.id)
		unit:SetAttribute("KeyFamily", branch.family)
		unit:SetAttribute("RecoveryCheckpoint", branch.recovery)
		unit:SetAttribute("BranchAfter", branch.from)
		unit:SetAttribute("MergeBefore", branch.before)
		local start = units[branch.from]:GetAttribute("ExitPosition")
		local finish = units[branch.before]:GetAttribute("EntryPosition")
		local control = Layout.NodePosition(branch.id, origin)
		local geometry = assert(Layout.BranchGeometry[branch.id])
		local departure = units[branch.from].ExitBank.BankContact
		local arrival = units[branch.before].BankContact
		local delta = control - start
		local direction = departure.CFrame:VectorToObjectSpace(Vector3.new(delta.X, 0, delta.Z).Unit)
		local reachX = if math.abs(direction.X) > .001 then (departure.Size.X / 2 - geometry.edgeInset) / math.abs(direction.X) else math.huge
		local reachZ = if math.abs(direction.Z) > .001 then (departure.Size.Z / 2 - geometry.edgeInset) / math.abs(direction.Z) else math.huge
		local reach = math.min(reachX, reachZ)
		local curveStart = departure.CFrame:PointToWorldSpace(Vector3.new(direction.X * reach, Parts.PressDepth + departure.Size.Y / 2, direction.Z * reach))
		local curveFinish = arrival.CFrame:PointToWorldSpace(Vector3.new(-arrival.Size.X / 2 + geometry.mergeInset, Parts.PressDepth + arrival.Size.Y / 2, geometry.mergeLocalZ))
		local function curve(alpha: number): Vector3
			return curveStart * (1 - alpha) ^ 2 + control * (2 * alpha * (1 - alpha)) + curveFinish * alpha ^ 2
		end
		unit:SetAttribute("PrecisionStartPosition", curveStart)
		unit:SetAttribute("PrecisionMergePosition", curveFinish)
		local samples = {{alpha = 0, length = 0, point = curveStart}}
		local length = 0
		for index = 1, 64 do
			local alpha = index / 64
			local p = curve(alpha)
			length += (p - samples[#samples].point).Magnitude
			table.insert(samples, {alpha = alpha, length = length, point = p})
		end
		local count = math.max(5, math.ceil(length / geometry.spacing))
		local function alphaAt(distance: number): number
			for index = 2, #samples do
				local a, b = samples[index - 1], samples[index]
				if distance <= b.length then return a.alpha + (b.alpha - a.alpha) * (distance - a.length) / (b.length - a.length) end
			end
			return 1
		end
		local landings = 0
		local traversal = Instance.new("Folder")
		traversal.Name, traversal.Parent = "TraversalPoints", unit
		for index = 1, count - 1 do
			local alpha = alphaAt(length * index / count)
			local p = curve(alpha)
			local tangent = curve(math.min(1, alpha + .01)) - curve(math.max(0, alpha - .01))
			local side = Vector3.new(-tangent.Z, 0, tangent.X).Unit
			p += side * (if index % 2 == 0 then geometry.lateralOffset else -geometry.lateralOffset)
			p += Vector3.new(0, if index % 2 == 0 then 1.6 else .2, 0)
			if overlapsLanding(p, departure) or overlapsLanding(p, arrival) then continue end
			landings += 1
			local landing = Parts.Model(unit, "PrecisionLanding" .. index)
			local top = Parts.Key(landing, template, CFrame.new(p + Vector3.new(0, -.425, 0)), branch.family, 2, (if index % 2 == 0 then "]" else "["))
			landing.PrimaryPart = top
			local contact = Parts.Block(landing, "KeyContact", Vector3.new(2.4, .25, 2.4), CFrame.new(p + Vector3.new(0, -Parts.PressDepth - .125, 0)), Parts.Charcoal)
			contact.Transparency = 1
			local press = Instance.new("ObjectValue")
			press.Name, press.Value, press.Parent = "PressKey", top, contact
			Parts.Block(landing, "SwitchStem", Vector3.new(1.3, 2, 1.3), CFrame.new(p + Vector3.new(0, -2, 0)), Parts.Charcoal, false)
			local marker = Instance.new("Vector3Value")
			marker.Name, marker.Value, marker.Parent = tostring(index), p, traversal
			marker:SetAttribute("Ordinal", index)
			marker:SetAttribute("JumpFromPrevious", true)
		end
		unit:SetAttribute("PrecisionLandings", landings)
		unit:SetAttribute("ArcLength", length)
		unit:SetAttribute("CenterSpacingTarget", geometry.spacing)
		sign(unit, "ExpertCommitment", CFrame.lookAt(start + Vector3.new(0, 5, 8), start + Vector3.new(0, 5, 0)), "EXPERT " .. branch.id .. "\nHARD JUMPS", Parts.Palette[branch.family][2])
		sign(units[branch.from], "NormalAlternative", CFrame.lookAt(start + Vector3.new(0, 5, -8), start + Vector3.new(0, 5, 0)), "NORMAL\n" .. (if branch.id == "X01" then "LIFT + ENTER" else "OUTER LEAP"), Parts.Palette[branch.family][2])
		unit:SetAttribute("EntryPosition", start)
		unit:SetAttribute("ExitPosition", finish)
		units[branch.id] = unit
		for fromId, toId in {[branch.from] = branch.id, [branch.id] = branch.before} do
			local edge = Instance.new("Folder")
			edge.Name, edge.Parent = fromId .. "_to_" .. toId, routeEdges
			for name, value in {From = units[fromId], To = units[toId]} do local reference = Instance.new("ObjectValue"); reference.Name, reference.Value, reference.Parent = name, value, edge end
		end
	end
	Surroundings.Build(root, origin)
	return root
end

return Course
