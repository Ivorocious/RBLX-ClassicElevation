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
	local cf, halfX, halfZ = start.CFrame, start.Size.X / 2, start.Size.Z / 2
	for _, side in ipairs({-1, 1}) do
		part(pen, "RetainingWall", Vector3.new(1.5, 5, start.Size.Z), cf * CFrame.new(side * halfX, 3.5, 0), ROCK, Enum.Material.Cobblestone, true)
		local wall = part(pen, "SideSafety", Vector3.new(1, 25, start.Size.Z), cf * CFrame.new(side * halfX, 14, 0), ROCK, Enum.Material.SmoothPlastic, true)
		wall.Transparency = 1
	end
	part(pen, "BackWall", Vector3.new(start.Size.X, 5, 1.5), cf * CFrame.new(0, 3.5, halfZ), ROCK, Enum.Material.Cobblestone, true)
	local back = part(pen, "BackSafety", Vector3.new(start.Size.X, 25, 1), cf * CFrame.new(0, 14, halfZ), ROCK, Enum.Material.SmoothPlastic, true)
	back.Transparency = 1
	local roof = part(pen, "SafetyCeiling", Vector3.new(start.Size.X, 1, start.Size.Z), cf * CFrame.new(0, 26, 0), ROCK, Enum.Material.SmoothPlastic, true)
	roof.Transparency = 1
	local gate = part(pen, "StartGate", Vector3.new(start.Size.X, 25, 1), cf * CFrame.new(0, 14, -halfZ), ROCK, Enum.Material.SmoothPlastic, true)
	gate.Transparency = 1
	local visuals = Instance.new("Folder")
	visuals.Name, visuals.Parent = "GateVisuals", pen
	for _, x in ipairs({-halfX, halfX}) do
		part(pen, "Gatepost", Vector3.new(1.5, 10, 1.5), cf * CFrame.new(x, 6.5, -halfZ), WOOD, Enum.Material.Wood, true)
	end
	for _, y in ipairs({3.5, 6.5}) do
		part(visuals, "ClosedTimberGate", Vector3.new(start.Size.X, 1, 0.8), cf * CFrame.new(0, y, -halfZ), AMBER, Enum.Material.Wood)
	end
	Details.Sign(pen, cf * CFrame.new(halfX - 6, 1.5, halfZ - 5), "CLASSIC ASCENT", "Gate opens when the race starts")
end

function Details.RouteExtras(model: Model, nodes: {BasePart})
	require(script.Parent.AscentObstacles).Build(model, nodes)
end

return Details
