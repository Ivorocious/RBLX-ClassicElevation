--!strict

local Config = require(game.ReplicatedStorage.Config.AscentJumpConfig)
local Props = require(script.Parent.AscentProps)
local Profiles = require(script.Parent.AscentJumpProfiles)
local JumpTuning = {}

local function key(pad: BasePart, step: number?): string
	return string.format("%d:%d:%d",pad:GetAttribute("SectionIndex"),step or pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane"))
end

function JumpTuning.Apply(model: Model)
	if model:GetAttribute("JumpRevision") == Config.Revision then return end
	assert(model:GetAttribute("JumpRevision") == nil,"Unknown jump revision")
	local pads: {[string]: BasePart} = {}
	local surfaces: {[string]: MeshPart} = {}
	local original: {[BasePart]: {size: Vector3, frame: CFrame}} = {}
	local central: {[number]: BasePart} = {}
	for _,part in ipairs(model:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		local section=part:GetAttribute("SectionIndex")
		if part:GetAttribute("RoutePad") then
			pads[key(part)]=part
			original[part]={size=part.Size,frame=part.CFrame}
			local index=part:GetAttribute("RouteIndex")
			if index then central[index]=part end
		elseif part:IsA("MeshPart") and part.Name:sub(1,8)=="Landing_" then
			surfaces[key(part)]=part
		end
	end
	-- Keep the accepted landscape, but put connecting ground below the jump route.
	for _,part in ipairs(model:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		local shoulder=part.Parent
		while shoulder and shoulder~=model and not shoulder.Name:match("^ConnectedShoulder_") do shoulder=shoulder.Parent end
		if shoulder and shoulder~=model then
			if not part.Name:find("RightWall",1,true) then part.CFrame-=Vector3.new(0,14,0) end
			part:SetAttribute("RouteLink",nil)
			part:SetAttribute("RouteSupport",true)
		elseif part:GetAttribute("RouteSupport") then
			part.CFrame-=Vector3.new(0,10,0)
		elseif part:GetAttribute("RavineBank") then
			part.CFrame-=Vector3.new(0,8,0)
		end
	end
	for _,pad in pairs(pads) do
		local section=pad:GetAttribute("SectionIndex")
		local tuning=Config.Sections[section]
		if not tuning then continue end
		pad:SetAttribute("ContinuousRoute",nil)
		if pad.Parent==model.Checkpoints then continue end
		local step,lane=pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane")
		local random=Random.new(section*7919+step*313+(lane+2)*101)
		local side=if step%2==0 then 1 else -1
		local amplitude=if lane==1 and step>=19 and step<=22 and tuning.MountainLateral then tuning.MountainLateral else tuning.Lateral
		local offset=side*amplitude*random:NextNumber(.82,1.12)
		local main=pads[string.format("%d:%d:0",section,step)]
		local frame=main:GetAttribute("SceneryFrame") or original[main].frame
		-- The three lines stay inside their existing course boundaries.
		local relative=frame:PointToObjectSpace(pad.Position)
		if section==5 and lane~=0 then offset=lane*26+random:NextNumber(-1.3,1.3)-relative.X end
		offset=math.clamp(relative.X+offset,-28,28)-relative.X
		pad.CFrame+=frame.RightVector*offset
		if (section==3 or section==9) and step<=3 then
			pad.CFrame+=frame.LookVector*({9,5,1})[step]
			if section==3 and step==1 and lane==-1 then pad.CFrame+=frame.LookVector*4 end
			if step==1 and (section==9 or lane==1) then pad.CFrame-=frame.LookVector*2 end
			if section==3 and step==1 and lane==1 then pad.CFrame-=frame.LookVector*2 end
		end
		if section==3 and step==13 and lane==-1 then pad.CFrame-=frame.RightVector*2 end
		if section==3 and step==2 and lane==1 then pad.CFrame-=frame.LookVector*2.5 end
		if section==7 and step==11 and lane==0 then pad.CFrame+=frame.LookVector*1.5 end
		pad:SetAttribute("JumpTargetGap",tuning.Gap+random:NextNumber(-tuning.GapVariation,tuning.GapVariation))
		pad.Size=Vector3.new(tuning.Width*random:NextNumber(.9,1.12),pad.Size.Y,pad.Size.Z)
	end
	local scales: {[BasePart]: number} = {}
	local edges={}
	for _,pad in pairs(pads) do
		if not Config.Sections[pad:GetAttribute("SectionIndex")] or pad.Parent==model.Checkpoints then continue end
		local random=Random.new(pad:GetAttribute("SectionIndex")*1709+pad:GetAttribute("SectionStep")*79+(pad:GetAttribute("Lane")+2)*29)
		pad.Size=Vector3.new(pad.Size.X,pad.Size.Y,pad.Size.X*random:NextNumber(.8,1.16))
		scales[pad]=1
		local section,step=pad:GetAttribute("SectionIndex"),pad:GetAttribute("SectionStep")
		local nextPad=pads[key(pad,step+1)] or pads[string.format("%d:%d:0",section,step+1)]
		if nextPad then table.insert(edges,{pad,nextPad}) end
		local previous=pads[key(pad,step-1)] or pads[string.format("%d:%d:0",section,step-1)]
		if step==1 then previous=central[pads[string.format("%d:1:0",section)]:GetAttribute("RouteIndex")-1] end
		if previous and previous.Parent==model.Checkpoints then table.insert(edges,{previous,pad}) end
	end
	table.sort(edges,function(a,b)return key(a[1])..">"..key(a[2])<key(b[1])..">"..key(b[2]) end)
	local function anchor(pad: BasePart, other: BasePart): Vector3
		if pad.Parent~=model.Checkpoints then return pad.Position end
		local relative=pad.CFrame:PointToObjectSpace(other.Position)
		return pad.CFrame:PointToWorldSpace(Vector3.new(math.clamp(relative.X,-pad.Size.X/2+2,pad.Size.X/2-2),0,0))
	end
	local function radius(pad: BasePart, direction: Vector3, point: Vector3): number
		local localDirection=pad.CFrame:VectorToObjectSpace(direction)
		local surface=surfaces[key(pad)]
		local localPoint=pad.CFrame:PointToObjectSpace(point)
		if not surface then
			local x=if math.abs(localDirection.X)<1e-8 then math.huge else (math.sign(localDirection.X)*pad.Size.X/2-localPoint.X)/localDirection.X
			local z=if math.abs(localDirection.Z)<1e-8 then math.huge else (math.sign(localDirection.Z)*pad.Size.Z/2-localPoint.Z)/localDirection.Z
			return math.min(x,z)
		end
		local profile=Profiles[surface.Parent.Name]
		assert(profile and profile.MeshId==surface.MeshId,"Landing outline must match its authored mesh")
		local size=surface.Size*Vector3.new(pad.Size.X/original[pad].size.X,1,pad.Size.Z/original[pad].size.Z)
		local ray=Vector2.new(localDirection.X/size.X,localDirection.Z/size.Z)
		local offset=Vector2.new(localPoint.X/size.X,localPoint.Z/size.Z)
		local function cross(a: Vector2,b: Vector2): number return a.X*b.Y-a.Y*b.X end
		local distance=math.huge
		for index,a in ipairs(profile.Points) do
			local b=profile.Points[index%#profile.Points+1]
			local edge=b-a
			local denominator=cross(ray,edge)
			if math.abs(denominator)<1e-8 then continue end
			local t,u=cross(a-offset,edge)/denominator,cross(a-offset,ray)/denominator
			if t>=0 and u>=0 and u<=1 then distance=math.min(distance,t) end
		end
		assert(distance<math.huge,"Landing outline has no forward edge")
		return distance
	end
	local starter=game.StarterPlayer
	local gravity=workspace.Gravity
	local velocity=if starter.CharacterUseJumpPower then starter.CharacterJumpPower else math.sqrt(2*gravity*starter.CharacterJumpHeight)
	for _,pair in ipairs(edges) do
		local a,b=pair[1],pair[2]
		local from,to=anchor(a,b),anchor(b,a)
		local delta=(to-from)*Vector3.new(1,0,1)
		pair.distance=delta.Magnitude
		pair.ar,pair.br=radius(a,delta.Unit,from),radius(b,-delta.Unit,to)
		local rise=b.Position.Y+b.Size.Y/2-a.Position.Y-a.Size.Y/2
		local flight=(velocity+math.sqrt(math.max(0,velocity*velocity-2*gravity*rise)))/gravity
		local aTarget,bTarget=a:GetAttribute("JumpTargetGap"),b:GetAttribute("JumpTargetGap")
		local target=if aTarget and bTarget then (aTarget+bTarget)/2 else aTarget or bTarget
		local section=b:GetAttribute("SectionIndex")
		pair.minimum=if a.Parent==model.Checkpoints or b.Parent==model.Checkpoints then 0 elseif section==3 or section==9 then 5.3 elseif section==6 then 4.5 else 3.5
		pair.maximum=math.min(target,starter.CharacterWalkSpeed*flight-.85)
	end
	-- Fit both sides of each gap; using only centre spacing overlooks diagonal landings.
	for _=1,120 do
		for _,pair in ipairs(edges) do
			local a,b=pair[1],pair[2]
			local ar,br=pair.ar,pair.br
			local gap=pair.distance-ar*(scales[a] or 1)-br*(scales[b] or 1)
			local error=if gap>pair.maximum then gap-pair.maximum elseif gap<pair.minimum then gap-pair.minimum else 0
			local denominator=(if scales[a] then ar*ar else 0)+(if scales[b] then br*br else 0)
			local adjustment=error*.9/denominator
			for _,entry in ipairs({{a,ar},{b,br}}) do
				local pad,extent=entry[1],entry[2]
				if not scales[pad] then continue end
				local minimum=math.max(4/pad.Size.X,4/pad.Size.Z)
				local section=pad:GetAttribute("SectionIndex")
				local widthLimit=if section==6 then 20 elseif section==3 or section==9 then 16 else 14
				local maximum=math.min(widthLimit/pad.Size.X,20/pad.Size.Z)
				scales[pad]=math.clamp(scales[pad]+adjustment*extent,minimum,maximum)
			end
		end
	end
	for pad,scale in pairs(scales) do pad.Size*=Vector3.new(scale,1,scale) end
	for id,surface in pairs(surfaces) do
		local pad=assert(pads[id],"Missing jump metadata")
		if pad.Parent==model.Checkpoints or not Config.Sections[pad:GetAttribute("SectionIndex")] then continue end
		local before=original[pad]
		surface.Size*=Vector3.new(pad.Size.X/before.size.X,1,pad.Size.Z/before.size.Z)
		surface.CFrame=pad.CFrame*before.frame:ToObjectSpace(surface.CFrame)
		surface.Transparency=0
		surface.CanCollide,surface.CanQuery,surface.CanTouch=true,true,false
		surface:SetAttribute("RouteSurface",true)
		Props.UseCollision(surface,Enum.CollisionFidelity.Hull)
	end
	local nodes={}
	for _,pad in pairs(pads) do
		local index=pad:GetAttribute("RouteIndex")
		if index then nodes[index]=pad end
	end
	local previous=model.Start.Position
	local length=0
	for _,node in ipairs(nodes) do length+=(node.Position-previous).Magnitude;previous=node.Position end
	model.CourseInfo:SetAttribute("RouteLengthStuds",math.floor(length+.5))
	model:SetAttribute("JumpRevision",Config.Revision)
end

return JumpTuning
