--!strict

local Kit = {}
local layerCount = 12
local depth = 44

local function layer(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position = name, size, position
	part.Color, part.Transparency = color, transparency
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored, part.CastShadow = true, false
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function label(parent: Instance, title: string, position: Vector3, width: number)
	local board = layer(parent, title, Vector3.new(width, 4, .15), position, Color3.fromRGB(46, 54, 65), 0)
	board.Locked = true
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Back, Vector2.new(width * 24, 96), board
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Text, text.TextColor3 = title, Color3.fromRGB(230, 216, 183)
	text.Font, text.TextScaled, text.Parent = Enum.Font.GothamBold, true, gui
end

function Kit.Build(parent: Instance, origin: Vector3?): Model
	assert(game.PlaceId == 85558151074819)
	assert(not parent:FindFirstChild("DepthIllusionKit"), "Preserve the existing editable depth kit")
	local root = Instance.new("Model")
	root.Name, root.WorldPivot = "DepthIllusionKit", CFrame.identity
	local models = Instance.new("Folder")
	models.Name, models.Parent = "CopyThese", root
	local display = Instance.new("Folder")
	display.Name, display.Parent = "Display_DoNotCopy", root
	for _, kind in { "Floor", "Horizon" } do
		local model = Instance.new("Model")
		model.Name = if kind == "Floor" then "01_FloorDepthFade" else "02_HorizonDepthFade"
		model.WorldPivot = CFrame.identity
		model:SetAttribute("FadeDirection", if kind == "Floor" then "Down along local -Y" else "Away along local -Z; view from +Z")
		for index = 1, layerCount do
			local fraction = (index-1)/(layerCount-1)
			local name = string.format("Layer_%02d_%s", index, if index == 1 then "Near_Clear" elseif index == layerCount then "Far_Opaque" else "Fade")
			local size = if kind == "Floor" then Vector3.new(72, .05, 72) else Vector3.new(80, 56, .05)
			local position = if kind == "Floor" then Vector3.new(0, -depth*fraction, 0) else Vector3.new(0, 0, -depth*fraction)
			local color = if kind == "Floor" then Color3.fromRGB(100, 128, 151) else Color3.fromRGB(164, 193, 214)
			layer(model, name, size, position, color, 1-fraction*fraction)
		end
		if kind == "Horizon" then model:PivotTo(CFrame.new(110, -16, 0)) end
		model.Parent = models
	end
	label(display, "FLOOR DEPTH  /  CLEAR TOP TO OPAQUE BOTTOM", Vector3.new(0, 4, 43), 80)
	label(display, "HORIZON DEPTH  /  CLEAR FRONT TO OPAQUE BACK", Vector3.new(110, 19, 6), 80)
	root:PivotTo(CFrame.new(origin or Vector3.new(3530, 62, 640)))
	root.Parent = parent
	return root
end

return Kit
