--!strict
local Parts = require(script.Parent.Parts)
local Motion = require(script.Parent.Motion)
local Mechanisms = {}

Mechanisms.Endpoints = {
	Seesaws = {entry = Vector3.new(-33, 0, 0), exit = Vector3.new(33, 0, 0), bank = Vector3.new(13, 0, 13)},
	Fallaway = {entry = Vector3.new(-28, 0, 0), exit = Vector3.new(28, 0, 0), bank = Vector3.new(13, 0, 20.8)},
	Foundry = {entry = Vector3.new(-31, 0, 0), exit = Vector3.new(31, 0, 0), bank = Vector3.new(13, 0, 15.6)},
	Lift = {entry = Vector3.new(-16, 0, 0), exit = Vector3.new(16, 8, 0), bank = Vector3.new(13, 0, 13)},
	Shuttle = {entry = Vector3.new(-16, 0, 0), exit = Vector3.new(40, 0, 0), bank = Vector3.new(15.6, 0, 15.6)},
	Sweep = {entry = Vector3.new(-24, 0, 0), exit = Vector3.new(24, 0, 0), bank = Vector3.new(13, 0, 13)},
	Domino = {entry = Vector3.new(-27, 0, 0), exit = Vector3.new(30, 0, 0), bank = Vector3.new(13, 0, 15.6)},
	Shift = {entry = Vector3.new(-28, 0, 0), exit = Vector3.new(28, 0, 0), bank = Vector3.new(13, 0, 15.6)},
}

local identity = {
	Seesaws = {"H02", "SpacebarSeesaws", "Creamy", "F00"},
	Fallaway = {"H03", "FallawayRows", "Creamy", "F00"},
	Foundry = {"H04", "FallingKeyFoundry", "Thocky", "CP1"},
	Lift = {"H05", "SpringLift", "Thocky", "CP1"},
	Shuttle = {"H06", "CarriageShuttle", "Clacky", "CP2"},
	Sweep = {"H07", "KeyPullerSweep", "Clacky", "CP2"},
	Domino = {"H08", "DominoKeyCascade", "Clicky", "CP3"},
	Shift = {"H01", "ShiftWindows", "Clicky", "CP3"},
}

local function unitFor(parent: Instance, kind: string, cf: CFrame, options)
	local id = identity[kind]
	local unit = Parts.Model(parent, id[1] .. "_" .. id[2])
	local tuning = Motion.Tuning(kind, if options then options.tuning else nil)
	unit:SetAttribute("MechanismId", id[1])
	unit:SetAttribute("MechanismKind", kind)
	unit:SetAttribute("KeyFamily", id[3])
	unit:SetAttribute("RecoveryCheckpoint", if options and options.recovery then options.recovery else id[4])
	unit:SetAttribute("SequenceId", id[1])
	unit:SetAttribute("CycleState", "Stopped")
	unit:SetAttribute("EncounterFrame", cf)
	for name, value in tuning do unit:SetAttribute("Timing_" .. name, value) end
	local endpoints = Mechanisms.Endpoints[kind]
	unit:SetAttribute("EntryPosition", cf:PointToWorldSpace(endpoints.entry))
	unit:SetAttribute("ExitPosition", cf:PointToWorldSpace(endpoints.exit))
	unit:SetAttribute("LocalEntry", endpoints.entry)
	unit:SetAttribute("LocalExit", endpoints.exit)
	return unit, tuning, id[3]
end

local function permanentBank(unit: Model, template: MeshPart, name: string, cf: CFrame, columns: number, rows: number, family: string, refuge: boolean?)
	local bank = Parts.Bank(unit, name, template, cf, columns, rows, family, if refuge then "Ctrl" else "→")
	bank:SetAttribute("Role", if refuge then "SafeRefuge" else "StableLanding")
	bank:SetAttribute("RecoveryCheckpoint", unit:GetAttribute("RecoveryCheckpoint"))
	return bank
end

local function endpoints(unit: Model, template: MeshPart, cf: CFrame, kind: string, family: string)
	local bounds = Mechanisms.Endpoints[kind]
	local entry = permanentBank(unit, template, "EntryBank", cf * CFrame.new(bounds.entry), bounds.bank.X / Parts.Pitch, bounds.bank.Z / Parts.Pitch, family, true)
	local exit = permanentBank(unit, template, "ExitBank", cf * CFrame.new(bounds.exit), bounds.bank.X / Parts.Pitch, bounds.bank.Z / Parts.Pitch, family, true)
	unit.PrimaryPart = entry.PrimaryPart
	unit:SetAttribute("FrameFromPrimary", entry.PrimaryPart.CFrame:ToObjectSpace(cf))
	return entry, exit
end

local function warning(unit: Instance, name: string, cf: CFrame, size: Vector3, mark: string): Part
	local plate = Parts.Warning(unit, cf, size)
	plate.Name = name
	plate:SetAttribute("KCWarning", true)
	Parts.Legend(plate, mark)
	return plate
end

local function setMover(actor: Model, index: number, lethal: boolean?)
	actor:SetAttribute("KCMover", true)
	actor:SetAttribute("MotionIndex", index)
	actor:SetAttribute("KCLethalActor", lethal == true)
	actor:SetAttribute("RestPivot", actor:GetPivot())
	if not lethal then
		for _,part in actor:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide then part:SetAttribute("KCSupport", true) end
		end
	end
end

local function weldBank(bank: Model)
	local root = bank.PrimaryPart :: BasePart
	root.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
	for _,part in bank:GetDescendants() do
		if part:IsA("BasePart") and part ~= root then
			part.Massless = true
			part.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = root, part, root
		end
	end
end

function Mechanisms.Slider(unit: Model, template: MeshPart, cf: CFrame, axis: Vector3, travel: number, family: string): Model
	local bank = Parts.Bank(unit, "RideableBank", template, cf, 10, 8, family, "↑")
	local root = bank.PrimaryPart :: BasePart
	local guide = Parts.Block(unit, "Guide", Vector3.new(2, 2, 2), root.CFrame, Parts.Charcoal, false)
	guide.Transparency = 1
	guide:SetAttribute("Role", "MechanismGuide")
	local fixed = Instance.new("Attachment")
	fixed.Name, fixed.Axis = "FixedAxis", axis
	fixed.SecondaryAxis = if math.abs(axis.Y) > .5 then Vector3.xAxis else Vector3.yAxis
	fixed.Parent = guide
	local moving = fixed:Clone()
	moving.Name, moving.Parent = "MovingAxis", root
	local slider = Instance.new("PrismaticConstraint")
	slider.Name, slider.Attachment0, slider.Attachment1 = "Slider", fixed, moving
	slider.ActuatorType, slider.TargetPosition = Enum.ActuatorType.Servo, 0
	slider.LimitsEnabled, slider.LowerLimit, slider.UpperLimit = true, 0, travel
	slider.Speed, slider.ServoMaxForce, slider.LinearResponsiveness = 6, 10000000, 15
	slider.Restitution, slider.Enabled = 0, false
	slider.Parent = unit
	weldBank(bank)
	setMover(bank, 1)
	bank:SetAttribute("KCPhysicalMover", true)
	unit:SetAttribute("Travel", travel)
	unit:SetAttribute("MotionAxis", cf:VectorToWorldSpace(axis))
	return bank
end

function Mechanisms.Seesaws(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, tuning, family = unitFor(parent, "Seesaws", cf, options)
	endpoints(unit, template, cf, "Seesaws", family)
	for index, x in {-13, 13} do
		local topFrame = cf * CFrame.new(x, 1.8, 0)
		local bar = Parts.SpecialKey(unit, "Spacebar" .. index, topFrame, Vector3.new(22, 1.25, 10), family, "SPACE")
		local root = bar.PrimaryPart :: BasePart
		local pivot = Parts.Block(unit, "PivotHousing" .. index, Vector3.new(3.5, 5, 11.5), topFrame * CFrame.new(0, -3, 0), Parts.Charcoal, false)
		Parts.Cylinder(unit, "BroadAxle" .. index, root.CFrame * CFrame.Angles(0, math.pi / 2, 0), 12, 2.1, Parts.Yellow)
		local fixed = Instance.new("Attachment")
		fixed.Name, fixed.Axis, fixed.SecondaryAxis = "PivotAxis", Vector3.zAxis, Vector3.yAxis
		fixed.Position = pivot.CFrame:PointToObjectSpace(root.CFrame.Position)
		fixed.Parent = pivot
		local moving = Instance.new("Attachment")
		moving.Name, moving.Axis, moving.SecondaryAxis = "BarAxis", Vector3.zAxis, Vector3.yAxis
		moving.Parent = root
		local hinge = Instance.new("HingeConstraint")
		hinge.Name, hinge.Attachment0, hinge.Attachment1 = "Hinge" .. index, fixed, moving
		hinge.ActuatorType = Enum.ActuatorType.Servo
		hinge.AngularSpeed, hinge.ServoMaxTorque, hinge.AngularResponsiveness = .55, 10000000, 20
		hinge.LimitsEnabled, hinge.LowerAngle, hinge.UpperAngle = true, -tuning.MaxAngle, tuning.MaxAngle
		hinge.TargetAngle, hinge.Enabled, hinge.Parent = 0, false, unit
		weldBank(bar)
		setMover(bar, index)
		bar:SetAttribute("KCPhysicalMover", true)
		warning(unit, "SeesawWarning" .. index, cf * CFrame.new(x, -.3, -6), Vector3.new(7, .18, 1.3), "↔")
	end
	return unit
end

function Mechanisms.Fallaway(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, _, family = unitFor(parent, "Fallaway", cf, options)
	endpoints(unit, template, cf, "Fallaway", family)
	for lane = 1, 2 do
		local z = if lane == 1 then -6.5 else 6.5
		for row, x in {-13, 0, 13} do
			local bank = Parts.Bank(unit, "Lane" .. lane .. "Row" .. row, template, cf * CFrame.new(x, 0, z), 8, 8, family)
			setMover(bank, (lane - 1) * 3 + row)
			bank:SetAttribute("LaneIndex", lane)
			bank:SetAttribute("RowIndex", row)
			local rowWarning = warning(bank, "RowWarning", cf * CFrame.new(x, .015, z - 4.7), Vector3.new(9, .14, .8), "↓")
			rowWarning:SetAttribute("KCActorWarning", true)
		end
		local lamp = warning(unit, "LaneWarning" .. lane, cf * CFrame.new(-27, .025, z), Vector3.new(5.2, .15, 4), "WAIT")
		lamp:SetAttribute("LaneIndex", lane)
	end
	permanentBank(unit, template, "PermanentCtrlRefuge", cf * CFrame.new(0, 0, 19), 8, 8, family, true)
	return unit
end

function Mechanisms.Foundry(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, _, family = unitFor(parent, "Foundry", cf, options)
	endpoints(unit, template, cf, "Foundry", family)
	local crossing = Parts.Bank(unit, "CrossingBank", template, cf, 30, 14, family)
	for _,z in {-12, 12} do
		local column = Parts.Block(unit, "GantryColumn", Vector3.new(2.5, 23, 3), cf * CFrame.new(0, 10, z), Parts.Charcoal)
		column:SetAttribute("Role", "SolidBlocker")
		Parts.Warning(unit, cf * CFrame.new(-1.3, 11, z) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(6, .2, 2.1))
	end
	Parts.Block(unit, "OverheadFeeder", Vector3.new(31, 3, 3), cf * CFrame.new(0, 22, 0), Parts.Charcoal, false)
	for index, offset in {Vector3.new(-12, 0, -4), Vector3.new(0, 0, 4), Vector3.new(12, 0, -4)} do
		local drop = Parts.KillBody(unit, "Drop" .. index, cf * CFrame.new(offset + Vector3.new(0, 17.5, 0)), Vector3.new(7, 5, 8))
		local plunger = Parts.Block(drop, "Plunger", Vector3.new(2.5, 5, 2.5), drop:GetPivot() * CFrame.new(0, 3.5, 0), Parts.Crimson, false)
		plunger.CanQuery = true
		plunger:SetAttribute("Role", "Lethal")
		setMover(drop, index, true)
		local lamp = warning(unit, "Warning" .. index, cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .025, 0)), Vector3.new(5, .04, 3), "↓")
		lamp:SetAttribute("MotionIndex", index)
		for _,key in crossing:GetChildren() do
			if not key:IsA("MeshPart") then continue end
			local point = cf:PointToObjectSpace(key.CFrame.Position) - offset
			if math.abs(point.X) > 3.6 or math.abs(point.Z) > 4.1 then continue end
			key:SetAttribute("DropWarningIndex", index)
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.Position = "DropWarning", UDim2.fromScale(.96, .96), UDim2.fromScale(.02, .02)
			frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = Parts.Yellow, 1, 0
			local stroke = Instance.new("UIStroke")
			stroke.Color, stroke.Thickness, stroke.Parent = Parts.Yellow, 6, frame
			frame.Parent = key.Legend
		end
		for _,side in {-1, 1} do
			Parts.Block(unit, "ZoneEdge", Vector3.new(7.3, .055, .22), cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .03, side * 4.1)), Parts.Yellow, false)
			Parts.Block(unit, "ZoneEdge", Vector3.new(.22, .055, 8), cf * CFrame.new(offset + Vector3.new(side * 3.6, -Parts.PressDepth + .03, 0)), Parts.Yellow, false)
		end
	end
	local refuge = permanentBank(unit, template, "PermanentCtrlRefuge", cf * CFrame.new(0, 0, 17), 10, 6, family, true)
	local roof = Parts.Block(refuge, "GuardRoof", Vector3.new(14, 1, 10), cf * CFrame.new(0, 14.5, 17), Parts.Charcoal)
	roof:SetAttribute("Role", "SolidBlocker")
	for _,x in {-6.4, 6.4} do
		local post = Parts.Block(refuge, "GuardPost", Vector3.new(.8, 15, .8), cf * CFrame.new(x, 6.7, 21), Parts.Charcoal)
		post:SetAttribute("Role", "SolidBlocker")
	end
	return unit
end

function Mechanisms.Lift(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, tuning, family = unitFor(parent, "Lift", cf, options)
	endpoints(unit, template, cf, "Lift", family)
	local exit = unit.ExitBank
	if tuning.Travel ~= 8 then
		exit:PivotTo(exit:GetPivot() + cf:VectorToWorldSpace(Vector3.new(0, tuning.Travel - 8, 0)))
		unit:SetAttribute("LocalExit", Vector3.new(16, tuning.Travel, 0))
		unit:SetAttribute("ExitPosition", cf:PointToWorldSpace(Vector3.new(16, tuning.Travel, 0)))
	end
	Mechanisms.Slider(unit, template, cf, Vector3.yAxis, tuning.Travel, family)
	Parts.Block(unit, "Foot", Vector3.new(14, 1, 11), cf * CFrame.new(0, -7.5, 0), Parts.Charcoal, false)
	Parts.Cylinder(unit, "Stem", cf * CFrame.new(0, -4, 0) * CFrame.Angles(0, 0, math.pi / 2), 6, 3, Parts.Charcoal)
	for index = 1, 4 do Parts.Cylinder(unit, "SpringDisc" .. index, cf * CFrame.new(0, -1.8 - index * 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2), .5, 5.5, Color3.fromRGB(128, 132, 135)) end
	warning(unit, "LiftWarning", cf * CFrame.new(-16, .025, -5), Vector3.new(6.5, .16, 2), "↑")
	return unit
end

function Mechanisms.Shuttle(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, tuning, family = unitFor(parent, "Shuttle", cf, options)
	endpoints(unit, template, cf, "Shuttle", family)
	if tuning.Travel ~= 24 then
		unit.ExitBank:PivotTo(unit.ExitBank:GetPivot() + cf:VectorToWorldSpace(Vector3.new(tuning.Travel - 24, 0, 0)))
		unit:SetAttribute("LocalExit", Vector3.new(tuning.Travel + 16, 0, 0))
		unit:SetAttribute("ExitPosition", cf:PointToWorldSpace(Vector3.new(tuning.Travel + 16, 0, 0)))
	end
	Mechanisms.Slider(unit, template, cf, Vector3.xAxis, tuning.Travel, family)
	local rails = Parts.Model(unit, "PermanentRails")
	for _,z in {-4.5, 4.5} do Parts.Cylinder(rails, "Rail", cf * CFrame.new(tuning.Travel / 2, -2.8, z), tuning.Travel + 13, .7, Color3.fromRGB(144, 155, 164)) end
	for _,x in {-7.5, tuning.Travel + 7.5} do
		local stop = Parts.Block(rails, "StopHousing", Vector3.new(2, 3, 13), cf * CFrame.new(x, -3.5, 0), Parts.Charcoal, false)
		stop:SetAttribute("Role", "Decoration")
	end
	warning(unit, "BoardingWarning", cf * CFrame.new(-16, .025, -6), Vector3.new(6.5, .16, 2), "WAIT")
	warning(unit, "ExitWarning", cf * CFrame.new(tuning.Travel + 16, .025, -6), Vector3.new(6.5, .16, 2), "WAIT")
	return unit
end

function Mechanisms.Sweep(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, _, family = unitFor(parent, "Sweep", cf, options)
	endpoints(unit, template, cf, "Sweep", family)
	permanentBank(unit, template, "CrossingBank", cf, 24, 6, family)
	permanentBank(unit, template, "PermanentCtrlRefuge", cf * CFrame.new(-13, 0, -13), 8, 8, family, true)
	local pivot = cf * CFrame.new(0, 1.05, 8)
	local housing = Parts.Block(unit, "KeyPullerPivot", Vector3.new(5, 3, 5), pivot * CFrame.new(0, -1.8, 0), Parts.Charcoal, false)
	housing:SetAttribute("Role", "Decoration")
	Parts.Cylinder(unit, "BroadAxle", pivot * CFrame.Angles(0, 0, math.pi / 2), 3.2, 3, Parts.Charcoal)
	local arm = Parts.KillBody(unit, "SweepArm", pivot * CFrame.new(7, 0, 0), Vector3.new(14, 1.6, 2))
	setMover(arm, 1, true)
	arm:SetAttribute("MotionPivot", pivot)
	arm:SetAttribute("MotionPivotLocal", cf:ToObjectSpace(pivot))
	arm:SetAttribute("MotionLocal", pivot:ToObjectSpace(arm:GetPivot()))
	warning(unit, "SweepWarning", cf * CFrame.new(-20, .025, 0), Vector3.new(5.2, .16, 4), "↶")
	return unit
end

function Mechanisms.Domino(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, _, family = unitFor(parent, "Domino", cf, options)
	endpoints(unit, template, cf, "Domino", family)
	for index, x in {-15, -5, 5, 15} do permanentBank(unit, template, "PassageBank" .. index, cf * CFrame.new(x, 0, 0), 4, 10, family) end
	permanentBank(unit, template, "PermanentCtrlRefuge", cf * CFrame.new(-5, 0, 15), 5, 7, family, true)
	for index, x in {-10, 0, 10} do
		local pivot = cf * CFrame.new(x, -3.25, 0)
		local panel = Parts.KillBody(unit, "DominoPanel" .. index, pivot * CFrame.new(0, 6, 0), Vector3.new(1.5, 12, 10))
		setMover(panel, index, true)
		panel:SetAttribute("MotionPivot", pivot)
		panel:SetAttribute("MotionPivotLocal", cf:ToObjectSpace(pivot))
		panel:SetAttribute("MotionLocal", CFrame.new(0, 6, 0))
		Parts.Cylinder(unit, "HingeAxle" .. index, pivot * CFrame.Angles(0, math.pi / 2, 0), 11, 1.2, Parts.Charcoal)
		local lamp = warning(unit, "LatchWarning" .. index, cf * CFrame.new(x - 3, .025, -4.5), Vector3.new(4, .15, 1.3), "↓")
		lamp:SetAttribute("MotionIndex", index)
	end
	return unit
end

function Mechanisms.ShiftWindows(parent: Instance, template: MeshPart, cf: CFrame, options): Model
	local unit, _, family = unitFor(parent, "Shift", cf, options)
	endpoints(unit, template, cf, "Shift", family)
	permanentBank(unit, template, "PermanentCtrlRefuge", cf, 6, 12, family, true)
	for index, x in {-13, 13} do
		local bridge = Parts.SpecialKey(unit, "ShiftBridge" .. index, cf * CFrame.new(x, 0, 0), Vector3.new(16, 1.25, 8), family, "SHIFT")
		setMover(bridge, index)
		bridge:SetAttribute("RetractDirection", if index == 1 then 1 else -1)
		local z = if index == 1 then 13 else -13
		Parts.Block(unit, "SideHousing" .. index, Vector3.new(17, 3, 10), cf * CFrame.new(x, -1.5, z), Parts.Charcoal, false)
		local lamp = warning(unit, "ShiftWarning" .. index, cf * CFrame.new(x - 7, .025, -4.5), Vector3.new(2, .16, 2), "WAIT")
		lamp:SetAttribute("MotionIndex", index)
	end
	return unit
end

function Mechanisms.GetFrame(unit: Model): CFrame
	return (unit.PrimaryPart :: BasePart).CFrame * (unit:GetAttribute("FrameFromPrimary") :: CFrame)
end

function Mechanisms.GetEndpoints(unit: Model): (Vector3, Vector3)
	local frame = Mechanisms.GetFrame(unit)
	return frame:PointToWorldSpace(unit:GetAttribute("LocalEntry") :: Vector3), frame:PointToWorldSpace(unit:GetAttribute("LocalExit") :: Vector3)
end

return Mechanisms
