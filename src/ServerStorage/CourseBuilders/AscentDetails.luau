--!strict

local Details = {}
local ROCK = Color3.fromRGB(95, 105, 100)
local WOOD = Color3.fromRGB(105, 75, 48)
local AMBER = Color3.fromRGB(216, 161, 79)
local DANGER = Color3.fromRGB(222, 82, 39)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = solid == true, solid == true, solid == true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Details.Sign(parent: Instance, base: CFrame, title: string, subtitle: string, stone: boolean?)
	local material = if stone then Enum.Material.Slate else Enum.Material.Wood
	local color = if stone then ROCK else WOOD
	part(parent, "WaymarkerPost", Vector3.new(0.8, 9, 0.8), base * CFrame.new(0, 0.5, 0), color, material)
	local board = part(parent, "TrailSign", Vector3.new(7, 2.8, 0.35), base * CFrame.new(0, 4.8, 0), color, material)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local gui = Instance.new("SurfaceGui")
		gui.Face, gui.PixelsPerStud, gui.Parent = face, 65, board
		local label = Instance.new("TextLabel")
		label.Size, label.Position = UDim2.fromScale(0.88, 0.84), UDim2.fromScale(0.06, 0.08)
		label.BackgroundTransparency, label.TextScaled = 1, true
		label.Font, label.TextColor3 = Enum.Font.GothamMedium, Color3.fromRGB(237, 225, 195)
		label.Text = title .. "\n" .. subtitle
		label.Parent = gui
	end
end

function Details.Checkpoint(parent: Instance, pad: BasePart, index: number)
	local snowy = pad.Material == Enum.Material.Snow or pad.Material == Enum.Material.Glacier
	local wood = pad.Material == Enum.Material.WoodPlanks or pad.Material == Enum.Material.Cobblestone
	local material = if wood then Enum.Material.Wood else pad.Material
	local color = if wood then WOOD else pad.Color:Lerp(ROCK, 0.25)
	local base = pad.CFrame * CFrame.new(pad.Size.X / 2 - 2, 1.5, 0)
	part(parent, "MilestoneFoot", Vector3.new(3, 1, 3), base * CFrame.new(0, 0.5, 0), color, material)
	part(parent, "Milestone", Vector3.new(1.5, 3.5, 1.5), base * CFrame.new(0, 2.5, 0), color, material)
	local band = part(parent, "SavedProgressBlaze", Vector3.new(1.6, 0.45, 1.6), base * CFrame.new(0, 3.2, 0), AMBER, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.PixelsPerStud, gui.Parent = Enum.NormalId.Back, 64, band
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Size = 1, UDim2.fromScale(1, 1)
	label.Text, label.TextScaled, label.Font = string.format("%02d", index), true, Enum.Font.GothamBold
	label.TextColor3, label.Parent = ROCK, gui
	local lamp = part(parent, "ShelteredLantern", Vector3.new(0.9, 1.1, 0.9), base * CFrame.new(0, 4.6, 0), AMBER, Enum.Material.Neon)
	part(parent, "LanternCap", Vector3.new(1.3, 0.25, 1.3), base * CFrame.new(0, 5.3, 0), if snowy then Color3.fromRGB(226, 237, 234) else color, material)
	local light = Instance.new("PointLight")
	light.Brightness, light.Range, light.Color, light.Parent = 0.3, 10, AMBER, lamp
end

function Details.StartPen(model: Model, start: BasePart)
	local pen = Instance.new("Folder")
	pen.Name, pen.Parent = "StartPen", model
	local cf = start.CFrame
	for _, x in ipairs({-20, 20}) do
		part(pen, "RetainingWall", Vector3.new(1.5, 5, 30), cf * CFrame.new(x, 3.5, 0), ROCK, Enum.Material.Cobblestone, true)
		local wall = part(pen, "SideSafety", Vector3.new(1, 25, 30), cf * CFrame.new(x, 14, 0), ROCK, Enum.Material.SmoothPlastic, true)
		wall.Transparency = 1
	end
	part(pen, "BackWall", Vector3.new(40, 5, 1.5), cf * CFrame.new(0, 3.5, 15), ROCK, Enum.Material.Cobblestone, true)
	local back = part(pen, "BackSafety", Vector3.new(40, 25, 1), cf * CFrame.new(0, 14, 15), ROCK, Enum.Material.SmoothPlastic, true)
	back.Transparency = 1
	local roof = part(pen, "SafetyCeiling", Vector3.new(40, 1, 30), cf * CFrame.new(0, 26, 0), ROCK, Enum.Material.SmoothPlastic, true)
	roof.Transparency = 1
	for _, x in ipairs({-15, 15}) do
		part(pen, "GateWing", Vector3.new(10, 5, 1.5), cf * CFrame.new(x, 3.5, -15), ROCK, Enum.Material.Cobblestone, true)
		local safety = part(pen, "GateWingSafety", Vector3.new(10, 25, 1), cf * CFrame.new(x, 14, -15), ROCK, Enum.Material.SmoothPlastic, true)
		safety.Transparency = 1
	end
	local gate = part(pen, "StartGate", Vector3.new(20, 25, 1), cf * CFrame.new(0, 14, -15), ROCK, Enum.Material.SmoothPlastic, true)
	gate.Transparency = 1
	local visuals = Instance.new("Folder")
	visuals.Name, visuals.Parent = "GateVisuals", pen
	for _, x in ipairs({-10.5, 10.5}) do
		part(pen, "Gatepost", Vector3.new(1.5, 10, 1.5), cf * CFrame.new(x, 6.5, -14), WOOD, Enum.Material.Wood, true)
	end
	for _, y in ipairs({3.5, 6.5}) do
		part(visuals, "ClosedTimberGate", Vector3.new(20, 1, 0.8), cf * CFrame.new(0, y, -14), AMBER, Enum.Material.Wood)
	end
	Details.Sign(pen, cf * CFrame.new(14, 1.5, 10), "CLASSIC ASCENT", "WAIT FOR THE TRAIL GATE")
end

local function beam(parent: Instance, a: Vector3, b: Vector3, color: Color3)
	part(parent, "ContinuousRope", Vector3.new(0.2, 0.2, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Fabric)
end

function Details.RouteExtras(model: Model, nodes: {BasePart})
	local hazards = Instance.new("Folder")
	hazards.Name, hazards.Parent = "Hazards", model
	for index, node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex")
		local step = node:GetAttribute("SectionStep") or 0
		local checkpoint = node.Parent == model.Checkpoints or node.Name == "Start" or node.Name == "Finish"
		local cf, size = node.CFrame, node.Size
		if section == 4 then
			if not checkpoint and step % 3 == 0 then node:SetAttribute("HazardType", "Crumble") end
			for _, side in ipairs({-1, 1}) do
				local previous = nodes[index - 1]
				if previous and previous:GetAttribute("SectionIndex") == 4 then
					local a = (previous.CFrame * CFrame.new(side * (previous.Size.X / 2 + 0.4), 5, 0)).Position
					local b = (cf * CFrame.new(side * (size.X / 2 + 0.4), 5, 0)).Position
					local midpoint = (a + b) / 2 - Vector3.new(0, 0.5, 0)
					beam(model.RouteMarkers, a, midpoint, WOOD)
					beam(model.RouteMarkers, midpoint, b, WOOD)
				end
				part(node, "BridgeUpright", Vector3.new(0.6, 5, 0.6), cf * CFrame.new(side * (size.X / 2 + 0.4), 3, 0), WOOD, Enum.Material.Wood)
			end
		end
		if not checkpoint and ((section == 3 and step % 4 == 2) or (section == 5 and step % 4 == 2) or (section == 9 and step % 4 == 2)) then
			local strip = part(hazards, if section == 9 then "SharpIce" else "BurningFissure", Vector3.new(size.X, 0.7, 1.2), cf * CFrame.new(0, 1.85, 0), if section == 9 then Color3.fromRGB(227, 99, 109) else DANGER, Enum.Material.Neon)
			strip.CanTouch, strip.CanQuery = true, true
			strip:SetAttribute("HazardType", "Kill")
			node:SetAttribute("JumpOverCenter", true)
		end
		if not checkpoint and section == 8 and step % 4 == 2 then node:SetAttribute("HazardType", "Crumble") end
		if not checkpoint and ((section == 6 and step % 4 == 2) or (section == 7 and step % 4 == 2) or (section == 9 and step % 4 == 0)) then
			local group = Instance.new("Model")
			group.Name, group.Parent = "Rockfall_" .. tostring(index), hazards
			local offset = if size.X >= 15 then size.X * 0.2 else 0
			local warning = part(group, "Warning", Vector3.new(7, 0.08, 7), cf * CFrame.new(offset, 1.56, 0), AMBER, Enum.Material.Neon)
			warning.Shape = Enum.PartType.Cylinder
			warning.Size = Vector3.new(0.08, 7, 7)
			warning.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
			warning.Transparency = 0.8
			local rock = part(group, "FallingRock", Vector3.new(5, 5, 5), cf * CFrame.new(offset, 36, 0), if section == 9 then Color3.fromRGB(170, 207, 221) else ROCK, if section == 9 then Enum.Material.Glacier else Enum.Material.Rock)
			rock.Shape = Enum.PartType.Ball
			rock.CanQuery = true
			rock.Transparency = 1
			rock:SetAttribute("HazardType", "FallingRock")
			rock:SetAttribute("FallDistance", 42)
			rock:SetAttribute("CycleOffset", index % 5 * 0.7)
			node:SetAttribute("RockfallLane", group.Name)
		end
		if not checkpoint and section == 1 and step == 3 then
			part(model.Obstacles, "FallenTrailLog", Vector3.new(size.X - 2, 2, 2), cf * CFrame.new(0, 2.5, 0), WOOD, Enum.Material.Wood, true)
			node:SetAttribute("JumpOverCenter", true)
		end
	end
end

return Details
