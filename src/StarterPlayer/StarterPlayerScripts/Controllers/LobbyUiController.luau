--!strict

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Theme = require(script.Parent.UiTheme)
local View = require(script.Parent.LobbyView)
local Presentation = require(script.Parent.LobbyPresentation)
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local Artwork = require(ReplicatedStorage.Config.VotingArtwork)
local RacePresentation = require(script.Parent.RacePresentation)
local Icons = require(script.Parent.LobbyIcons)
local Kit = require(script.Parent.UiKit)
local PortalMarker = require(script.Parent.PortalMarker)
local ShopView = require(script.Parent.ShopView)

local LobbyUi = {}
local gui: (ScreenGui | Frame)? = nil
local ui: any = nil
local player: Player? = nil
local previewMode, largeText = false,false
local actions: any = {}
local connections: {RBXScriptConnection} = {}
local panelName: string? = nil
local lastFocus: GuiObject? = nil
local latestRows: {any} = {}
local latestCourse = ""
local balance: any = nil
local latest: any = {state=nil,status="Lobby",remaining=nil,course="-",format=nil,pending=false}
local presentation: any = nil
local flowState: any = nil
local eventState: any = nil
local raceRacers: {[string]: number} = {}
local toastedRaces: {[string]: boolean} = {}
local navigationAction = "ClassicElevationLobbyNavigation"
local arriving,revealAt,revealMotion = false,nil,true

local function enabled(): boolean
	return gui ~= nil and (if gui:IsA("ScreenGui") then gui.Enabled else gui.Visible)
end

local function setEnabled(value: boolean)
	if not gui then return end
	if gui:IsA("ScreenGui") then gui.Enabled=value else gui.Visible=value end
end

local function ready(): boolean
	return previewMode or (player ~= nil and player:GetAttribute("TournamentPresentation") ~= true and player:GetAttribute("OnboardingReady") == true
		and player:GetAttribute("ArrivalPhase") == "Ready" and (player:GetAttribute("ArrivalOpen") ~= true or revealAt ~= nil))
end

local function textSizes()
	if not gui then return end
	for _, item in gui:GetDescendants() do
		local base = item:GetAttribute("BaseTextSize")
		if typeof(base) == "number" and (item:IsA("TextLabel") or item:IsA("TextButton")) then
			item.TextSize = base * (if largeText then 1.15 else 1)
		end
	end
	if ui then ui.FitCourse(ui.Labels.Course.TextSize) end
end

local function updateSelection()
	for _, name in {"Shop","MyRacer","Records","Settings","Go","RaceOptions","Second","Quests","Gold","Keys","KeysPlus"} do
		ui.Buttons[name].Selectable = ui.InputReady and panelName == nil and ui.Buttons[name].Visible and ui.Buttons[name]:GetAttribute("Available") ~= false
	end
end

local function applyReveal()
	if not ui then return end
	ui.InputReady = not arriving
	if arriving then ui.Reveal.Apply(if revealAt then os.clock()-revealAt else 0,revealMotion) end
	ui.Root:SetAttribute("InputReady",ui.InputReady)
	updateSelection()
end

function LobbyUi.ClosePanel()
	panelName = nil
	if not ui then return end
	ui.Dialog.Visible,ui.Shade.Visible = false,false
	ShopView.Close(ui.Shop)
	for _, name in {"Shop","MyRacer","Records","Settings","RaceOptions","Quests","Gold","Keys"} do Theme.SetSelected(ui.Buttons[name],false) end
	if not previewMode and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(ui.Dialog) then
		GuiService.SelectedObject = if lastFocus and lastFocus.Parent and enabled() then lastFocus else nil
	end
	lastFocus = nil
	updateSelection()
end

local function renderPanel()
	if not ui or not panelName then return end
	Kit.SetBig(ui.ModalTitleBig, if panelName == "RaceOptions" then "Race options" elseif panelName == "Gold" then "Coins" elseif panelName == "MyRacer" then "My racer" else panelName)
	ui.Labels.ModalNote.Text = if panelName == "Records" then "Session finishes" elseif panelName == "Settings" then "On this device · this session" else ""
	ui.Records.Visible,ui.Settings.Visible = panelName == "Records",panelName == "Settings"
	-- Records stops at 495 so a long list's visible edge falls in the gap between rows 6 and 7
	-- (rows sit every 56 px) instead of showing a sliver of the next row; the rest scrolls.
	View.SizeDialog(ui,if panelName == "Settings" then 384 elseif panelName == "Records" then (if #latestRows == 0 then 330 else math.min(495,170+#latestRows*56)) elseif panelName == "Gold" then 346 else 320)
	if player then
		Kit.SetButtonText(ui.Buttons.Sound, if player:GetAttribute("SoundMuted") == true then "Off" else "On")
		Kit.SetButtonText(ui.Buttons.Motion, if player:GetAttribute("ReducedMotion") == true then "Reduced" else "Full")
	end
	ui.Wallet.Visible = panelName == "Gold"
	ui.Body.Visible = not ui.Records.Visible and not ui.Settings.Visible and not ui.Wallet.Visible
	local canChoose = presentation and presentation.canChoose and not latest.pending
	ui.Buttons.Spectate.Visible,ui.Buttons.RaceLate.Visible = panelName == "RaceOptions" and canChoose,panelName == "RaceOptions" and canChoose
	if panelName == "Shop" then ui.Labels.Body.Text = "The shop isn't available yet."
	elseif panelName == "Quests" then ui.Labels.Body.Text = "No quests yet."
	elseif panelName == "Keys" then ui.Labels.Body.Text = "Keys aren't available yet."
	elseif panelName == "Gold" then
		Kit.SetBig(ui.WalletAmount, if balance == nil then "–" else Presentation.Balance(balance))
		ui.Labels.ModalNote.Text = if balance == nil then "Balance unavailable right now" else "Your coin balance"
	elseif panelName == "RaceOptions" and presentation then
		ui.Labels.Body.Text = if latest.pending then "Waiting for the server…" else presentation.options
	end
	updateSelection()
end

local function showPanel(name: string)
	if not enabled() or not ui.InputReady then return end
	if panelName == name then LobbyUi.ClosePanel(); return end
	local opening = panelName == nil
	panelName = name
	ui.Dialog.Visible,ui.Shade.Visible = name ~= "Shop",true
	-- The dialog rises into place when it opens (its UIScale is the layout scale, so it slides instead of popping).
	if opening and name ~= "Shop" and Kit.Motion() then
		ui.Dialog.Position = UDim2.new(.5,0,.5,36)
		Kit.Tween(ui.Dialog,.42,{Position = UDim2.fromScale(.5,.5)},"Pop")
		Kit.Play("Whoosh")
	end
	if name == "Shop" then ShopView.Open(ui.Shop) else ShopView.Close(ui.Shop) end
	for _, key in {"Shop","Records","Settings","RaceOptions","Quests","Gold","Keys"} do Theme.SetSelected(ui.Buttons[key],key==name) end
	renderPanel()
	if name == "Gold" then Kit.Punch(ui.WalletCoin,.6,.45) end
	if opening and not previewMode then
		lastFocus = GuiService.SelectedObject
		if UserInputService.GamepadEnabled or lastFocus then GuiService.SelectedObject = if name == "Shop" then ui.Buttons.ShopClose else ui.Buttons.Close end
	end
end

function LobbyUi.ToggleRecords() showPanel("Records") end
function LobbyUi.ToggleSettings() showPanel("Settings") end
-- `tab` ("Keys" or "Styles") lets previews open a given tab; buttons call it without one.
function LobbyUi.ToggleShop(tab: string?)
	if tab and ui then ui.Shop.tab = tab end
	showPanel("Shop")
end
function LobbyUi.ToggleCoins() showPanel("Gold") end
function LobbyUi.ToggleQuests() showPanel("Quests") end
function LobbyUi.ToggleRaceOptions() showPanel("RaceOptions") end

function LobbyUi.ToggleLargeText()
	largeText = not largeText
	-- Race screens and the finish ticket scale up from this local setting too.
	if player and not previewMode then player:SetAttribute("LargeText", largeText) end
	Kit.SetButtonText(ui.Buttons.TextSize, if largeText then "Larger" else "Standard")
	ui.Reveal.Restore()
	View.Resize(ui); textSizes(); ui.PlaceFormat()
	if presentation then View.SetRaceMood(ui,presentation.timed,presentation.queued) end
	ui.Reveal.Capture(); applyReveal()
end

-- Sound and motion are the same local settings the arrival screen and race screens read.
function LobbyUi.ToggleSound()
	if not player or previewMode then return end
	player:SetAttribute("SoundMuted", player:GetAttribute("SoundMuted") ~= true)
	renderPanel()
end

function LobbyUi.ToggleMotion()
	if not player or previewMode then return end
	player:SetAttribute("ReducedMotion", player:GetAttribute("ReducedMotion") ~= true)
	renderPanel()
end

function LobbyUi.ToggleShadows()
	if previewMode then
		ui.PreviewShadows = not ui.PreviewShadows
		Kit.SetButtonText(ui.Buttons.Shadows, if ui.PreviewShadows then "On" else "Off")
		return
	end
	Lighting.GlobalShadows = not Lighting.GlobalShadows
	Kit.SetButtonText(ui.Buttons.Shadows, if Lighting.GlobalShadows then "On" else "Off")
end

local function renderRecords()
	if not ui then return end
	for _, item in ui.Records:GetChildren() do if item:IsA("GuiObject") then item:Destroy() end end
	if #latestRows == 0 then
		local holder = Kit.Frame(ui.Records,"EmptyState",UDim2.new(1,-12,0,170),UDim2.new())
		holder.LayoutOrder = 1
		local trophy = Icons.Create(holder,"Records",UDim2.new(.5,-36,0,4),72)
		trophy.Name = "Trophy"
		local empty = Kit.SkyBig(holder,"Empty","NO FINISHES YET",28)
		empty.Position,empty.Size = UDim2.fromOffset(0,86),UDim2.new(1,0,0,30)
		local hint = Kit.Body(holder,"Hint","Finish a race this visit to see the top times here.",17,Kit.White)
		hint.Position,hint.Size,hint.TextWrapped = UDim2.fromOffset(0,124),UDim2.new(1,0,0,40),true
	else
		local course = Kit.Caption(ui.Records,"Course",latestCourse,15,Kit.White)
		course.Size,course.LayoutOrder,course.TextXAlignment = UDim2.new(1,-12,0,22),0,Enum.TextXAlignment.Left
		for i, result in latestRows do
			local row = Kit.SkyPlate(ui.Records,"Result"..i,UDim2.new(1,-16,0,48),UDim2.new(),{fill=if i==1 then "Hero" else "White",class="S"})
			row.LayoutOrder = i
			local content = Kit.Content(row)
			local place = Kit.SkyBig(content,"Place",tostring(result.placement),24)
			place.Position,place.Size = UDim2.fromOffset(18,12),UDim2.fromOffset(40,24)
			local name = Kit.Body(content,"Player",result.displayName,18,Kit.Navy)
			name.Position,name.Size,name.TextXAlignment = UDim2.fromOffset(64,0),UDim2.new(1,-190,1,0),Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			local time = Kit.Body(content,"Time",RacePresentation.Clock(result.finishTime,2),18,Kit.Navy)
			time.Position,time.Size,time.TextXAlignment = UDim2.new(1,-128,0,0),UDim2.fromOffset(108,48),Enum.TextXAlignment.Right
		end
	end
	textSizes()
end

function LobbyUi.UpdateRecords(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.placements) ~= "table" then return end
	local rows = {}
	for i, result in ipairs(payload.placements) do
		if i > 20 then break end
		if typeof(result) == "table" and result.official == true and typeof(result.finishTime) == "number"
			and result.finishTime >= 0 and result.finishTime < math.huge then
			table.insert(rows,{placement=result.placement or i,displayName=tostring(result.displayName or result.name or "Player"),finishTime=result.finishTime})
		end
	end
	if typeof(payload.raceId) == "string" then
		local count = 0
		for _, key in {"activeRacers","placements","dnfs"} do
			if typeof(payload[key]) == "table" then count += #payload[key] end
		end
		raceRacers[payload.raceId] = count
		local winner = payload.placements[1]
		if ui and not previewMode and typeof(winner) == "table" and winner.official == true and not toastedRaces[payload.raceId]
			and typeof(winner.finishTime) == "number" then
			toastedRaces[payload.raceId] = true
			View.Toast(ui,tostring(winner.displayName or winner.name or "Racer"),"won "..tostring(payload.courseDisplayName or "the race"),RacePresentation.Clock(winner.finishTime,2))
		end
	end
	-- Retain the last populated race while the next race has no finishers.
	if #rows == 0 then return end
	latestRows,latestCourse = rows,tostring(payload.courseDisplayName or "Latest race")
	renderRecords()
end

local function refresh()
	if not ui then return end
	ui.Reveal.Restore()
	presentation = Presentation.Race(latest.state,latest.status,latest.remaining,
		RunService:IsStudio() and RaceConfig.StudioLobbyPreview and (latest.state==nil or latest.state=="WaitingForPlayers"),ready())
	setEnabled(presentation.visible and (not arriving or revealAt ~= nil))
	if not enabled() then
		LobbyUi.ClosePanel()
		if not previewMode and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui :: Instance) then GuiService.SelectedObject=nil end
	end
	local cardFlow = flowState or {enrolled=false,actionLabel="Start racing",courseDisplayName=if latest.course~="-" then latest.course else nil}
	local card = Presentation.Card(cardFlow,latest.state,eventState,raceRacers[tostring(flowState and flowState.raceId)])
	-- Outside an event there is no catalog to carry the picture, so use the shared course artwork.
	if #card.images == 1 and card.images[1] == "" and typeof(cardFlow.courseId) == "string" then
		local ok, image = pcall(Artwork.Image, cardFlow.courseId)
		if ok and typeof(image) == "string" then card.images[1] = image end
	end
	View.SetCard(ui,card)
	local held = RunService:IsStudio() and RaceConfig.StudioLobbyPreview and (latest.state==nil or latest.state=="WaitingForPlayers")
	local phase = Presentation.Phase(latest.state,latest.remaining,latest.duration,held)
	phase.urgent = phase.timed and typeof(latest.remaining)=="number" and latest.remaining<=5 and latest.remaining>0
	if not phase.timed and (latest.state==nil or latest.state=="WaitingForPlayers") and not held then phase.label,phase.time = "Waiting for racers","Join in" end
	View.SetPhase(ui,phase)
 if flowState and flowState.preparation and latest.state~="Countdown" and latest.state~="Racing" then
  local prep=flowState.preparation
  View.SetPhase(ui,{label="Preparing",time=if prep.status=="Failed" then "Stay in lobby" elseif prep.status=="Loading" then "Loading course" else "Next race",timed=false,fraction=nil})
 end
	Theme.SetAvailable(ui.Buttons.MyRacer,presentation.canEdit and (previewMode or actions.MyRacer ~= nil)
		and (not actions.CanEditRacer or actions.CanEditRacer()))
	-- No one owns Keys until Keys go on sale, so 0 is accurate (a dash read as unfinished).
	View.SetBalances(ui,Presentation.Balance(balance),"0")
	ui.HasQuest = false
	View.Resize(ui); textSizes(); ui.PlaceFormat()
	View.SetRaceMood(ui,presentation.timed,presentation.queued)
	-- Practice screens and the opening vote own the screen; only the wallet stays.
	View.SetPracticeMode(ui,not previewMode and player ~= nil and (player:GetAttribute("PracticeRoom") == true or player:GetAttribute("VoteOpen") == true))
	renderPanel()
	ui.Reveal.Capture(); applyReveal()
end

function LobbyUi.PrepareEntrance()
	arriving,revealAt = true,nil
	LobbyUi.ClosePanel()
	refresh()
	local assets = {}
	if ui then
		for _, item in ui.Root:GetDescendants() do
			if item:IsA("ImageLabel") and item.Image ~= "" then table.insert(assets,item) end
		end
	else for _,id in Icons.Assets do table.insert(assets,id) end end
	return assets
end

function LobbyUi.RevealEntrance(motion: boolean)
	if not arriving then return end
	revealAt,revealMotion = os.clock(),motion
	refresh()
end

function LobbyUi.EntranceSettled(): boolean
	return not arriving or (revealAt ~= nil and os.clock()-revealAt >= (if revealMotion then .48 else .18))
end

function LobbyUi.FinishEntrance()
	arriving,revealAt = false,nil
	if ui then ui.Reveal.Restore(); ui.InputReady=true end
	refresh()
end

function LobbyUi.CancelEntrance() LobbyUi.FinishEntrance() end

function LobbyUi.Update(state: string?, status: string, remaining: number?, course: string, raceFormat: string?, pending: boolean?, duration: number?)
	latest = {state=state,status=status,remaining=remaining,course=course,format=raceFormat,pending=pending==true,duration=Presentation.Duration(duration)}
	refresh()
end

function LobbyUi.UpdateFlow(snapshot: any)
 local joined = flowState~=nil and flowState.enrolled~=true and typeof(snapshot)=="table" and snapshot.enrolled==true
 flowState=snapshot
 refresh()
 if joined and ui and enabled() then View.Stamp(ui,"YOU'RE IN!") end
end
function LobbyUi.UpdateEvent(snapshot: any)
 eventState=snapshot
 refresh()
end
function LobbyUi.IsVisible(): boolean return enabled() end

function LobbyUi.SetPreviewBalance(value: any)
	assert(previewMode,"Sample balances are only allowed in Edit preview")
	balance = value
	refresh()
end

-- Edit preview only: the race-winner toast that live results raise in the lobby feed.
function LobbyUi.PreviewToast(strong: string, rest: string, dim: string?)
	assert(previewMode,"Sample toasts are only allowed in Edit preview")
	if ui then View.Toast(ui,strong,rest,dim) end
end

function LobbyUi.SetReferencePreview()
	assert(previewMode and not RunService:IsRunning(),"Reference samples are only allowed in Edit preview")
	balance = 0
	LobbyUi.Update("Intermission","Lobby",18,"Classic Point-to-Point","PointToPoint",false,24)
end

local function disconnect()
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	if not previewMode and RunService:IsRunning() then ContextActionService:UnbindAction(navigationAction) end
end

local function build(screen: ScreenGui | Frame, preview: boolean, boundActions: any?)
	disconnect()
	gui,previewMode,actions = screen,preview,boundActions or {}
	latestRows,latestCourse,balance = {},"",nil
	latest = {state=nil,status="Lobby",course="-",pending=false}
	local handlers = {
		Shop=LobbyUi.ToggleShop, MyRacer=LobbyUi.OpenRacer,
		Records=LobbyUi.ToggleRecords, Settings=LobbyUi.ToggleSettings, Quests=LobbyUi.ToggleQuests,
		RaceOptions=function() if actions.RaceOptions then actions.RaceOptions() else LobbyUi.ToggleRaceOptions() end end, Gold=function() showPanel("Gold") end, Keys=function() showPanel("Keys") end,
		Close=LobbyUi.ClosePanel, TextSize=LobbyUi.ToggleLargeText, Shadows=LobbyUi.ToggleShadows,
		Sound=function() LobbyUi.ToggleSound() end, Motion=function() LobbyUi.ToggleMotion() end,
		Spectate=function() if actions.Spectate then actions.Spectate() end end,
		RaceLate=function() if actions.RaceLate then actions.RaceLate() end end,
	}
	-- Next-race card buttons carry the action ids the card was drawn with.
	local function cardAction(slot: string)
		return function()
			local id = ui and ui.CardActions and ui.CardActions[slot]
			if id == "RaceOptions" then handlers.RaceOptionsPanel()
			elseif id and actions[id] then actions[id]() end
		end
	end
	handlers.RaceOptionsPanel = handlers.RaceOptions
	handlers.Go, handlers.RaceOptions, handlers.Second = cardAction("Go"), cardAction("RaceOptions"), cardAction("Second")
	handlers.Keys = LobbyUi.ToggleShop
	for name, callback in handlers do
		handlers[name] = function() if ui and ui.InputReady and enabled() then callback() end end
	end
	ui = View.Create(screen,handlers)
	ui.Shop = ShopView.Create(ui.Root,handlers.Close)
	ui.Buttons.ShopClose,ui.Buttons.TabKeys,ui.Buttons.TabStyles = ui.Shop.buttons.Close,ui.Shop.buttons.TabKeys,ui.Shop.buttons.TabStyles
	local function resize()
		ui.Reveal.Restore(); View.Resize(ui); textSizes(); ui.PlaceFormat()
		ShopView.Layout(ui.Shop,ui.Root.AbsoluteSize)
		if presentation then View.SetRaceMood(ui,presentation.timed,presentation.queued) end
		ui.Reveal.Capture(); applyReveal()
	end
	table.insert(connections,ui.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	if not preview then table.insert(connections,GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(resize)) end
	Kit.SetButtonText(ui.Buttons.TextSize, if largeText then "Larger" else "Standard")
	ui.PreviewShadows = true
	Kit.SetButtonText(ui.Buttons.Shadows, if previewMode or Lighting.GlobalShadows then "On" else "Off")
	LobbyUi.ClosePanel()
	renderRecords()
	resize()
	refresh()
	-- Also in previews, so a story can play the arrival fly-in (PrepareEntrance / RevealEntrance).
	table.insert(connections,RunService.RenderStepped:Connect(function() if arriving then applyReveal() end end))
	if not preview then
		ContextActionService:BindActionAtPriority(navigationAction,function(_,state,input)
			if state ~= Enum.UserInputState.Begin or not enabled() or not ui.InputReady or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			local key = input.KeyCode
			if key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB then
				if panelName then LobbyUi.ClosePanel(); return Enum.ContextActionResult.Sink end
				if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui :: Instance) then GuiService.SelectedObject=nil end
				return Enum.ContextActionResult.Pass
			end
			local selected = GuiService.SelectedObject
			if key == Enum.KeyCode.Return or key == Enum.KeyCode.Space then
				if selected and selected:IsDescendantOf(gui :: Instance) then ui.Activate(selected); return Enum.ContextActionResult.Sink end
				return Enum.ContextActionResult.Pass
			end
			if key ~= Enum.KeyCode.Tab and (not selected or not selected:IsDescendantOf(gui :: Instance)) then return Enum.ContextActionResult.Pass end
			local names = if panelName == "Settings" then {"Close","TextSize","Shadows","Sound","Motion"}
				elseif panelName == "RaceOptions" and ui.Buttons.Spectate.Visible then {"Close","Spectate","RaceLate"}
				elseif panelName == "Shop" then {"ShopClose","TabKeys","TabStyles"}
				elseif panelName then {"Close"} else {"Shop","MyRacer","Records","Settings","Gold","Keys","KeysPlus","Go","RaceOptions","Second"}
			local candidates, index = {},0
			for _, name in names do
				local button = ui.Buttons[name]
				if button.Selectable and button.Visible then
					table.insert(candidates,button)
					if button == selected then index=#candidates end
				end
			end
			local backward = key == Enum.KeyCode.Up or key == Enum.KeyCode.Left or
				(key == Enum.KeyCode.Tab and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)))
			if #candidates > 0 then
				local nextIndex = if index == 0 then (if backward then #candidates else 1) else ((index-1+(if backward then -1 else 1)) % #candidates)+1
				GuiService.SelectedObject = candidates[nextIndex]
			end
			return Enum.ContextActionResult.Sink
		end,false,3000,Enum.KeyCode.Tab,Enum.KeyCode.Escape,Enum.KeyCode.ButtonB,Enum.KeyCode.Return,Enum.KeyCode.Space,
			Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right)
	end
	screen.Destroying:Connect(function()
		if gui ~= screen then return end
		LobbyUi.ClosePanel()
		disconnect()
		gui,ui,player = nil,nil,nil
	end)
end

function LobbyUi.Init(localPlayer: Player, boundActions: any?)
	player = localPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("LobbyUI")
	if old then old:Destroy() end
	player = localPlayer
	local screen = Instance.new("ScreenGui")
	screen.Name,screen.ResetOnSpawn,screen.DisplayOrder = "LobbyUI",false,20
	screen.ScreenInsets,screen.ZIndexBehavior = Enum.ScreenInsets.None,Enum.ZIndexBehavior.Sibling
	screen.ClipToDeviceSafeArea = false
	screen.Parent = playerGui
	build(screen,false,boundActions)
	balance = localPlayer:GetAttribute("Gold")
	for _, name in {"Gold","OnboardingReady","ArrivalPhase","ArrivalOpen","TournamentPresentation","TournamentCourseReady","PracticeRoom","VoteOpen"} do
		table.insert(connections,localPlayer:GetAttributeChangedSignal(name):Connect(function()
			balance = localPlayer:GetAttribute("Gold")
			refresh()
		end))
	end
	PortalMarker.Init(function() return enabled() and panelName == nil end)
	local stylePrompt: ProximityPrompt? = nil
	local elapsed = 0
	table.insert(connections,RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < .2 then return end
		elapsed = 0
		if not stylePrompt or not stylePrompt.Parent then
			local lobby = workspace:FindFirstChild("Lobby")
			local amenities = lobby and lobby:FindFirstChild("LobbyAmenities")
			local shops = amenities and amenities:FindFirstChild("Shops")
			local style = shops and shops:FindFirstChild("Style")
			stylePrompt = style and style:FindFirstChild("EditRacer",true) :: ProximityPrompt?
		end
		if stylePrompt then stylePrompt.Enabled = LobbyUi.CanEditRacer() end
	end))
	table.insert(connections,ProximityPromptService.PromptTriggered:Connect(function(prompt,triggeringPlayer)
		if prompt ~= stylePrompt or (triggeringPlayer and triggeringPlayer ~= localPlayer) then return end
		LobbyUi.OpenRacer()
	end))
	refresh()
end

function LobbyUi.CanEditRacer(): boolean
	return ui ~= nil and ui.InputReady == true and enabled() and presentation ~= nil and presentation.canEdit
		and actions.MyRacer ~= nil and (not actions.CanEditRacer or actions.CanEditRacer())
end

function LobbyUi.OpenRacer()
	if not LobbyUi.CanEditRacer() then return end
	LobbyUi.ClosePanel()
	actions.MyRacer()
end

function LobbyUi.InitPreview(parent: Instance, boundActions: any?): Frame
	assert(RunService:IsStudio() and not RunService:IsRunning(),"UI preview requires Edit mode")
	-- Each preview starts clean, so an earlier preview's join does not stamp "YOU'RE IN!" here.
	player, flowState, eventState = nil, nil, nil
	local screen = Theme.Frame(parent,"LobbyUI",UDim2.fromScale(1,1),UDim2.new())
	build(screen,true,boundActions)
	return screen
end

return LobbyUi
