--!nonstrict
return function(Layout)
	local surfaces = {}
	for _, floor in Layout.Surfaces do
		surfaces["Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact"] = floor
	end
	local records = {}
	local function add(name, kind, path, z, opening, side, yaw, expert)
		local floor = assert(surfaces[path], "Phase3 hazard floor missing: " .. path)
		local frame = (floor.frame or CFrame.new(floor.position)) * CFrame.Angles(0, yaw or 0, 0)
		local width = math.abs(frame.RightVector:Dot((floor.frame or CFrame.new(floor.position)).RightVector)) * floor.size.X
			+ math.abs(frame.RightVector:Dot((floor.frame or CFrame.new(floor.position)).LookVector)) * floor.size.Z
		local offset = z or 0
		assert(math.abs(offset) + 3.6 + .65 <= floor.size.Z / 2 or yaw, name .. " lacks supported preparation")
		table.insert(records, {
			name = name, kind = kind, surfacePath = path,
			frame = frame * CFrame.new(0, 0, offset),
			size = Vector3.new(width, if kind == "Hurdle" then 1.2 else 13, 1.2),
			centerHeight = if kind == "Hurdle" then (if expert then 2.2 else 1.6) else nil,
			openingWidth = opening, side = side,
			difficulty = if expert then "Expert" else "SharedNormal",
		})
	end
	for _, data in {
		{"GateCausewayHurdle", "Obstacles/Gate/Causeway_3_2/Contact"},
		{"OuterArchHurdle01", "Obstacles/ArchNormal/Causeway_3_2/Contact"},
		{"OuterArchHurdle02", "Obstacles/ArchNormal/Causeway_9_2/Contact"},
		{"MachineryCausewayHurdle", "Obstacles/MachineryApproach/Causeway_4_3/Contact"},
		{"UpperNormalHurdle", "Obstacles/UpperNormalApproach/Causeway_6_3/Contact"},
		{"CrownCausewayHurdle", "Obstacles/CrownApproach/Causeway_2_3/Contact"},
	} do add(data[1], "Hurdle", data[2]) end
	for _, data in {
		{"SharedWeave3Left", "Obstacles/SharedArches/Causeway_1_1/Contact", -1},
		{"SharedWeave3Right", "Obstacles/SharedArches/Causeway_1_2/Contact", 1},
		{"SharedWeave4Left", "Obstacles/SharedArches/Causeway_2_1/Contact", -1},
		{"SharedWeave4Right", "Obstacles/SharedArches/Causeway_2_2/Contact", 1},
	} do add(data[1], "WeaveGate", data[2], 0, 6.5, data[3]) end
	add("ExpertWrapGate", "WeaveGate", "Obstacles/ArchExpert/WrapTurn/Contact", 1, 5, -1, nil, true)
	add("ExpertBeamHurdle01", "Hurdle", "Obstacles/ArchExpert/HurdleBeam/Contact", 12, nil, nil, nil, true)
	add("ExpertBeamHurdle02", "Hurdle", "Obstacles/ArchExpert/HurdleBeam/Contact", -9, nil, nil, nil, true)
	add("ExpertFinalRailHurdle", "Hurdle", "Obstacles/ArchExpert/FinalRiseRail/Contact", -3, nil, nil, nil, true)
	add("ExpertUpperExitHurdle", "Hurdle", "Obstacles/UpperExpertExit/OuterExitBeam/Contact", 2, nil, nil, nil, true)
	add("ExpertUpperExitMirrorHurdle", "Hurdle", "Obstacles/UpperExpertExitMirror/OuterExitBeam/Contact", 2, nil, nil, nil, true)
	add("ExpertGalleryLinkHurdle02", "Hurdle", "Obstacles/GalleryExpertApproach/BetweenBandRail2/Contact", 0, nil, nil, nil, true)
	add("ExpertGalleryLinkHurdle03", "Hurdle", "Obstacles/GalleryExpertApproach/BetweenBandRail3/Contact", 0, nil, nil, nil, true)
	add("ExpertGalleryExitHurdle", "Hurdle", "Obstacles/GalleryExpertExit/ExitRail/Contact", 0, nil, nil, nil, true)
	add("ExpertPostLiftGate", "WeaveGate", "Obstacles/UpperExpertExit/PostLiftTurn/Contact", 0, 5, -1, -math.pi / 2, true)
	add("ExpertPostLiftMirrorGate", "WeaveGate", "Obstacles/UpperExpertExitMirror/PostLiftTurn/Contact", 0, 5, 1, math.pi / 2, true)
	assert(#records == 21, "Phase3 retains exactly21 existing on-course red contacts")
	Layout.RouteHazards = records
	return records
end
