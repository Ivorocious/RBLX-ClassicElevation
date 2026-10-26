--!nonstrict
local Clearance={}
local function axes(cf) return {cf.RightVector,cf.UpVector,-cf.LookVector} end
local function box(cf,size,reason,kind)
	local aa,h=axes(cf),size/2
	local radius=Vector3.new(math.abs(aa[1].X)*h.X+math.abs(aa[2].X)*h.Y+math.abs(aa[3].X)*h.Z,
		math.abs(aa[1].Y)*h.X+math.abs(aa[2].Y)*h.Y+math.abs(aa[3].Y)*h.Z,
		math.abs(aa[1].Z)*h.X+math.abs(aa[2].Z)*h.Y+math.abs(aa[3].Z)*h.Z)
	return {frame=cf,size=size,half={h.X,h.Y,h.Z},axes=aa,reason=reason,kind=kind or "Movement",low=cf.Position-radius,high=cf.Position+radius}
end
local function overlaps(a,b)
	if a.low.X>b.high.X or a.high.X<b.low.X or a.low.Y>b.high.Y or a.high.Y<b.low.Y or a.low.Z>b.high.Z or a.high.Z<b.low.Z then return false end
	local delta=b.frame.Position-a.frame.Position
	local function separates(axis)
		if axis.Magnitude<.00001 then return false end
		local radius=0
		for i=1,3 do radius+=math.abs(axis:Dot(a.axes[i]))*a.half[i]+math.abs(axis:Dot(b.axes[i]))*b.half[i] end
		return math.abs(delta:Dot(axis))>radius+.00001
	end
	for i=1,3 do if separates(a.axes[i]) or separates(b.axes[i]) then return false end end
	for _,aa in a.axes do for _,bb in b.axes do if separates(aa:Cross(bb)) then return false end end end
	return true
end
local function corridor(a,b,width,height,pad,reason,kind)
	local horizontal=Vector3.new(b.X-a.X,0,b.Z-a.Z)
	if horizontal.Magnitude<.05 then return nil end
	local low,high=math.min(a.Y,b.Y)+.05,math.max(a.Y,b.Y)+height
	local center=Vector3.new((a.X+b.X)/2,(low+high)/2,(a.Z+b.Z)/2)
	local cf=CFrame.new(center)*CFrame.Angles(0,math.atan2(-horizontal.X,-horizontal.Z),0)
	return box(cf,Vector3.new(width,high-low,horizontal.Magnitude+2*pad),reason,kind)
end
function Clearance.Prepare(layout,config)
	local volumes,floors,seen={},{},{}
	local body,jump=6.5,config.Movement.JumpHeight+6.5+.8
	local function add(value) if value then table.insert(volumes,value) end end
	for _,floor in layout.Surfaces do
		local path="Obstacles/"..floor.group.."/"..floor.name.."/Contact"
		floors[path]=floor
		local cf=floor.frame or CFrame.new(floor.position)
		add(box(cf*CFrame.new(0,body/2+.05,0),Vector3.new(floor.size.X+2,body,floor.size.Z+2),"Standing "..path))
		add(box(cf*CFrame.new(0,jump/2+.05,0),Vector3.new(floor.size.X+2,jump,floor.size.Z+2),"Free jump above "..path,"JumpHeadroom"))
	end
	local function point(node)
		local floor=floors[node.path];if not floor then return nil end
		return (floor.frame or CFrame.new(floor.position)):PointToWorldSpace(node.offset or Vector3.zero)
	end
	local function segment(a,b,isJump,label)
		local key=tostring(a)..">"..tostring(b)..tostring(isJump)
		if seen[key] then return end;seen[key]=true
		add(corridor(a,b,4.5,if isJump then jump else body,1.25,label))
		local direction=Vector3.new(b.X-a.X,0,b.Z-a.Z)
		if direction.Magnitude<.05 then return end;direction=direction.Unit
		local rearA,rearB=a-direction*11,b-direction*11
		add(corridor(rearA+Vector3.yAxis*3,rearB+Vector3.yAxis*3,8,if isJump then 15.2 else 8,2,"Follow camera "..label,"Camera"))
		local camera=rearA+Vector3.yAxis*7
		local target=b+Vector3.yAxis*.7
		local delta=target-camera
		local right=delta:Cross(Vector3.yAxis)
		if right.Magnitude>.01 then
			right=right.Unit;local forward=delta.Unit;local up=right:Cross(forward).Unit
			add(box(CFrame.fromMatrix((camera+target)/2,right,up,-forward),Vector3.new(3,.9,delta.Magnitude),"Landing sight "..label,"Visibility"))
		end
	end
	for _,tr in layout.Transfers do
		if tr.fromPoint and tr.toPoint then segment(tr.fromPoint,tr.toPoint,true,tr.from..">"..tr.to) end
	end
	local routes={layout.GetRoute({false,false,false},{1,2}),layout.GetRoute({true,true,true},{1,2})}
	if layout.GetCatchRoute then table.insert(routes,layout.GetCatchRoute("Arch"));table.insert(routes,layout.GetCatchRoute("Upper")) end
	for _,route in routes do
		for i=2,#route do
			local before,node=route[i-1],route[i]
			local a,b=point(before),point(node)
			if a and b and not node.drop then segment(a,b,node.kind=="Jump",before.path..">"..node.path) end
			if node.kind=="Ride" then
				local wait,exit=point({path=node.waitPath,offset=node.waitOffset}),point({path=node.exitPath,offset=node.exitOffset})
				local stage=if string.find(node.path,"Upper_",1,true) then "Upper" else "Lower"
				local bay=if string.find(node.path,"Bay1",1,true) then -9 else 9
				local center=layout.LiftOrigins[stage]+Vector3.new(bay,0,0)
				if wait then segment(wait,center+node.board,true,stage.." boarding") end
				if exit then segment(center+Vector3.new(0,34,0)+(node.exitTakeoff or Vector3.zero),exit,true,stage.." exit") end
			end
		end
	end
	for stage,origin in layout.LiftOrigins do
		for _,bay in {-9,9} do
			add(box(CFrame.new(origin+Vector3.new(bay,24.5,0)),Vector3.new(18,49,16),stage.." car full swept/body space","Mechanism"))
		end
		for _,side in {-27,27} do
			add(box(CFrame.new(origin+Vector3.new(side,22,-1)),Vector3.new(8,44,6.5),stage.." counterweight swept space","Mechanism"))
		end
	end
	for _,lantern in layout.Lanterns do
		local low,high=Vector3.one*math.huge,Vector3.one*-math.huge
		for sample=0,16 do
			local rotation=CFrame.fromAxisAngle(lantern.axis,math.rad(-32+sample*4))
			local cage=CFrame.new(lantern.pivot)*rotation*CFrame.new(-lantern.pivot)*CFrame.new(lantern.point)
			for _,x in {-4,4} do for _,y in {-7,7} do for _,z in {-4,4} do
				local p=cage:PointToWorldSpace(Vector3.new(x,y,z))
				low=Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
				high=Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
			end end end
		end
		add(box(CFrame.new((low+high)/2),high-low+Vector3.one,"Swing envelope "..lantern.name,"Mechanism"))
	end
	return volumes
end
function Clearance.CheckParts(parts,volumes,origin)
	local report={blocking={},headroom={},camera={},visibility={},invalidContactFlags={}}
	for _,part in parts do
		if part.collide or part.query or part.touch or not part.anchored then table.insert(report.invalidContactFlags,part.path) end
		if part.transparency and part.transparency>=1 then continue end
		local cf=CFrame.new(table.unpack(part.frame));if origin then cf=CFrame.new(-origin)*cf end
		local obstacle=box(cf,Vector3.new(table.unpack(part.size)),part.path)
		for _,volume in volumes do
			if not overlaps(obstacle,volume) then continue end
			local target=if volume.kind=="Camera" then report.camera elseif volume.kind=="Visibility" then report.visibility
				elseif volume.kind=="JumpHeadroom" then report.headroom else report.blocking
			table.insert(target,{part=part.path,space=volume.reason})
		end
	end
	report.physicalAndStandingScreenPass=#report.blocking==0 and #report.invalidContactFlags==0
	report.nativeCameraProof=false
	return report
end
function Clearance.AddImportantViews(volumes,views,origin)
	for _,view in views do
		local camera=Vector3.new(table.unpack(view.camera))-(origin or Vector3.zero)
		local target=Vector3.new(table.unpack(view.lookAt))-(origin or Vector3.zero)
		local forward=(target-camera).Unit
		local right=forward:Cross(Vector3.yAxis)
		if right.Magnitude<.01 then continue end
		right=right.Unit
		table.insert(volumes,box(CFrame.new(camera),Vector3.new(4,6,4),"Review camera "..view.name,"Camera"))
		table.insert(volumes,box(CFrame.fromMatrix((camera+target)/2,right,right:Cross(forward).Unit,-forward),
			Vector3.new(3,2,(target-camera).Magnitude),"Review view "..view.name,"Visibility"))
	end
	return #volumes
end
return Clearance
