--!strict
local Environment = {}

local boundaries = {
	{name="RoofOuterCorner", p=Vector3.new(3625.1,81.45,-325.14), s=Vector3.new(13.5,153,4), section="Roof"},
	{name="DepotWest", p=Vector3.new(3652,70,-165), s=Vector3.new(4,140,142), section="Depot"},
	{name="DepotEast", p=Vector3.new(3728,72,-152), s=Vector3.new(4,144,252), section="Depot"},
	{name="DepotShedBack", p=Vector3.new(3704,72,-226), s=Vector3.new(44,144,4), section="Depot"},
	{name="CrossingWestFacade", p=Vector3.new(3689,71,-43), s=Vector3.new(3,142,42), section="Crossing"},
	{name="CrossingEastFacade", p=Vector3.new(3732,71,-43), s=Vector3.new(4,142,42), section="Crossing"},
	{name="StationWest", p=Vector3.new(3674,85,121), s=Vector3.new(4,170,200), section="Station"},
	{name="StationFinishWest", p=Vector3.new(3653,85,252), s=Vector3.new(4,170,64), section="Station"},
	{name="StationFinishShoulder", p=Vector3.new(3663.5,85,220), s=Vector3.new(21,170,2), section="Station"},
	{name="StationEast", p=Vector3.new(3867,85,157), s=Vector3.new(4,170,302), section="Station"},
	{name="StationFarEnd", p=Vector3.new(3760,85,286), s=Vector3.new(214,170,4), section="Station"},
	{name="StationSouthFacades", p=Vector3.new(3791,80,32), s=Vector3.new(152,160,4), section="Station"},
}

function Environment.Apply()
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C11_01")
	assert(not course.OwnerEdits:FindFirstChild("C11InvisibleWalls"), "Environment pass already installed")
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = {course.Obstacles.WalkingSurfaces, course.Checkpoints,
		course.Obstacles.OwnerKillStrips, course.Obstacles.C10Obstacles}
	local issues = {}
	for _, b in boundaries do
		for _, p in workspace:GetPartBoundsInBox(CFrame.new(b.p), b.s+Vector3.new(3,3,3), overlap) do
			if p:GetAttribute("HazardType") or p:IsDescendantOf(course.Checkpoints)
				or (p.CanCollide and (p.Transparency == 1 or p:GetAttribute("CheckpointLanding"))) then
				table.insert(issues, b.name .. " overlaps " .. p:GetFullName())
			end
		end
	end
	assert(#issues == 0, table.concat(issues, "\n"))
	local walls = Instance.new("Folder")
	walls.Name, walls.Parent = "C11InvisibleWalls", course.OwnerEdits
	for _, b in boundaries do
		local p = Instance.new("Part")
		p.Name, p.Position, p.Size = b.name, b.p, b.s
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, true, true, false
		p.Transparency, p.CastShadow = 1, false
		p:SetAttribute("Section", b.section)
		p:SetAttribute("InvisibleBoundary", true)
		p.Parent = walls
	end
	local fades = Instance.new("Folder")
	fades.Name, fades.Parent = "C11FloorDepth", course.Decoration
	for _, zone in {
		{name="RoofDistrict", x0=3255,x1=3640,z0=-382,z1=-170},
		{name="DepotDistrict", x0=3640,x1=3790,z0=-320,z1=30},
		{name="StationDistrict", x0=3640,x1=3945,z0=30,z1=278},
	} do
		local model = Instance.new("Model")
		model.Name, model.Parent = zone.name, fades
		model:SetAttribute("FadeDirection", "Clear top to opaque bottom")
		model:SetAttribute("EditableUnit", true)
		for index = 1, 12 do
			local fraction = (index-1)/11
			local p = Instance.new("Part")
			p.Name = string.format("Layer_%02d_%s", index, if index == 1 then "Near_Clear" elseif index == 12 then "Far_Opaque" else "Fade")
			p.Size = Vector3.new(zone.x1-zone.x0, .05, zone.z1-zone.z0)
			p.Position = Vector3.new((zone.x0+zone.x1)/2, 58-44*fraction, (zone.z0+zone.z1)/2)
			p.Color, p.Transparency = Color3.fromRGB(100,128,151), 1-fraction*fraction
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored, p.CastShadow = true, false
			p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = model
		end
		model.WorldPivot = CFrame.new((zone.x0+zone.x1)/2,58,(zone.z0+zone.z1)/2)
	end
	return {walls=#boundaries, fadeZones=3, fadeLayers=36, routeClearanceCheck=true}
end

return Environment
