--!strict
local Checkpoints = {}
local blue = Color3.fromRGB(48, 149, 255)
local navy = Color3.fromRGB(28, 67, 106)

local function part(parent, name, position, size, color, collide)
	local p = Instance.new("Part")
	p.Name, p.Position, p.Size, p.Color = name, position, size, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, collide, false, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function trigger(parent, name, position, size)
	local p = part(parent, name, position, size, blue, false)
	p.Transparency, p.CanTouch = 1, true
	return p
end

local function recolor(sign, index)
	for _, p in sign:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide, p.CanTouch = false, false
			if p.Name == "FloorBorder" or p.Name == "BeaconCap" then
				p.Color, p.Material = blue, Enum.Material.Neon
			elseif p.Name == "NumberedBeacon" then p.Color = navy end
		elseif p:IsA("TextLabel") and p.Name == "Number" then p.Text = string.format("%02d", index) end
	end
end

local function smallSign(parent, name, target, size, signOffset)
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	local link = Instance.new("ObjectValue")
	link.Name, link.Value, link.Parent = "CheckpointTrigger", target, model
	local at = target.Position
	for _, z in {-size.Z/2+.18, size.Z/2-.18} do
		part(model, "FloorBorder", at+Vector3.new(0,.15,z), Vector3.new(size.X,.12,.3), blue, false)
	end
	for _, x in {-size.X/2+.18, size.X/2-.18} do
		part(model, "FloorBorder", at+Vector3.new(x,.15,0), Vector3.new(.3,.12,size.Z), blue, false)
	end
	local base = at+signOffset
	part(model, "Post", base+Vector3.new(0,1.8,0), Vector3.new(.2,3.6,.2), navy, false)
	local beacon = part(model, "NumberedBeacon", base+Vector3.new(0,4.9,0), Vector3.new(2.3,2.8,2.3), navy, false)
	part(model, "BeaconCap", base+Vector3.new(0,6.4,0), Vector3.new(2.5,.14,2.5), blue, false)
	for _, face in {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right} do
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Face, gui.CanvasSize = "CheckpointLabel", face, Vector2.new(230,280)
		gui.Parent = beacon
		local label = Instance.new("TextLabel")
		label.Name, label.Text = "Number", "03"
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1,1), 1
		label.Font, label.TextScaled, label.TextColor3 = Enum.Font.GothamBold, true, Color3.new(1,1,1)
		label.Parent = gui
	end
	recolor(model, 3)
	model.WorldPivot = CFrame.new(at)
end

function Checkpoints.Apply()
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C11_01")
	local archive = game.ServerStorage.CityRun_C11_Archive
	assert(not archive:FindFirstChild("PreviousCheckpoints"), "Checkpoint pass already installed")
	local saved = Instance.new("Folder")
	saved.Name, saved.Parent = "PreviousCheckpoints", archive
	local signs = course.RouteMarkers.CheckpointSigns
	local active = course.Checkpoints
	local old, oldSigns = {}, {}
	for i = 1, 9 do
		old[i] = assert(active:FindFirstChild(string.format("Checkpoint_%03d", i)))
		oldSigns[i] = assert(signs:FindFirstChild(string.format("Checkpoint_%02d_Sign", i)))
	end
	local keep = {[1]=1,[2]=2,[3]=4,[4]=5,[5]=6,[7]=7}
	for i, cp in old do
		local copy = cp:Clone()
		copy.Parent = saved
		local sign = oldSigns[i]
		sign.Parent = saved
		if keep[i] then
			cp.Name = string.format("Checkpoint_%03d", keep[i])
			local replacement = sign:Clone()
			replacement.Name = string.format("Checkpoint_%02d_Sign", keep[i])
			replacement.CheckpointTrigger.Value = cp
			recolor(replacement, keep[i])
			replacement.Parent = signs
		else
			cp.Name = "Removed_" .. cp.Name
			cp.Parent = saved
		end
		local surface = course.Obstacles.WalkingSurfaces[string.format("CP%02d", i)]
		for _, p in surface:GetChildren() do
			if p:IsA("MeshPart") and (string.find(p.Name, "__Cream__", 1, true) or string.find(p.Name, "__Teal__", 1, true)) then
				assert(not p.CanCollide, "Preserve unexpected checkpoint collision")
				p.Parent = saved
			end
		end
	end
	local surfaces = Instance.new("Model")
	surfaces.Name, surfaces.Parent = "C11CheckpointLandings", course.Obstacles.WalkingSurfaces
	local configs = {
		{name="MuralLedge", at=Vector3.new(3330,41.55,5), size=Vector3.new(12,1,5.4), offset=Vector3.new(-4.8,0,1.7)},
		{name="ClimbRoute", at=Vector3.new(3285,61.05,-55), size=Vector3.new(14,1,16), offset=Vector3.new(-5.3,0,-6.3)},
		{name="ExpertRoute", at=Vector3.new(3390,52.10,-43.3077), size=Vector3.new(6,1,7.8), offset=Vector3.new(2.6,0,2.6)},
	}
	local primary, alternatives
	for i, c in configs do
		local landing = part(surfaces, c.name, c.at-Vector3.new(0,.15,0), Vector3.new(c.size.X,.3,c.size.Z), Color3.fromRGB(75,92,111), true)
		landing:SetAttribute("CheckpointLanding", true)
		local cp
		if i == 1 then
			primary = trigger(active, "Checkpoint_003", c.at, c.size)
			alternatives = Instance.new("Folder")
			alternatives.Name, alternatives.Parent = "AlternateTriggers", primary
			cp = primary
		else cp = trigger(alternatives, c.name, c.at, c.size) end
		smallSign(signs, if i == 1 then "Checkpoint_03_Sign" else "Checkpoint_03_" .. c.name .. "_Sign", cp, c.size, c.offset)
	end
	local removedHazards = 0
	for _, p in course.Obstacles.OwnerKillStrips:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("HazardType") == "Kill"
			and math.abs(p.Position.X-3390)<3 and p.Position.Z>-47 and p.Position.Z<-39 then
			p:SetAttribute("C11ArchiveReason", "Clear expert checkpoint landing")
			p.Parent = saved
			removedHazards += 1
		end
	end
	assert(removedHazards == 2, "Unexpected expert checkpoint hazard count")
	course.CourseInfo:SetAttribute("CheckpointCount", 7)
	course:SetAttribute("C11CheckpointPass", true)
	return {logicalCheckpoints=7, physicalTriggers=9, clearedExpertHazards=removedHazards}
end

return Checkpoints
