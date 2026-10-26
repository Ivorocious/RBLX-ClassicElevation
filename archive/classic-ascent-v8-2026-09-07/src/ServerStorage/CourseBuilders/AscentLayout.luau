--!strict

local Layout = {}
local unevenSections = { [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [9] = true }

local function fitJumpLengths(model: Model)
	local pads: {[string]: BasePart} = {}
	local targetGap = {[3]=2.8,[5]=2.6,[6]=2.8,[7]=2.8,[9]=4.0}
	for _,pad in ipairs(model:GetDescendants()) do
		if pad:IsA("BasePart") and pad:GetAttribute("RoutePad") then
			pads[string.format("%d:%d:%d",pad:GetAttribute("SectionIndex"),pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane"))]=pad
		end
	end
	for _,pad in pairs(pads) do
		local section=pad:GetAttribute("SectionIndex") :: number
		if not targetGap[section] or pad.Parent==model.Checkpoints then continue end
		local step,lane=pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane")
		local spacing=math.huge
		for _,neighborStep in ipairs({step-1,step+1}) do
			local neighbor=pads[string.format("%d:%d:%d",section,neighborStep,lane)] or pads[string.format("%d:%d:0",section,neighborStep)]
			if neighbor then
				local position=neighbor.Position
				if neighbor.Parent==model.Checkpoints then
					local relative=neighbor.CFrame:PointToObjectSpace(pad.Position)
					position=(neighbor.CFrame*CFrame.new(math.clamp(relative.X,-neighbor.Size.X/2+2,neighbor.Size.X/2-2),0,0)).Position
				end
				spacing=math.min(spacing,((pad.Position-position)*Vector3.new(1,0,1)).Magnitude)
			end
		end
		if spacing<math.huge then
			pad.Size=Vector3.new(pad.Size.X,pad.Size.Y,math.max(4,spacing-targetGap[section]))
		end
	end
end

function Layout.Apply(model: Model)
	local pads = model:GetDescendants()
	table.sort(pads, function(a,b)
		return (a:GetAttribute("SectionStep") or 0) < (b:GetAttribute("SectionStep") or 0)
	end)
	local lastOffsets: {[string]: number} = {}
	local lastHeights: {[string]: number} = {}
	for _, pad in ipairs(pads) do
		if not pad:IsA("BasePart") or pad:GetAttribute("RoutePad") ~= true then continue end
		local section = pad:GetAttribute("SectionIndex") :: number
		if not unevenSections[section] or pad.Parent == model.Checkpoints or pad.Name == "Finish" then continue end
		local step = pad:GetAttribute("SectionStep") :: number
		local lane = pad:GetAttribute("Lane") :: number
		if section ~= 9 then
			local random = Random.new(section*719 + step*193 + (lane+2)*53)
			local key = tostring(section)..":"..tostring(lane)
			local count = ({[3]=24,[4]=16,[5]=18,[6]=12,[7]=16})[section]
			local progress = step / count
			local bend = math.sin(progress * math.pi * 2)
			local offset = if lane == 0 then (if section == 4 then 2*bend else 3*math.sin(step*.53)) else -lane * (3 + 4 * math.sin(step*.47+lane))
			local previous = lastOffsets[key] or 0
			local previousHeight = lastHeights[key] or 0
			local x = math.clamp(random:NextNumber(-7,7),previous-3.8,previous+3.8)
			local height = math.clamp(random:NextNumber(-1.8,1.8),previousHeight-1.1,previousHeight+1.1)
			lastOffsets[key],lastHeights[key] = x,height
			pad:SetAttribute("SceneryFrame", pad.CFrame)
			if section == 4 then
				pad.CFrame *= CFrame.new(offset+x*.3,0,0)
			else
				pad.CFrame *= CFrame.new(offset+x,height,random:NextNumber(-1.35,1.35))*CFrame.Angles(0,math.rad(random:NextNumber(-14,14)),0)
				pad.Size = Vector3.new(math.clamp(pad.Size.X*random:NextNumber(if lane==0 then 1.1 else .88,if lane==0 then 1.65 else 1.2),8,18),pad.Size.Y,pad.Size.Z)
				pad:SetAttribute("HeightVariation",height)
			end
			pad:SetAttribute("NaturalFoothold", true)
			continue
		end
		local random = Random.new(section*719 + step*193 + (lane+2)*53)
		local key = tostring(section)..":"..tostring(lane)
		local target = if lane == 0 then random:NextNumber(-7,7) else random:NextNumber(-4,11)*-lane
		local previous = lastOffsets[key] or 0
		local x = math.clamp(target,previous-5,previous+5)
		lastOffsets[key] = x
		local z = random:NextNumber(-1.1,1.1)
		local height = math.sin(step*0.73+lane*1.5)*1.15 + random:NextNumber(-0.35,0.35)
		local yaw = if lane == 0 then 0 else math.rad(random:NextNumber(-10,10))
		pad:SetAttribute("SceneryFrame",pad.CFrame)
		pad.CFrame *= CFrame.new(x,height,z)*CFrame.Angles(0,yaw,0)
		pad.Size = Vector3.new(math.clamp(pad.Size.X*random:NextNumber(0.88,1.12),8,14),pad.Size.Y,pad.Size.Z)
		pad:SetAttribute("HeightVariation",height)
		pad:SetAttribute("NaturalFoothold",true)
	end
	local routeFrames: {[string]: CFrame} = {}
	for _,pad in ipairs(pads) do
		if pad:IsA("BasePart") and pad:GetAttribute("RouteIndex") then
			routeFrames[tostring(pad:GetAttribute("SectionIndex"))..":"..tostring(pad:GetAttribute("SectionStep"))] = pad:GetAttribute("SceneryFrame") or pad.CFrame
		end
	end
	for _,pad in ipairs(pads) do
		if not pad:IsA("BasePart") or not pad:GetAttribute("RoutePad") or pad.Parent==model.Checkpoints then continue end
		local section,step,lane = pad:GetAttribute("SectionIndex"),pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane")
		if section~=3 and section~=6 and section~=9 then continue end
		local frame = routeFrames[tostring(section)..":"..tostring(step)]
		local relative = frame:PointToObjectSpace(pad.Position)
		local offset = if lane==0 then 11+3*math.sin(step*.55) elseif lane==1 then -4+3*math.sin(step*.6) else -24+2.5*math.sin(step*.46)
		if section==3 then offset=if lane==0 then 2+3*math.sin(step*.55) elseif lane==1 then 22+2*math.sin(step*.6) else offset end
		if section==9 and lane==1 then offset-=3 end
		pad.CFrame += frame.RightVector*(offset-relative.X)
		local span = if section==3 then 12 elseif section==6 then 6 else 9
		local drop = if lane==0 then 0 else (if lane==1 then 4 else 2.7)*math.sin(step%span/span*math.pi)
		if section==3 and lane==1 then drop=-2*math.sin(step%span/span*math.pi) end
		pad.CFrame -= Vector3.new(0,drop,0)
		pad:SetAttribute("SideRouteDrop",drop)
		if lane==0 then pad.Size=Vector3.new(15.5+2*math.sin(step*.8),pad.Size.Y,pad.Size.Z) end
		if section==9 and lane==0 then
			local widths = {18,11,13,21,12,10,17,11,18,17,11,21,13,10,19,11,15}
			local bends = {12,10,6,10,15,15,10,8,0,10,14,12,7,8,13,16,12}
			pad.Size=Vector3.new(widths[step],pad.Size.Y,pad.Size.Z)
			pad.CFrame += frame.RightVector*(bends[step]-offset)
		end
	end
	fitJumpLengths(model)
	-- Extend the back edges at the two tight switchback turns without moving their exits.
	for _,pad in ipairs(pads) do
		if not pad:IsA("BasePart") or not pad:GetAttribute("RoutePad") or pad:GetAttribute("SectionIndex") ~= 3 then continue end
		local step,lane = pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane")
		local extension = if step == 1 and lane == 1 then 14 elseif step == 23 and lane == -1 then 3 else 0
		if extension > 0 then
			pad.Size += Vector3.new(0,0,extension)
			pad.CFrame *= CFrame.new(0,0,extension/2)
		end
	end
	local centers: {[string]: BasePart} = {}
	for _,pad in ipairs(pads) do
		if pad:IsA("BasePart") and pad:GetAttribute("RouteIndex") then
			centers[tostring(pad:GetAttribute("SectionIndex"))..":"..tostring(pad:GetAttribute("SectionStep"))]=pad
		end
	end
	for _,pad in ipairs(pads) do
		if not pad:IsA("BasePart") or not pad:GetAttribute("RoutePad") or pad:GetAttribute("Lane")==0 then continue end
		local section=pad:GetAttribute("SectionIndex")
		if section~=3 and section~=5 and section~=6 and section~=7 and section~=9 then continue end
		local main=centers[tostring(section)..":"..tostring(pad:GetAttribute("SectionStep"))]
		local frame=main:GetAttribute("SceneryFrame") or main.CFrame
		local offset=frame:PointToObjectSpace(pad.Position).X
		local side=frame:VectorToObjectSpace(pad.CFrame.RightVector)
		local forward=frame:VectorToObjectSpace(pad.CFrame.LookVector)
		local extent=math.abs(side.X)*pad.Size.X/2+math.abs(forward.X)*pad.Size.Z/2
		local bounded=math.clamp(offset,-33.5+extent,33.5-extent)
		pad.CFrame += frame.RightVector*(bounded-offset)
	end
end

return Layout
