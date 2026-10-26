local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local environment = {}
for name, value in roblox do environment[name] = value end
local nativeCFrame=table.clone(roblox.CFrame)
-- This bundled Lune lookAt reverses target Z; construct Roblox's documented basis explicitly.
function nativeCFrame.lookAt(origin,target,up)
	local look=(target-origin).Unit
	local right=look:Cross(up or roblox.Vector3.yAxis).Unit
	return roblox.CFrame.fromMatrix(origin,right,right:Cross(look),-look)
end
environment.CFrame=nativeCFrame
local direction=roblox.Vector3.new(-57,0,-36).Unit
assert((nativeCFrame.lookAt(roblox.Vector3.zero,direction).LookVector-direction).Magnitude<1e-6,"lookAt faces actual target")
local authoring = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/Authoring.luau"), {environment=environment})()
local course = authoring.Build()
local V, C = roblox.Vector3, roblox.CFrame
local speed, height, gravity = 16, 7.2, 196.2
local jumpVelocity = math.sqrt(2 * gravity * height)
local function horizontal(point) return V.new(point.X, 0, point.Z) end
local function surface(part, offset)
	local frame = part.CFrame + (offset or V.zero)
	local corners = {}
	for _, sign in {{-1,-1},{1,-1},{1,1},{-1,1}} do
		table.insert(corners, horizontal(frame * V.new(sign[1]*part.Size.X/2, 0, sign[2]*part.Size.Z/2)))
	end
	local name=if part.Name=="ShellContact" then part.Parent.Name..".ShellContact" else part.Name
	return {name=name, part=part, corners=corners, top=frame.Position.Y+part.Size.Y/2, center=frame.Position}
end
local function pointSegment(point, a, b)
	local line = b-a
	local alpha = math.clamp((point-a):Dot(line)/line:Dot(line), 0, 1)
	return (point-(a+line*alpha)).Magnitude
end
local function interval(corners, axis)
	local low, high = math.huge, -math.huge
	for _, point in corners do low=math.min(low,point:Dot(axis)); high=math.max(high,point:Dot(axis)) end
	return low, high
end
local function gap(a,b)
	local separated = false
	for _, corners in {a.corners,b.corners} do
		for i=1,2 do
			local edge = corners[i+1]-corners[i]
			local axis = V.new(-edge.Z,0,edge.X).Unit
			local al,ah = interval(a.corners,axis)
			local bl,bh = interval(b.corners,axis)
			if ah < bl or bh < al then separated=true end
		end
	end
	if not separated then return 0 end
	local distance = math.huge
	for _, pair in {{a,b},{b,a}} do
		for _, point in pair[1].corners do
			for i=1,4 do distance=math.min(distance,pointSegment(point,pair[2].corners[i],pair[2].corners[i%4+1])) end
		end
	end
	return distance
end
local function reach(rise)
	local discriminant = jumpVelocity^2-2*gravity*rise
	return if discriminant < 0 then -1 else speed*(jumpVelocity+math.sqrt(discriminant))/gravity
end
local fixtures = {
	surface({Name="A",CFrame=C.identity,Size=V.new(6,2,6)}),
	surface({Name="B",CFrame=C.new(10,0,0),Size=V.new(6,2,6)}),
	surface({Name="C",CFrame=C.new(10,0,10),Size=V.new(6,2,6)}),
	surface({Name="D",CFrame=C.new(1,0,0)*C.Angles(0,.7,0),Size=V.new(6,2,6)}),
}
assert(math.abs(gap(fixtures[1],fixtures[2])-4)<1e-6, "straight edge gap")
assert(math.abs(gap(fixtures[1],fixtures[3])-math.sqrt(32))<1e-6, "diagonal corner gap")
assert(gap(fixtures[1],fixtures[4])==0, "rotated overlap")
assert(math.abs(gap(fixtures[2],fixtures[1])-gap(fixtures[1],fixtures[2]))<1e-6, "gap symmetry")
assert(reach(7.3)<0 and reach(-2)>reach(0), "rise/descent reach")
local turned=C.Angles(0,.7,0)
local turnedA=surface({Name="TurnedA",CFrame=turned,Size=V.new(12,2,6)})
local turnedB=surface({Name="TurnedB",CFrame=turned+turned.LookVector*10,Size=V.new(12,2,6)})
assert(math.abs(gap(turnedA,turnedB)-4)<1e-5, "rotated same-direction forward gap")
local function route(name)
	local refs=course.Routes[name]:GetChildren()
	table.sort(refs,function(a,b) return a.Name<b.Name end)
	local list={}
	for _, ref in refs do table.insert(list,surface(ref.Value)) end
	return list
end
local obstacles=course.Obstacles
local function fixed(name) return surface(obstacles[name]) end
local start=surface(course.Start)
local cp={fixed("CP1_Pocket"),fixed("CP2_Pocket"),fixed("CP3_Pocket"),fixed("CP4_Pocket")}
local routes={}
local blocked, tight, overlaps, ordinaryOverlaps, ordinaryLinks={}, {}, {}, {}, {}
local function audit(name, first, middle, last)
	local list={first}
	for _, item in middle do table.insert(list,item) end
	table.insert(list,last)
	local length, maximumGap=0,0
	for i=2,#list do
		local a,b=list[i-1],list[i]
		local distance,rise=gap(a,b),b.top-a.top
		local allowed=reach(rise)
		length+=horizontal(b.center-a.center).Magnitude
		maximumGap=math.max(maximumGap,distance)
		local row={route=name,from=a.name,to=b.name,gap=distance,rise=rise,reach=allowed}
		local ar,br=a.part:GetAttribute("ERRoute"),b.part:GetAttribute("ERRoute")
		local ordinary=(ar=="Normal" or ar=="Expert") and (br=="Normal" or br=="Expert")
			and not a.part:GetAttribute("ERSupport") and not b.part:GetAttribute("ERSupport")
		if ordinary then table.insert(ordinaryLinks,row) end
		if allowed<0 or distance>allowed+2 then table.insert(blocked,row)
		elseif distance>allowed then table.insert(tight,row) end
		if distance<.01 then
			table.insert(overlaps,row)
			if ordinary then table.insert(ordinaryOverlaps,row) end
		end
	end
	routes[name]={length=length,pads=#list,maximumGap=maximumGap,list=list}
	return routes[name]
end
audit("S1",start,route("S1_Nestyard"),cp[1])
local expert1={route("S1_Nestyard")[1]}
for _, item in route("E1_RimSprint") do table.insert(expert1,item) end
audit("E1",start,expert1,cp[1])
audit("S2",cp[1],route("S2_EggRollers"),cp[2])
audit("E2",cp[1],route("E2_ChuteCut"),cp[2])
audit("S3Approach",cp[2],route("S3_ShellApproach"),fixed("Shell_ForkWait"))
local expert3=route("E3_CrownApproach")
for _, item in route("E3_MovingCrown") do table.insert(expert3,item) end
audit("E3",cp[2],expert3,fixed("Shell_ExitWait"))
local lips={}
for i=1,4 do table.insert(lips,surface(obstacles.Mechanisms["ShellLip"..i].ShellContact)) end
audit("Shells",fixed("Shell_ForkWait"),{lips[1],lips[2],fixed("Shell_MiddleWait"),lips[3],lips[4]},fixed("Shell_ExitWait"))
audit("S4Approach",fixed("Shell_ExitWait"),route("S4_IncubatorApproach"),fixed("Tray_BoardPocket"))
local mainApproach,alternateApproach=route("S4_IncubatorApproach"),route("S4_TrayApproachB")
assert(#mainApproach==6 and #alternateApproach==3,"six unchanged main and three alternate Incubator landings")
local alternateAudit=audit("S4ApproachB",mainApproach[5],alternateApproach,fixed("Tray_BoardPocket"))
for i=2,#alternateAudit.list do
	local a,b=alternateAudit.list[i-1],alternateAudit.list[i]
	assert(gap(a,b)>=2.6 and gap(a,b)<=reach(b.top-a.top),"alternate joins require useful open gap and point-jump reach")
end
for _, landing in alternateApproach do
	assert(landing.part.Size==V.new(8,2,4),"alternate ordinary targets stay readable")
	for i=1,4 do
		assert(gap(mainApproach[i],landing)>reach(landing.top-mainApproach[i].top)+2,"alternate cannot bypass shared red hop from pre-red approach")
	end
	for _, decoration in course.Decoration:GetDescendants() do
		if not decoration:IsA("BasePart") or not decoration.CanCollide then continue end
		local destination=surface(decoration)
		assert(gap(landing,destination)>reach(destination.top-landing.top),"alternate must not introduce reachable scenery stepping stones")
	end
end
local trayModel=obstacles.Mechanisms.SidewaysTray
local trayBoard=surface(trayModel.TrayContact)
local trayExit=surface(trayModel.TrayContact,trayModel:GetAttribute("Travel"))
audit("TrayBoard",fixed("Tray_BoardPocket"),{},trayBoard)
audit("TraySideExit",trayExit,{},fixed("Tray_ReceivePocket"))
assert(trayModel.TrayContact.Size==V.new(12,1,18),"deck actual footprint12x18")
assert(obstacles.Tray_BoardPocket.Size==V.new(24,2,8),"boarding wait actual footprint24x8")
assert(obstacles.Tray_ReceivePocket.Size==V.new(18,2,10),"side receiving edge spans18")
assert(math.abs(obstacles.Tray_ReceivePocket.CFrame.RightVector.Z)>.999,"receiving width faces sideways exit")
assert(gap(fixed("Tray_BoardPocket"),fixed("Tray_ReceivePocket"))>reach(0)+2,"static waits cannot bypass moving transfer")
for _, landing in alternateApproach do
	assert(gap(landing,fixed("Tray_ReceivePocket"))>reach(fixed("Tray_ReceivePocket").top-landing.top)+2,"alternate cannot bypass tray to receiving side")
end
local function nominalTwenty(part,columns,rows)
	local pitch,half=2.5,1.25
	local positions={}
	for index=0,19 do
		local x=(index%columns-(columns-1)/2)*pitch
		local z=(math.floor(index/columns)-(rows-1)/2)*pitch
		assert(math.abs(x)+half<=part.Size.X/2 and math.abs(z)+half<=part.Size.Z/2,"nominal full square footprint fits")
		for _, previous in positions do assert(math.abs(x-previous.X)>=pitch or math.abs(z-previous.Z)>=pitch,"nominal squares do not overlap") end
		table.insert(positions,V.new(x,0,z))
	end
	assert(#positions==20,"exactly twenty nominal positions")
	print(string.format("NOMINAL_FOOTPRINT %s:20 squares2.5x2.5 fit; geometry only, no avatar/crowd/passing/capacity proof",part.Name))
end
nominalTwenty(trayModel.TrayContact,4,5)
nominalTwenty(obstacles.Tray_BoardPocket,8,3)
audit("S4Exit",fixed("Tray_ReceivePocket"),route("S4_ExitClimb"),cp[3])
audit("S5",cp[3],route("S5_Rookery"),fixed("Tail_SafeWait"))
audit("E4",cp[3],route("E4_RoostCut"),fixed("Tail_SafeWait"))
audit("TailBand",fixed("Tail_SafeWait"),route("S5_TailBand"),cp[4])
audit("S6",cp[4],route("S6_ShellSpill"),start)
print(string.format("Point-jump reach %.3f studs at16/7.2/196.2; blocker classification allows extra2 studs body margin",reach(0)))
for _, name in {"S1","E1","S2","E2","S3Approach","E3","Shells","S4Approach","S4ApproachB","TrayBoard","TraySideExit","S4Exit","S5","E4","TailBand","S6"} do
	local row=routes[name]
	print(string.format("ROUTE %s: %.2f horizontal centerline studs, %d surfaces, max nearest gap %.2f",name,row.length,row.pads,row.maximumGap))
end
local function report(prefix,list)
	for _, row in list do
		print(string.format("%s %s %s -> %s: gap%.2f rise%.2f reach%.2f",prefix,row.route,row.from,row.to,row.gap,row.rise,row.reach))
	end
end
report("BLOCKED",blocked); report("TIGHT",tight); report("OVERLAP",overlaps)
local normal, expert=0,0
for _, name in {"S1","S2","S3Approach","Shells","S4Approach","TrayBoard","TraySideExit","S4Exit","S5","TailBand","S6"} do normal+=routes[name].length end
for _, name in {"E1","E2","E3","S4Approach","TrayBoard","TraySideExit","S4Exit","E4","TailBand","S6"} do expert+=routes[name].length end
normal+=trayModel:GetAttribute("Travel").Magnitude
expert+=trayModel:GetAttribute("Travel").Magnitude
print(string.format("PACING centerline Normal%.2f Expert%.2f delta%.2f; at16, %.2f/%.2f s perlap before wait/alignment/fall",normal,expert,normal-expert,normal/speed,expert/speed))
print(string.format("TRAY direct static gap%.2f vs samelevel point reach%.2f; sideexit gap%.2f",gap(fixed("Tray_BoardPocket"),fixed("Tray_ReceivePocket")),reach(0),gap(trayExit,fixed("Tray_ReceivePocket"))))
local tail=obstacles.Mechanisms.GuardianTail
local tailBody=tail.RoughTail
local pivot=tail.WorldPivot
local rest=pivot:Inverse()*tailBody.CFrame
local wait=fixed("Tail_SafeWait")
local minimumZ,minimumTailGap=math.huge,math.huge
local waitSamplesHit=0
for degrees=0,tail:GetAttribute("SweepAngleDegrees"),.25 do
	local frame=pivot*C.fromAxisAngle(tail:GetAttribute("RotationAxis"),math.rad(degrees))*rest
	minimumTailGap=math.min(minimumTailGap,gap(surface({Name="TailPose",CFrame=frame,Size=tailBody.Size}),wait))
	for _, corner in {{-1,-1},{1,-1},{1,1},{-1,1}} do
		minimumZ=math.min(minimumZ,(frame*V.new(corner[1]*tailBody.Size.X/2,0,corner[2]*tailBody.Size.Z/2)).Z)
	end
	for _, point in wait.corners do
		local localPoint=frame:PointToObjectSpace(V.new(point.X,wait.top+2,point.Z))
		if math.abs(localPoint.X)<=tailBody.Size.X/2+1 and math.abs(localPoint.Y)<=tailBody.Size.Y/2+2
			and math.abs(localPoint.Z)<=tailBody.Size.Z/2+1 then waitSamplesHit+=1 end
	end
end
local waitMaxZ=-math.huge
for _, corner in wait.corners do waitMaxZ=math.max(waitMaxZ,corner.Z) end
print(string.format("TAIL sweep minimumZ%.3f vs safeWait maximumZ%.3f; Zseparation%.3f orientedgap%.3f; expanded corner samples hit%d",minimumZ-authoring.Origin.Z,waitMaxZ-authoring.Origin.Z,minimumZ-waitMaxZ,minimumTailGap,waitSamplesHit))
print(string.format("SUMMARY %d blocked, %d tight beyond point reach, %d touching/overlapping consecutive links",#blocked,#tight,#overlaps))
print(string.format("ORDINARY %d ordinary consecutive pad pairs have zero open-air gap",#ordinaryOverlaps))
report("ORDINARY_OVERLAP",ordinaryOverlaps)
local narrow=0
local smallestGap,largestGap=math.huge,0
for _, row in ordinaryLinks do
	if row.gap<1.5 then narrow+=1 end
	smallestGap=math.min(smallestGap,row.gap);largestGap=math.max(largestGap,row.gap)
end
print(string.format("NARROW %d/%d ordinary links have less than1.5stud geometric gap (including overlaps); native no-jump tests required",narrow,#ordinaryLinks))
local short={}
for _, row in ordinaryLinks do if row.gap<2.5 then table.insert(short,row) end end
report("SHORT",short)
print(string.format("ORDINARY_GAPS minimum%.3f maximum%.3f across%dlinks",smallestGap,largestGap,#ordinaryLinks))
local sortedGaps,demanding={},{}
for _,row in ordinaryLinks do
	table.insert(sortedGaps,row.gap)
	if row.gap>7.5 then table.insert(demanding,row) end
end
table.sort(sortedGaps)
print(string.format("GAP_DISTRIBUTION median%.3f p90%.3f",sortedGaps[math.ceil(#sortedGaps*.5)],sortedGaps[math.ceil(#sortedGaps*.9)]))
report("DEMANDING",demanding)
local movingOverlaps=0
for _, a in route("E3_MovingCrown") do
	for _, b in lips do
		if gap(a,b)<.01 and math.abs(a.center.Y-b.center.Y)<(a.part.Size.Y+b.part.Size.Y)/2 then
			movingOverlaps+=1
			print(string.format("MOVING_OVERLAP %s -> %s: planar overlap, vertical solid penetration%.2f",a.name,b.name,(a.part.Size.Y+b.part.Size.Y)/2-math.abs(a.center.Y-b.center.Y)))
		end
	end
end
for _, rock in course.Decoration.RoughSupports:GetChildren() do assert(not rock.CanCollide,"Decorative support must not bridge jumps") end
for _, name in {"S1_Nestyard","E1_RimSprint","S2_EggRollers","E2_ChuteCut","S3_ShellApproach","E3_CrownApproach","S4_IncubatorApproach","S4_TrayApproachB","S4_ExitClimb","S5_Rookery","E4_RoostCut","S5_TailBand","S6_ShellSpill"} do
	local list=route(name);local bridges=0;local minimumGap=math.huge
	for i=2,#list do
		local a=course.Decoration.RoughSupports[list[i-1].name.."_Rock"]
		local b=course.Decoration.RoughSupports[list[i].name.."_Rock"]
		local distance=gap(surface(a),surface(b));minimumGap=math.min(minimumGap,distance)
		if distance<.01 and a.CanCollide and b.CanCollide then bridges+=1 end
	end
	print(string.format("ROCK %s: %d/%d consecutive support pairs touch/overlap; minimum gap%.2f",name,bridges,#list-1,minimumGap))
end
for _, pair in {{"S1_Nestyard","E1_RimSprint",true}} do
	local normalRoute,expertRoute=route(pair[1]),route(pair[2])
	local endpoint=if pair[3] then expertRoute[1] else expertRoute[#expertRoute]
	for i, item in normalRoute do
		local a,b=if pair[3] then item else endpoint,if pair[3] then endpoint else item
		local distance=gap(a,b);local allowed=reach(b.top-a.top)
		if distance<=allowed+2 then print(string.format("REJOIN %s %s -> %s:gap%.2f rise%.2f reach%.2f center%.2f",pair[2],a.name,b.name,distance,b.top-a.top,allowed,horizontal(a.center-b.center).Magnitude)) end
	end
end
for _, mass in course.Decoration:GetChildren() do
	if not mass:IsA("BasePart") or not mass.CanCollide or (mass.Name~="DistrictRoughMass" and mass.Name~="EggRunout") then continue end
	local destination=surface(mass)
	for _, refGroup in course.Routes:GetChildren() do
		for _, ref in refGroup:GetChildren() do
			local source=surface(ref.Value);local rise=destination.top-source.top
			if rise>0 and rise<=height and gap(source,destination)<=reach(rise) then
				print(string.format("SCENERY %s -> %s roof at(%.0f,%.0f):gap%.2f rise%.2f reach%.2f",source.name,mass.Name,mass.CFrame.Position.X-authoring.Origin.X,mass.CFrame.Position.Z-authoring.Origin.Z,gap(source,destination),rise,reach(rise)))
			end
		end
	end
end
for _, part in course:GetDescendants() do
	local padName=part:GetAttribute("ERPadName")
	if padName then
		local pad=course.Obstacles:FindFirstChild(padName,true)
		local nextPad=course.Obstacles:FindFirstChild(part:GetAttribute("ERNextPadName"),true)
		assert(pad and nextPad and pad.Parent==nextPad.Parent and pad:GetAttribute("ERRoute")=="Normal","red bar belongs between consecutive Normal landings")
		local a,b=pad:GetAttribute("ERTop"),nextPad:GetAttribute("ERTop")
		local direction=horizontal(b-a).Unit
		local function extent(p)
			return math.abs(p.CFrame.RightVector:Dot(direction))*p.Size.X/2+math.abs(p.CFrame.LookVector:Dot(direction))*p.Size.Z/2
		end
		local expected=((a+direction*extent(pad))+(b-direction*extent(nextPad)))/2+V.new(0,.7,0)
		assert((part.CFrame.Position-expected).Magnitude<.01,"red bar centered in actual gap")
		assert(part.CFrame.LookVector:Dot(direction)>.999,"red bar faces transfer direction")
		local departureGap,arrivalGap=gap(surface(part),surface(pad)),gap(surface(part),surface(nextPad))
		assert(departureGap>.1 and arrivalGap>.1,"red bar leaves takeoff and landing footprints clear")
		print(string.format("RED_GAP %s: takeoffclearance%.3f landingclearance%.3f",part.Name,departureGap,arrivalGap))
	end
end
assert(#blocked==0 and #tight==0,"Study links must fit point-jump reach")
assert(#short==0,"Ordinary pads need useful geometric gaps")
for _,row in ordinaryLinks do
	local minimum=5+math.min(1.5,math.max(0,-row.rise)*.5)
	assert(row.gap>=minimum-.02,"ordinary jump-spacing candidate minimum, with extra descending clearance")
end
assert(movingOverlaps==0,"Moving Normal/Expert lips must not intersect in open pose")
assert(minimumTailGap>2.5,"Safe wait needs body clearance from full tail sweep")
print("FOCUSED_GEOMETRY_CLEAR: jump links, ordinary gaps, moving-lip separation, red-bar placement and tail-wait clearance")
