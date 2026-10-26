local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local base, draft = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/', 'tools/moonlit-citadel/phase3/drafts/'
local parent = {}
local config = luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),
	{environment = {Vector3 = roblox.Vector3}})()
local function load(name, ownDraft)
	return luau.load(fs.readFile((if ownDraft then draft else base) .. name .. '.luau'), {environment = {
		Vector3 = roblox.Vector3, CFrame = roblox.CFrame, script = {Parent = parent},
		game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = config}}},
		require = function(value) return value end,
	}})()
end
for _, name in {'ExpertRoutes','RouteHazardGoals'} do parent[name] = load(name, false) end
for _, name in {'RouteHazardLayout','SupportingObstacles'} do parent[name] = load(name, true) end
local layout = load('Layout', false)
local floors = layout.SupportingObstacleData.floors
local function point(node)
	local floor = floors[node.path]
	if not floor then return nil end
	return (floor.frame or roblox.CFrame.new(floor.position)):PointToWorldSpace(node.offset or roblox.Vector3.zero)
end
local function affected(node)
	return layout.SupportingObstacleData.changed[node.path] or string.find(node.path or '', '/ArchExpert/', 1, true)
		or node.obstacleFamily == 'ExpertSharedMerge' or node.obstacleFamily == 'ExpertRisingCorbel'
end
local function vec(value) return {value.X,value.Y,value.Z} end
local report = {surfaces=#layout.Surfaces,hazards=#layout.RouteHazards,routes={},offsets={},flights={},boarding={},failures={},minSupport=math.huge,minExpertFlight=math.huge,minAllFlight=math.huge}
local speed=math.sqrt(2*config.Gravity*config.Movement.JumpHeight)
local deckRiseSpeed = 34 / ((config.CycleSeconds - 2 * config.DwellSeconds) / 2)
for mask=0,7 do
	local choices={bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0}
	for lower=1,2 do for upper=1,2 do
		local id=tostring(mask)..'_L'..lower..'_U'..upper
		local route=layout.GetRoute(choices,{lower,upper})
		local margins=parent.SupportingObstacles.SupportMargins(layout,route)
		local minSupport=math.huge
		for _, record in margins do
			local spare=math.min(record.xMargin,record.zMargin)
			minSupport=math.min(minSupport,spare)
			report.minSupport=math.min(report.minSupport,spare)
			if spare<.04975 then table.insert(report.failures,{route=id,kind='support',path=record.path,x=record.xMargin,z=record.zMargin,offset=vec(record.offset)}) end
			table.insert(report.offsets,{route=id,index=record.index,path=record.path,kind=record.kind,offset=vec(record.offset),x=record.xMargin,z=record.zMargin})
		end
		table.insert(report.routes,{id=id,nodes=#route,affectedOffsets=#margins,minSupport=minSupport})
		for index,node in route do
			local previous=route[index-1]
			if node.kind=='Jump' and previous then
				local a,b=point(previous),point(node)
				if not a or not b then table.insert(report.failures,{route=id,kind='missingJumpSupport',path=node.path});continue end
				local d=roblox.Vector3.new(b.X-a.X,0,b.Z-a.Z).Magnitude
				local rise=b.Y-a.Y
				local discriminant=speed*speed-2*196.2*rise
				local reach=if discriminant>=0 then 16*(speed+math.sqrt(discriminant))/196.2 else -math.huge
				local margin=reach-d
				local changed = affected(node) or affected(previous)
				if changed then report.minExpertFlight=math.min(report.minExpertFlight,margin) end
				report.minAllFlight=math.min(report.minAllFlight,margin)
				local record={route=id,index=index,from=previous.path,to=node.path,start=vec(a),stop=vec(b),flight=d,rise=rise,reach=reach,margin=margin,family=node.obstacleFamily,affected=changed == true or type(changed)=='number'}
				table.insert(report.flights,record)
				if margin<.44975 then table.insert(report.failures,{route=id,kind='flight',data=record}) end
			elseif node.kind=='Ride' and node.boardHeightTolerance==.9 then
				local floor=floors[node.waitPath]
				local waitOffset = roblox.Vector3.new(if upper==1 then 1 else -1,node.waitOffset.Y,node.waitOffset.Z)
				local start=(floor.frame or roblox.CFrame.new(floor.position)):PointToWorldSpace(waitOffset)
				local origin=layout.LiftOrigins.Upper
				local board = roblox.Vector3.new(if upper==1 then -4.5 else 4.5,node.board.Y,4.8)
				local target=origin+roblox.Vector3.new(if upper==1 then -9 else 9,20,0)+board
				local d=roblox.Vector3.new(target.X-start.X,0,target.Z-start.Z).Magnitude
				local margins = {}
				for _, initialRise in {-.9,0,.9} do
					local staticReach=16*(speed+math.sqrt(speed*speed-2*config.Gravity*initialRise))/config.Gravity
					local relativeSpeed=speed-deckRiseSpeed
					local movingReach=16*(relativeSpeed+math.sqrt(relativeSpeed*relativeSpeed-2*config.Gravity*initialRise))/config.Gravity
					table.insert(margins,{initialDeckRise=initialRise,staticSpare=staticReach-d,movingInterceptSpare=movingReach-d})
				end
				table.insert(report.boarding,{route=id,sourceWaitOffset=vec(node.waitOffset),proposedWaitOffset=vec(waitOffset),sourceBoard=vec(node.board),proposedBoard=vec(board),
					start=vec(start),target=vec(target),flight=d,flatIdealSpare=16*2*speed/config.Gravity-d,
					waitFootprintXSpare=floor.size.X/2-math.abs(waitOffset.X)-1,
					waitFootprintZSpare=floor.size.Z/2-math.abs(waitOffset.Z)-1,deckRiseSpeed=deckRiseSpeed,
					deckFootprintXSpare=7-math.abs(board.X)-1,deckFootprintZSpare=6-math.abs(board.Z)-1,
					sideRailClearance=6.57-math.abs(board.X)-1,heightWindowCalculations=margins,movingUpperWindowRequiresNativeCheck=true})
			end
		end
	end end
end
local output='docs/artifacts/moonlit-citadel/phase3/drafts/OBSTACLE_PROBE.json'
fs.writeFile(output,serde.encode('json',report))
print('Loaded current production Layout with draft obstacles; surfaces='..report.surfaces..' hazards='..report.hazards)
print('Routes='..#report.routes..' affectedOffsets='..#report.offsets..' allFlights='..#report.flights..' boarding='..#report.boarding)
print('minSupport='..report.minSupport..' minExpertIdealSpare='..report.minExpertFlight..' minAllIdealSpare='..report.minAllFlight..' failures='..#report.failures)
for index, record in report.failures do if index<=12 then print(serde.encode('json',record)) end end
print(output)
assert(#report.failures==0,'Actual module route/support evaluation failed')
