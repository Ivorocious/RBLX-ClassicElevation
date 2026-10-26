--!nonstrict
return function(Layout)
	local records, serial = {}, 0
	local kinds = {Hurdle = true, TallHurdle = true, FloorBand = true, CrenelWeave = true, PinchColumns = true, WindowGate = true}
	local normalGroups = {Gate = true, SharedArches = true, ArchNormal = true,
		MachineryApproach = true, UpperNormalApproach = true, CrownApproach = true, SouthCloister = true}
	local function add(floor, spec, expert)
		local basis = floor.frame or CFrame.new(floor.position)
		assert(basis.UpVector.Y > .999, "Red route contacts require level floors")
		local yaw, z = spec.yaw or 0, spec.z or 0
		local oriented = basis * CFrame.Angles(0, yaw, 0)
		local width = math.abs(oriented.RightVector:Dot(basis.RightVector)) * floor.size.X
			+ math.abs(oriented.RightVector:Dot(basis.LookVector)) * floor.size.Z
		local depth = math.abs(oriented.LookVector:Dot(basis.RightVector)) * floor.size.X
			+ math.abs(oriented.LookVector:Dot(basis.LookVector)) * floor.size.Z
		local approach = spec.approachStuds or 3.6
		assert(math.abs(z) + approach + 1.05 <= depth / 2, "Red obstacle has unsupported approach on " .. floor.name)
		serial += 1
		local name = floor.group .. "_" .. floor.name .. "_Red" .. serial
		local kind = spec.kind
		assert(kinds[kind], "Unsupported red obstacle")
		local height = if kind == "FloorBand" then .25 elseif kind == "TallHurdle" then 4.2
			elseif kind == "Hurdle" then 1 elseif kind == "WindowGate" then 7.8
			elseif kind == "PinchColumns" then 5.8 elseif expert then 9 else 2.8
		if spec.openingWidth then
			assert(spec.openingWidth >= (if expert then 6.4 else 5) and spec.openingWidth < width, "Red gate needs a supported body opening")
		end
		table.insert(records, {name = name, kind = kind,
			surfacePath = "Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact",
			frame = oriented * CFrame.new(0, 0, z), size = Vector3.new(width, height, if kind == "FloorBand" then 2.2 else 1),
			centerHeight = if kind == "Hurdle" then (spec.centerHeight or 1.6) elseif kind == "TallHurdle" then height / 2 + .1 else height / 2,
			openingWidth = spec.openingWidth, side = spec.side,
			openingHeight = if kind == "WindowGate" then 6.8 else nil,
			direction = spec.direction or -1, approachStuds = approach,
			difficulty = if expert then "Expert" else "SharedNormal"})
	end
	local normalIndex = {}
	for _, floor in Layout.Surfaces do
		if floor.hazardSpecs then
			for _, spec in floor.hazardSpecs do add(floor, spec, true) end
		elseif normalGroups[floor.group] and string.find(floor.name, "Causeway_", 1, true) then
			local basis = floor.frame or CFrame.new(floor.position)
			if basis.UpVector.Y < .999 or floor.size.Z < 11 or floor.size.X < 8 then continue end
			local count = (normalIndex[floor.group] or 0) + 1
			normalIndex[floor.group] = count
			if count % 3 == 1 then
				add(floor, {kind = "Hurdle", centerHeight = floor.hurdleCenterHeight}, false)
			elseif count % 3 == 2 then
				add(floor, {kind = "CrenelWeave", openingWidth = 5.5, side = if count % 2 == 0 then 1 else -1}, false)
			end
		end
	end
	assert(#records > 10, "Rework needs purposeful shared and Expert red contacts")
	Layout.RouteHazards = records
	return records
end
