--!strict

local Props = require(script.Parent.AscentProps)
local Pass = {}
local REVISION = 1
local ROCK = Color3.fromRGB(76, 92, 88)
local WATER = Color3.fromRGB(50, 118, 137)

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, frame, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function nearestNode(nodes: {BasePart}, position: Vector3): (BasePart?, Vector3?)
	local chosen, localPosition = nil, nil
	local distance = math.huge
	for _,node in ipairs(nodes) do
		local relative = node.CFrame:PointToObjectSpace(position)
		if math.abs(relative.Y) < 30 and math.abs(relative.X) < 140 then
			local score = math.abs(relative.Z)
			if score < distance then chosen, localPosition, distance = node, relative, score end
		end
	end
	if distance > 9 then return nil, nil end
	return chosen, localPosition
end

local function river(model: Model, nodes: {BasePart})
	-- The first moving log needs clearance across the full entrance platform width.
	local entrance = model.Checkpoints.Checkpoint_002
	entrance.Size = Vector3.new(entrance.Size.X, entrance.Size.Y, 13)
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "RiverContinuation", model.Decoration
	local world = model.Decoration.CliffsAndValley
	local environment = model.Decoration.Environment
	for _,object in ipairs(environment:GetChildren()) do
		if object:IsA("BasePart") and object.Name == "SharedAdventureGround" and (object.Position-entrance.Position).Magnitude < 3 then
			object.Size = Vector3.new(object.Size.X,object.Size.Y,13)
		end
	end
	for _,object in ipairs(world:GetChildren()) do
		if object:IsA("BasePart") and object.Name == "ScenicBank" and object.Size.X == 20 then
			local node, relative = nearestNode(nodes, object.Position)
			if node and relative and math.abs(relative.X) > 40 then
				local side = if relative.X > 0 then 1 else -1
				local rest = node.Parent == model.Checkpoints or node:GetAttribute("SectionStep")%4 == 0
				if not rest then
					object.CFrame += node.CFrame.RightVector * side * 60
					object.Size = Vector3.new(36, object.Size.Y, object.Size.Z * 1.4)
				end
			end
		end
	end
	for _,object in ipairs(environment:GetChildren()) do
		if not object:IsA("Model") or object.Name == "AlpineMassif" then continue end
		local node, relative = nearestNode(nodes, object:GetPivot().Position)
		if node and relative and math.abs(relative.X) > 40 and math.abs(relative.X) < 68 and math.abs(relative.Y-1.5) < 3 then
			local side = if relative.X > 0 then 1 else -1
			local rest = node.Parent == model.Checkpoints or node:GetAttribute("SectionStep")%4 == 0
			if not rest or math.abs(relative.Z) > 4 then
				object:PivotTo(object:GetPivot() + node.CFrame.RightVector * side * 60)
			end
		end
	end
	for _,node in ipairs(nodes) do
		local step = node:GetAttribute("SectionStep") :: number
		for _,side in ipairs({-1, 1}) do
			local water = part(scenery,"ScenicRiverWater",Vector3.new(68,1,18),node.CFrame*CFrame.new(side*80,-2.3,0),WATER,Enum.Material.SmoothPlastic)
			water.Transparency = 0
			water:SetAttribute("SceneryOnly",true)
			if step%3 == 1 then
				local shore = Props.Place(scenery,"LichenBoulder",node.CFrame*CFrame.new(side*(51+step%5*3),-5,2)*CFrame.Angles(0,step*.91,0),10+step%4*2)
				shore.Name = "RiverShoreOutcrop"
			end
			if step%4 == 0 then
				local edge = Props.Place(scenery,"LichenBoulder",node.CFrame*CFrame.new(side*(39+step%3),-3,side*2)*CFrame.Angles(0,step*.43,0),7+step%3*2)
				edge.Name = "RiverBankEdge"
				local spill = part(scenery,"RiverSpill",Vector3.new(16+step%3*3,2.5,5),node.CFrame*CFrame.new(side*61,-2.2,-7),WATER,Enum.Material.SmoothPlastic)
				spill:SetAttribute("SceneryOnly",true)
				local foam = part(scenery,"CascadeFoam",Vector3.new(11,0.08,2),spill.CFrame*CFrame.new(0,1.28,-1),Color3.fromRGB(151,197,199),Enum.Material.SmoothPlastic)
				foam.Transparency = .55
			end
			-- This opaque rock core hides the complete log at both reset positions.
			local wall = part(scenery,"RiverResetScreen",Vector3.new(42,26+step%4,20),node.CFrame*CFrame.new(side*96,3,0),ROCK,Enum.Material.Rock)
			wall.CanQuery = true
			wall:SetAttribute("SceneryOnly",true)
			wall:SetAttribute("RiverScreenSide",side)
			if step%2 == 1 then
				local rock = Props.Place(scenery,if side == 1 then "GraniteBoulder" else "LichenBoulder",node.CFrame*CFrame.new(side*(86+step%4),-10,0)*CFrame.Angles(0,step*.73,0),44+step%5*2)
				rock.Name = "RiverGorgeCrag"
				for _,mesh in ipairs(rock:GetDescendants()) do
					if mesh:IsA("BasePart") then mesh.CanQuery=true end
				end
			end
		end
	end
	local streams: {[string]: {BasePart}} = {}
	local foamIndex = 0
	for _,object in ipairs(model:GetDescendants()) do
		if not object:IsA("BasePart") then continue end
		if object:GetAttribute("MotionKind") == "MovingLog" then
			local originalStart = object:GetAttribute("MotionStart") :: CFrame
			local originalEnd = object:GetAttribute("MotionEnd") :: CFrame
			local center = originalStart:Lerp(originalEnd,.5)
			local key = tostring(center.Position)
			streams[key] = streams[key] or {}
			table.insert(streams[key],object)
			local start, finish = center*CFrame.new(88,0,0), center*CFrame.new(-88,0,0)
			local first = (object:GetAttribute("InitialProgress") :: number) < .5
			local progress = if first then .33 else .83
			local newFrame = start:Lerp(finish,progress)
			local delta = newFrame*object.CFrame:Inverse()
			for _,visual in ipairs(object:GetDescendants()) do
				if visual:IsA("BasePart") then visual.CFrame = delta*visual.CFrame end
			end
			object.CFrame = newFrame
			object:SetAttribute("MotionStart",start)
			object:SetAttribute("MotionEnd",finish)
			object:SetAttribute("MotionDuration",176/(68/13))
			object:SetAttribute("InitialProgress",progress)
			object:SetAttribute("HiddenRiverReset",true)
		elseif object.Name == "MountainRiver" then
			object.Transparency = 0
			object.Color = WATER
		elseif object.Name == "RiverFoam" then
			foamIndex += 1
			object.Size = Vector3.new(1.1+(foamIndex%5)*.65,object.Size.Y,.12+(foamIndex%3)*.13)
			object:SetAttribute("FlowPhase",(foamIndex*.61803398875)%1)
			object:SetAttribute("FlowDirection",-1)
			object:SetAttribute("FlowWidth",144)
		end
	end
	-- Five staggered logs retain the old arrival frequency on the longer hidden route.
	for _,logs in pairs(streams) do
		assert(#logs == 2,"Expected a pair of logs per river crossing")
		for index=3,5 do
			local copy = logs[1].Parent:Clone()
			copy.Name = logs[1].Parent.Name .. "_Stream" .. index
			copy.Parent = model.Hazards
			table.insert(logs,copy.FlowingLog)
		end
		for index,log in ipairs(logs) do
			local start = log:GetAttribute("MotionStart") :: CFrame
			local finish = log:GetAttribute("MotionEnd") :: CFrame
			local stagger = (math.sin(start.Position.X*.13)+1)*2
			local frame = start:Lerp(finish,((index-.5)/5+stagger*.14)%1)
			local delta = frame*log.CFrame:Inverse()
			for _,visual in ipairs(log:GetDescendants()) do
				if visual:IsA("BasePart") then visual.CFrame = delta*visual.CFrame end
			end
			log.CFrame = frame
			log:SetAttribute("InitialProgress",0)
			log:SetAttribute("CycleOffset",stagger+(index-1)*((log:GetAttribute("MotionDuration") :: number)+(log:GetAttribute("PauseDuration") :: number))/5)
		end
	end
end

local function skyline(model: Model)
	for _,marker in ipairs(model.RouteMarkers:GetChildren()) do
		if marker:IsA("BasePart") and (marker.Name == "TrailSign" or marker.Name == "WaymarkerPost") and (marker.Position-Vector3.new(1593.36,213,-1195.01)).Magnitude < 4 then
			marker.CFrame += Vector3.new(-17.9,0,-1.7)
		end
	end
	local entranceTeeth = {
		{position=Vector3.new(1560.7052,213.5,-1183.7600),offset=Vector3.new(-13.3,0,-4.3)},
		{position=Vector3.new(1638.5536,215,-1157.6815),offset=Vector3.new(13.3,0,4.3)},
		{position=Vector3.new(1640.0499,215,-1156.8674),offset=Vector3.new(13.3,0,4.3)},
	}
	for _,object in ipairs(model.Decoration.Environment:GetChildren()) do
		if object:IsA("Model") and (object.Name == "IceToothA" or object.Name == "IceToothB") then
			for _,target in ipairs(entranceTeeth) do
				if (object:GetPivot().Position-target.position).Magnitude < .1 then
					object:PivotTo(object:GetPivot()+target.offset)
					object:SetAttribute("SkylineEntranceSightline",true)
				end
			end
		end
	end
	local pads = {}
	for _,object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") and object:GetAttribute("RoutePad") and object:GetAttribute("SectionIndex") == 9 and object.Parent ~= model.Checkpoints then
			table.insert(pads,object)
		end
	end
	for _,pad in ipairs(pads) do
		for _,support in ipairs(model.Decoration.CliffsAndValley:GetChildren()) do
			if support:IsA("BasePart") and support.Name == "ExposedRockStratum" then
				local top = support.Position+support.CFrame.UpVector*support.Size.Y/2
				local bottom = pad.Position-pad.CFrame.UpVector*pad.Size.Y/2
				if (top-bottom).Magnitude < .1 then
					support.Size = Vector3.new(support.Size.X,support.Size.Y,support.Size.Z-.5)
					support.Color = Color3.fromRGB(78,99,109)
				end
			end
		end
		pad.Size = Vector3.new(pad.Size.X,pad.Size.Y,pad.Size.Z-.5)
		pad.Color = Color3.fromRGB(110,190,208)
		pad:SetAttribute("SkylineGapIncrease",.5)
	end
end

function Pass.Apply(model: Model)
	if model:GetAttribute("RiverFinishRevision") == REVISION then return end
	assert(model:GetAttribute("AltitudeRevision") == 2,"Apply the accepted altitude pass first")
	local nodes: {BasePart} = {}
	for _,object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") and object:GetAttribute("RouteIndex") and object:GetAttribute("SectionIndex") == 2 then table.insert(nodes,object) end
	end
	table.sort(nodes,function(a,b) return a:GetAttribute("SectionStep") < b:GetAttribute("SectionStep") end)
	assert(#nodes == 28,"Expected the accepted 28 river route samples")
	river(model,nodes)
	skyline(model)
	model:SetAttribute("RiverFinishRevision",REVISION)
end

return Pass
