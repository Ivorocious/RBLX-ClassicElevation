-- Read-only repeated-asset face checks and measured hazard barriers.
local course=workspace.Course_StudGardenV2
local out={candidate=course:GetAttribute("CandidateId"),models=0,boxParts=0,coplanarFaces={},hazards={}}
local function bounds(model,part)
	local rel=model:GetPivot():ToObjectSpace(part.CFrame)
	if math.abs(rel.XVector.X)<.999 or math.abs(rel.YVector.Y)<.999 or math.abs(rel.ZVector.Z)<.999 then return nil end
	local lo,hi=rel.Position-part.Size/2,rel.Position+part.Size/2
	return {lo.X,lo.Y,lo.Z},{hi.X,hi.Y,hi.Z}
end
for _,m in course:GetDescendants() do
	local family=m:GetAttribute("AssetFamily")
	if not m:IsA("Model") or not family or not (family=="HarvestCrate" or family=="HarvestWagon" or string.match(family,"^GardenTool_")) then continue end
	out.models+=1
	local boxes={}
	for _,p in m:GetDescendants() do
		if not p:IsA("Part") or p.Shape~=Enum.PartType.Block or not p.CanCollide then continue end
		local lo,hi=bounds(m,p)
		if lo then table.insert(boxes,{part=p,lo=lo,hi=hi});out.boxParts+=1 end
	end
	for i,a in boxes do for j=i+1,#boxes do
		local b=boxes[j]
		for axis=1,3 do for _,side in {"lo","hi"} do
			if math.abs(a[side][axis]-b[side][axis])>.005 then continue end
			local area=1
			for k=1,3 do if k~=axis then area*=math.max(0,math.min(a.hi[k],b.hi[k])-math.max(a.lo[k],b.lo[k])) end end
			if area>.01 then table.insert(out.coplanarFaces,{model=m:GetFullName(),a=a.part.Name,b=b.part.Name,axis=axis,side=side,area=area}) end
		end end
	end end
end
for _,name in {"H1_Sprinkler","H2_Fruit"} do
	local m=course[name]
	local parts={}
	for _,p in m:GetDescendants() do
		if p:IsA("BasePart") and (string.find(p.Name,"Rail") or string.find(p.Name,"Nozzle") or string.find(p.Name,"Mesh") or p.Name=="CatchTrough") then
			local relative=m:GetPivot():ToObjectSpace(p.CFrame)
			table.insert(parts,{name=p.Name,center={relative.X,relative.Y,relative.Z},size={p.Size.X,p.Size.Y,p.Size.Z},solid=p.CanCollide})
		end
	end
	out.hazards[name]=parts
end
out.limit="Same-facing coplanar box faces within repeated tools/crates/wagons only; does not prove all visual contacts, no bypasses, or avatar traversal."
return out
