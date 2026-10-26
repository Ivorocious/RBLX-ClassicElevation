--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = {}

function Mechanisms.Slider(parent: Instance, name: string, template: MeshPart, cf: CFrame, axis: Vector3, travel: number, family: string)
	local unit = Parts.Model(parent, name)
	local bank = Parts.Bank(unit, "RideableBank", template, cf, 10, 8, family, "↑")
	local root = bank.PrimaryPart :: BasePart
	root.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
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
	slider.Speed, slider.ServoMaxForce, slider.LinearResponsiveness = 4, 10000000, 15
	slider.Restitution = 0
	slider.Enabled = false
	slider.Parent = unit
	for _,part in bank:GetDescendants() do
		if part:IsA("BasePart") and part ~= root then
			part.Massless = true
			part.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = root, part, root
		end
	end
	unit:SetAttribute("Travel", travel)
	unit:SetAttribute("RestTop", cf.Position)
	unit:SetAttribute("MotionAxis", axis)
	unit.PrimaryPart = root
	return unit
end

function Mechanisms.Lift(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Mechanisms.Slider(parent, "H05_SpringLift", template, cf, Vector3.yAxis, 8, "Thocky")
	Parts.Block(unit, "Foot", Vector3.new(14, 1, 11), cf * CFrame.new(0, -7.5, 0), Parts.Charcoal, false)
	Parts.Cylinder(unit, "Stem", cf * CFrame.new(0, -4, 0) * CFrame.Angles(0, 0, math.pi / 2), 6, 3, Parts.Charcoal)
	for i = 1, 4 do
		Parts.Cylinder(unit, "SpringDisc", cf * CFrame.new(0, -1.8 - i * 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2), .5, 5.5, Color3.fromRGB(128, 132, 135))
	end
	return unit
end

function Mechanisms.Shuttle(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Mechanisms.Slider(parent, "H06_CarriageShuttle", template, cf, Vector3.xAxis, 24, "Clacky")
	local rail = Parts.Model(unit, "PermanentRails")
	for _,z in {-4.5, 4.5} do
		Parts.Cylinder(rail, "Rail", cf * CFrame.new(12, -2.8, z), 37, .7, Color3.fromRGB(144, 155, 164))
	end
	for _,x in {-6.5, 30.5} do
		local stop = Parts.Block(rail, "StopHousing", Vector3.new(2, 5, 13), cf * CFrame.new(x, -3.2, 0), Parts.Charcoal)
		stop:SetAttribute("Role", "SolidBlocker")
		Parts.Warning(rail, cf * CFrame.new(x, .6, -5.5), Vector3.new(1.9, .2, 1.8))
	end
	return unit
end

function Mechanisms.Foundry(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Parts.Model(parent, "H04_FallingKeyFoundry")
	local crossing = Parts.Bank(unit, "CrossingBank", template, cf, 30, 14, "Thocky")
	for _,z in {-12, 12} do
		local column = Parts.Block(unit, "GantryColumn", Vector3.new(2.5, 23, 3), cf * CFrame.new(0, 10, z), Parts.Charcoal)
		column:SetAttribute("Role", "SolidBlocker")
		Parts.Warning(unit, cf * CFrame.new(-1.3, 11, z) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(6, .2, 2.1))
	end
	Parts.Block(unit, "OverheadFeeder", Vector3.new(31, 3, 3), cf * CFrame.new(0, 22, 0), Parts.Charcoal, false)
	for i,offset in {Vector3.new(-12, 0, -4), Vector3.new(0, 0, 4), Vector3.new(12, 0, -4)} do
		local drop = Parts.KillBody(unit, "Drop" .. i, cf * CFrame.new(offset + Vector3.new(0, 17.5, 0)), Vector3.new(7, 5, 8))
		drop:SetAttribute("DropOffset", offset)
		drop:SetAttribute("CycleOffset", (i - 1) * 2.1)
		local plunger = Parts.Block(drop, "Plunger", Vector3.new(2.5, 5, 2.5), drop:GetPivot() * CFrame.new(0, 3.5, 0), Parts.Crimson, false)
		plunger.CanQuery = true
		plunger:SetAttribute("Role", "Lethal")
		local warning = Parts.Block(unit, "Warning" .. i, Vector3.new(5, .04, 3), cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .025, 0)), Parts.Yellow, false)
		Parts.Legend(warning, "↓", nil, Parts.Charcoal)
		for _,key in crossing:GetChildren() do
			if not key:IsA("MeshPart") then continue end
			local point = cf:PointToObjectSpace(key.Position) - offset
			if math.abs(point.X) > 3.6 or math.abs(point.Z) > 4.1 then continue end
			key:SetAttribute("DropWarningIndex", i)
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.Position = "DropWarning", UDim2.fromScale(.96, .96), UDim2.fromScale(.02, .02)
			frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = Parts.Yellow, 1, 0
			local stroke = Instance.new("UIStroke")
			stroke.Color, stroke.Thickness, stroke.Parent = Parts.Yellow, 6, frame
			local arrow = Instance.new("TextLabel")
			arrow.Position, arrow.Size = UDim2.fromScale(.78, .02), UDim2.fromScale(.2, .2)
			arrow.Text, arrow.TextScaled, arrow.Font = "↓", true, Enum.Font.GothamBold
			arrow.BackgroundColor3, arrow.TextColor3, arrow.BorderSizePixel, arrow.ZIndex = Parts.Yellow, Parts.Charcoal, 0, 3
			arrow.Parent, frame.Parent = frame, key.Legend
		end
		for _,side in {-1, 1} do
			Parts.Block(unit, "ZoneEdge", Vector3.new(7.3, .055, .22), cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .03, side * 4.1)), Parts.Yellow, false)
			Parts.Block(unit, "ZoneEdge", Vector3.new(.22, .055, 8), cf * CFrame.new(offset + Vector3.new(side * 3.6, -Parts.PressDepth + .03, 0)), Parts.Yellow, false)
		end
	end
	local refuge = Parts.Bank(unit, "PermanentCtrlRefuge", template, cf * CFrame.new(0, 0, 17), 10, 6, "Thocky", "Ctrl")
	refuge:SetAttribute("Role", "SafeRefuge")
	local roof = Parts.Block(refuge, "GuardRoof", Vector3.new(14, 1, 10), cf * CFrame.new(0, 14.5, 17), Parts.Charcoal)
	roof:SetAttribute("Role", "SolidBlocker")
	for _,x in {-6.4, 6.4} do
		local post = Parts.Block(refuge, "GuardPost", Vector3.new(.8, 15, .8), cf * CFrame.new(x, 6.7, 21), Parts.Charcoal)
		post:SetAttribute("Role", "SolidBlocker")
	end
	return unit
end

return Mechanisms
