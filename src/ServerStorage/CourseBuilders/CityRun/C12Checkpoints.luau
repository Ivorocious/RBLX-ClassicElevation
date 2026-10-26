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
	assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
	local course=workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId")=="C12_01")
	local archive=game.ServerStorage.CityRun_C12_Archive
	assert(not archive:FindFirstChild("PreviousCP3"),"CP3 migration already applied")
	local saved=Instance.new("Folder") saved.Name,saved.Parent="PreviousCP3",archive
	local primary=course.Checkpoints.Checkpoint_003
	local alternatives=primary.AlternateTriggers
	local main=alternatives.ClimbRoute
	local expert=alternatives.ExpertRoute
	local signs=course.RouteMarkers.CheckpointSigns
	local surfaces=course.Obstacles.WalkingSurfaces.C11CheckpointLandings
	primary:Clone().Parent=saved
	surfaces.ClimbRoute:Clone().Parent=saved
	main.Parent=course.Checkpoints
	alternatives.Parent=main
	primary.Parent=saved
	primary.Name="RemovedMuralCheckpoint"
	main.Name="Checkpoint_003"
	main.Position,main.Size=Vector3.new(3287.5,43.05,-.5),Vector3.new(4,1,7)
	main:SetAttribute("RouteBranch","Main") expert:SetAttribute("RouteBranch","Expert")
	surfaces.MuralLedge.Parent=saved
	surfaces.ClimbRoute.Position,surfaces.ClimbRoute.Size=Vector3.new(3286.3,42.85,-.5),Vector3.new(7,.3,8)
	signs.Checkpoint_03_Sign.Parent=saved
	signs.Checkpoint_03_ClimbRoute_Sign.Parent=saved
	smallSign(signs,"Checkpoint_03_Sign",main,main.Size,Vector3.new(1.2,0,2))
	local support=Instance.new("Model") support.Name,support.Parent="C12CheckpointSupport",course.Decoration
	part(support,"Pillar",Vector3.new(3287.5,21.1,-.5),Vector3.new(2,43.2,2),Color3.fromRGB(182,172,140),false)
	part(support,"Capital",Vector3.new(3287.5,42.25,-.5),Vector3.new(4.5,.9,5.5),Color3.fromRGB(212,205,180),false)
	part(support,"Footing",Vector3.new(3287.5,.1,-.5),Vector3.new(3.5,1.2,3.5),Color3.fromRGB(182,172,140),false)
	course:SetAttribute("C12CheckpointMigration",true)
	return {logicalCheckpoints=7,physicalCP3=2,main={3287.5,43.05,-.5},expert={expert.Position.X,expert.Position.Y,expert.Position.Z}}
end
return Checkpoints
