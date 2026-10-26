--!nonstrict
local FOOT = 1.05
local function v(x, y, z) return Vector3.new(x, y, z) end

return function(Layout, surface, archMerge, cp04, galleryFrame, galleryExitNode, upperExit)
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
		local start, finish = lip(from, direction), lip(to, -direction)
		if (finish - start):Dot(direction) < 0 then
			local shared = (start + finish) / 2
			start, finish = v(shared.X, a.Y, shared.Z), v(shared.X, b.Y, shared.Z)
		end
		local lineGap = math.max(0, (lip(to, -direction, 0) - lip(from, direction, 0)):Dot(direction))
		jump(route, from, to, start, finish, family, lineGap)
		table.insert(route, table.clone(to))
	end
	local function make(group, name, point, size, hazards, basis)
		local node = surface(group, name, point, size, "ExpertPerch", basis)
		if hazards then record(node).hazardSpecs = hazards end
		return node
	end
	local function hurdle(z, yaw, sign) return {kind = "Hurdle", z = z or 0, yaw = yaw or 0, direction = sign or -1} end
	local function weave(z, yaw, side, opening, sign)
		return {kind = "CrenelWeave", z = z or 0, yaw = yaw or 0, side = side, openingWidth = opening, direction = sign or -1}
	end
	local cp01 = {path = Layout.CP01.support, name = "CP01Terrace", kind = "Walk"}
	local origin = Layout.CP01.point - v(-144, 28, -112)
	local archNodes = {}
	for index, item in {
		{"InnerTakeoff", v(-119,28,-112),v(6,1,10)},
		{"RiseCorbel", v(-119,30,-93),v(3.2,1,18),{hurdle(-4,0,1),hurdle(4,0,1)}},
		{"FirstNeedle", v(-119,32,-73),v(4.5,1,12)},
		{"WrapTurn", v(-111,34,-62),v(7,1,10)},
		{"HurdleBeam", v(-98.4,36,-62),v(18,1,3.2),{hurdle(-4,math.pi/2,1),hurdle(4,math.pi/2,1)}},
		{"OuterTurn", v(-85,38,-62),v(7,1,10)},
		{"HighNeedle", v(-85,40,-42),v(3.2,1,20),{hurdle(-4,0,1),hurdle(4,0,1)}},
		{"OffsetCorbel", v(-85,42,-19),v(3.6,1,20),{hurdle(-4,0,1),hurdle(4,0,1)}},
		{"ReturnTurn", v(-85,44,1),v(7,1,10)},
		{"ReturnBeam", v(-99,46,1),v(18,1,3.2),{hurdle(0,-math.pi/2,1)}},
		{"MergeTurn", v(-114,48,1),v(7,1,10)},
		{"FinalRiseRail", v(-114,50,15),v(3.6,1,14)},
	} do archNodes[index] = make("ArchExpert", item[1], origin + item[2], item[3], item[4]) end
	local arch = {table.clone(cp01)}
	local previous = cp01
	for _, node in archNodes do connect(arch, previous, node, "ExpertStonePrecision"); previous = node end
	connect(arch, previous, archMerge, "ExpertSharedArchMerge")

	local function gp(x,y,z) return galleryFrame:PointToWorldSpace(v(x,y,z)) end
	local function gs(group,name,x,y,z,width,depth,hazards)
		return make(group,name,gp(x,y,z),v(width,1,depth),hazards,galleryFrame*CFrame.new(x,y,z))
	end
	local entry = gs("GalleryExpertApproach","EntryRail",10,0,-12,3.2,22,{hurdle(0)})
	local lantern = {}
	local cp02 = {path = Layout.CP02.support, name = "CP02Terrace", kind = "Walk"}
	connect(lantern,cp02,entry,"ExpertGalleryCommit")
	previous = entry
	for band=1,3 do
		local bandData = assert(Layout.GalleryBands[band], "Expert requires authored gallery band anchors")
		local z,y = bandData.z, bandData.y
		local before = gs("Gallery","ExpertBefore"..band,10,y,z+13,3.4,8)
		local crossing = gs("Gallery","ExpertCrossing"..band,10,y,z,3.0,8)
		local after = gs("Gallery","ExpertAfter"..band,if band%2==1 then 11.5 else 8.5,y+2,z-13,3.4,8)
		if band>1 then
			local link=gs("GalleryExpertApproach","BetweenBandRail"..band,if band%2==0 then 11.5 else 8.5,y-2,z+25,3.2,16,{hurdle(0)})
			connect(lantern,previous,link,"ExpertGalleryLink")
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
	local exitRail=gs("GalleryExpertExit","ExitRail",11.5,12,finalZ+15,3.2,18,{hurdle(0)})
	connect(lantern,previous,exitRail,"ExpertGalleryExitNeedle")
	local exitTurn=gs("GalleryExpertExit","ExitTurn",13,12,finalZ,7,10)
	connect(lantern,exitRail,exitTurn,"ExpertGalleryExitTurn")
	connect(lantern,exitTurn,galleryExitNode,"ExpertGallerySharedMerge")

	local liftOrigin = record(cp04).position - v(112,106,-86)
	local rearWait={name="UpperRearBoarding",path="Obstacles/Lifts/UpperRearBoarding/Contact",kind="Walk"}
	local rearZ = record(rearWait).position.Z - liftOrigin.Z - 6
	local braceNodes={}
	for index,item in {
		{v(80,106,-86),v(8,1,8)},
		{v(66,106,-86),v(16,1,3.2),{hurdle(0,-math.pi/2,1)}},
		{v(51,106,-86),v(6,1,18),{weave(-3,0,1,3.2)}},
		{v(51,106,-106),v(3.2,1,26),{hurdle(5),hurdle(-5)}},
		{v(51,106,-126),v(6,1,8)},
		{v(51,106,rearZ+20),v(3.2,1,26),{hurdle(5),hurdle(-5)}},
		{v(51,106,rearZ),v(6,1,8)},
		{v(65,106,rearZ),v(16,1,3.2),{hurdle(0,math.pi/2,1)}},
		{v(79,106,rearZ),v(6,1,8)},
		{v(87,106,rearZ),v(12,1,3.2)},
	} do braceNodes[index]=make("UpperBrace","BraceStep"..index,liftOrigin+item[1],item[2],item[3]) end
	local brace={}
	previous=cp04
	for _,node in braceNodes do connect(brace,previous,node,"ExpertUpperFullCommit"); previous=node end
	connect(brace,previous,rearWait,"ExpertUpperRearMerge")
	return {archExpert=arch,lanternExpert=lantern,expertBrace=brace,earlyExit=upperExit,expertExit={},
		braceFirstPath=braceNodes[1].path,returnCorbel=upperExit,boardY=106,exitY=138,
		galleryMergePath=galleryExitNode.path,fullUpperRide=true,rearBoarding=true,mirrorUpper=false}
end
