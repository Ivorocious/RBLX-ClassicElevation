--!strict

local Props = require(script.Parent.AscentProps)
local World = {}
local ROCK = Color3.fromRGB(79, 94, 96)
local SNOW = Color3.fromRGB(213, 227, 229)

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, solid == true, false, solid == true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function rockMass(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3)
	local model = Props.Place(parent, "GraniteBoulder", CFrame.identity, 5)
	model.Name = name
	local bounds, originalSize = model:GetBoundingBox()
	local scale = size / originalSize
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local relative = bounds:ToObjectSpace(p.CFrame)
			p.Size *= scale
			p.CFrame = cf * CFrame.new(relative.Position * scale) * relative.Rotation
			p.Color = color
		end
	end
end

local function boundary(parent: Instance, previous: BasePart, node: BasePart, side: number)
	local a = (previous.CFrame * CFrame.new(side*35, 8, 0)).Position
	local b = (node.CFrame * CFrame.new(side*35, 8, 0)).Position
	local mid = (a+b)/2
	local delta = (b-a)*Vector3.new(1,0,1)
	local wall = block(parent, if side == 1 then "MountainBoundary" else "SceneryBoundary", Vector3.new(2,44,delta.Magnitude+4), CFrame.lookAt(mid,mid+delta), ROCK, Enum.Material.SmoothPlastic, true)
	wall.Transparency = 1
	wall:SetAttribute("CourseBoundary", true)
end

local function backdrop(parent: Instance, center: Vector3)
	local random = Random.new(64023)
	for ring=1,2 do
		local count = if ring == 1 then 13 else 17
		for i=1,count do
			local angle = i/count*math.pi*2 + random:NextNumber(-0.09,0.09)
			local radius = (if ring == 1 then 850 else 1350) + random:NextNumber(-90,90)
			local height = random:NextNumber(330,620)
			local position = center+Vector3.new(math.cos(angle)*radius,height/2-260,math.sin(angle)*radius)
			local color = if ring == 1 then Color3.fromRGB(104,137,153) else Color3.fromRGB(147,172,186)
			rockMass(parent,"DistantAlpineRidge",Vector3.new(random:NextNumber(260,430),height,random:NextNumber(270,410)),CFrame.new(position)*CFrame.Angles(0,angle,0),color)
		end
	end
end

local function waterfall(parent: Instance, node: BasePart, step: number)
	local side = if step%8 == 0 then 1 else -1
	local cf = node.CFrame*CFrame.new(side*48,-18,0)
	local fall = block(parent,"RavineWaterfall",Vector3.new(1.2,38,5),cf,Color3.fromRGB(125,188,201),Enum.Material.Glass)
	fall.Transparency = 0.35
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "WaterSpray"
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(218,237,238))
	mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,8)})
	mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,1)})
	mist.Lifetime, mist.Rate, mist.Speed = NumberRange.new(1,2), 5, NumberRange.new(1,3)
	mist.SpreadAngle = Vector2.new(40,40)
	local attachment = Instance.new("Attachment")
	attachment.Position,attachment.Parent = Vector3.new(0,-17,0),fall
	mist.Parent = attachment
end

function World.Build(model: Model, nodes: {BasePart}, center: Vector3)
	local root = Instance.new("Folder")
	root.Name,root.Parent = "CliffsAndValley",model.Decoration
	local horizon = Instance.new("Folder")
	horizon.Name,horizon.Parent = "DistantLandscape",root
	backdrop(horizon,center)
	for i,node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local step = (node:GetAttribute("SectionStep") or 0) :: number
		local previous = nodes[math.max(1,i-1)]
		local nextNode = nodes[math.min(#nodes,i+1)]
		local length = math.max(node.Size.Z, (node.Position-previous.Position).Magnitude, (nextNode.Position-node.Position).Magnitude)+5
		local top = node.Size.Y/2
		local snow = section >= 8
		local color = if snow then Color3.fromRGB(126,149,157) elseif section <= 3 then Color3.fromRGB(94,105,91) else ROCK
		-- The continuous face starts below recovery height, leaving every jump gap open.
		block(root,"DeepCliffCore",Vector3.new(124,104,length),node.CFrame*CFrame.new(2,top-70,0),color,Enum.Material.Rock)
		if i%2 == 0 then
			rockMass(root,"WeatheredCliffFace",Vector3.new(28,95+i%3*11,length*2.1),node.CFrame*CFrame.new(-51,top-68,0)*CFrame.Angles(0,0,math.rad(3-i%7)),color)
		end
		for _,side in ipairs({-1,1}) do
			local river = section == 2
			local x = side*(if river then 59 else 49)
			local width = if river then 16 else 26
			local material = if snow then Enum.Material.Snow elseif section <= 2 then Enum.Material.Grass else Enum.Material.Rock
			block(root,"ScenicBank",Vector3.new(width,22,length),node.CFrame*CFrame.new(x,top-11,0),if snow then SNOW elseif section <= 2 then Color3.fromRGB(72,98,66) else color,material)
			if i>1 then boundary(model.Bounds,previous,node,side) end
		end
		if i%3 == 0 then
			rockMass(root,"InnerCrag",Vector3.new(21+(i*7)%23,14+(i*11)%25,length*(1.6+(i%5)*0.25)),node.CFrame*CFrame.new(50,top+1,0)*CFrame.Angles(0,math.rad((i*13)%41-20),0),color)
		end
		if section == 2 and step>0 and step%4 == 0 then waterfall(root,node,step) end
		if section == 6 then
			-- A rock-cut gallery has a continuous mountain connection, rather than free-floating beams.
			block(root,"GalleryRockRoof",Vector3.new(103,10,length),node.CFrame*CFrame.new(15,35,0),Color3.fromRGB(112,111,98),Enum.Material.Limestone)
			if step%3 == 1 then
				block(root,"GalleryPier",Vector3.new(5,33,6),node.CFrame*CFrame.new(-32,top+16.5,0),Color3.fromRGB(132,125,103),Enum.Material.Limestone)
				rockMass(root,"GalleryRoofFracture",Vector3.new(18,12,length),node.CFrame*CFrame.new(-28,36,0),Color3.fromRGB(124,122,109))
			end
		end
	end
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and (p:GetAttribute("RoutePad") == true or p.Name == "CliffRefuge" or p.Name == "BridgeCliffRefuge") and p.CanCollide and p.Transparency < 1 then
			local section = p:GetAttribute("SectionIndex")
			if section ~= 1 and section ~= 8 and section ~= 10 then
				block(root,"ExposedRockStratum",Vector3.new(p.Size.X,17,p.Size.Z),p.CFrame*CFrame.new(0,-p.Size.Y/2-8.5,0),p.Color:Lerp(ROCK,0.5),Enum.Material.Rock)
			end
		end
	end
end

return World
