-- Call the returned check with the tools/ui-preview Preview module in Studio Edit mode.
return function(Preview)
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Edit mode only")
	local Lighting, StarterGui = game:GetService("Lighting"), game:GetService("StarterGui")
	local before = {
		workspaceCount=#workspace:GetDescendants(), starterCount=#StarterGui:GetChildren(),
		remotesCount=#game.ReplicatedStorage.Remotes:GetChildren(), soundsCount=#game.SoundService:GetChildren(),
		shadows=Lighting.GlobalShadows, brightness=Lighting.Brightness, ambient=Lighting.Ambient,
		camera=workspace.CurrentCamera, frame=workspace.CurrentCamera.CFrame,
	}
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset = "ClassicElevationUIPreviewChecks", true
	gui.Parent = game:GetService("CoreGui")
	local host = Instance.new("Frame")
	host.Size, host.Position = UDim2.fromOffset(1500,980), UDim2.fromOffset(-10000,-10000)
	host.Parent = gui
	local preview = Preview.Create(host)
	local checks = {}
	local function check(name, value) assert(value,name); table.insert(checks,name) end
	local function waitLayout() task.wait(.12) end
	local function contained(item, bounds)
		local p, s = item.AbsolutePosition-bounds.AbsolutePosition, item.AbsoluteSize
		return p.X >= -1 and p.Y >= -1 and p.X+s.X <= bounds.AbsoluteSize.X+1 and p.Y+s.Y <= bounds.AbsoluteSize.Y+1
	end
	local ok, failure = pcall(function()
		preview.SetDevice(2)
		waitLayout()
		for _, device in {2,3,4} do
			preview.SetDevice(device)
			preview.Select("Choose look")
			waitLayout()
			local ui = preview.CurrentScreen()
			check("chooser dock contained " .. device,contained(ui.Dock,ui.Backdrop))
			check("chooser header contained " .. device,contained(ui.Brand,ui.Backdrop))
			check("chooser touch targets " .. device,ui.Create.AbsoluteSize.Y >= 44 and ui.UseAvatar.AbsoluteSize.Y >= 44)
			ui.Highlight(1)
			check("pressed choice " .. device,ui.Create:GetAttribute("Pressed") and not ui.UseAvatar:GetAttribute("Pressed"))
			check("floor focus " .. device,ui.Stage.frame.StageWorld.SharedPlatform.SelectionLight1.Transparency < .5)
			preview.Select("Creator")
			waitLayout()
			ui = preview.CurrentScreen()
			check("creator visible " .. device,ui.Editor.Visible and not ui.Choice.Visible)
			check("creator options contained " .. device,contained(ui.Options,ui.Backdrop))
			check("creator save contained " .. device,contained(ui.Save,ui.Options))
			ui.SetLook({hair=1,skin=3,top=5,legs=2})
			check("creator edits temporary look " .. device,ui.Look.skin==3 and ui.Look.top==5 and ui.Look.legs==2)
		end
		preview.SetDevice(2)
		preview.Select("Choose look")
		waitLayout()
		local ui = preview.CurrentScreen()
		local torso = ui.Stage.frame.StageWorld.BlankRacer.Torso
		ui.Highlight(1)
		local beforePose = torso.CFrame
		task.wait(.6)
		check("preview animates",torso.CFrame~=beforePose)
		ui.Stage.SetMotion(false)
		local still = torso.CFrame
		task.wait(.2)
		check("motion preference stops animation",torso.CFrame==still)
		for _, name in {"Confirm avatar","Confirm racer","Save error","Load error","Title / loading","Lobby","Reference HUD","Records","Settings","Shop","Quests","Race options","Waiting","Not queued"} do
			preview.Select(name)
			waitLayout()
			local content = preview.Canvas.Content
			check(name .. " renders",content~=nil and preview.Canvas:FindFirstChild("PreviewError")==nil)
			ui = preview.CurrentScreen()
			if name=="Confirm avatar" then
				check("confirmation uses current copy",ui.Backdrop.ArrivalDialog.Panel.Message.Text=="Ready to join with this look?")
				check("confirmation is open",ui.Dialog.IsOpen())
			elseif name=="Confirm racer" or name=="Save error" then check(name .. " dialog open",ui.Dialog.IsOpen())
			elseif name=="Load error" then check("load retry visible",ui.Retry.Visible and not ui.Choice.Visible)
			elseif name=="Title / loading" then
				check("entrance logo shared with game",#content.LobbyEntrance.ElevationEmblem.EmblemWorld:GetChildren()==6)
			elseif name=="Records" then check("record samples render",content.LobbyUI.SafeArea.Dialog.Records:FindFirstChild("Result2")~=nil)
			elseif name=="Settings" then
				check("settings panel open",content.LobbyUI.SafeArea.Dialog.Settings.Visible)
			elseif name=="Lobby" then
				check("racer preview action enabled",content.LobbyUI.SafeArea.Menu.MyRacer:GetAttribute("Available"))
			elseif name=="Reference HUD" then
				local sample=content.LobbyUI.SafeArea
				check("reference samples are isolated",sample.Currencies.Gold.Balance.Text=="0" and sample.Currencies.Keys.Balance.Text=="—" and sample.Phase.Capsule.Timer.Text=="00:18")
			elseif name=="Not queued" then
				check("preview does not promise eligibility",content.LobbyUI.SafeArea.RaceStack.NextRace.StatusPlate.Status.Text=="Not queued yet")
			elseif name=="Race options" then
				check("preview late actions visible",content.LobbyUI.SafeArea.Dialog.Body.RaceLate.Visible)
			end
		end
		for _, size in {Vector2.new(375,700),Vector2.new(667,320),Vector2.new(1360,779)} do
			preview.SetDevice(1)
			preview.Select("Not queued")
			preview.Canvas.Size=UDim2.fromOffset(size.X,size.Y)
			waitLayout()
			local bounds=preview.Canvas.Content.LobbyUI.SafeArea
			for _, item in {bounds.Menu,bounds.Currencies,bounds.RaceStack.NextRace,bounds.RaceStack.QuestTicket} do
				check(item.Name .. " contained " .. tostring(size),contained(item,bounds))
			end
			local labelsClear = true
			for _, button in bounds.Menu:GetChildren() do
				if button:IsA("TextButton") then
					local label=button.Label
					labelsClear = labelsClear and label.TextFits and contained(label,button)
				end
			end
			check("menu labels clear outline "..tostring(size),labelsClear)
			local dialog=bounds.Dialog
			check("currency captions readable "..tostring(size),bounds.Currencies.Gold.Caption.TextFits and bounds.Currencies.Keys.Caption.TextFits)
			local race=bounds.RaceStack.NextRace
			check("race labels readable "..tostring(size),race.Heading.TextFits and bounds.Phase.Capsule.Timer.TextFits and race.StatusPlate.Status.TextFits and race.RaceOptions.Title.TextFits)
			check("quest uses a native rounded strip "..tostring(size),bounds.RaceStack.QuestTicket:FindFirstChild("Outline")~=nil and bounds.RaceStack.QuestTicket:FindFirstChild("TicketArtwork")==nil)
		end
		preview.Select("Choose look")
		local old = preview.CurrentScreen().Backdrop
		preview.Refresh()
		check("refresh replaces previous UI",old.Parent==nil and preview.CurrentScreen().Backdrop~=old)
		preview.SetVisible(false)
		check("closing clears the canvas",preview.Canvas:FindFirstChild("Content")==nil and preview.CurrentScreen()==nil)
		preview.SetVisible(true)
		check("reopening rebuilds the canvas",preview.CurrentScreen()~=nil)
		check("no world changes",#workspace:GetDescendants()==before.workspaceCount)
		check("no shipped preview GUI",#StarterGui:GetChildren()==before.starterCount)
		check("no networking changes",#game.ReplicatedStorage.Remotes:GetChildren()==before.remotesCount)
		check("no preview audio",#game.SoundService:GetChildren()==before.soundsCount)
		check("lighting unchanged",Lighting.GlobalShadows==before.shadows and Lighting.Brightness==before.brightness and Lighting.Ambient==before.ambient)
		check("camera unchanged",workspace.CurrentCamera==before.camera and workspace.CurrentCamera.CFrame==before.frame)
	end)
	preview.Destroy()
	gui:Destroy()
	assert(ok,failure)
	return {passed=#checks,checks=checks}
end
