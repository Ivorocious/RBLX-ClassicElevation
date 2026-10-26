--!nonstrict
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local MeshKit = require(script.Parent.MeshKit)
local Prototype = require(script.Parent.Installer)
local Installer = {}

local function group(parent, name, className)
	local item = Instance.new(className or "Model")
	item.Name, item.Parent = name, parent
	return item
end

local function contact(parent, name, size, frame, collide, role)
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, frame
	part.Anchored, part.Transparency = true, 1
	part.CanCollide, part.CanQuery, part.CanTouch = collide, true, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part:SetAttribute("Role", role)
	part.Parent = parent
	return part
end

local function art(parent, name, asset, frame, scale)
	return MeshKit.Place(parent, name, asset, frame, scale)
end

local function floor(parent, name, point, size, role)
	local model = group(parent, name)
	local frame = if typeof(point) == "CFrame" then point else CFrame.new(point)
	local part = contact(model, "Contact", size, frame * CFrame.new(0, -size.Y / 2, 0), true, role or "WalkableSurface")
	part.PivotOffset = CFrame.new(0, size.Y / 2, 0)
	model.PrimaryPart = part
	art(model, "StoneSkin", "MC_FloorStone", frame, Vector3.new(size.X / 18, size.Y, size.Z / 12))
	return part
end

local function trigger(parent, name, point, index, recovery)
	local part = contact(parent, name, Vector3.new(10, 6, 8), CFrame.new(point + Vector3.new(0, 3, 0)), false, "PreviewTrigger")
	part.CanTouch = true
	if index then part:SetAttribute("CheckpointIndex", index) end
	part:SetAttribute("RecoveryCFrame", CFrame.new(recovery or point) + Vector3.new(0, 4, 0))
	return part
end

local function area(name, origin, size, fallOffset)
	local model = group(nil, name)
	model:SetAttribute("BoundsCenter", origin + Vector3.new(0, 70, 0))
	model:SetAttribute("BoundsSize", size)
	model:SetAttribute("FallY", origin.Y + fallOffset)
	for _, folder in {"Checkpoints", "MovingCars", "SwingLanterns"} do group(model, folder, "Folder") end
	return model
end

local function lane(parent, name, points, width, archHeight)
	local rise = if archHeight == nil then 1.2 else archHeight
	local model = group(parent, name)
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local length = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
		local sections = math.max(2, math.ceil(length / 5))
		for step = 1, sections do
			local t0, t1 = (step - 1) / sections, step / sections
			local pa, pb = a:Lerp(b, t0), a:Lerp(b, t1)
			pa += Vector3.new(0, math.sin(t0 * math.pi) * rise, 0)
			pb += Vector3.new(0, math.sin(t1 * math.pi) * rise, 0)
			local frame = CFrame.lookAt((pa + pb) / 2, pb)
			floor(model, "Tread_" .. index .. "_" .. step, frame, Vector3.new(width, 1, (pb - pa).Magnitude + .06))
		end
		floor(model, "Landing_" .. index, b, Vector3.new(width + 2, 1, width + 2))
	end
	return model
end

function Installer.AddCatchReturn(parent, origin)
	assert(not parent:FindFirstChild("CatchReturn"), "Preserve the existing catch return before rebuilding")
	return lane(parent, "CatchReturn", {
		origin + Vector3.new(-25, -8, 24), origin + Vector3.new(-31, -8, 24),
		origin + Vector3.new(-31, -4, 18), origin + Vector3.new(-31, 0, 12),
		origin + Vector3.new(-23, 0, 12),
	}, 6, 0)
end

local function cable(parent, point, part, attachmentOffset)
	local anchor = contact(parent, "CableAnchor", Vector3.one * .2, CFrame.new(point), false, "Decoration")
	anchor.CanQuery = false
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Parent, b.Parent = anchor, part
	b.Position = attachmentOffset or Vector3.new(0, part.Size.Y / 2, 0)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = "MechanismCable", a, b
	beam.Color, beam.Width0, beam.Width1 = ColorSequence.new(Color3.fromRGB(30, 37, 49)), .14, .14
	beam.FaceCamera, beam.Parent = true, anchor
end

local function red(parent, name, point, size)
	local model = group(parent, name)
	local part = contact(model, "HazardContact", size, CFrame.new(point), false, "Hazard")
	part.CanTouch = true
	part:SetAttribute("PreviewHazard", true)
	model.PrimaryPart = part
	local scale = Vector3.new(size.X / 14, size.Y / 2, size.Z / 12)
	for _, asset in {"MC_KillCasing", "MC_KillRed"} do art(model, asset, asset, part.CFrame, scale) end
	return model
end

local function lifts(model, o)
	for bay, x in {-9, 9} do
		local car = group(model.MovingCars, "Upper_Bay" .. bay)
		local frame = CFrame.new(o + Vector3.new(x, 0, 0))
		local deck = contact(car, "Deck", Vector3.new(14, .75, 12), frame * CFrame.new(0, -.375, 0), true, "Walkable")
		deck.PivotOffset, car.PrimaryPart = CFrame.new(0, .375, 0), deck
		for _, side in {-6.82, 6.82} do contact(car, "SideRailContact", Vector3.new(.5, 3, 11.5), frame * CFrame.new(side, 1.5, 0), true, "SolidBlocker") end
		for _, asset in {"MC_CarStone", "MC_CarIronBrass"} do art(car, asset, asset, frame) end
		car:SetAttribute("Travel", Vector3.new(0, Config.LiftRise, 0))
		car:SetAttribute("CycleSeconds", Config.LiftCycleSeconds)
		car:SetAttribute("DwellSeconds", Config.LiftDwellSeconds)
		car:SetAttribute("PhaseSeconds", if bay == 1 then 0 else Config.SecondBayDelay)
		local outside = if bay == 1 then -27 else 27
		local carCableX = x + (if bay == 1 then -6.4 else 6.4)
		local cableMid = (outside + carCableX) / 2
		local weight = group(model, "Upper_OutboardWeight" .. bay)
		local weightFrame = CFrame.new(o + Vector3.new(outside, 39, 0))
		weight.PrimaryPart = contact(weight, "WeightContact", Vector3.new(4, 8, 2.5), weightFrame, true, "SolidBlocker")
		for _, asset in {"MC_WeightStone", "MC_WeightIron"} do art(weight, asset, asset, weightFrame) end
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "Counterweight", weight, car
		for _, gx in {x - 8, x + 8, outside - 3, outside + 3} do art(model, "MachineGuide", "MC_GuideIron", CFrame.new(o + Vector3.new(gx, 18, -1))) end
		for _, px in {math.min(outside, carCableX) + 3.02 * .7, math.max(outside, carCableX) - 3.02 * .7} do
			for _, asset in {"MC_PulleyIron", "MC_PulleyBrass"} do art(model, asset .. px, asset, CFrame.new(o + Vector3.new(px, 46, 0)), Vector3.one * .7) end
		end
		art(model, "PulleyReturn" .. bay, "MC_CableReturnIron", CFrame.new(o + Vector3.new(cableMid, 46, 0)))
		art(model, "MachineHeader" .. bay, "MC_GuideIron", CFrame.new(o + Vector3.new(cableMid, 46, -1.8)) * CFrame.Angles(0, 0, -math.pi / 2), Vector3.new(.75, 11.6 / 52, .75))
		cable(model, o + Vector3.new(carCableX, 46, 0), deck, Vector3.new(carCableX - x, 3.375, 0))
		cable(model, o + Vector3.new(outside, 46, 0), weight.PrimaryPart)
	end
end

local function architecture(model, o)
	local surroundings = group(model, "NearArchitecture")
	art(surroundings, "KeepFacade", "MC_KeepShell", CFrame.new(o + Vector3.new(0, -10, -31)))
	for _, asset in {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"} do art(surroundings, asset, asset, CFrame.new(o + Vector3.new(0, -8, -28))) end
	for _, x in {-31, -18, 18, 31} do art(surroundings, "CarvedButtress", "MC_PierStone", CFrame.new(o + Vector3.new(x, -10, -27))) end
	local function turret(x, y, z, scale)
		local frame = CFrame.new(o + Vector3.new(x, y, z))
		for _, asset in {"MC_TurretStone", "MC_TurretAmber"} do art(surroundings, "Turret" .. x .. "_" .. asset, asset, frame, Vector3.one * scale) end
		art(surroundings, "TurretSideAmber" .. x, "MC_TurretAmber", frame * CFrame.Angles(0, math.pi / 2, 0), Vector3.one * scale)
		art(surroundings, "Spire" .. x, "MC_SlateSpire", frame + Vector3.new(0, 28 * scale, 0), Vector3.one * scale)
	end
	for _, x in {-37, 37} do
		turret(x, -10, -23, 1)
		art(surroundings, "CurvedSupport" .. x, "MC_StoneArch", CFrame.new(o + Vector3.new(x, -16, 13)) * CFrame.Angles(0, math.pi / 2, 0))
		local side = if x < 0 then 1 else -1
		art(surroundings, "Banner" .. x, "MC_Banner", CFrame.new(o + Vector3.new(x + side * 4.5, 5, -19.6)))
		art(surroundings, "Ivy" .. x, "MC_Ivy", CFrame.new(o + Vector3.new(x + side * 4.8, -3, -20)))
	end
	for _, x in {-29, 29} do turret(x, 39, -30, .7) end
	for _, x in {-15, 3} do
		local frame = CFrame.new(o + Vector3.new(x, 0, 25.5))
		for _, asset in {"MC_BalustradeStone", "MC_BalustradeIron"} do art(surroundings, "EntryRail" .. x .. asset, asset, frame) end
		contact(surroundings, "EntryRailContact", Vector3.new(18, 3, 1), frame + Vector3.new(0, 1.5, 0), true, "SolidBlocker")
	end
	for _, x in {-10, 10} do
		local frame = CFrame.new(o + Vector3.new(x, 34, -25.5))
		for _, asset in {"MC_BalustradeStone", "MC_BalustradeIron"} do art(surroundings, "ExitRail" .. x .. asset, asset, frame) end
		contact(surroundings, "ExitRailContact", Vector3.new(18, 3, 1), frame + Vector3.new(0, 1.5, 0), true, "SolidBlocker")
	end
	for _, x in {-24, 24} do
		local frame = CFrame.new(o + Vector3.new(x, 5, 21))
		for _, asset in {"MC_LanternCage", "MC_LanternCore"} do art(surroundings, "FixedLamp" .. x .. asset, asset, frame, Vector3.one * .5) end
	end
	art(surroundings, "CrownAccent", "MC_CrownEmblem", CFrame.new(o + Vector3.new(0, 53, -25.8)))
	art(surroundings, "EntryArrow", "MC_RouteArrow", CFrame.new(o + Vector3.new(-17, 2.4, 25.7)))
end

local function sample(o)
	local model = area("UpperSample", o, Vector3.new(150, 250, 140), -20)
	floor(model, "CP04_Wait", o + Vector3.new(0, 0, 17), Vector3.new(48, 2, 18))
	floor(model, "SharedUpperExit", o + Vector3.new(0, 34, -17), Vector3.new(40, 2, 18))
	trigger(model.Checkpoints, "CP04", o + Vector3.new(-18, 0, 21), 1, o + Vector3.new(-18, 0, 21))
	trigger(model, "Start", o + Vector3.new(-18, 0, 21))
	trigger(model, "Finish", o + Vector3.new(0, 34, -19))
	local approach = group(model, "ExpertBraceApproach")
	for i, point in {Vector3.new(23, 0, 21), Vector3.new(31, 4, 19), Vector3.new(25, 8, 14), Vector3.new(17, 12, 12), Vector3.new(9, 14, 10.5)} do
		floor(approach, "BraceStep" .. i, o + point, Vector3.new(6, 1, 5))
		if i > 1 then art(approach, "StoneCorbel" .. i, "MC_ExpertCorbel", CFrame.new(o + point)) end
	end
	floor(approach, "EarlyExitContact", o + Vector3.new(9, 28, 10.5), Vector3.new(6, 1, 5))
	art(approach, "EarlyExitCorbel", "MC_ExpertCorbel", CFrame.new(o + Vector3.new(9, 28, 10.5)))
	lane(approach, "ExitRise", {o + Vector3.new(9, 28, 10.5), o + Vector3.new(18, 30, 14), o + Vector3.new(26, 32, 15), o + Vector3.new(34, 34, 7), o + Vector3.new(34, 34, -14), o + Vector3.new(21, 34, -21)}, 6)
	floor(model, "CatchShelf", o + Vector3.new(0, -8, 23), Vector3.new(54, 1, 14), "SafeRefuge")
	Installer.AddCatchReturn(model, o)
	for _, x in {-9, 9} do red(model, "NeonReset_" .. x, o + Vector3.new(x, -12, 0), Vector3.new(14, 2, 12)) end
	lifts(model, o)
	architecture(model, o)
	return model
end

local function lanterns(o)
	local model = area("LanternStudy", o, Vector3.new(110, 210, 150), -18)
	model:SetAttribute("BoundsCenter", o + Config.LanternBoundsOffset)
	model:SetAttribute("BoundsSize", Config.LanternBoundsSize)
	floor(model, "EntranceWait", o, Vector3.new(24, 2, 16))
	trigger(model, "Start", o)
	trigger(model.Checkpoints, "CP02", o, 1, o + Vector3.new(-8, 0, 0))
	for band = 1, 3 do
		local z, y = -20 - (band - 1) * 22, (band - 1) * 4 + 2
		local cageFrame = CFrame.new(o + Vector3.new(0, y + 3, z))
		local pivot = cageFrame.Position + Vector3.new(0, Config.LanternLength, 0)
		local cage = group(model.SwingLanterns, "SwingBand" .. band)
		cage.PrimaryPart = contact(cage, "CageContact", Vector3.new(4, 7, 4), cageFrame, false, "HazardBroadPhase")
		local visible = group(cage, "CageAndCore")
		for _, asset in {"MC_LanternCage", "MC_LanternCore"} do
			local unit = art(visible, asset, asset, cageFrame)
			for _, part in unit:GetDescendants() do if part:IsA("BasePart") then part.CanQuery = true end end
			if asset == "MC_LanternCore" then
				local light = Instance.new("PointLight")
				light.Name, light.Color = "AmberLight", Color3.fromRGB(255, 188, 75)
				light.Brightness, light.Range, light.Shadows = 1.2, 12, false
				light.Parent = unit:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		cage:SetAttribute("PivotPosition", pivot)
		cage:SetAttribute("SwingAngleDegrees", Config.LanternAngleDegrees)
		cage:SetAttribute("CycleSeconds", Config.LanternCycleSeconds)
		cage:SetAttribute("PhaseSeconds", (band - 1) * 1.5)
		cable(model, pivot, cage.PrimaryPart)
		local normalX = if band % 2 == 1 then -8 else 8
		floor(model, "NormalCrossing" .. band, o + Vector3.new(normalX, y, z), Vector3.new(8, 1, 16))
		floor(model, "NormalWait" .. band, o + Vector3.new(normalX, y + 2, z - 11), Vector3.new(12, 1, 10), "SafeRefuge")
		for _, dz in {7, -7} do floor(model, "ExpertIsland" .. band .. "_" .. dz, o + Vector3.new(0, y, z + dz), Vector3.new(5, 1, 6)) end
		red(model, "RedGap" .. band, o + Vector3.new(0, y - 12, z), Vector3.new(16, 2, 8))
	end
	floor(model, "ExitWait", o + Vector3.new(0, 12, -80), Vector3.new(24, 2, 14))
	trigger(model, "Finish", o + Vector3.new(0, 12, -80))
	return model
end

function Installer.Build(parent)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Build in Studio Edit")
	assert(game.PlaceId == Config.PlaceId and game.CreatorId == 86069177, "Wrong project destination")
	local destination = parent or workspace
	assert(not destination:FindFirstChild(Config.BlenderRootName), "Preserve the existing Blender candidate")
	local root = group(destination, Config.BlenderRootName)
	root:SetAttribute("CandidateId", Config.BlenderCandidateId)
	root:SetAttribute("TaskId", "MC-PHASE1-20261010")
	root:SetAttribute("CommissionPhase", 1)
	root:SetAttribute("PreviewOnly", true)
	root:SetAttribute("PreviewEnabled", false)
	root:SetAttribute("WorkLighting", "Daylight; final night lighting deferred")
	local offset = Config.BlenderOffset
	local rough = Prototype.BuildRough()
	rough.Parent = root
	rough:PivotTo(rough:GetPivot() + offset)
	for _, item in {rough, table.unpack(rough:GetDescendants())} do
		for _, key in {"BoundsCenter", "PivotPosition", "RecoveryCFrame"} do
			local value = item:GetAttribute(key)
			if typeof(value) == "Vector3" or typeof(value) == "CFrame" then item:SetAttribute(key, value + offset) end
		end
	end
	rough:SetAttribute("VisualStatus", "Rough native route; geometry and connections only")
	sample(Config.SampleOrigin + offset).Parent = root
	lanterns(Config.LanternOrigin + offset).Parent = root
	return root
end

return Installer
