-- Run in the Play client with StudioLobbyPreview enabled; stop Play afterwards to clear fixtures.
local player = game.Players.LocalPlayer
assert(player, "Run this check in the client")
assert(require(game.ReplicatedStorage.Config.RaceConfig).StudioLobbyPreview, "Use lobby preview")
local lobby = require(player.PlayerScripts.Controllers.LobbyUiController)
local race = require(player.PlayerScripts.Controllers.RaceUiController)
-- The Studio command environment has its own module cache, separate from LocalScripts.
race.Init({ localPlayer = player })
local playerGui = player.PlayerGui
local gui = playerGui.LobbyUI
local root = gui.SafeArea
local card = root.RaceStack.NextRace
if player:GetAttribute("LargeText") == true then lobby.ToggleLargeText() end
local passed = {}
local function check(name, condition)
	assert(condition, name)
	table.insert(passed, name)
end
-- Big titles are two stacked labels; "Main" carries the text.
local function bigText(frame: Instance): string
	local main = frame:FindFirstChild("Main", true)
	return if main and main:IsA("TextLabel") then main.Text else ""
end

check("preview is honest", gui.Enabled and bigText(root.Phase.Capsule) ~= "")
check("no inactive preview dev controls", playerGui:FindFirstChild("DevRaceControls") == nil)
check("legacy race screens removed", playerGui:FindFirstChild("LateJoinUI") == nil and playerGui:FindFirstChild("FinishedOptionsUI") == nil
	and playerGui:FindFirstChild("PersonalSummaryUI") == nil)
check("keys always visible", root.Currencies.Keys.Visible and root.Currencies.Keys.KeysPlus.Visible)
lobby.ToggleRecords()
check("empty records", root.Dialog.Visible and root.Dialog:FindFirstChild("Empty", true) ~= nil)
lobby.ClosePanel()
lobby.ToggleSettings()
lobby.ToggleLargeText()
check("larger text", player:GetAttribute("LargeText") == true)
lobby.ToggleLargeText()
check("standard text restored", player:GetAttribute("LargeText") ~= true)
local shadows = game.Lighting.GlobalShadows
lobby.ToggleShadows()
check("shadow preference applies", game.Lighting.GlobalShadows ~= shadows)
lobby.ToggleShadows()
check("shadows restored", game.Lighting.GlobalShadows == shadows)
lobby.ClosePanel()

race.HandleRaceStateChanged({ raceId = "ui-fixture", state = "Intermission", remainingTime = 27.2,
	courseDisplayName = "Classic Ascent", raceFormat = "PointToPoint", duration = 30 })
check("course metadata", gui.Enabled and string.find(bigText(card), "CLASSIC ASCENT", 1, true) ~= nil)
check("phase shows a time", bigText(root.Phase.Capsule) ~= "")
check("race HUD stays hidden in the lobby", not playerGui.RaceHUD.RaceHudCanvas.Visible)
race.HandlePlayerRaceStatusChanged({ userId = player.UserId, status = "Queued" })
check("queued lobby visible", gui.Enabled)
check("queued editor unavailable", root.Menu.MyRacer:GetAttribute("Available") == false)
lobby.ToggleSettings()
race.HandleRaceStateChanged({ state = "Countdown", remainingTime = 3 })
check("countdown hands off and closes modal", not gui.Enabled and not root.Dialog.Visible)
race.HandleRaceStateChanged({ state = "Racing", remainingTime = 90 })
for _, status in { "Racing", "LateRacing", "GhostRacing", "Spectating" } do
	race.HandlePlayerRaceStatusChanged({ userId = player.UserId, status = status })
	check(status .. " hides the lobby", not gui.Enabled)
end
race.HandlePlayerRaceStatusChanged({ userId = player.UserId, status = "Lobby" })
check("lobby returns with the next-race card", gui.Enabled and card.Visible)
lobby.ToggleSettings()
race.HandleRaceTimerUpdated({ remainingTime = 89 })
check("timer leaves settings open", root.Dialog.Visible)
lobby.ClosePanel()
race.HandleRaceResultsUpdated({ raceId = "ui-fixture", courseId = "fixture", courseDisplayName = "UI fixture", placements = {
	{ official = true, placement = 1, userId = 0, displayName = "Fixture racer", finishTime = 42.125 },
} })
race.HandleRaceStateChanged({ state = "Results", remainingTime = 8, duration = 10 })
task.wait(.3)
check("results screen shows", playerGui.RaceResultsUI.Enabled)
race.HandleRaceStateChanged({ state = "Intermission", remainingTime = 28 })
race.HandleRaceResultsUpdated({ courseDisplayName = "UI fixture", placements = {
	{ official = true, placement = 1, displayName = "Fixture racer", finishTime = 42.125 },
	{ official = false, placement = 2, displayName = "Unofficial", finishTime = 43 },
	{ official = true, placement = 3, displayName = "Invalid", finishTime = 0 / 0 },
} })
lobby.ToggleRecords()
local first = root.Dialog:FindFirstChild("Result1", true)
check("only valid official finishes", first ~= nil and first:FindFirstChild("Player", true).Text == "Fixture racer" and root.Dialog:FindFirstChild("Result2", true) == nil)
race.HandleRaceResultsUpdated({ placements = {} })
check("previous finish retained between races", root.Dialog:FindFirstChild("Result1", true) ~= nil)
lobby.ClosePanel()

local originalSize = root.Size
local function inside(child)
	local p, s, origin, bounds = child.AbsolutePosition, child.AbsoluteSize, root.AbsolutePosition, root.AbsoluteSize
	return p.X >= origin.X - 1 and p.Y >= origin.Y - 1
		and p.X + s.X <= origin.X + bounds.X + 1 and p.Y + s.Y <= origin.Y + bounds.Y + 1
end
for _, size in { Vector2.new(1280, 720), Vector2.new(1920, 1080), Vector2.new(1024, 640) } do
	root.Size = UDim2.fromOffset(size.X, size.Y)
	task.wait(.1)
	check("touch targets " .. tostring(size), root.Menu.Shop.AbsoluteSize.X >= 44 and root.Menu.Shop.AbsoluteSize.Y >= 44)
	check(tostring(size) .. " layout bounds", inside(card) and inside(root.Menu) and inside(root.Currencies) and inside(root.Phase))
end
root.Size = originalSize
task.wait(.1)
lobby.Init(player)
local count = 0
for _, child in playerGui:GetChildren() do if child.Name == "LobbyUI" then count += 1 end end
check("reinit has one UI", count == 1)
lobby.Update(nil, "Lobby", nil, "-", nil)
return { passed = #passed, checks = passed, fixtures = "Client UI only; stop Play to clear sample records" }
