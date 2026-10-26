-- Read-only support vertices; WedgePart points exclude the empty half of its box.
local course=workspace:FindFirstChild("Course_StudGardenV2")
assert(course and course:GetAttribute("SGV2Owned"),"V2 candidate required")
local origin=course:GetAttribute("CourseOrigin")
local result={candidate=course:GetAttribute("CandidateId"),groups={}}
local wedgeCorners={{-1,-1,-1},{1,-1,-1},{-1,-1,1},{1,-1,1},{-1,1,1},{1,1,1}}
local boxCorners={{-1,-1,-1},{1,-1,-1},{-1,-1,1},{1,-1,1},{-1,1,-1},{1,1,-1},{-1,1,1},{1,1,1}}
for _,model in course:GetDescendants() do
	if not model:IsA("Model") or not (model:GetAttribute("AssetFamily") or string.match(model.Name,"^Stake_")) then continue end
	local group={name=model:GetFullName():sub(#course:GetFullName()+2),family=model:GetAttribute("AssetFamily"),pivot={model:GetPivot():GetComponents()},parts={}}
	for _,part in model:GetDescendants() do
		if not part:IsA("BasePart") or not part.CanCollide then continue end
		if part:GetAttribute("Role")~="Walk" and part:GetAttribute("Role")~="Refuge" then continue end
		local points={}
		for _,v in if part:IsA("WedgePart") then wedgeCorners else boxCorners do
			local p=part.CFrame:PointToWorldSpace(Vector3.new(v[1]*part.Size.X/2,v[2]*part.Size.Y/2,v[3]*part.Size.Z/2))-origin
			table.insert(points,{p.X,p.Y,p.Z})
		end
		table.insert(group.parts,{name=part.Name,class=part.ClassName,points=points,cf={part.CFrame:GetComponents()},size={part.Size.X,part.Size.Y,part.Size.Z}})
	end
	if #group.parts>0 then table.insert(result.groups,group) end
end
return result
