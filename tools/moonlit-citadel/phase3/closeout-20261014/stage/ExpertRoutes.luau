--!nonstrict
local FOOT = 1.05
local function v(x, y, z) return Vector3.new(x, y, z) end

return function(Layout, surface, archMerge, cp04, galleryFrame, galleryExitNode, upperExit, cp03)
	local floors = {}
	local function record(node)
		if floors[node.path] then return floors[node.path] end
		for _, floor in Layout.Surfaces do
			local path = "Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact"
			floors[path] = floor
		end
		return assert(floors[node.path], "Missing Expert contact " .. node.path)
	end
	local function frame(node) local floor = record(node); return floor.frame or CFrame.new(floor.position) end
	local function at(node, point, jump, family)
		local copy, floor = table.clone(node), record(node)
		copy.offset = frame(node):PointToObjectSpace(point)
		assert(math.abs(copy.offset.X) + FOOT <= floor.size.X / 2 + .001
			and math.abs(copy.offset.Z) + FOOT <= floor.size.Z / 2 + .001, "Expert foot support escapes " .. node.path)
		copy.kind, copy.requiredJump = if jump then "Jump" else "Walk", jump == true
		copy.obstacleFamily = family
		return copy
	end
	local serial = 0
	local function jump(route, from, to, start, finish, family, lineGap)
		local distance, rise = v(finish.X - start.X, 0, finish.Z - start.Z).Magnitude, finish.Y - start.Y
		if distance < .05 and math.abs(rise) < .01 then
			table.insert(route, at(to, finish, false, family))
			return
		end
		local speed = math.sqrt(2 * 196.2 * 7.2)
		local discriminant = speed * speed - 2 * 196.2 * rise
		assert(discriminant > 0, "Expert jump exceeds ordinary rise")
		local reach = 16 * (speed + math.sqrt(discriminant)) / 196.2
		assert(reach - distance >= .45, from.name .. " -> " .. to.name .. " lacks ordinary ideal reach margin: " .. tostring(reach - distance))
		table.insert(route, at(from, start, false, family))
		local arrival = at(to, finish, true, family)
		arrival.flightStuds, arrival.riseStuds, arrival.gapStuds = distance, rise, lineGap
		table.insert(route, arrival)
		serial += 1
		table.insert(Layout.Transfers, {group = "ExpertRework", name = "Commit_" .. serial, from = from.path, to = to.path,
			fromPoint = start, toPoint = finish, flightStuds = distance, riseStuds = rise,
			gapStuds = arrival.gapStuds, idealReachMargin = reach - distance, kind = "Jump", requiredJump = true,
			obstacleFamily = family})
	end
	local function lip(node, direction, inset)
		local floor, basis = record(node), frame(node)
		local localDirection = basis:VectorToObjectSpace(direction)
		local margin = if inset == nil then FOOT else inset
		local reach = math.min(if math.abs(localDirection.X) > .001 then (floor.size.X / 2 - margin) / math.abs(localDirection.X) else math.huge,
			if math.abs(localDirection.Z) > .001 then (floor.size.Z / 2 - margin) / math.abs(localDirection.Z) else math.huge)
		return basis:PointToWorldSpace(localDirection * reach)
	end
	local function connect(route, from, to, family)
		local a, b = record(from).position, record(to).position
		local direction = v(b.X - a.X, 0, b.Z - a.Z).Unit
		local function closest(node, target)
			local floor, basis = record(node), frame(node)
			local point = basis:PointToObjectSpace(target)
			return basis:PointToWorldSpace(v(math.clamp(point.X, -floor.size.X / 2 + FOOT, floor.size.X / 2 - FOOT), 0,
				math.clamp(point.Z, -floor.size.Z / 2 + FOOT, floor.size.Z / 2 - FOOT)))
		end
		-- Offset needles need supported corner departures rather than a ray through both centers.
		local start = closest(from, b)
		local finish = closest(to, start)
		start = closest(from, finish)
		local lineGap = math.max(0, (lip(to, -direction, 0) - lip(from, direction, 0)):Dot(direction))
		jump(route, from, to, start, finish, family, lineGap)
		table.insert(route, table.clone(to))
	end
	local function make(group, name, point, size, hazards, basis)
		local node = surface(group, name, point, size, "ExpertPerch", basis)
		if hazards then record(node).hazardSpecs = hazards end
		return node
	end
	local function hurdle(z, yaw, sign) return {kind = "TallHurdle", z = z or 0, yaw = yaw or 0, direction = sign or -1} end
	local function strip(z, yaw, sign) return {kind = "FloorBand", z = z or 0, yaw = yaw or 0, direction = sign or -1} end
	local function gate(kind, z, side, sign, approach)
		-- Leave room for R15 arms while the avatar turns between offset gates.
		return {kind = kind, z = z or 0, side = side, openingWidth = 6.4, direction = sign or -1,
			approachStuds = approach or (if kind == "CrenelWeave" then 3.8 else 4.8)}
	end
	local cp01 = {path = Layout.CP01.support, name = "CP01Terrace", kind = "Walk"}
	local origin = Layout.CP01.point - v(-144, 28, -112)
	local archNodes = {}
	for index, item in {
		{"InnerTakeoff", v(-121.8,28,-112),v(2.4,1,10),{strip(0,0,1)}},
		{"RiseCorbel", v(-121.8,30,-93),v(2.2,1,18),{hurdle(-4,0,1),strip(4,0,1)}},
		{"FirstNeedle", v(-121.8,32,-73),v(2.2,1,12),{hurdle(0,0,1)}},
		{"WrapTurn", v(-114,34,-62),v(7,1,14),{gate("WindowGate",0,nil,1)}},
		{"HighNeedle", v(-111,40,-42),v(2.2,1,24),{strip(-4,0,1),hurdle(4,0,1)}},
		{"OffsetCorbel", v(-114,42,-19),v(9.2,1,20),{gate("CrenelWeave",-4,1,1),gate("CrenelWeave",4,-1,1)}},
		{"ReturnTurn", v(-109,44,-1),v(7,1,14),{gate("PinchColumns",0,nil,1)}},
		{"ReturnBeam", v(-123.4,46,1),v(14,1,2.2),{hurdle(0,-math.pi/2,1)}},
		{"MergeTurn", v(-127.2,48,12),v(7,1,14),{gate("WindowGate",0,nil,1)}},
		{"FinalRiseRail", v(-118.1,50,21),v(2.2,1,10),{strip(0,0,1)}},
	} do archNodes[index] = make("ArchExpert", item[1], origin + item[2], item[3], item[4]) end
	local arch = {table.clone(cp01)}
	local previous = cp01
	for _, node in archNodes do
		if previous == cp01 then
			jump(arch,previous,node,origin+v(-129.05,28,-115.6),origin+v(-121.8,28,-115.6),"ExpertInnerCommit",5.6)
			table.insert(arch,table.clone(node))
		elseif node.name == "ReturnBeam" then
			jump(arch,previous,node,origin+v(-111.45,44,4.95),origin+v(-117.45,46,1.05),"ExpertStonePrecision",3.5)
			table.insert(arch,table.clone(node))
		else connect(arch,previous,node,"ExpertStonePrecision") end
		previous=node
	end
	connect(arch, previous, archMerge, "ExpertSharedArchMerge")

	local function gp(x,y,z) return galleryFrame:PointToWorldSpace(v(x,y,z)) end
	local function gs(group,name,x,y,z,width,depth,hazards)
		return make(group,name,gp(x,y,z),v(width,1,depth),hazards,galleryFrame*CFrame.new(x,y,z))
	end
	local entry = gs("GalleryExpertApproach","EntryRail",10,0,-21.5,2.4,17,{hurdle(0)})
	local lantern = {}
	local cp02 = {path = Layout.CP02.support, name = "CP02Terrace", kind = "Walk"}
	table.insert(lantern,at(cp02,gp(10,0,-14.95),false,"ExpertGalleryCommit"))
	table.insert(lantern,at(entry,gp(10,0,-17.9),false,"ExpertGalleryCommit"))
	table.insert(lantern,table.clone(entry))
	previous = entry
	for band=1,3 do
		local bandData = assert(Layout.GalleryBands[band], "Expert requires authored gallery band anchors")
		local z,y = bandData.z, bandData.y
		local before = gs("Gallery","ExpertBefore"..band,10,y,z+10,2.4,8)
		local crossing = gs("Gallery","ExpertCrossing"..band,10,y,z,2.2,8)
		local after = gs("Gallery","ExpertAfter"..band,if band%2==1 then 12.5 else 7.5,y+2,z-16,
			if band==2 then 9.2 else 2.2,14,{if band==2 then gate("CrenelWeave",0,1,nil,4.8) elseif band==1 then strip(0) else hurdle(0)})
		if band>1 then
			local x = if band%2==0 then 12.5 else 7.5
			local link=gs("GalleryExpertApproach","BetweenBandRail"..band,x,y-2,z+25,2.2,15)
			-- These narrow rails overlap at the same height, so they form a continuous walk.
			table.insert(lantern,at(previous,gp(x,y-2,z+32.05),false,"ExpertGalleryLink"))
			table.insert(lantern,table.clone(link))
			previous=link
		end
		connect(lantern,previous,before,"ExpertPhaseApproach")
		lantern[#lantern].waitForLantern=band
		connect(lantern,before,crossing,"ExpertTimedNeedle")
		for index=#lantern-2,#lantern do
			if lantern[index].kind=="Jump" then
				lantern[index].lanternBand,lantern[index].lanternPath,lantern[index].lanternClearance=band,"Obstacles/SwingLanterns/SwingBand"..band,6.5
			end
		end
		connect(lantern,crossing,after,"ExpertTimedOffsetExit")
		previous=after
	end
	local finalZ = galleryFrame:PointToObjectSpace(record(galleryExitNode).position).Z
	local exitRail=gs("GalleryExpertExit","ExitRail",9.5,12,finalZ+12,2.2,12)
	connect(lantern,previous,exitRail,"ExpertGalleryExitNeedle")
	local shortcut = {}
	for index,item in {
		{v(108,66,30),v(2.4,1,12),{strip(0)}},
		{v(111,68,11),v(2.2,1,18),{hurdle(0)}},
		{v(111,70,-10),v(2.2,1,16),{strip(0)}},
		{v(112,70,-30),v(2.2,1,16)},
	} do
		shortcut[index]=make("GalleryExpertShortcut","LiftNeedle"..index,origin+item[1],item[2],item[3])
		connect(lantern,if index==1 then exitRail else shortcut[index-1],shortcut[index],"ExpertLowerLiftShortcut")
	end
	connect(lantern,shortcut[#shortcut],cp03,"ExpertLowerLiftShortcutMerge")

	local liftOrigin = record(cp04).position - v(112,106,-86)
	local rearWait={name="UpperRearBoarding",path="Obstacles/Lifts/UpperRearBoarding/Contact",kind="Walk"}
	local rearZ = record(rearWait).position.Z - liftOrigin.Z - 6
	local braceNodes={}
	for index,item in {
		{v(82.1,106,-101),v(2.4,1,20),{strip(4),hurdle(-4)}},
		{v(77,109,-124),v(2.2,1,20),{hurdle(4),strip(-4)}},
		{v(77,113,-147),v(9.2,1,20),{gate("CrenelWeave",4,1),gate("CrenelWeave",-4,-1)}},
		{v(79,109,rearZ+1),v(2.4,1,8)},
		{v(92.5,106,rearZ-7),v(20,1,2.2),{strip(-5,math.pi/2,1),hurdle(3,math.pi/2,1)}},
	} do braceNodes[index]=make("UpperBrace","BraceStep"..index,liftOrigin+item[1],item[2],item[3]) end
	local brace={}
	previous=cp04
	jump(brace,cp04,braceNodes[1],liftOrigin+v(89.05,106,-93.95),liftOrigin+v(82.25,106,-92.05),"ExpertUpperCornerCommit",4.7)
	table.insert(brace,table.clone(braceNodes[1]))
	previous=braceNodes[1]
	for index=2,#braceNodes do local node=braceNodes[index];connect(brace,previous,node,"ExpertUpperFullCommit");previous=node end
	jump(brace,previous,rearWait,liftOrigin+v(100.1,106,rearZ-7),liftOrigin+v(100.1,106,rearZ-1.95),"ExpertUpperRearMerge",2.4)
	table.insert(brace,table.clone(rearWait))
	return {archExpert=arch,lanternExpert=lantern,expertBrace=brace,earlyExit=upperExit,expertExit={},
		braceFirstPath=braceNodes[1].path,returnCorbel=upperExit,boardY=106,exitY=138,
		galleryMergePath=cp03.path,
		fullUpperRide=true,rearBoarding=true,mirrorUpper=false}
end

