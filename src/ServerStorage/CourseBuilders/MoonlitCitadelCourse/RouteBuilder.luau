--!nonstrict
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local VisualAssembly = require(script.Parent.VisualAssembly)
local Finishing = require(script.Parent.SurfaceFinishingPlan)
local AssemblyConfig = require(game.ReplicatedStorage.Config.MoonlitCitadelAssemblyConfig)
local Wayfinding = require(script.Parent.Wayfinding)
local DecorativeClearance = require(script.Parent.DecorativeClearance)
local Layout = require(script.Parent.Layout)
local Coverage = require(script.Parent.Coverage)
local WorldAssembly = require(script.Parent.WorldAssembly)
local RouteHazards = require(script.Parent.RouteHazards)
local MeshKit = require(script.Parent.Parent.MoonlitCitadel.MeshKit)
local Builder = {}
local Stone = Color3.fromRGB(149, 164, 178)
local Iron = Color3.fromRGB(30, 37, 49)

local function group(parent, name, className)
	local item = Instance.new(className or "Model")
	item.Name, item.Parent = name, parent
	return item
end

local function part(parent, name, size, frame, collide, role, visible)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, frame
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, collide, true, false
	item.Transparency, item.Color = if visible then 0 else 1, Stone
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item:SetAttribute("Role", role)
	item.Parent = parent
	return item
end

local function art(parent, name, asset, frame, scale)
	return MeshKit.Place(parent, name, asset, frame, scale)
end

local function floor(parent, data)
	local unit = group(parent, data.name)
	local frame = CFrame.new(Config.Origin) * (data.frame or CFrame.new(data.position))
	local contact = part(unit, "Contact", data.size, frame * CFrame.new(0, -data.size.Y / 2, 0), true, data.role)
	contact.PivotOffset, unit.PrimaryPart = CFrame.new(0, data.size.Y / 2, 0), contact
	contact:SetAttribute("MCWalkable", true)
	art(unit, "StoneSkin", "MC_FloorStone", frame, Vector3.new(data.size.X / 18, data.size.Y, data.size.Z / 12))
	if string.find(data.group, "UpperBrace", 1, true) then art(unit, "BraceSkin", "MC_ExpertCorbel", frame, Vector3.new(data.size.X / 5.8, 1, data.size.Z / 5)) end

	return unit
end

local function trigger(parent, name, point, size, respawn)
	local item = part(parent, name, size, CFrame.new(Config.Origin + point + Vector3.new(0, size.Y / 2, 0)), false, "RaceTrigger")
	item.CanTouch = true
	item:SetAttribute("RespawnCFrame", CFrame.new(Config.Origin + (respawn or point) + Vector3.new(0, 4, 0)))
	return item
end

local function cable(parent, name, anchorPoint, target, offset)
	local anchor = part(parent, name .. "Anchor", Vector3.one * .15, CFrame.new(anchorPoint), false, "MechanismCable")
	anchor.CanQuery = false
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	top.Parent, bottom.Parent = anchor, target
	bottom.Position = offset or Vector3.new(0, target.Size.Y / 2, 0)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, top, bottom
	beam.Color, beam.Width0, beam.Width1 = ColorSequence.new(Iron), .14, .14
	beam.FaceCamera, beam.Parent = true, anchor
end

local function liftStage(obstacles, moving, stage, localOrigin)
	local mechanism = group(obstacles, stage .. "Mechanism")
	local origin = Config.Origin + localOrigin
	for bay, x in {-9, 9} do
		local frame = CFrame.new(origin + Vector3.new(x, 0, 0))
		local car = group(moving, stage .. "_Bay" .. bay)
		local deck = part(car, "Deck", Vector3.new(14, .75, 12), frame * CFrame.new(0, -.375, 0), true, "MovingDeck")
		deck.PivotOffset, car.PrimaryPart = CFrame.new(0, .375, 0), deck
		for side, sideX in {-6.82, 6.82} do
			part(car, "SideRail" .. side, Vector3.new(.5, 3, 11.5), frame * CFrame.new(sideX, 1.5, 0), true, "SolidBlocker")
		end
		for _, asset in {"MC_CarStone", "MC_CarIronBrass"} do art(car, asset, asset, frame) end
		car:SetAttribute("Travel", Vector3.new(0, 34, 0))
		car:SetAttribute("CycleSeconds", Config.CycleSeconds)
		car:SetAttribute("DwellSeconds", Config.DwellSeconds)
		car:SetAttribute("PhaseSeconds", if bay == 1 then 0 else Config.SecondBayDelay)
		car:SetAttribute("Stage", stage)
		car:SetAttribute("Bay", bay)
		local outside = if bay == 1 then (if stage == "Upper" then -46 else -27) else 27
		local weight = group(mechanism, "OutboardWeight" .. bay)
		local weightFrame = CFrame.new(origin + Vector3.new(outside, 39, 0))
		weight.PrimaryPart = part(weight, "WeightContact", Vector3.new(4, 8, 2.5), weightFrame, false, "CounterweightVisual")
		for _, asset in {"MC_WeightStone", "MC_WeightIron"} do art(weight, asset, asset, weightFrame) end
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "Counterweight", weight, car
		for index, guideX in {x - 8, x + 8, outside - 3, outside + 3} do
			art(mechanism, "GuideBay" .. bay .. "_" .. index, "MC_GuideIron", CFrame.new(origin + Vector3.new(guideX, 18, -1)))
		end
		local cableX = x + (if bay == 1 then -6.4 else 6.4)
		local mid = (outside + cableX) / 2
		for index, px in {math.min(outside, cableX) + 2.114, math.max(outside, cableX) - 2.114} do
			for _, asset in {"MC_PulleyIron", "MC_PulleyBrass"} do
				art(mechanism, asset .. bay .. "_" .. index, asset, CFrame.new(origin + Vector3.new(px, 46, 0)), Vector3.one * .7)
			end
		end
		art(mechanism, "PulleyReturn" .. bay, "MC_CableReturnIron", CFrame.new(origin + Vector3.new(mid, 46, 0)))
		art(mechanism, "Header" .. bay, "MC_GuideIron", CFrame.new(origin + Vector3.new(mid, 46, -1.8)) * CFrame.Angles(0, 0, -math.pi / 2), Vector3.new(.75, 11.6 / 52, .75))
		cable(mechanism, "CarChain" .. bay, origin + Vector3.new(cableX, 46, 0), deck, Vector3.new(cableX - x, 3.375, 0))
		cable(mechanism, "WeightChain" .. bay, origin + Vector3.new(outside, 46, 0), weight.PrimaryPart)
	end
end

local function lanterns(obstacles)
	local swings = group(obstacles, "SwingLanterns", "Folder")
	local mounts = group(obstacles, "LanternMounts")
	for _, data in Layout.Lanterns do
		local frame = CFrame.new(Config.Origin + data.point)
		local pivot = Config.Origin + data.pivot
		local cage = group(swings, data.name)
		cage.PrimaryPart = part(cage, "CageContact", Vector3.new(4, 7, 4), frame, false, "HazardBroadPhase")
		local visible = group(cage, "CageAndCore")
		for _, asset in {"MC_LanternCage", "MC_LanternCore"} do
			local unit = art(visible, asset, asset, frame)
			for _, contact in unit:GetDescendants() do if contact:IsA("BasePart") then contact.CanQuery = true end end
			if asset == "MC_LanternCore" then
				local light = Instance.new("PointLight")
				light.Name, light.Color = "AmberLight", Color3.fromRGB(255, 188, 75)
				light.Brightness, light.Range, light.Shadows = 1.2, 12, false
				light.Parent = unit:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		cage:SetAttribute("PivotPosition", pivot)
		cage:SetAttribute("RestCFrame", cage:GetPivot())
		cage:SetAttribute("SwingAxis", data.axis)
		cage:SetAttribute("SwingAngleDegrees", 32)
		cage:SetAttribute("CycleSeconds", 6)
		cage:SetAttribute("PhaseSeconds", data.phase)
		local mount = part(mounts, data.name .. "Header", Vector3.new(2, 1, 30), CFrame.new(pivot), false, "MechanismFrame", true)
		mount.Color, mount.Material, mount.CanQuery = Iron, Enum.Material.Metal, false
		cable(mounts, data.name .. "Chain", pivot, cage.PrimaryPart)
	end
end

local function fallCoverage(course)
	local origin = Config.Origin
	local bottom = part(course.FallZones, "BelowPlayableRoute", Vector3.new(310, 4, 250), CFrame.new(origin + Vector3.new(0, -25, 0)), false, "FallReset")
	bottom.CanTouch = true
	for name, data in {
		West = {Vector3.new(-151, 75, 0), Vector3.new(4, 220, 250)},
		East = {Vector3.new(151, 75, 0), Vector3.new(4, 220, 250)},
		North = {Vector3.new(0, 75, -121), Vector3.new(310, 220, 4)},
		South = {Vector3.new(0, 75, 121), Vector3.new(310, 220, 4)},
	} do
		local wall = part(course.FallZones, "Outside" .. name, data[2], CFrame.new(origin + data[1]), false, "FallReset")
		wall.CanTouch = true
	end
end

function Builder.Build(parent)
	local course = group(parent, Config.CourseName)
	for key, value in {CourseId = Config.CourseId, CandidateId = Finishing.Candidate, MoonlitCourse = true,
		SourceRevision = Finishing.SourceRevision, BuildRevision = Finishing.BuildRevision,
		CommissionPhase = 3, Origin = Config.Origin, WorkLighting = "Daylight", TimingValidated = false} do course:SetAttribute(key, value) end
	for _, name in {"CourseInfo", "Checkpoints", "Obstacles", "FallZones", "RouteMarkers", "Decoration", "Bounds"} do group(course, name, "Folder") end
	for key, value in {CourseId = Config.CourseId, DisplayName = "Moonlit Citadel", RaceFormat = "PointToPoint", LapCount = 1,
		CheckpointCount = 4, Enabled = true, DesignedRacerCapacity = 20, Difficulty = "Normal / Expert", TimingValidated = false,
		TargetNewPlayerTime = 300, TargetPracticedTime = 150} do course.CourseInfo:SetAttribute(key, value) end
	for index, data in Layout.Surfaces do
		local parent = course.Obstacles:FindFirstChild(data.group) or group(course.Obstacles, data.group)
		floor(parent, data)
		if index % 32 == 0 then task.wait() end
	end
	local start = trigger(course, "Start", Layout.StartPoint, Vector3.new(38, 6, 22))
	start:SetAttribute("RespawnAreaSize", Vector3.new(34, 0, 20))
	local finishGate = Layout.FinishGate
	local finish = trigger(course, "Finish", finishGate.point, finishGate.size)
	finish.CFrame *= CFrame.Angles(0, finishGate.yaw, 0)
	finish:SetAttribute("RequireForwardCrossing", true)
	for index = 1, 4 do
		local name = string.format("CP%02d", index)
		local data = Layout[name]
		local cp = trigger(course.Checkpoints, string.format("Checkpoint_%03d", index), data.point, Vector3.new(data.size.X, 6, data.size.Z), data.pocket)
		cp:SetAttribute("CheckpointIndex", index)
		cp:SetAttribute("RespawnAreaSize", data.respawnArea)
		cp:SetAttribute("RespawnPocketPath", data.pocketSupport)
		local inlay = part(course.RouteMarkers, name .. "Inlay", Vector3.new(5, .1, 5), CFrame.new(Config.Origin + data.point + Vector3.new(0, .06, 0)), false, "CheckpointInlay", true)
		inlay.Color, inlay.Material, inlay.CanQuery = Color3.fromRGB(57, 215, 220), Enum.Material.SmoothPlastic, false
	end
	local moving = group(course.Obstacles, "MovingCars", "Folder")
	liftStage(course.Obstacles, moving, "Lower", Layout.LiftOrigins.Lower)
	liftStage(course.Obstacles, moving, "Upper", Layout.LiftOrigins.Upper)
	lanterns(course.Obstacles)
	RouteHazards.Build(course, Layout, Config.Origin)
	local archArt = group(course.Decoration, "ArchUndersides")
	for _, data in Layout.ArchSkins do
		local span = Vector3.new(data.b.X - data.a.X, 0, data.b.Z - data.a.Z).Magnitude
		if span > 72 then continue end
		local approved = DecorativeClearance.Suggest(Layout, data)
		if approved then
			art(archArt, data.group .. "_" .. data.name, "MC_StoneArch", CFrame.new(Config.Origin) * approved.frame, approved.scale)
		end
	end
	local bound = part(course.Bounds, "CourseBounds", Vector3.new(300, 220, 240), CFrame.new(Config.Origin + Vector3.new(0, 75, 0)), false, "CourseBounds")
	bound.CanQuery = false
	course:SetAttribute("BoundsCenter", bound.Position)
	course:SetAttribute("BoundsSize", bound.Size)
	course:SetAttribute("FallY", Config.Origin.Y - 23)
	fallCoverage(course)
	Coverage.ApplyCoverage(course, Config.Origin)
	Coverage.ValidateCourse(course, Layout, Config.Origin, 20)
	art(course.Decoration, "CrownEmblem", "MC_CrownEmblem", CFrame.new(Config.Origin + Layout.FinishPoint + Vector3.new(0, 6, 19.65)))
	course.WorldPivot = CFrame.new(Config.Origin)
	VisualAssembly.Apply(course)
	Wayfinding.Apply(course, Layout)
	WorldAssembly.Apply(course, Layout)
	assert(course.Decoration.Phase3World:GetAttribute("NewLights") <= 10)
	course:SetAttribute("MoonlitNightAmbience", true)
	return course
end

return Builder
