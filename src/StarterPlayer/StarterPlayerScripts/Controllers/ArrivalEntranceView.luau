--!strict
local Players = game:GetService("Players")
local View = require(script.Parent.ArrivalView)
local EntranceView = {}

function EntranceView.Create(gui, sourceTitle)
	local root = View.Make("Frame", "LobbyEntrance", gui, {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Active=true, Visible=false, ZIndex=40})
	local curtain = View.Make("Frame", "Curtain", root, {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(1,3,9), BorderSizePixel=0})
	local top = View.Make("Frame", "UpperReveal", root, {Size=UDim2.fromScale(1,.5), BackgroundColor3=Color3.fromRGB(1,3,9), BorderSizePixel=0})
	local bottom = View.Make("Frame", "LowerReveal", root, {Size=UDim2.fromScale(1,.5), Position=UDim2.fromScale(0,1), AnchorPoint=Vector2.new(0,1), BackgroundColor3=Color3.fromRGB(1,3,9), BorderSizePixel=0})
	local halo, haloLayers = View.Glow(root, "EmblemGlow", View.Cyan, UDim2.fromScale(.5,.37), UDim2.fromScale(.3,.3), .09)
	View.Make("UIAspectRatioConstraint", "Square", halo, {DominantAxis=Enum.DominantAxis.Height})
	-- The transition drives ImageTransparency; the name is kept for the Studio title test.
	local mark = View.Make("ImageLabel", "ElevationEmblem", root, {Image=View.StarCoin, Size=UDim2.fromScale(.16,.16), Position=UDim2.fromScale(.5,.37),
		AnchorPoint=Vector2.new(.5,.5), BackgroundTransparency=1, ScaleType=Enum.ScaleType.Fit})
	View.Make("UIAspectRatioConstraint", "Square", mark, {DominantAxis=Enum.DominantAxis.Height})
	local pop = View.Make("UIScale", "Pop", mark)
	mark:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
		local shown = 1-mark.ImageTransparency
		local player = Players.LocalPlayer
		local reduced = player ~= nil and player:GetAttribute("ReducedMotion") == true
		for _, layer in haloLayers do layer.BackgroundTransparency = 1-.09*shown end
		pop.Scale = if reduced then 1 else .72+.28*math.sin(shown*math.pi/2)
	end)
	local title = View.Text("Title", root, sourceTitle.Text, UDim2.fromScale(.84,.09), UDim2.fromScale(.08,.48))
	title.RichText = true
	title.Font, title.TextColor3, title.TextLimit.MaxTextSize = Enum.Font.GothamBlack, View.Ivory, 46
	title.TextStrokeColor3, title.TextStrokeTransparency = Color3.fromRGB(8,20,32), .65
	local underline = View.Make("Frame", "Underline", title, {Size=UDim2.new(.36,0,0,2), Position=UDim2.new(.5,0,1,6), AnchorPoint=Vector2.new(.5,0),
		BackgroundColor3=View.Cyan, BorderSizePixel=0})
	View.Make("UIGradient", "Fade", underline, {Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(.5,0), NumberSequenceKeypoint.new(1,1)})})
	title:GetPropertyChangedSignal("TextTransparency"):Connect(function() underline.BackgroundTransparency = title.TextTransparency end)
	local loading = View.Text("Loading", root, "", UDim2.new(.8,0,0,42), UDim2.fromScale(.5,.7))
	loading.AnchorPoint = Vector2.new(.5,0)
	loading.BackgroundColor3, loading.BackgroundTransparency = Color3.fromRGB(10,16,34), .12
	loading.Font, loading.TextColor3 = Enum.Font.GothamBold, Color3.fromRGB(221,232,255)
	View.Make("UISizeConstraint", "Bounds", loading, {MaxSize=Vector2.new(380,42)})
	View.Make("UICorner", "Corners", loading, {CornerRadius=UDim.new(.5,0)})
	View.Make("UIStroke", "Edge", loading, {Color=View.Cyan, Transparency=.55, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	loading.TextLimit.MaxTextSize = 15
	local retry = View.Button("Retry", root, "Retry", UDim2.fromOffset(160,46), UDim2.new(.5,-80,.77,0))
	retry.Font, retry.Corners.CornerRadius = Enum.Font.GothamBlack, UDim.new(.5,0)
	retry.Visible = false
	return {
		Root = root,
		Curtain = curtain,
		Top = top,
		Bottom = bottom,
		Mark = mark,
		Pieces = {},
		Title = title,
		Loading = loading,
		Retry = retry,
	}
end

return EntranceView
