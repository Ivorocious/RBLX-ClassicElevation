--!strict

local Layout = {}
local unevenSections = { [3] = true, [5] = true, [6] = true, [7] = true, [9] = true }

function Layout.Apply(model: Model)
	local pads = model:GetDescendants()
	table.sort(pads, function(a,b)
		return (a:GetAttribute("SectionStep") or 0) < (b:GetAttribute("SectionStep") or 0)
	end)
	local lastOffsets: {[string]: number} = {}
	for _, pad in ipairs(pads) do
		if not pad:IsA("BasePart") or pad:GetAttribute("RoutePad") ~= true then continue end
		local section = pad:GetAttribute("SectionIndex") :: number
		if not unevenSections[section] or pad.Parent == model.Checkpoints or pad.Name == "Finish" then continue end
		local step = pad:GetAttribute("SectionStep") :: number
		local lane = pad:GetAttribute("Lane") :: number
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
end

return Layout
