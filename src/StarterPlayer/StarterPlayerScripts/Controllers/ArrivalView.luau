--!strict
local Players = game:GetService("Players")
local Kit = require(script.Parent.UiKit)
local View = {}
local white = Color3.fromRGB(236, 245, 255)
local mint = Color3.fromRGB(51, 240, 200)
View.Space = Color3.fromRGB(2, 4, 11)
View.Cyan = Color3.fromRGB(82, 223, 255)
View.Mint = mint
View.Ivory = Color3.fromRGB(247, 243, 232)
View.Ink = Color3.fromRGB(11, 21, 48)
View.StarCoin = Kit.Images.StarCoin

function View.Make(className, name, parent, properties)
	local item = Instance.new(className)
	item.Name = name
	for key, value in properties or {} do item[key] = value end
	item.Parent = parent
	return item
end

function View.Round(parent, radius)
	View.Make("UICorner", "Corners", parent, {CornerRadius = UDim.new(0, radius or 22)})
end

function View.Text(name, parent, text, size, position)
	local item = View.Make("TextLabel", name, parent, {
		Text = text, Size = size, Position = position, BackgroundTransparency = 1,
		TextColor3 = white, Font = Enum.Font.GothamMedium, TextScaled = true, TextWrapped = true,
	})
	View.Make("UITextSizeConstraint", "TextLimit", item, {MinTextSize = 10, MaxTextSize = 25})
	return item
end

function View.Button(name, parent, text, size, position, secondary)
	local item = View.Make("TextButton", name, parent, {
		Text = text, Size = size, Position = position, BorderSizePixel = 0,
		BackgroundColor3 = if secondary then Color3.fromRGB(19, 34, 56) else mint,
		TextColor3 = if secondary then white else View.Ink,
		Font = Enum.Font.GothamBold, TextScaled = true, AutoButtonColor = true,
		Selectable = true,
	})
	View.Make("UITextSizeConstraint", "TextLimit", item, {MinTextSize = 10, MaxTextSize = 28})
	View.Make("UIPadding", "Padding", item, {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)})
	View.Round(item, 18)
	return item
end

function View.Card(name, parent)
	local card = View.Make("Frame", name, parent, {BackgroundColor3 = Color3.fromRGB(10, 16, 34), BackgroundTransparency = 0.08, BorderSizePixel = 0})
	View.Round(card, 22)
	View.Make("UIStroke", "Outline", card, {Color = View.Cyan, Thickness = 1.5, Transparency = 0.5})
	return card
end

-- Soft glow from three faint stacked ellipses, since UI has no radial gradient.
function View.Glow(parent, name, color, position, size, opacity)
	local outer = View.Make("Frame", name, parent, {AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = size, BackgroundTransparency = 1})
	local layers = {}
	for index, fraction in {1, 0.68, 0.38} do
		local layer = View.Make("Frame", "Layer" .. index, outer, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(fraction, fraction), BackgroundColor3 = color, BackgroundTransparency = 1 - opacity, BorderSizePixel = 0})
		View.Make("UICorner", "Corners", layer, {CornerRadius = UDim.new(0.5, 0)})
		View.Make("UIGradient", "Soften", layer, {Rotation = index * 60, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})})
		layers[index] = layer
	end
	return outer, layers
end

-- Small translucent pill for secondary controls on the space backdrop.
function View.Pill(button)
	button.BackgroundColor3, button.BackgroundTransparency = Color3.new(1, 1, 1), 0.92
	button.TextColor3, button.Font = Color3.fromRGB(221, 232, 255), Enum.Font.GothamBold
	button.Corners.CornerRadius = UDim.new(0.5, 0)
	View.Make("UIStroke", "Edge", button, {Color = Color3.new(1, 1, 1), Transparency = 0.82, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	return button
end

local function part(parent, name, size, frame, color)
	return View.Make("Part", name, parent, {Size = size, CFrame = frame, Color = color,
		Anchored = true, CanCollide = false, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth})
end

function View.Dummy()
	local model = Instance.new("Model")
	model.Name = "BlankRacer"
	local gray = Color3.fromRGB(181, 185, 190)
	part(model, "Torso", Vector3.new(2,2,1), CFrame.new(0,3,0), gray)
	local head = part(model, "Head", Vector3.new(2,1,1), CFrame.new(0,4.5,0), gray)
	View.Make("SpecialMesh", "RoundedHead", head, {MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25,1.25,1.25)})
	for _, side in {-1, 1} do
		part(model, "Arm", Vector3.new(1,2,1), CFrame.new(side * 1.52,3,0) * CFrame.Angles(0,0,math.rad(side * 7)), gray)
		part(model, "Leg", Vector3.new(1,2,1), CFrame.new(side * 0.52,1,0), gray)
	end
	return model
end

function View.Preview(name, parent, size, position)
	local viewport = View.Make("ViewportFrame", name, parent, {
		Size = size, Position = position, BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(130, 145, 167), LightColor = Color3.fromRGB(255, 246, 231), LightDirection = Vector3.new(-1,-1,2),
	})
	local world = View.Make("WorldModel", "PreviewWorld", viewport)
	local camera = View.Make("Camera", "PreviewCamera", viewport, {FieldOfView = 35})
	viewport.CurrentCamera = camera
	local current, base, rim
	local restPivot: CFrame? = nil
	local generation = 0
	local function frameModel()
		if not current then return end
		local _, bounds = current:GetBoundingBox()
		local height = bounds.Y + 0.6
		local aspect = math.max(0.5, viewport.AbsoluteSize.X / math.max(1, viewport.AbsoluteSize.Y))
		-- Far and low enough that the pedestal's front edge stays inside the frame (the camera looks down).
		local distance = math.max(height, math.max(bounds.X, 5.2) / aspect) / (2 * math.tan(math.rad(17.5))) * 1.32
		local target = Vector3.new(0, height * 0.39, 0)
		camera.CFrame = CFrame.lookAt(target + Vector3.new(distance * 0.25, distance * 0.12, -distance), target)
	end
	local function setModel(model)
		if current then current:Destroy() end
		if base then base:Destroy(); rim:Destroy() end
		current = model
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then item.Anchored, item.CanCollide = true, false end
			if item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
		end
		model.Parent = world
		-- Viewport worlds do not solve anchored avatar joints; place welded accessories before framing.
		for _, joint in model:GetDescendants() do
			if joint:IsA("Weld") and joint.Part0 and joint.Part1 and joint.Part0:FindFirstAncestorOfClass("Accessory") then
				joint.Part0.CFrame = joint.Part1.CFrame * joint.C1 * joint.C0:Inverse()
			end
		end
		local cf, bounds = model:GetBoundingBox()
		model:PivotTo(CFrame.new(-cf.Position.X, bounds.Y / 2 - cf.Position.Y + 0.25, -cf.Position.Z) * model:GetPivot())
		restPivot = model:GetPivot()
		base = part(world, "Platform", Vector3.new(0.32,5.2,5.2), CFrame.new(0,0,0) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(18, 35, 57))
		base.Shape = Enum.PartType.Cylinder
		rim = part(world, "CyanRim", Vector3.new(0.07,5.3,5.3), CFrame.new(0,0.17,0) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(67, 218, 255))
		rim.Shape = Enum.PartType.Cylinder
		local top = part(model, "PlatformTop", Vector3.new(0.09,5.08,5.08), CFrame.new(0,0.22,0) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(18, 35, 57))
		top.Shape = Enum.PartType.Cylinder
		frameModel()
	end
	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(frameModel)
	setModel(View.Dummy())
	return {frame = viewport, SetModel = setModel,
	-- Slow turn to either side so the racer shows its sides while you pick colours.
	Sway = function(time: number)
		if current and restPivot then current:PivotTo(restPivot * CFrame.Angles(0, math.sin(time * 0.7) * 0.45, 0)) end
	end,
	SetDescription = function(description)
		description.UseAvatarSettings = true
		generation += 1
		local token = generation
		task.spawn(function()
			local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15) end)
			description:Destroy()
			if ok then
				if token == generation and viewport.Parent then setModel(model) else model:Destroy() end
			end
		end)
	end}
end

return View
