--!strict
local RunService = game:GetService("RunService")
local Loader = require(script.Parent.SourceLoader)
local RacePreview = require(script.Parent.RacePreview)
local Preview = {}

local screenNames = {"Choose look", "Creator", "Confirm avatar", "Confirm racer", "Save error", "Load error", "Title / loading", "Lobby", "Reference HUD", "Records", "Settings", "Shop", "Quests", "Race options", "Waiting", "Not queued"}
for _, name in RacePreview.Screens do table.insert(screenNames, name) end
local devices = {
	{name = "Fit"},
	{name = "Desktop", size = Vector2.new(1360,779)},
	{name = "Phone", size = Vector2.new(375,700)},
	{name = "Wide phone", size = Vector2.new(667,375)},
	{name = "Phone 844", size = Vector2.new(844,390)},
}

local function frame(class, name, parent, properties)
	local item = Instance.new(class)
	item.Name = name
	for key, value in properties do item[key] = value end
	item.Parent = parent
	return item
end

local function label(name, parent, text, size, position)
	return frame("TextLabel", name, parent, {Text=text, Size=size, Position=position,
		BackgroundTransparency=1, TextColor3=Color3.fromRGB(218,225,236), TextSize=14,
		Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left})
end

function Preview.Create(parent)
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Open UI Preview in Edit mode")
	local root = frame("Frame", "UIPreview", parent, {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(23,26,32), BorderSizePixel=0})
	local controls = frame("ScrollingFrame", "Screens", root, {Size=UDim2.new(1,-20,0,42), Position=UDim2.fromOffset(10,8),
		BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollingDirection=Enum.ScrollingDirection.X,
		CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.X})
	frame("UIListLayout", "Layout", controls, {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
	local deviceBar = frame("Frame", "Devices", root, {Size=UDim2.new(1,-20,0,34), Position=UDim2.fromOffset(10,54), BackgroundTransparency=1})
	frame("UIListLayout", "Layout", deviceBar, {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
	local status = label("Status",root,"",UDim2.new(1,-20,0,22),UDim2.new(0,10,1,-27))
	status.TextTruncate = Enum.TextTruncate.AtEnd
	local area = frame("ScrollingFrame", "CanvasArea", root, {Size=UDim2.new(1,-20,1,-127), Position=UDim2.fromOffset(10,95),
		BackgroundColor3=Color3.fromRGB(12,15,20), BorderSizePixel=0, ScrollBarThickness=6, CanvasSize=UDim2.new()})
	local canvas = frame("Frame", "Canvas", area, {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(33,41,55), BorderSizePixel=0, ClipsDescendants=true})
	local selection, deviceIndex, visible = "Choose look", 1, true
	local modules, content, screen, reducedMotion, largeText = nil, nil, nil, false, false
	local savedLook = nil
	local sourceButtons, deviceButtons = {}, {}
	local render
	local function button(name, parent, text, width, action)
		local item = frame("TextButton",name,parent,{Text=text, Size=UDim2.fromOffset(width,30), Font=Enum.Font.GothamMedium,
			TextSize=13, TextColor3=Color3.fromRGB(230,235,243), BackgroundColor3=Color3.fromRGB(46,54,67), BorderSizePixel=0})
		frame("UICorner","Corners",item,{CornerRadius=UDim.new(0,6)})
		item.Activated:Connect(action)
		return item
	end
	local function highlightButtons()
		for name, item in sourceButtons do item.BackgroundColor3 = if name == selection then Color3.fromRGB(30,96,130) else Color3.fromRGB(46,54,67) end
		for index, item in deviceButtons do item.BackgroundColor3 = if index == deviceIndex then Color3.fromRGB(30,96,130) else Color3.fromRGB(46,54,67) end
	end
	local function layout()
		local size = devices[deviceIndex].size or area.AbsoluteSize
		canvas.Size = UDim2.fromOffset(size.X,size.Y)
		canvas.Position = UDim2.fromOffset(math.max(0,(area.AbsoluteSize.X-size.X)/2),math.max(0,(area.AbsoluteSize.Y-size.Y)/2))
		area.CanvasSize = UDim2.fromOffset(math.max(size.X,area.AbsoluteSize.X),math.max(size.Y,area.AbsoluteSize.Y))
		status.Text = selection .. " · " .. math.floor(size.X) .. " × " .. math.floor(size.Y) .. " · Edit preview"
	end
	local function clear()
		screen = nil
		if content then content:Destroy(); content = nil end
		if modules then modules.Destroy(); modules = nil end
	end
	local function choose(name)
		selection = name
		render()
	end
	render = function()
		clear()
		highlightButtons()
		layout()
		if not visible then return end
		local ok, reason = pcall(function()
			modules = Loader.Load()
			content = frame("Frame","Content",canvas,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
			if table.find(RacePreview.Screens, selection) then
				RacePreview.Render(selection, content, modules, largeText)
				return
			end
			if table.find({"Lobby","Reference HUD","Records","Settings","Shop","Quests","Race options","Waiting","Not queued"},selection) then
				local lobby = modules.Lobby
				local sample
				lobby.InitPreview(content,{
					MyRacer=function() choose("Choose look") end,
					Spectate=function() sample.Dialog.Body.Message.Text="Spectating · Edit preview" end,
					RaceLate=function() sample.Dialog.Body.Message.Text="Late run · Edit preview" end,
				})
				sample = content.LobbyUI.SafeArea
				lobby.SetPreviewBalance(nil)
				lobby.Update("Intermission","Queued",27,"Shipwreck Cove","LapBased",false,30)
				if selection == "Lobby" then lobby.Update("WaitingForPlayers","Lobby",nil,"Shipwreck Cove","LapBased") end
				if selection == "Reference HUD" then lobby.SetReferencePreview() end
				if selection == "Records" then
					lobby.UpdateRecords({courseDisplayName="Shipwreck Cove",placements={
						{placement=1,displayName="Racer One",finishTime=92.47,official=true},
						{placement=2,displayName="Racer Two",finishTime=99.16,official=true},
					}})
					lobby.ToggleRecords()
				elseif selection == "Settings" then lobby.ToggleSettings()
				elseif selection == "Shop" then lobby.ToggleShop()
				elseif selection == "Quests" then lobby.ToggleQuests()
				elseif selection == "Race options" then
					lobby.Update("Racing","Lobby",80,"Shipwreck Cove","LapBased")
					lobby.ToggleRaceOptions()
				elseif selection == "Waiting" then lobby.Update("WaitingForPlayers","Lobby",nil,"-")
				elseif selection == "Not queued" then lobby.Update("Intermission","Lobby",27,"Shipwreck Cove","LapBased")
				end
				return
			end
			screen = modules.Screen.Create(content, true)
			local ui, config = screen, modules.Config
			ui.Reopen.Visible, ui.Status.Text = false, ""
			ui.Reward.Text = "+" .. config.CreationBonus .. " coins"
			local description = modules.Appearance.Description({hair=1,skin=1,top=3,legs=2})
			ui.Stage.SetDescription(description)
			ui.Stage.SetMotion(not reducedMotion)
			ui.Dialog.SetMotion(not reducedMotion)
			ui.MotionButton.Text = if reducedMotion then "Motion off" else "Motion on"
			ui.MotionButton.Activated:Connect(function()
				reducedMotion = not reducedMotion
				ui.MotionButton.Text = if reducedMotion then "Motion off" else "Motion on"
				ui.Stage.SetMotion(not reducedMotion)
				ui.Dialog.SetMotion(not reducedMotion)
			end)
			ui.SoundButton.Activated:Connect(function() ui.SoundButton.Text = if ui.SoundButton.Text == "Sound on" then "Sound off" else "Sound on" end)
			local function creator()
				ui.Dialog.Close()
				ui.Choice.Visible, ui.Editor.Visible, ui.Brand.Visible = false, true, false
				ui.SetLook(savedLook or config.DefaultLook)
			end
			local function confirmAvatar()
				ui.Highlight(2)
				ui.Dialog.Show("Ready to join with this look?","Let’s play →","Go back",function() choose("Title / loading") end)
			end
			local function confirmRacer()
				creator()
				ui.Dialog.Show("Save your racer and head to the lobby?","Save & play →","Keep editing",function() savedLook=table.clone(ui.Look); choose("Title / loading") end)
			end
			ui.Create.Activated:Connect(creator)
			ui.Stage.HitTargets[1].Activated:Connect(creator)
			ui.UseAvatar.Activated:Connect(confirmAvatar)
			ui.Stage.HitTargets[2].Activated:Connect(confirmAvatar)
			ui.Save.Activated:Connect(confirmRacer)
			ui.Back.Activated:Connect(function() savedLook=table.clone(ui.Look); choose("Choose look") end)
			ui.Retry.Activated:Connect(function() choose("Choose look") end)
			if selection == "Creator" then creator()
			elseif selection == "Confirm avatar" then confirmAvatar()
			elseif selection == "Confirm racer" then confirmRacer()
			elseif selection == "Save error" then
				creator()
				ui.Dialog.Show("Could not save. Your choice is still here — try again.","Retry save →","Back",function() savedLook=table.clone(ui.Look); choose("Confirm racer") end,true)
			elseif selection == "Load error" then
				ui.Choice.Visible, ui.Retry.Visible = false, true
				ui.Status.Text = "Could not load your profile. Please retry."
			elseif selection == "Title / loading" then
				ui.Backdrop.Visible = false
				local title = modules.Entrance.Create(content,ui.Brand)
				title.Root.Visible = true
				title.Top.Visible, title.Bottom.Visible = false, false
				title.Loading.Visible, title.Loading.Text = true, "Loading…"
				title.Retry.Visible = false
			end
		end)
		if not ok then
			clear()
			content = label("PreviewError",canvas,tostring(reason),UDim2.new(1,-40,1,-40),UDim2.fromOffset(20,20))
			content.TextWrapped = true
			status.Text = "Preview unavailable · sync this project's source, then Refresh"
			warn("[UI Preview] " .. tostring(reason))
		end
	end
	for index, name in screenNames do
		local item = button("Screen" .. index,controls,name,math.max(84,#name*8+20),function() choose(name) end)
		item.LayoutOrder, sourceButtons[name] = index, item
	end
	for index, device in devices do
		local item = button("Device" .. index,deviceBar,device.name,if index >= 4 then 108 else 84,function() deviceIndex=index; area.CanvasPosition=Vector2.zero; highlightButtons(); layout() end)
		item.LayoutOrder, deviceButtons[index] = index, item
	end
	local refresh = button("Refresh",deviceBar,"Refresh",84,render)
	refresh.LayoutOrder = 10
	local larger
	larger = button("LargerText",deviceBar,"Text: Standard",120,function()
		largeText = not largeText
		larger.Text = if largeText then "Text: Larger" else "Text: Standard"
		render()
	end)
	larger.LayoutOrder = 11
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		if screen and visible then screen.Update(dt,reducedMotion) end
	end)
	area:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	root.Destroying:Connect(function() heartbeat:Disconnect(); clear() end)
	render()
	return {
		Root=root, Canvas=canvas, Select=choose, Refresh=render,
		SetDevice=function(index) assert(devices[index],"Unknown preview device"); deviceIndex=index; highlightButtons(); layout() end,
		SetLargeText=function(value) largeText=value; render() end,
		SetVisible=function(value) visible=value; root.Visible=value; if value then render() else clear() end end,
		CurrentScreen=function() return screen end,
		Destroy=function() root:Destroy() end,
	}
end

return Preview
