--!strict

local Check = {}

function Check.Run(model: Model, geometry: any): any
	assert(model:IsDescendantOf(workspace),"Gap clearance requires a workspace course")
	assert(model:GetAttribute("JumpRevision")==1,"Expected restored jump routes")
	local stats={}
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={model}
	params.RespectCanCollide=true
	local clearanceSamples=0
	local checkpointSideSamples=0
	for _,part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and ({[3]=true,[5]=true,[6]=true,[7]=true,[9]=true})[part:GetAttribute("SectionIndex")] then
			assert(not part:GetAttribute("ContinuousRoute") and not part:GetAttribute("RouteLink"),"A continuous route bypasses the jumps")
		end
	end
	for _,row in ipairs(geometry.jumps) do
		local starter=game.StarterPlayer
		local gravity=workspace.Gravity
		local velocity=if starter.CharacterUseJumpPower then starter.CharacterJumpPower else math.sqrt(2*gravity*starter.CharacterJumpHeight)
		local flight=(velocity+math.sqrt(math.max(0,velocity*velocity-2*gravity*row.rise)))/gravity
		assert(row.gap<=starter.CharacterWalkSpeed*flight-.25,"Gap exceeds the normal jump range: "..row.sourceKey..">"..row.targetKey)
		-- Broad checkpoints are rest areas; compare the actual obstacle sequences.
		if row.source:find("Checkpoint") or row.target:find("Checkpoint") then continue end
		local stat=stats[row.section] or {count=0,total=0,minimum=math.huge,maximum=0}
		stat.count+=1
		stat.total+=row.gap
		stat.minimum=math.min(stat.minimum,row.gap)
		stat.maximum=math.max(stat.maximum,row.gap)
		stats[row.section]=stat
		assert(row.gap>=3,"A jump gap closed: "..row.sourceKey..">"..row.targetKey)
		assert(row.gap<=12,"A jump exceeds the tested tuning range: "..row.sourceKey..">"..row.targetKey)
		local a=Vector3.new(row.launchAnchor.x,row.launchAnchor.y,row.launchAnchor.z)
		local b=Vector3.new(row.targetAnchor.x,row.targetAnchor.y,row.targetAnchor.z)
		local direction=((b-a)*Vector3.new(1,0,1)).Unit
		local side=Vector3.new(-direction.Z,0,direction.X)
		local floor=math.min(a.Y,b.Y)
		for _,offset in ipairs({-.75,0,.75}) do
			local center=a+direction*(row.takeoffEdge+row.gap/2)+side*offset
			local hit=workspace:Raycast(Vector3.new(center.X,floor+3,center.Z),Vector3.new(0,-10,0),params)
			if hit and hit.Position.Y>floor-3.5 then
				local part=hit.Instance
				local adjacentCheckpoint=offset~=0 and part:GetAttribute("SharedCheckpoint")
					and part:GetAttribute("SectionIndex")==row.section
					and part:GetAttribute("SectionStep")==row.step-2
				assert(adjacentCheckpoint,"Geometry bridges a jump: "..row.sourceKey..">"..row.targetKey)
				checkpointSideSamples+=1
			end
			clearanceSamples+=1
		end
	end
	for _,stat in pairs(stats) do stat.average=stat.total/stat.count;stat.total=nil end
	for _,section in ipairs({3,9}) do
		assert(stats[section].average>stats[6].average+.5,"Hardest sections lost their gap advantage")
		assert(stats[section].maximum>stats[6].maximum+1,"Hardest sections no longer have the furthest jumps")
	end
	for _,section in ipairs({5,7}) do
		assert(stats[6].average>stats[section].average+1,"Section 06 should be harder than 05 and 07")
		assert(stats[6].maximum>stats[section].maximum+.5,"Section 06 should have longer jumps than 05 and 07")
	end
	return {status="Passed",sections=stats,clearanceSamples=clearanceSamples,checkpointSideSamples=checkpointSideSamples}
end

return Check
