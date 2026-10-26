-- Read-only geometric checks; ray paths do not establish character traversal.
local course=workspace:FindFirstChild("Course_StudGardenV2")
assert(course and course:GetAttribute("SGV2Owned"),"V2 candidate required")
local origin=course:GetAttribute("CourseOrigin")
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={course}
params.RespectCanCollide=true
local function ground(point)
	local best=nil
	for _,offset in {Vector3.zero,Vector3.new(.35,0,0),Vector3.new(-.35,0,0),Vector3.new(0,0,.35),Vector3.new(0,0,-.35)} do
		local hit=workspace:Raycast(point+offset+Vector3.new(0,2.6,0),Vector3.new(0,-5,0),params)
		if hit and (not best or math.abs(hit.Position.Y-point.Y)<math.abs(best.Position.Y-point.Y)) then best=hit end
	end
	return best
end
local report={candidate=course:GetAttribute("CandidateId"),paths={},packs={},counts={parts=0,colliders=0,meshes=0},limit="Geometry only; no avatars moved, runtime started or human pacing measured"}
for _,object in course:GetDescendants() do
	if object:IsA("BasePart") then report.counts.parts+=1;if object.CanCollide then report.counts.colliders+=1 end;if object:IsA("MeshPart") then report.counts.meshes+=1 end end
end
local folders=course.RouteMarkers:GetChildren()
table.sort(folders,function(a,b)return a.Name<b.Name end)
for _,folder in folders do
	local points=folder:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
	local result={name=folder.Name,kind=folder:GetAttribute("RouteKind"),length=0,maxGap=0,gaps={},lowHeadroom={},samples=0}
	local gap=0;local gapStart=nil;local blocked={}
	for i=1,#points-1 do
		local a,b=points[i].Position,points[i+1].Position
		local distance=(a-b).Magnitude; result.length+=distance
		local count=math.ceil(distance/.3);local step=distance/count
		for j=0,count-1 do
			local p=a:Lerp(b,j/count); local hit=ground(p);result.samples+=1
			if not hit or hit.Position.Y<p.Y-1.5 then
				gap+=step;gapStart=gapStart or (p-origin)
			else
				if gap>1 then table.insert(result.gaps,{length=gap,start={gapStart.X,gapStart.Y,gapStart.Z}}) end
				result.maxGap=math.max(result.maxGap,gap);gap=0;gapStart=nil
				local ceiling=workspace:Raycast(hit.Position+Vector3.new(0,.25,0),Vector3.new(0,5.5,0),params)
				if ceiling then blocked[ceiling.Instance:GetFullName()]=(blocked[ceiling.Instance:GetFullName()] or 0)+1 end
			end
		end
	end
	result.maxGap=math.max(result.maxGap,gap)
	for name,count in blocked do table.insert(result.lowHeadroom,{part=name,samples=count}) end
	table.insert(report.paths,result)
end
local stations={course.Start}
for _,cp in course.Checkpoints:GetChildren() do table.insert(stations,cp) end
for _,r in {{"H1_Wait",course.H1_Sprinkler.DryWait,Vector3.new(34,0,18)},{"H2_Wait",course.H2_Fruit.EntryRefuge,Vector3.new(28,0,18)}} do
	local frame=r[2]:GetPivot()+Vector3.new(0,5.24,0)
	table.insert(stations,{Name=r[1],GetAttribute=function(_,name) return if name=="RespawnCFrame" then frame elseif name=="RespawnAreaSize" then r[3] else nil end})
end
table.sort(stations,function(a,b)return a.Name<b.Name end)
local overlaps=OverlapParams.new();overlaps.FilterType=Enum.RaycastFilterType.Include;overlaps.FilterDescendantsInstances={course};overlaps.RespectCanCollide=true
for _,station in stations do
	local frame=station:GetAttribute("RespawnCFrame");local size=station:GetAttribute("RespawnAreaSize")
	local columns=math.max(1,1+math.floor((size.X-3)/4.5))
	local rows=math.max(1,1+math.floor((size.Z-3)/4.5))
	local result={name=station.Name,id=station:GetAttribute("CheckpointId"),supported=0,requiredSlots=20,slots=columns*rows,capacity=columns*rows,clearanceProblems=0,footprintProblems=0,bodyObstructions={},spacing=4.5}
	local bodies={}
	for slot=0,columns*rows-1 do
		local point=frame*Vector3.new((slot%columns-(columns-1)/2)*4.5,-5,(math.floor(slot/columns)-(rows-1)/2)*4.5)
		local hit=ground(point)
		if hit and math.abs(hit.Position.Y-point.Y)<.7 then
			result.supported+=1
			local obstruction=workspace:Raycast(hit.Position+Vector3.new(0,.2,0),Vector3.new(0,5.5,0),params)
			if obstruction then result.clearanceProblems+=1 end
			for _,blocker in workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,2.9,0)),Vector3.new(3,5.3,3),overlaps) do bodies[blocker:GetFullName()]=(bodies[blocker:GetFullName()] or 0)+1 end
			for _,offset in {Vector3.new(-1.5,0,-1.5),Vector3.new(1.5,0,-1.5),Vector3.new(1.5,0,1.5),Vector3.new(-1.5,0,1.5)} do
				local foot=ground(point+offset)
				if not foot or math.abs(foot.Position.Y-point.Y)>.7 then result.footprintProblems+=1 end
			end
		end
	end
	for part,count in bodies do table.insert(result.bodyObstructions,{part=part,slots=count}) end
	table.insert(report.packs,result)
end
local _,size=course:GetBoundingBox();report.bounds={size.X,size.Y,size.Z}
return report
