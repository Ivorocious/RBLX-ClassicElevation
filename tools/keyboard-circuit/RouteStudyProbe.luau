--!strict
local study = workspace:FindFirstChild("KeyboardCircuit_P1_C05").CheapWholeRouteStudy
local main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
local function insideEdge(part: BasePart, direction: Vector3): Vector3
	local localDirection = part.CFrame:VectorToObjectSpace(direction)
	local x = if math.abs(localDirection.X) > .001 then (part.Size.X / 2 - 1.15) / math.abs(localDirection.X) else math.huge
	local z = if math.abs(localDirection.Z) > .001 then (part.Size.Z / 2 - 1.15) / math.abs(localDirection.Z) else math.huge
	return part.Position + direction * math.min(x, z)
end
shared.KCStudy = {active = true, edges = {}, started = os.clock()}
task.spawn(function()
	local result = shared.KCStudy
	for index, from in main do
		local to = main[index % #main + 1]
		local connection = {}
		for _, part in study.OrderedNormalConnections:GetChildren() do
			if part:GetAttribute("ConnectionFrom") == from and part:GetAttribute("ConnectionTo") == to then table.insert(connection, part) end
		end
		table.sort(connection, function(a, b) return a:GetAttribute("ConnectionIndex") < b:GetAttribute("ConnectionIndex") end)
		local surfaces = {study[from].PrimaryPart}
		for _, part in connection do table.insert(surfaces, part) end
		table.insert(surfaces, study[to].PrimaryPart)
		for step = 1, #surfaces - 1 do
			local a, b = surfaces[step], surfaces[step + 1]
			local direction = Vector3.new(b.Position.X - a.Position.X, 0, b.Position.Z - a.Position.Z).Unit
			result.stage = from .. " → " .. to .. " / " .. step
			local launch, landing = insideEdge(a, direction), insideEdge(b, -direction)
			local approach = shared.KCProbe.Move(result.stage .. " approach", launch, false, 3, .35)
			local transfer = approach and shared.KCProbe.Move(result.stage .. " transfer", landing, true, 3, .35)
			table.insert(result.edges, {from = from, to = to, step = step, approach = approach, transfer = transfer})
			if not transfer then result.ok, result.active = false, false; return end
		end
		if not shared.KCProbe.Move("Study " .. to .. " center", study[to].PrimaryPart.Position, false, 3, .35) then result.ok, result.active = false, false; return end
	end
	result.totalSeconds, result.ok, result.active = os.clock() - result.started, true, false
end)
return {started = true}
