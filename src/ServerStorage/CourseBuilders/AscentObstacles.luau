--!strict

local Obstacles = {}
local WOOD = Color3.fromRGB(113, 78, 46)
local ROCK = Color3.fromRGB(100, 113, 110)
local AMBER = Color3.fromRGB(224, 170, 78)
local SNOW = Color3.fromRGB(226, 239, 243)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, solid == true, true, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function group(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name, m.Parent = name, parent
	return m
end

local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number)
	return part(parent, name, Vector3.new(thickness, thickness, (a-b).Magnitude), CFrame.lookAt((a+b)/2, b), WOOD, Enum.Material.Wood, false)
end

local function warning(parent: Instance, cf: CFrame, diameter: number): Part
	local p = part(parent, "Warning", Vector3.new(0.06, diameter, diameter), cf * CFrame.Angles(0,0,math.pi/2), AMBER, Enum.Material.Neon)
	p.Shape, p.Transparency = Enum.PartType.Cylinder, 0.35
	p.CanQuery, p.CanTouch = false, false
	return p
end

local function motion(p: BasePart, kind: string, destination: CFrame, duration: number, pause: number, offset: number)
	p:SetAttribute("MotionKind", kind)
	p:SetAttribute("MotionEnd", destination)
	p:SetAttribute("MotionDuration", duration)
	p:SetAttribute("PauseDuration", pause)
	p:SetAttribute("WarningDuration", 1.4)
	p:SetAttribute("CycleOffset", offset)
end

local function rockfall(parent: Instance, pad: BasePart, seed: number)
	local m = group(parent, "Rockfall_" .. pad.Name)
	local diameter = 3.5 + seed % 4
	local offset = if pad.Size.X > 12 then 2.5 else 0
	warning(m, pad.CFrame * CFrame.new(offset, 1.56, 0), diameter + 2)
	local rock = part(m, "FallingRock", Vector3.one * diameter, pad.CFrame * CFrame.new(offset, 36, 0), ROCK, Enum.Material.Rock)
	rock.Shape, rock.Transparency = Enum.PartType.Ball, 1
	rock:SetAttribute("HazardType", "FallingRock")
	rock:SetAttribute("FallDistance", 44)
	rock:SetAttribute("CycleOffset", seed % 7 * 0.6)
	pad:SetAttribute("RockfallLane", m.Name)
end

local function bridge(parent: Instance, pad: BasePart)
	-- Separate boards collapse locally, so a trailing racer still has other lines.
	pad.Transparency, pad.CanCollide, pad.CanTouch, pad.CanQuery = 1, false, false, false
	for _, child in ipairs(pad:GetChildren()) do
		if child:IsA("BasePart") then child.Transparency = 1 end
	end
	local count = math.max(2, math.ceil(pad.Size.Z / 3.2))
	local length = pad.Size.Z / count
	for i = 1, count do
		local board = part(parent, "LooseBridgeBoard", Vector3.new(pad.Size.X, 0.8, length - 0.16), pad.CFrame * CFrame.new(0, 1.05, pad.Size.Z/2 - (i-0.5)*length), WOOD:Lerp(AMBER, i%3*0.07), Enum.Material.WoodPlanks, true)
		board:SetAttribute("HazardType", "Crumble")
		board:SetAttribute("CrumbleDelay", 0.45)
		board:SetAttribute("CrumbleResetTime", 1.8)
	end
	for _, side in ipairs({-1, 1}) do
		for _, z in ipairs({-pad.Size.Z/2, pad.Size.Z/2}) do
			part(parent, "BridgeAnchorPost", Vector3.new(0.65, 5, 0.65), pad.CFrame * CFrame.new(side*(pad.Size.X/2+0.5), 3, z), WOOD, Enum.Material.Wood)
		end
		local x = side*(pad.Size.X/2+0.5)
		beam(parent, "BridgeHandrope", (pad.CFrame*CFrame.new(x,5,-pad.Size.Z/2)).Position, (pad.CFrame*CFrame.new(x,5,pad.Size.Z/2)).Position, 0.22)
	end
end

local function cover(parent: Instance, pad: BasePart, side: number)
	local cf = pad.CFrame * CFrame.new(side*(if pad:GetAttribute("SectionIndex") == 10 then 12 else 7.5), 0, 0)
	part(parent, "ShelterFooting", Vector3.new(10, 6, 10), cf * CFrame.new(0,-1.5,0), ROCK, Enum.Material.Rock, true)
	local wall = part(parent, "SnowballCover", Vector3.new(9, 8, 3), cf * CFrame.new(0,5,-3.4), ROCK, Enum.Material.Rock, true)
	wall:SetAttribute("ProjectileCover", true)
	part(parent, "CoverSnowCap", Vector3.new(9.5,1,3.5), cf*CFrame.new(0,9.4,-3.4), SNOW, Enum.Material.Snow)
end

local function projectile(parent: Instance, startNode: BasePart, endNode: BasePart, lane: number, avalanche: boolean, offset: number)
	local kind = if avalanche then "Avalanche" else "Snowball"
	local m = group(parent, kind .. "_" .. startNode.Name .. "_" .. lane)
	local diameter = if avalanche then 12 else 3.2
	local height = if avalanche then 7.7 else 4.5
	local origin = (startNode.CFrame * CFrame.new(lane*20, height, 0)).Position
	local destination = (endNode.CFrame * CFrame.new(lane*20, height, 0)).Position
	local ball = part(m, kind, Vector3.one*diameter, CFrame.lookAt(origin, destination), SNOW, Enum.Material.Snow)
	ball.Shape, ball.Transparency = Enum.PartType.Ball, 1
	motion(ball, kind, CFrame.lookAt(destination, destination+(destination-origin)), if avalanche then 4.5 else 2.4, if avalanche then 6 else 3.8, offset)
	ball:SetAttribute("Damage", 35)
	warning(m, startNode.CFrame*CFrame.new(lane*20,1.56,0), diameter+2)
	-- A visible snow chute places the projectile source in the mountain scenery.
	for _, side in ipairs({-1,1}) do
		part(m, "SnowChuteCheek", Vector3.new(3,diameter+6,10), CFrame.lookAt(origin,destination)*CFrame.new(side*(diameter/2+2),0,3), ROCK, Enum.Material.Slate)
	end
	part(m, "SnowChuteCornice", Vector3.new(diameter+9,4,12), CFrame.lookAt(origin,destination)*CFrame.new(0,diameter/2+4,4), SNOW, Enum.Material.Snow)
end

function Obstacles.Build(model: Model, nodes: {BasePart})
	local hazards = group(model, "Hazards")
	local details = group(model.Decoration, "RouteStructures")
	local pads: {BasePart} = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("RoutePad") == true and p.Parent ~= model.Checkpoints and p.Name ~= "Finish" then table.insert(pads,p) end
	end
	local bySection: {{BasePart}} = {}
	for i=1,10 do bySection[i] = {} end
	for _, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local step = node:GetAttribute("SectionStep")
		if step then bySection[section][step] = node end
		if step and (section == 2 or section == 5) then
			local water = section == 2
			local bed = part(hazards, if water then "MountainRiver" else "LavaBasin", Vector3.new(68,1,node.Size.Z+6), node.CFrame*CFrame.new(0,-6,0), if water then Color3.fromRGB(50,118,137) else Color3.fromRGB(229,92,30), if water then Enum.Material.Glass else Enum.Material.Neon)
			bed.Transparency = if water then 0.22 else 0
			bed:SetAttribute("HazardType", "Kill")
			if water then
				for _, x in ipairs({-15,12}) do
					local foam = part(details,"RiverFoam",Vector3.new(10,0.08,0.6),node.CFrame*CFrame.new(x,-5.4,0),Color3.fromRGB(199,230,223),Enum.Material.SmoothPlastic)
					foam.CanTouch, foam.CanQuery = false, false
				end
			end
		end
	end
	for index, pad in ipairs(pads) do
		local section = pad:GetAttribute("SectionIndex") :: number
		local step = pad:GetAttribute("SectionStep") :: number
		local lane = pad:GetAttribute("Lane") :: number
		local cf = pad.CFrame
		if section == 1 then
			pad.Material, pad.Color = Enum.Material.Ground, Color3.fromRGB(133,119,87)
			if (step+lane)%3 == 0 then
				local log = part(details,"LowFallenTrunk",Vector3.new(pad.Size.X-2,2,2.2),cf*CFrame.new(0,2.5,0)*CFrame.Angles(0,0.1*lane,0),WOOD,Enum.Material.Wood,true)
				log.Shape = Enum.PartType.Cylinder
			end
		elseif section == 2 then
			if step%3 ~= 0 then
				pad.Material, pad.Color = Enum.Material.Wood, WOOD
				for _, child in ipairs(pad:GetChildren()) do if child:IsA("BasePart") then child.Transparency=1 end end
				pad.CFrame = cf*CFrame.new(-2,0,0)
				for z = -pad.Size.Z/2+1.4, pad.Size.Z/2-0.5, 2.8 do
					local timber = part(pad,"RaftTimber",Vector3.new(pad.Size.X+0.5,3,3),pad.CFrame*CFrame.new(0,0,z),WOOD,Enum.Material.Wood)
					timber.Shape, timber.CanQuery, timber.CanTouch = Enum.PartType.Cylinder, false, false
				end
				motion(pad,"MovingLog",cf*CFrame.new(2,0,0),2.8+(step%3)*0.4,0,index%3*0.3)
			elseif lane == 0 then
				pad.Size = Vector3.new(66,3,pad.Size.Z)
				pad.Material = Enum.Material.Ground
			end
		elseif section == 3 or section == 9 then
			pad.Size = Vector3.new(pad.Size.X, 5+(step%3), pad.Size.Z)
			pad.CFrame -= Vector3.new(0,(pad.Size.Y-3)/2,0)
			if section == 9 then
				pad.CustomPhysicalProperties = PhysicalProperties.new(0.9,0.025,0,100,100)
				pad:SetAttribute("SlipperySurface", true)
			end
		elseif section == 4 then
			if step%4 == 0 then
				pad.Material, pad.Color = Enum.Material.Rock, ROCK
				if lane == 0 then pad.Size=Vector3.new(66,3,pad.Size.Z+2) end
				for _, child in ipairs(pad:GetChildren()) do if child:IsA("BasePart") then child.Transparency=1 end end
			else bridge(details,pad) end
		elseif section == 5 and (step+lane)%4 == 2 then
			local m = group(hazards,"Vent_"..pad.Name)
			warning(m,cf*CFrame.new(0,1.56,0),6)
			local plume=part(m,"LavaSpurt",Vector3.new(5,15,5),cf*CFrame.new(0,-15,0),Color3.fromRGB(241,108,31),Enum.Material.Neon)
			plume.Transparency=1
			motion(plume,"LavaSpurt",cf*CFrame.new(0,5,0),0.75,1.4,index%5*0.65)
		elseif section == 6 then
			if (step+lane)%3 == 1 then rockfall(hazards,pad,index) end
		elseif section == 7 then
			if lane == 1 and step%3 == 0 then
				part(details,"ClimbOverRock",Vector3.new(pad.Size.X,2.2,2.5),cf*CFrame.new(0,2.6,0),ROCK,Enum.Material.Rock,true)
			elseif lane == -1 and step%5 == 2 then rockfall(hazards,pad,index) end
		elseif section == 8 then
			if step%3 == 0 then cover(details,pad,if lane == 1 then 1 else -1) end
		elseif section == 10 then
			pad.Material = Enum.Material.Snow
			if step%2 == 0 then cover(details,pad,if lane == 1 then 1 else -1) end
		end
	end
	for _, section in ipairs({8,10}) do
		local list = bySection[section]
		local pairsOfSteps = if section == 8 then {{7,2},{16,11}} else {{4,1},{9,6}}
		for pairIndex, pair in ipairs(pairsOfSteps) do
			for _, lane in ipairs({-1,0,1}) do
				projectile(hazards,list[pair[1]],list[pair[2]],lane,section==10,(lane+1)*(if section==10 then 2.4 else 0.35)+pairIndex*0.5)
			end
		end
	end
	for _, pad in ipairs(pads) do
		if pad:GetAttribute("SectionIndex") == 4 then
			local step = pad:GetAttribute("SectionStep") :: number
			local lane = pad:GetAttribute("Lane") :: number
			local previous = bySection[4][step-1]
			if previous then
				local previousFrame = previous.CFrame
				if lane ~= 0 then
					for _, candidate in ipairs(pads) do
						if candidate:GetAttribute("SectionIndex")==4 and candidate:GetAttribute("SectionStep")==step-1 and candidate:GetAttribute("Lane")==lane then previous=candidate;previousFrame=candidate.CFrame;break end
					end
					if previous:GetAttribute("Lane")==0 then previousFrame*=CFrame.new(lane*20,0,0) end
				end
				for _, side in ipairs({-1,1}) do
					local x=side*5.5
					beam(details,"JoinedBridgeRope",(previousFrame*CFrame.new(x,5,-previous.Size.Z/2)).Position,(pad.CFrame*CFrame.new(x,5,pad.Size.Z/2)).Position,0.22)
				end
			end
		end
	end
end

return Obstacles
