--!strict
-- Decides which race screens show (countdown, racing HUD, checkpoint ribbon, Still racing?,
-- finish burst) and feeds them from the race remotes and the race-flow snapshot. Display only:
-- every rule, timer and place decision stays on the server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local Artwork = require(ReplicatedStorage.Config.VotingArtwork)
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)
local HudView = require(script.Parent.RaceHudView)
local MomentsView = require(script.Parent.RaceMomentsView)
local WatchView = require(script.Parent.WatchView)

local Controller = {}
local player = Players.LocalPlayer
local hud: any, moments: any = nil, nil
local hudGui: ScreenGui?, momentsGui: ScreenGui? = nil, nil
local actions: any = {}
local race: any = {state = nil, raceId = "", startedAt = nil, endsAt = nil, course = "", courseId = nil, format = nil, laps = 1, checkpoints = nil}
local results: any = nil
local status = "Lobby"
local flow: any = nil
local event: any = nil
local standings: {any} = {}
local shownPlace: number? = nil
local lastCheckpoint: string? = nil
local countdownRace: string? = nil
local racedIn: {[string]: boolean} = {}
local finishShown: {[string]: boolean} = {}
local goAt = 0
local clockText = ""
local ticketOpen = false
local idleWarnAt: number? = nil
local watch: any = nil
local watchView: any = nil

local function now(): number return workspace:GetServerTimeNow() end

-- Matches RaceFlowController's readiness so HUD buttons are never shown when their action would be ignored.
local function ready(): boolean
	return player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalOpen") ~= true
		and player:GetAttribute("ArrivalPhase") == "Ready" and player:GetAttribute("TournamentPresentation") ~= true
end

local function racing(): boolean
	return status == "Racing" and race.state == "Racing"
end

local function layout()
	if hud and hudGui then HudView.Layout(hud, hudGui.AbsoluteSize, Kit.LargeText()) end
	if moments and momentsGui then MomentsView.Layout(moments, momentsGui.AbsoluteSize, Kit.LargeText()) end
	if watchView and hudGui then WatchView.Layout(watchView, hudGui.AbsoluteSize, Kit.LargeText()) end
end

local function resetRace(raceId: string)
	race.raceId = raceId
	results, standings, shownPlace, lastCheckpoint, clockText = nil, {}, nil, nil, ""
end

local function courseArt(courseId: string?): string
	if not courseId then return "" end
	local ok, image = pcall(Artwork.Image, courseId)
	return if ok and typeof(image) == "string" then image else ""
end

local function refreshStandings(animate: boolean)
	if not hud then return end
	local previous = standings
	standings = Presentation.Standings(results)
	local me = player.UserId
	local place = Presentation.PlaceOf(standings, me)
	local mine = Presentation.FindResult(results, me)
	local steps, total = 0, 1
	if mine then steps, total = Presentation.Steps(mine, results) end
	HudView.SetLadder(hud, standings, me, if watch and not watch.loading then watch.userId else nil, animate)
	local laps = math.max(1, race.laps or 1)
	local lap = if mine and typeof(mine.currentLap) == "number" then math.clamp(mine.currentLap, 1, laps) else 1
	HudView.SetCourse(hud, race.course)
	HudView.SetLap(hud, lap, laps)
	HudView.SetStats(hud, math.min(steps, total - 1), total - 1, if mine and typeof(mine.falls) == "number" then mine.falls else 0)
	if place ~= shownPlace then
		HudView.SetPlace(hud, place, #standings, animate and shownPlace ~= nil)
		if animate and racing() and #previous > 0 then
			local passed, passedBy = Presentation.Overtakes(previous, standings, me)
			if passed then HudView.Toast(hud, "Passed " .. passed, true); Kit.Play("Whoosh") end
			if passedBy then HudView.Toast(hud, passedBy .. " passed you", false) end
		end
		shownPlace = place
	else
		HudView.SetPlace(hud, place, #standings, false)
	end
	local moment = if mine then Presentation.LatestCheckpoint(mine, results) else nil
	local key = if moment then moment.key else nil
	if key ~= lastCheckpoint then
		if moment and animate and racing() and ready() then
			MomentsView.Ribbon(moments, moment)
			HudView.LadderBurst(hud, steps, total)
			HudView.PunchCheckpoints(hud)
		end
		lastCheckpoint = key
	end
end

local function cardFor(): any
	local caption = Presentation.RaceNumber(event, race.courseId)
	local info = {
		racers = if event and typeof(event.activeRacers) == "number" then event.activeRacers else nil,
		checkpointCount = race.checkpoints, raceFormat = race.format, lapCount = race.laps,
	}
	return {title = race.course, caption = caption or "Get ready", line = Presentation.CourseLine(info), image = courseArt(race.courseId)}
end

local function updateIdle()
	if not moments then return end
	local warningAt = flow and flow.inactivityWarning
	local show = ready() and status == "Racing" and typeof(warningAt) == "number"
	if not show then
		if idleWarnAt then MomentsView.SetIdle(moments, false) end
		idleWarnAt = nil
		return
	end
	local window = math.max(1, RaceConfig.InactivityBreakSeconds - RaceConfig.InactivityWarningSeconds)
	local fraction = 1 - (now() - warningAt) / window
	local first = idleWarnAt ~= warningAt
	idleWarnAt = warningAt
	MomentsView.SetIdle(moments, true, fraction, function()
		if actions.KeepRacing then actions.KeepRacing() end
	end)
	if first and UserInputService.GamepadEnabled then
		local button = MomentsView.IdleButton(moments)
		if button then GuiService.SelectedObject = button end
	end
end

local momentSerial = 0
-- Returns a release function that only ends this moment, never a later one.
local function holdMoment(): () -> ()
	momentSerial += 1
	local serial = momentSerial
	player:SetAttribute("RaceMoment", true)
	return function()
		if momentSerial == serial then player:SetAttribute("RaceMoment", nil) end
	end
end

local function checkFinish()
	if not moments then return end
	local ticket = flow and flow.finishTicket
	if typeof(ticket) ~= "table" or typeof(ticket.raceId) ~= "string" then return end
	local key = ticket.raceId .. ":" .. tostring(ticket.status)
	if finishShown[key] then return end
	if not racedIn[ticket.raceId] or not ready() then finishShown[key] = true; return end
	local finished = Presentation.TicketFinished(ticket)
	if not finished then
		-- Only a run that ran out of time gets the "Time's up" beat; wait for its result record.
		local mine = if typeof(results) == "table" and results.raceId == ticket.raceId then Presentation.FindResult(results, player.UserId) else nil
		if not mine or mine.status ~= "DNF" then return end
		finishShown[key] = true
		if mine.dnfReason ~= "Time expired" then return end
	end
	finishShown[key] = true
	HudView.SetShown(hud, false, true)
	MomentsView.SetIdle(moments, false)
	local release = holdMoment()
	-- The finish ticket waits for the burst; never hold it longer than the burst itself.
	task.delay(4, release)
	if finished then
		local improvement = if ticket.isVisitBest == true and typeof(ticket.previousBestTime) == "number" and typeof(ticket.finishTime) == "number"
			then ticket.previousBestTime - ticket.finishTime else nil
		MomentsView.Finish(moments, {placement = ticket.placement, finishTime = ticket.finishTime, falls = ticket.falls, improvement = improvement}, function()
			release()
		end)
	else
		local reached = if typeof(ticket.furthestCheckpoint) == "number" and typeof(ticket.checkpointCount) == "number"
			then string.format("Reached checkpoint %d of %d", ticket.furthestCheckpoint, ticket.checkpointCount) else nil
		MomentsView.Unfinished(moments, {reached = reached}, release)
	end
end

local function updateVisibility()
	if not hud then return end
	local watching = watch ~= nil and race.state == "Racing"
	local show = ready() and (racing() or watching) and player:GetAttribute("RaceMoment") ~= true
	HudView.SetWatching(hud, watching)
	if show and not hud.shown then
		local wait = goAt + .9 - os.clock()
		if wait > 0 then
			task.delay(wait, updateVisibility)
			return
		end
	end
	HudView.SetShown(hud, show, true)
	if hudGui then hudGui.Enabled = true end
	-- The compact finish plate stays only while the finish ticket is open during the same race.
	if moments and MomentsView.HasMini(moments) and player:GetAttribute("RaceMoment") ~= true
		and (not ticketOpen or race.state ~= "Racing" or not ready()) then
		MomentsView.HideMini(moments)
	end
	updateIdle()
end

local function startCountdown()
	if not moments or countdownRace == race.raceId or not ready() then return end
	if not (status == "Queued" or (flow and flow.status == "Queued")) then return end
	if typeof(race.endsAt) ~= "number" then return end
	countdownRace = race.raceId
	MomentsView.Countdown(moments, cardFor(), race.endsAt, race.duration or 3, now, function() goAt = os.clock() end)
end

function Controller.Init(callbacks: any)
	actions = callbacks or {}
	local playerGui = player:WaitForChild("PlayerGui")
	for _, name in {"RaceHUD", "RaceMoments", "RaceMomentsBack", "RaceMomentsFront", "PersonalSummaryUI", "LateJoinUI", "FinishedOptionsUI"} do
		local old = playerGui:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local function screen(name: string, order: number, fullScreen: boolean?): ScreenGui
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = name, false, order, fullScreen == true
		gui.ScreenInsets = if fullScreen then Enum.ScreenInsets.None else Enum.ScreenInsets.CoreUISafeInsets
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = playerGui
		return gui
	end
	hudGui = screen("RaceHUD", 3)
	-- Moments sit above the vote and Race options for their second or two; arrival and course delivery stay above.
	momentsGui = screen("RaceMoments", 45)
	hud = HudView.Create(hudGui :: ScreenGui)
	watchView = WatchView.Create(hudGui :: ScreenGui, function(id: string) if actions.Watch then actions.Watch(id) end end)
	moments = MomentsView.Create(momentsGui :: ScreenGui, screen("RaceMomentsBack", 44, true), screen("RaceMomentsFront", 46, true))
	;(hudGui :: ScreenGui):GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	player:GetAttributeChangedSignal("LargeText"):Connect(layout)
	for _, name in {"OnboardingReady", "ArrivalOpen", "TournamentPresentation", "RaceMoment"} do
		player:GetAttributeChangedSignal(name):Connect(updateVisibility)
	end
	layout()
	RunService.RenderStepped:Connect(function()
		if not hud or not hud.shown then return end
		local text = if typeof(race.startedAt) == "number" then Presentation.Clock(now() - race.startedAt, 1) else "0:00.0"
		if text ~= clockText then clockText = text; HudView.SetClock(hud, text) end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < .1 then return end
		elapsed = 0
		updateIdle()
	end)
end

function Controller.HandleRaceState(payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.raceId) == "string" and payload.raceId ~= race.raceId then resetRace(payload.raceId) end
	if typeof(payload.state) == "string" then race.state = payload.state end
	if typeof(payload.courseDisplayName) == "string" and payload.courseDisplayName ~= "" then race.course = payload.courseDisplayName end
	if typeof(payload.courseId) == "string" then race.courseId = payload.courseId end
	if typeof(payload.raceFormat) == "string" then race.format = payload.raceFormat end
	if typeof(payload.lapCount) == "number" then race.laps = payload.lapCount end
	if typeof(payload.checkpointCount) == "number" then race.checkpoints = payload.checkpointCount end
	if typeof(payload.endsAt) == "number" then race.endsAt = payload.endsAt end
	if typeof(payload.duration) == "number" then race.duration = payload.duration end
	if race.state == "Racing" and typeof(payload.startedAt) == "number" then race.startedAt = payload.startedAt end
	if race.state == "Countdown" then startCountdown()
	elseif race.state ~= "Racing" and moments then MomentsView.CancelCountdown(moments) end
	if race.state == "Racing" and status == "Racing" then racedIn[race.raceId] = true end
	refreshStandings(false)
	updateVisibility()
end

function Controller.HandleStatus(newStatus: string)
	status = newStatus
	if status == "Racing" and race.state == "Racing" then racedIn[race.raceId] = true end
	if race.state == "Countdown" then startCountdown() end
	updateVisibility()
end

function Controller.HandleResults(payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.raceId) == "string" and payload.raceId ~= race.raceId then resetRace(payload.raceId) end
	local first = results == nil
	results = payload
	if typeof(payload.courseDisplayName) == "string" and payload.courseDisplayName ~= "" then race.course = payload.courseDisplayName end
	if first then
		-- Joining mid-race: remember the current checkpoint so no old ribbon plays.
		local mine = Presentation.FindResult(payload, player.UserId)
		local moment = if mine then Presentation.LatestCheckpoint(mine, payload) else nil
		lastCheckpoint = if moment then moment.key else nil
	end
	refreshStandings(not first)
	checkFinish()
end

function Controller.HandleFlow(snapshot: any, isTicketOpen: boolean)
	flow = snapshot
	ticketOpen = isTicketOpen
	if typeof(snapshot) == "table" and typeof(snapshot.status) == "string" and snapshot.status ~= status then
		status = snapshot.status
		if status == "Racing" and race.state == "Racing" then racedIn[race.raceId] = true end
	end
	if race.state == "Countdown" then startCountdown() end
	checkFinish()
	updateVisibility()
end

-- Watching screen: info is {userId, name, loading} from RaceFlowController, or nil.
function Controller.HandleWatch(info: any?)
	local changed = (watch == nil) ~= (info == nil) or (watch ~= nil and info ~= nil and (watch.userId ~= info.userId or watch.loading ~= info.loading))
	watch = info
	if not watchView then return end
	if not info then
		WatchView.Set(watchView, nil)
	else
		local place = if info.userId and not info.loading then Presentation.PlaceOf(standings, info.userId) else nil
		local target = if info.userId then Presentation.FindResult(results, info.userId) else nil
		local steps, total = 0, 1
		if target then steps, total = Presentation.Steps(target, results) end
		WatchView.Set(watchView, {userId = info.userId, name = info.name, loading = info.loading, place = place, total = #standings,
			checkpoint = if target then math.min(steps, total - 1) else nil, checkpoints = if target then total - 1 else nil,
			remaining = if race.state == "Racing" and typeof(race.endsAt) == "number" then race.endsAt - now() else nil})
	end
	if changed then
		if hud then HudView.SetLadder(hud, standings, player.UserId, if info and not info.loading then info.userId else nil, false) end
		updateVisibility()
	end
end

function Controller.HandleTournament(snapshot: any)
	event = snapshot
end

-- Where the Race options launcher sits while racing, in screen pixels (right edge, top):
-- just under the live place plate, whatever insets the two screens use.
function Controller.LauncherSlot(): Vector2?
	if not hud or not hud.shown then return nil end
	-- From the plates' resting layout, so the launcher does not chase the slide-in animation.
	local gui = hudGui :: ScreenGui
	local s = hud.scale
	local bottom = (16 + 132 + (if hud.coins.Visible then 14 + 52 else 0) + 14) * s
	return Vector2.new(gui.AbsolutePosition.X + gui.AbsoluteSize.X - 20 * s, gui.AbsolutePosition.Y + bottom)
end

function Controller.IsHudShown(): boolean
	return hud ~= nil and hud.shown == true
end

return Controller
