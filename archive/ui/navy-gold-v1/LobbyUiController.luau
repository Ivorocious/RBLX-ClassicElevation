--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Theme = require(script.Parent.UiTheme)
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local FormatTime = require(ReplicatedStorage.Shared.FormatTime)

local LobbyUi = {}
local gui: ScreenGui? = nil
local root: Frame
local header: Frame
local menu: Frame
local footer: Frame
local modal: Frame
local shade: Frame
local records: ScrollingFrame
local settings: Frame
local labels: { [string]: TextLabel } = {}
local scales: { [string]: UIScale } = {}
local buttons: { [string]: TextButton } = {}
local resizeConnection: RBXScriptConnection? = nil
local panelName: string? = nil
local largeText = false
local latestRows: { any } = {}
local latestCourse = ""

local function textSizes()
	if not gui then return end
	for _, item in gui:GetDescendants() do
		local base = item:GetAttribute("BaseTextSize")
		if typeof(base) == "number" and (item:IsA("TextLabel") or item:IsA("TextButton")) then
			item.TextSize = base * (if largeText then 1.12 else 1)
		end
	end
end

local function resize()
	local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local compact = width < 850 or height < 550
	local hudScale = if compact then .8 else 1
	hudScale = math.min(hudScale, math.max(.6, (width - 24) / 360))
	scales.Header.Scale, scales.Menu.Scale, scales.Footer.Scale = hudScale, hudScale, hudScale
	scales.Modal.Scale = math.min(1, (width - 24) / 500, (height - 24) / 360)
	header.Position = UDim2.new(.5, 0, 0, if compact then 8 else 18)
	menu.Position = UDim2.new(0, if compact then 10 else 26, .44, 0)
	footer.Position = UDim2.new(.5, 0, 1, if compact then -8 else -22)
end

function LobbyUi.ClosePanel()
	panelName = nil
	if gui then
		modal.Visible, shade.Visible = false, false
		buttons.Records.BackgroundColor3, buttons.Settings.BackgroundColor3 = Theme.Navy, Theme.Navy
	end
end

local function showPanel(name: string)
	if not gui or not gui.Enabled then return end
	if panelName == name then LobbyUi.ClosePanel(); return end
	panelName = name
	modal.Visible, shade.Visible = true, true
	records.Visible, settings.Visible = name == "Records", name == "Settings"
	labels.ModalTitle.Text = name
	labels.ModalNote.Text = if name == "Records" then "Recent finishes received this session" else "Applies on this device for this session"
	buttons.Records.BackgroundColor3 = if name == "Records" then Theme.Raised else Theme.Navy
	buttons.Settings.BackgroundColor3 = if name == "Settings" then Theme.Raised else Theme.Navy
end

function LobbyUi.ToggleRecords() showPanel("Records") end
function LobbyUi.ToggleSettings() showPanel("Settings") end

function LobbyUi.ToggleLargeText()
	largeText = not largeText
	buttons.TextSize.Text = if largeText then "Larger" else "Standard"
	textSizes()
end

function LobbyUi.ToggleShadows()
	Lighting.GlobalShadows = not Lighting.GlobalShadows
	buttons.Shadows.Text = if Lighting.GlobalShadows then "On" else "Off"
end

local function renderRecords()
	if not gui then return end
	for _, item in records:GetChildren() do if item:IsA("GuiObject") then item:Destroy() end end
	if #latestRows == 0 then
		local empty = Theme.Label(records, "Empty", "No finishes yet", 22, UDim2.new(), UDim2.new(1, -12, 0, 64))
		empty.LayoutOrder = 1
		local note = Theme.Label(records, "EmptyNote", "Finish a race to see its results here.", 16, UDim2.new(), UDim2.new(1, -12, 0, 50))
		note.TextWrapped, note.TextColor3, note.LayoutOrder = true, Theme.Muted, 2
	else
		local course = Theme.Label(records, "Course", latestCourse, 18, UDim2.new(), UDim2.new(1, -12, 0, 32))
		course.TextColor3, course.LayoutOrder = Theme.Gold, 0
		for i, result in latestRows do
			local row = Theme.Frame(records, "Result" .. i, UDim2.new(1, -12, 0, 44), UDim2.new())
			row.LayoutOrder = i
			local place = Theme.Label(row, "Place", tostring(result.placement), 20, UDim2.fromOffset(0, 0), UDim2.fromOffset(40, 44))
			place.TextColor3 = Theme.Gold
			local name = Theme.Label(row, "Player", result.displayName, 18, UDim2.fromOffset(48, 0), UDim2.new(1, -180, 1, 0))
			name.TextXAlignment = Enum.TextXAlignment.Left
			local time = Theme.Label(row, "Time", FormatTime.fromSeconds(result.finishTime), 18, UDim2.new(1, -126, 0, 0), UDim2.fromOffset(126, 44))
			time.TextXAlignment = Enum.TextXAlignment.Right
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
			table.insert(rows, {
				placement = result.placement or i,
				displayName = tostring(result.displayName or result.name or "Player"),
				finishTime = result.finishTime,
			})
		end
	end
	-- Keep the last populated race visible while the next race has no finishers.
	if #rows == 0 then return end
	latestRows, latestCourse = rows, tostring(payload.courseDisplayName or "Latest race")
	renderRecords()
end

function LobbyUi.Update(state: string?, status: string, remaining: number?, course: string, raceFormat: string?)
	if not gui then return end
	local lobbyStatus = status == RaceConstants.PlayerRaceStatus.Lobby or status == RaceConstants.PlayerRaceStatus.Queued
	local waiting = state == nil or state == "WaitingForPlayers" or state == "Intermission" or state == "Resetting"
	gui.Enabled = lobbyStatus and (waiting or state == "Racing")
	if not gui.Enabled then LobbyUi.ClosePanel(); return end
	header.Visible = waiting
	labels.Course.Text = if course ~= "-" and course ~= "" then string.upper(course) else "CLASSIC ELEVATION"
	labels.Format.Text = if raceFormat == "LapBased" then "CIRCUIT" elseif raceFormat == "PointToPoint" then "POINT TO POINT" else "THE SKYCOURT"
	local preview = state == nil and RunService:IsStudio() and RaceConfig.StudioLobbyPreview
	if state == "Intermission" then
		labels.Heading.Text = "NEXT RACE"
		local seconds = if remaining and remaining == remaining and remaining < math.huge then math.max(0, math.ceil(remaining)) else nil
		labels.Timer.Text = if seconds then string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60) else "--:--"
		labels.Status.Text, labels.Hint.Text = "Joining next race", "Explore the lobby while you wait"
	elseif state == "Racing" then
		labels.Status.Text, labels.Hint.Text = "Race in progress", "Spectate or join a late run"
	elseif preview then
		labels.Heading.Text, labels.Timer.Text = "LOBBY OPEN", "EXPLORE"
		labels.Status.Text, labels.Hint.Text = "Lobby open", "Practice, explore, or check records"
	else
		labels.Heading.Text, labels.Timer.Text = "NEXT RACE", "WAITING"
		labels.Status.Text = if state == "Resetting" then "Preparing next race" else "Waiting for the next race"
		labels.Hint.Text = "Explore the lobby while you wait"
	end
end

function LobbyUi.IsVisible(): boolean
	return gui ~= nil and gui.Enabled
end

local function scale(frame: Frame): UIScale
	local value = Instance.new("UIScale")
	value.Parent = frame
	return value
end

function LobbyUi.Init(player: Player)
	if resizeConnection then resizeConnection:Disconnect() end
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("LobbyUI")
	if old then old:Destroy() end
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.ResetOnSpawn, screen.DisplayOrder = "LobbyUI", false, 20
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent, gui = playerGui, screen
	root = Theme.Frame(screen, "SafeArea", UDim2.fromScale(1, 1), UDim2.new())
	header = Theme.Frame(root, "NextRace", UDim2.fromOffset(304, 124), UDim2.new(.5, 0, 0, 18))
	header.AnchorPoint = Vector2.new(.5, 0)
	Theme.Panel(header)
	scales.Header = scale(header)
	Theme.Icon(header, "Compass", UDim2.new(.5, -14, 0, -14))
	labels.Heading = Theme.Label(header, "Heading", "NEXT RACE", 13, UDim2.fromOffset(16, 19), UDim2.new(1, -32, 0, 20))
	labels.Timer = Theme.Label(header, "Timer", "--:--", 34, UDim2.fromOffset(16, 39), UDim2.new(1, -32, 0, 40))
	labels.Timer.Font = Enum.Font.GothamBold
	labels.Course = Theme.Label(header, "Course", "CLASSIC ELEVATION", 19, UDim2.fromOffset(12, 79), UDim2.new(1, -24, 0, 25))
	labels.Course.TextColor3 = Theme.Gold
	labels.Format = Theme.Label(header, "Format", "THE SKYCOURT", 11, UDim2.fromOffset(12, 104), UDim2.new(1, -24, 0, 16))

	menu = Theme.Frame(root, "Menu", UDim2.fromOffset(182, 148), UDim2.new(0, 26, .44, 0))
	menu.AnchorPoint = Vector2.new(0, .5)
	scales.Menu = scale(menu)
	Theme.Label(menu, "GameTitle", "CLASSIC ELEVATION", 12, UDim2.new(), UDim2.fromOffset(182, 25))
	for i, name in {"Records", "Settings"} do
		local button = Theme.Button(menu, name, "     " .. name, UDim2.fromOffset(0, 32 + (i - 1) * 58), UDim2.fromOffset(174, 50), function() showPanel(name) end)
		Theme.Icon(button, name, UDim2.fromOffset(12, 11))
		buttons[name] = button
	end
	footer = Theme.Frame(root, "JoiningStatus", UDim2.fromOffset(360, 58), UDim2.new(.5, 0, 1, -22))
	footer.AnchorPoint = Vector2.new(.5, 1)
	Theme.Panel(footer)
	scales.Footer = scale(footer)
	Theme.Icon(footer, "Check", UDim2.fromOffset(16, 15))
	labels.Status = Theme.Label(footer, "Status", "Waiting for the next race", 17, UDim2.fromOffset(58, 7), UDim2.new(1, -70, 0, 25))
	labels.Hint = Theme.Label(footer, "Hint", "Explore the lobby while you wait", 12, UDim2.fromOffset(58, 32), UDim2.new(1, -70, 0, 18))
	labels.Status.TextXAlignment, labels.Hint.TextXAlignment = Enum.TextXAlignment.Left, Enum.TextXAlignment.Left

	shade = Theme.Frame(root, "Shade", UDim2.fromScale(1, 1), UDim2.new())
	shade.BackgroundColor3, shade.BackgroundTransparency, shade.Active, shade.ZIndex = Color3.new(0, 0, 0), .4, true, 19
	modal = Theme.Frame(root, "Dialog", UDim2.fromOffset(500, 360), UDim2.fromScale(.5, .5))
	modal.AnchorPoint, modal.ZIndex, modal.Active = Vector2.new(.5, .5), 20, true
	Theme.Panel(modal)
	scales.Modal = scale(modal)
	labels.ModalTitle = Theme.Label(modal, "Title", "Records", 25, UDim2.fromOffset(24, 16), UDim2.fromOffset(380, 36))
	labels.ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
	labels.ModalNote = Theme.Label(modal, "Note", "", 14, UDim2.fromOffset(24, 52), UDim2.fromOffset(440, 25))
	labels.ModalNote.TextXAlignment, labels.ModalNote.TextColor3 = Enum.TextXAlignment.Left, Theme.Muted
	buttons.Close = Theme.Button(modal, "Close", "X", UDim2.new(1, -60, 0, 12), UDim2.fromOffset(44, 44), LobbyUi.ClosePanel)
	buttons.Close.Modal = true
	records = Instance.new("ScrollingFrame")
	records.Name, records.Position, records.Size = "Records", UDim2.fromOffset(24, 92), UDim2.new(1, -48, 1, -110)
	records.BackgroundTransparency, records.BorderSizePixel = 1, 0
	records.CanvasSize, records.AutomaticCanvasSize = UDim2.new(), Enum.AutomaticSize.Y
	records.ScrollingDirection, records.ScrollBarThickness, records.ScrollBarImageColor3 = Enum.ScrollingDirection.Y, 5, Theme.Gold
	records.Parent = modal
	local list = Instance.new("UIListLayout")
	list.Padding, list.SortOrder, list.Parent = UDim.new(0, 6), Enum.SortOrder.LayoutOrder, records
	settings = Theme.Frame(modal, "Settings", UDim2.new(1, -48, 1, -110), UDim2.fromOffset(24, 92))
	local settingsOptions: { { name: string, title: string, value: string, activate: () -> () } } = {
		{ name = "TextSize", title = "Lobby UI text", value = "Standard", activate = LobbyUi.ToggleLargeText },
		{ name = "Shadows", title = "World shadows", value = if Lighting.GlobalShadows then "On" else "Off", activate = LobbyUi.ToggleShadows },
	}
	for i, item in settingsOptions do
		local y = (i - 1) * 76
		local title = Theme.Label(settings, item.name .. "Label", item.title, 20, UDim2.fromOffset(0, y), UDim2.fromOffset(250, 50))
		title.TextXAlignment = Enum.TextXAlignment.Left
		buttons[item.name] = Theme.Button(settings, item.name, item.value, UDim2.new(1, -144, 0, y), UDim2.fromOffset(144, 50), item.activate)
	end
	local note = Theme.Label(settings, "ShadowsNote", "Turn shadows off for a lighter scene.", 16, UDim2.fromOffset(0, 151), UDim2.new(1, 0, 0, 44))
	note.TextColor3, note.TextWrapped = Theme.Muted, true
	LobbyUi.ClosePanel()
	renderRecords()
	resizeConnection = root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	buttons.TextSize.Text = if largeText then "Larger" else "Standard"
	textSizes()
end

return LobbyUi
