--!strict

local Depth = {}
local PIT = {[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[9]=true}
local TREES = {PineA=true,PineWind=true,PineSnow=true,Cedar=true,CedarLite=true}

local function key(position: Vector3): string
	return string.format("%.1f:%.1f:%.1f",position.X,position.Y,position.Z)
end

local function cloud(parent: Instance, frame: CFrame, size: number, color: Color3, opacity: number)
	local anchor = Instance.new("Part")
	anchor.Name = "BottomlessHaze"
	anchor.Size,anchor.CFrame = Vector3.new(size*.4,6,size*.3),frame
	anchor.Anchored,anchor.Transparency = true,1
	anchor.CanCollide,anchor.CanTouch,anchor.CanQuery = false,false,false
	anchor.Parent = parent
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "AltitudeMist"
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(color)
	mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,size*.85),NumberSequenceKeypoint.new(1,size)})
	mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,opacity),NumberSequenceKeypoint.new(.7,opacity),NumberSequenceKeypoint.new(1,1)})
	mist.Lifetime = NumberRange.new(16,20)
	mist.Rate = .4
	mist.Speed = NumberRange.new(.1,.4)
	mist.Rotation,mist.RotSpeed = NumberRange.new(0,360),NumberRange.new(-1,1)
	mist.LightInfluence = 0
	mist:SetAttribute("PrewarmParticles",12)
	mist.Parent = anchor
end

local function refineHaze(model: Model)
	local anchors = model.Decoration:FindFirstChild("AltitudeClouds")
	assert(anchors,"The altitude pass must exist before refining haze")
	local skyline: {[string]: {frame: CFrame, layer: number}} = {}
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("SectionIndex") == 9 and p:GetAttribute("RouteIndex") then
			local frame = p:GetAttribute("SceneryFrame") or p.CFrame
			for layer,depth in ipairs({67,132}) do
				skyline[key((frame*CFrame.new(0,-depth,0)).Position)] = {frame=frame,layer=layer}
			end
		end
	end
	for _,anchor in ipairs(anchors:GetChildren()) do
		if not anchor:IsA("BasePart") then continue end
		local mist = anchor:FindFirstChildOfClass("ParticleEmitter")
		if not mist then continue end
		if anchor.Name == "ValleyCloud" then
			mist.Enabled,mist.Rate = false,0
			mist:SetAttribute("PrewarmParticles",0)
			mist:Clear()
			anchor:SetAttribute("RetiredForAtmosphere",true)
		else
			mist.Lifetime = NumberRange.new(16,20)
			local placement = skyline[key(anchor.Position)]
			if placement then
				local upper = placement.layer == 1
				local size = if upper then 44 else 66
				local opacity = if upper then .45 else .14
				anchor.CFrame = placement.frame*CFrame.new(0,if upper then -34 else -51,0)
				anchor.Size = Vector3.new(size*.4,6,size*.3)
				anchor:SetAttribute("SectionIndex",9)
				anchor:SetAttribute("DepthLayer",placement.layer)
				mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,size*.85),NumberSequenceKeypoint.new(1,size)})
				mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,opacity),NumberSequenceKeypoint.new(.7,opacity),NumberSequenceKeypoint.new(1,1)})
			end
		end
	end
	model:SetAttribute("AltitudeRevision",2)
end

function Depth.Apply(model: Model)
	local revision = model:GetAttribute("AltitudeRevision")
	if revision == 2 then return end
	if revision == 1 then refineHaze(model); return end
	local decoration = model:FindFirstChild("Decoration")
	assert(decoration,"Course decoration is required")
	local world = decoration:FindFirstChild("CliffsAndValley")
	local environment = decoration:FindFirstChild("Environment")
	assert(world and environment,"The v7 environment is required")
	local cores: {[string]: CFrame} = {}
	local supports: {[string]: boolean} = {}
	local nodes: {BasePart} = {}
	for _,p in ipairs(model:GetDescendants()) do
		if not p:IsA("BasePart") then continue end
		local section = p:GetAttribute("SectionIndex") :: number
		if p:GetAttribute("RoutePad") and PIT[section] then
			supports[key((p.CFrame*CFrame.new(0,-p.Size.Y/2,0)).Position)] = true
			if p:GetAttribute("RouteIndex") then
				local frame = p:GetAttribute("SceneryFrame") or p.CFrame
				local oldDepth = if section == 3 or section == 4 then 105 else 70
				cores[key((frame*CFrame.new(2,p.Size.Y/2-oldDepth,0)).Position)] = frame*CFrame.new(2,p.Size.Y/2,0)
				table.insert(nodes,p)
			end
		elseif p.Name == "CliffRefuge" or p.Name == "BridgeCliffRefuge" then
			supports[key((p.CFrame*CFrame.new(0,-p.Size.Y/2,0)).Position)] = true
		end
	end
	for _,p in ipairs(world:GetDescendants()) do
		if p:IsA("ParticleEmitter") and p.Name == "RavineDepthMist" then p.Enabled = false end
		if not p:IsA("BasePart") then continue end
		if p.Name == "DeepCliffCore" then
			local top = cores[key(p.Position)]
			if top then
				p.Size = Vector3.new(p.Size.X,260,p.Size.Z)
				p.CFrame = top*CFrame.new(0,-370,0)
			end
		elseif p.Name == "ExposedRockStratum" and supports[key((p.CFrame*CFrame.new(0,p.Size.Y/2,0)).Position)] then
			local top = p.CFrame*CFrame.new(0,p.Size.Y/2,0)
			p.Size = Vector3.new(p.Size.X,240,p.Size.Z)
			p.CFrame = top*CFrame.new(0,-120,0)
		end
	end
	local haze = Instance.new("Folder")
	haze.Name,haze.Parent = "AltitudeClouds",decoration
	for _,p in ipairs(nodes) do
		if (p:GetAttribute("SectionStep") :: number)%3 ~= 1 then continue end
		local frame = p:GetAttribute("SceneryFrame") or p.CFrame
		cloud(haze,frame*CFrame.new(0,-67,0),75,Color3.fromRGB(111,137,151),.6)
		cloud(haze,frame*CFrame.new(0,-132,0),125,Color3.fromRGB(77,103,121),.14)
	end
	local random = Random.new(8011)
	for _,prop in ipairs(environment:GetChildren()) do
		if not prop:IsA("Model") then continue end
		local factor = 1
		if TREES[prop.Name] then
			factor = random:NextNumber(2.2,3.1)
			if random:NextNumber()<.13 then factor = 3.6 end
		elseif prop.Name == "IceToothA" or prop.Name == "IceToothB" then factor = 1.5
		elseif prop.Name == "GraniteBoulder" or prop.Name == "BasaltBoulder" then factor = 2.1
		elseif prop.Name == "LichenBoulder" then factor = 1.5 end
		if factor ~= 1 then prop:ScaleTo(prop:GetScale()*factor) end
	end
	model:SetAttribute("AltitudeRevision",1)
	refineHaze(model)
end

return Depth
