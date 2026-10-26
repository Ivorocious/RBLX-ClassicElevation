--!strict
local Parts = require(script.Parent.Parts)
local StaticPatterns = {}

function StaticPatterns.Build(parent: Instance, id: string, template: MeshPart, cf: CFrame, family: string): Model
	local unit = Parts.Model(parent, id)
	unit:SetAttribute("SequenceId", id)
	unit:SetAttribute("KeyFamily", family)
	local waypoints = Instance.new("Folder")
	waypoints.Name, waypoints.Parent = "TraversalPoints", unit
	local ordinal = 0
	local function point(name: string, position: Vector3, jump: boolean)
		ordinal += 1
		local marker = Instance.new("Attachment")
		marker.Name, marker.Position = name, cf:PointToWorldSpace(Vector3.new(position.X * .75, position.Y, position.Z * .75))
		marker:SetAttribute("Ordinal", ordinal)
		marker:SetAttribute("JumpFromPrevious", jump)
		marker.Parent = waypoints
	end
	local function bank(name: string, x: number, y: number, z: number, columns: number?, rows: number?, glyph: string?, jump: boolean?): Model
		local pose = cf * CFrame.new(x * .75, y, z * .75)
		local model = Parts.Bank(unit, name, template, pose, math.max(8, (columns or 12) - 2), math.max(8, (rows or 10) - 2), family, glyph)
		Parts.Support(model, pose, 7, Parts.Palette[family][2])
		point(name, Vector3.new(x, y, z), jump == true)
		return model
	end
	local function kill(name: string, x: number, y: number, z: number)
		local hazard = Parts.KillBody(unit, name, cf * CFrame.new(x * .75, y + 2, z * .75), Vector3.new(4, 4, 4))
		hazard:SetAttribute("StaticHazard", true)
	end
	local function arrowBank(name: string, position: Vector3, destination: Vector3)
		local delta = destination - position
		local direction = Vector3.new(delta.X, 0, delta.Z).Unit
		local p = Vector3.new(position.X * .75, position.Y, position.Z * .75)
		local pose = cf * CFrame.fromMatrix(p, direction, Vector3.yAxis, direction:Cross(Vector3.yAxis))
		local model = Parts.SpecialKey(unit, name, pose, Vector3.new(13, 1.25, 12), family, "→", template)
		Parts.Support(model, pose, 7, Parts.Palette[family][2])
		model:SetAttribute("ArrowDirection", cf:VectorToWorldSpace(direction))
		model:SetAttribute("ArrowLocalDirection", direction)
		point(name, position, true)
	end
	local entry, exit
	if id == "O01" then
		entry = bank("Entry", -27, 0, 0, 12, 12)
		bank("OffsetLeft", -9, 1, -5, 10, 10, nil, true)
		bank("OffsetRight", 9, 1, 5, 10, 10, nil, true)
		exit = bank("Exit", 27, 2, 0, 12, 12, nil, true)
	elseif id == "O02" then
		entry = bank("Entry", -27, 0, 0, 12, 12)
		bank("MissingClusterLeft", -9, 0, -6, 10, 10, nil, true)
		bank("MissingClusterRight", 9, 0, 6, 10, 10, nil, true)
		exit = bank("Exit", 27, 0, 0, 12, 12, nil, true)
		kill("MarkedKillKeyLeft", -9, 0, 6)
		kill("MarkedKillKeyRight", 9, 0, -6)
	elseif id == "O03" then
		entry = bank("Entry", -27, 0, 0, 12, 12, "Esc")
		bank("EscStep1", -9, 2, -3, 10, 10, "Esc", true)
		bank("EscStep2", 9, 4, 3, 10, 10, "Esc", true)
		exit = bank("Exit", 27, 6, 0, 12, 12, "Esc", true)
	elseif id == "O04" then
		entry = bank("Entry", -29, 0, 0, 12, 12, "→")
		local enter = Parts.Model(unit, "EnterHairpin")
		local stem = Parts.SpecialKey(enter, "EnterStem", cf * CFrame.new(-7.5, 0, 0), Vector3.new(13, 1.25, 20.8), family, "ENTER", template)
		local turn = Parts.SpecialKey(enter, "EnterReturn", cf * CFrame.new(-17.9, 0, 7.8), Vector3.new(7.8, 1.25, 5.2), family, "ENTER", template)
		Parts.JoinSpecialKeys(stem, turn)
		Parts.Support(enter, cf * CFrame.new(-7.5, 0, 0), 9, Parts.Palette[family][2])
		point("EnterStem", Vector3.new(-10, 0, 0), true)
		point("EnterTurn", Vector3.new(-10, 0, 8), false)
		bank("OutwardLanding", 7, 0, 17, 12, 10, "→", true)
		exit = bank("Exit", 27, 0, 0, 12, 12, "→", true)
	elseif id == "O05" then
		entry = bank("Entry", -27, 0, 0, 12, 12, "[")
		local left = bank("BracketLeft", -9, 0, -6, 10, 12, "[", true)
		-- Extend the shared grid by one column; overlapping full banks duplicate caps.
		Parts.Bank(left, "TopArm", template, cf * CFrame.new(-.25, 0, -8.4), 2, 4, family, "[")
		local right = bank("BracketRight", 9, 1, 6, 10, 12, "]", true)
		Parts.Bank(right, "BottomArm", template, cf * CFrame.new(.25, 1, 8.4), 2, 4, family, "]")
		exit = bank("Exit", 27, 0, 0, 12, 12, "]", true)
		kill("MarkedKillKeyLeft", -9, 0, 6)
		kill("MarkedKillKeyRight", 9, 1, -6)
	elseif id == "O06" then
		entry = bank("Entry", -29, 0, 0, 12, 12)
		bank("OuterLeftHalf", -10, 1, -13, 12, 12, nil, true)
		bank("OuterRightHalf", 10, 1, -13, 12, 12, nil, true)
		exit = bank("Exit", 29, 0, 0, 12, 12, nil, true)
		kill("MarkedInnerGap", 0, 0, 0)
	elseif id == "O07" then
		entry = bank("Entry", -27, 0, 0, 12, 12, "↓")
		arrowBank("ArrowTurnRight", Vector3.new(-9, -1.5, 6), Vector3.new(9, -3, -6))
		arrowBank("ArrowTurnLeft", Vector3.new(9, -3, -6), Vector3.new(27, -4, 0))
		exit = bank("Exit", 27, -4, 0, 12, 12, "↓", true)
		kill("MarkedKillKeyLeft", -9, -1.5, -6)
		kill("MarkedKillKeyRight", 9, -3, 6)
	elseif id == "O08" then
		entry = bank("Entry", -27, 0, 0, 12, 12)
		for index, p in {Vector3.new(-9, 0, -5), Vector3.new(9, 0, 5)} do
			local pose = cf * CFrame.new(p.X * .75, p.Y, p.Z * .75)
			local enter = Parts.SpecialKey(unit, "LongEnter" .. index, pose, Vector3.new(13, 1.25, 10), family, "ENTER", template)
			Parts.Support(enter, pose, 7, Parts.Palette[family][2])
			point("LongEnter" .. index, p, true)
		end
		exit = bank("Exit", 27, 0, 0, 12, 12, "→", true)
	else
		error("Unknown fixed sequence " .. id)
	end
	unit:SetAttribute("EntryPosition", entry:GetAttribute("TopPosition"))
	unit:SetAttribute("ExitPosition", exit:GetAttribute("TopPosition"))
	unit:SetAttribute("EntryLocal", cf:PointToObjectSpace(entry:GetAttribute("TopPosition")))
	unit:SetAttribute("ExitLocal", cf:PointToObjectSpace(exit:GetAttribute("TopPosition")))
	return unit
end

return StaticPatterns

