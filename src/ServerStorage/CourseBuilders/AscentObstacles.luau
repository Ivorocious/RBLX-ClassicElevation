--!strict

local Obstacles = {}
local Props = require(script.Parent.AscentProps)
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
	local p = part(parent, "Warning", Vector3.new(0.06, diameter, diameter), cf * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(239,65,55), Enum.Material.Neon)
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
	local section = pad:GetAttribute("SectionIndex")
	local offset = if section == 10 then 11 else 8
	local cf = pad.CFrame * CFrame.new(side*offset, pad.Size.Y/2, 0)
	local cliff = section == 7
	if cliff then
		part(parent, "CliffRefuge", Vector3.new(11,3,9), cf*CFrame.new(0,-1.5,0), ROCK, Enum.Material.Rock, true)
	end
	local wall = part(parent,"CoverCollision",Vector3.new(7,6,4),cf*CFrame.new(0,3,0),ROCK,Enum.Material.Rock,true)
	wall.Transparency = 1
	wall:SetAttribute("ProjectileCover",true)
	Props.Place(parent, if cliff then "GraniteBoulder" else "SnowCoverOutcrop", cf*CFrame.Angles(0,side*0.5,0), if cliff then 7 else 8)
end

local function rollingLog(parent: Instance, startNode: BasePart, endNode: BasePart, lane: number, offset: number)
	local m = group(parent,"RollingTrunk_"..startNode.Name.."_"..lane)
	local origin = startNode.CFrame*CFrame.new(lane*20,2.7,0)
	local destination = endNode.CFrame*CFrame.new(lane*20,2.7,0)
	local log = part(m,"RollingLog",Vector3.new(12,2.4,2.4),origin,WOOD,Enum.Material.Wood)
	log.Shape = Enum.PartType.Cylinder
	motion(log,"RollingLog",destination,7.5,3,offset)
	for _, side in ipairs({-1,1}) do
		local cap = part(log,"CutEnd",Vector3.new(0.08,2.2,2.2),origin*CFrame.new(side*6.03,0,0),Color3.fromRGB(180,138,87),Enum.Material.Wood)
		cap.Shape,cap.CanTouch,cap.CanQuery = Enum.PartType.Cylinder,false,false
	end
	warning(m,startNode.CFrame*CFrame.new(lane*20,1.56,0),4)
end

local function riverLog(parent: Instance, pad: BasePart, central: BasePart, lane: number, step: number)
	pad.Transparency,pad.CanCollide,pad.CanTouch,pad.CanQuery = 1,false,false,false
	local direction = if step%2 == 0 then 1 else -1
	local start = central.CFrame*CFrame.new(-direction*50,-0.7,0)
	local finish = central.CFrame*CFrame.new(direction*50,-0.7,0)
	local progress = 0.18+(lane+1)*0.32
	local m = group(parent,"RiverLog_"..pad.Name)
	local log = part(m,"FlowingLog",Vector3.new(26,4.4,4.4),start:Lerp(finish,progress),WOOD,Enum.Material.Wood,true)
	log.Shape = Enum.PartType.Cylinder
	motion(log,"MovingLog",finish,14,0.6,0)
	log:SetAttribute("MotionStart",start)
	log:SetAttribute("InitialProgress",progress)
	for _, side in ipairs({-1,1}) do
		local cap = part(log,"CutEnd",Vector3.new(0.08,4.1,4.1),log.CFrame*CFrame.new(side*13.02,0,0),Color3.fromRGB(180,138,87),Enum.Material.Wood)
		cap.Shape,cap.CanTouch,cap.CanQuery = Enum.PartType.Cylinder,false,false
	end
end

local function rollingBoulder(parent: Instance, pad: BasePart, step: number)
	local m = group(parent,"HillsideBoulder_"..step)
	local diameter = 6+step%3
	local start = pad.CFrame*CFrame.new(38,diameter/2+1.5,0)
	local finish = pad.CFrame*CFrame.new(-40,diameter/2+1.5,0)
	local rock = part(m,"RollingBoulder",Vector3.one*diameter,start,ROCK,Enum.Material.Rock)
	rock.Shape,rock.Transparency = Enum.PartType.Ball,1
	motion(rock,"RollingBoulder",finish,4.8,6,step*0.4)
	rock:SetAttribute("PauseMin",4)
	rock:SetAttribute("PauseMax",8)
	warning(m,pad.CFrame*CFrame.new(20,1.56,0),diameter+2)
	Props.Place(m,"BasaltBoulder",pad.CFrame*CFrame.new(43,-3,1)*CFrame.Angles(0,0.7,0),15)
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
	if avalanche then
		Props.Place(m,"SnowCoverOutcrop",startNode.CFrame*CFrame.new(lane*20+8,1.5,4),12)
	else
		ball:SetAttribute("PauseMin",3)
		ball:SetAttribute("PauseMax",6)
		local sourceFrame = CFrame.lookAt(origin,destination)
		Props.Place(m,"Snowman",sourceFrame*CFrame.new(0,-height+1.5,3.5)*CFrame.Angles(0,math.pi,0),7)
	end
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
		elseif section == 2 then
			if step%4 ~= 0 then
				riverLog(hazards,pad,bySection[2][step],lane,step)
			elseif lane == 0 then
				pad.Size = Vector3.new(66,3,pad.Size.Z)
				pad.Material = Enum.Material.Ground
			end
		elseif section == 3 or section == 9 then
			pad.Size = Vector3.new(pad.Size.X, 5+(step%3), pad.Size.Z)
			pad.CFrame -= Vector3.new(0,(pad.Size.Y-3)/2,0)
			if section == 9 then
				pad.CustomPhysicalProperties = PhysicalProperties.new(0.9,0.005,0,100,100)
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
			if (step+lane*2)%5 == 1 then cover(details,pad,if lane == 1 then 1 else -1) end
		elseif section == 8 then
			if (step+lane)%4 == 0 then cover(details,pad,if lane == 1 then 1 else -1) end
		elseif section == 10 then
			pad.Material = Enum.Material.Snow
			if step < 8 and step%2 == 0 then cover(details,pad,if lane == 1 then 1 else -1) end
		end
	end
	for _, step in ipairs({2,6,10,14}) do
		local node = bySection[4][step]
		for _, side in ipairs({-1,1}) do
			local cf = node.CFrame*CFrame.new(side*10,0,0)
			part(details,"BridgeCliffRefuge",Vector3.new(7,5,8),cf*CFrame.new(0,-1,0),ROCK,Enum.Material.Rock,true)
			Props.Place(details,"LichenBoulder",cf*CFrame.new(side*2.3,1.5,2.7),1.6)
		end
	end
	for pairIndex, steps in ipairs({{4,1},{9,6}}) do
		for _, lane in ipairs({-1,0,1}) do rollingLog(hazards,bySection[1][steps[1]],bySection[1][steps[2]],lane,(lane+1)*1.6+pairIndex) end
	end
	for _, step in ipairs({3,7,11,15}) do rollingBoulder(hazards,bySection[7][step],step) end
	for _, section in ipairs({8,10}) do
		local list = bySection[section]
		local pairsOfSteps = if section == 8 then {{7,2},{16,11}} else {{4,1},{8,6}}
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
