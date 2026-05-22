--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatTime = require(ReplicatedStorage.Shared.FormatTime)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

type ControllerConfig = {
	localPlayer: Player?,
	requestSpectateRemote: RemoteEvent?,
	requestRaceLateRemote: RemoteEvent?,
	requestGhostRaceRemote: RemoteEvent?,
}

type LabelMap = { [string]: TextLabel }

local RaceUiController = {}

local localPlayer: Player = Players.LocalPlayer
local requestSpectateRemote: RemoteEvent? = nil
local requestRaceLateRemote: RemoteEvent? = nil
local requestGhostRaceRemote: RemoteEvent? = nil

local currentRaceId = ""
local currentRaceState: string? = nil
local currentRemainingTime: number? = nil
local localPlayerStatus: string = RaceConstants.PlayerRaceStatus.Lobby
local currentRaceResult: any = nil
local lateChoiceSubmittedRaceId: string? = nil
local finishedChoiceSubmittedRaceId: string? = nil

local raceHudGui: ScreenGui? = nil
local resultsGui: ScreenGui? = nil
local personalSummaryGui: ScreenGui? = nil
local lateJoinGui: ScreenGui? = nil
local finishedOptionsGui: ScreenGui? = nil

local raceHudLabels: LabelMap = {}
local resultsRowsFrame: Frame? = nil
local summaryLabels: LabelMap = {}
local summarySplitsFrame: ScrollingFrame? = nil
local renderedSummarySplitKey = ""

local RELEVANT_HUD_STATES = {
	[RaceConstants.RaceState.Intermission] = true,
	[RaceConstants.RaceState.Countdown] = true,
	[RaceConstants.RaceState.Racing] = true,
	[RaceConstants.RaceState.RaceEnding] = true,
	[RaceConstants.RaceState.Results] = true,
}

local function getPlayerGui(): PlayerGui
	return localPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function removeExistingGui(guiName: string)
	local existingGui = getPlayerGui():FindFirstChild(guiName)

	if existingGui ~= nil then
		existingGui:Destroy()
	end
end

local function createScreenGui(guiName: string, displayOrder: number): ScreenGui
	removeExistingGui(guiName)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = guiName
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = displayOrder
	screenGui.Enabled = false
	screenGui.Parent = getPlayerGui()

	return screenGui
end

local function createPanel(parent: Instance, name: string, position: UDim2, size: UDim2, anchorPoint: Vector2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchorPoint
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(24, 27, 32)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent

	return frame
end

local function createLabel(parent: Instance, name: string, text: string, textSize: number, isBold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = if isBold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(238, 238, 238)
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent

	return label
end

local function createPaddedList(parent: Instance, padding: UDim): UIListLayout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = padding
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = parent

	return listLayout
end

local function formatMaybeTime(value: any): string
	if typeof(value) == "number" then
		return FormatTime.fromSeconds(value)
	end

	return "-"
end

local function formatMaybeNumber(value: any): string
	if typeof(value) == "number" then
		return tostring(value)
	end

	return "-"
end

local function formatPlacement(value: any): string
	if typeof(value) == "number" then
		return "#" .. tostring(value)
	end

	return "-"
end

local function getResultDisplayName(playerResult: any): string
	if typeof(playerResult) ~= "table" then
		return "Unknown"
	end

	local displayName = "Unknown"

	if typeof(playerResult.displayName) == "string" and playerResult.displayName ~= "" then
		displayName = playerResult.displayName
	end

	local userName: string? = nil

	if typeof(playerResult.name) == "string" then
		userName = playerResult.name
	end

	if userName ~= nil and userName ~= "" and userName ~= displayName then
		return string.format("%s (@%s)", displayName, userName)
	end

	return displayName
end

local function getResultFalls(playerResult: any): number?
	if typeof(playerResult) == "table" and typeof(playerResult.falls) == "number" then
		return playerResult.falls
	end

	return nil
end

local function getResultSplits(playerResult: any): any
	if typeof(playerResult) == "table" and typeof(playerResult.checkpointSplits) == "table" then
		return playerResult.checkpointSplits
	end

	return nil
end

local function findLocalPlayerResult(): any
	if typeof(currentRaceResult) ~= "table" then
		return nil
	end

	local resultLists = {
		currentRaceResult.placements,
		currentRaceResult.dnfs,
		currentRaceResult.activeRacers,
		currentRaceResult.unofficialRuns,
	}

	for _, resultList in ipairs(resultLists) do
		if typeof(resultList) == "table" then
			for _, playerResult in ipairs(resultList) do
				if typeof(playerResult) == "table" and playerResult.userId == localPlayer.UserId then
					return playerResult
				end
			end
		end
	end

	return nil
end

local function rememberRaceId(raceId: any)
	if typeof(raceId) ~= "string" or raceId == currentRaceId then
		return
	end

	currentRaceId = raceId
	currentRaceResult = nil
	lateChoiceSubmittedRaceId = nil
	finishedChoiceSubmittedRaceId = nil
	renderedSummarySplitKey = ""
end

local function getSummaryNote(playerResult: any): string
	if typeof(playerResult) ~= "table" then
		if localPlayerStatus == RaceConstants.PlayerRaceStatus.LateRacing
			or localPlayerStatus == RaceConstants.PlayerRaceStatus.GhostRacing
			or localPlayerStatus == RaceConstants.PlayerRaceStatus.Spectating
		then
			return "Unofficial Run"
		end

		return localPlayerStatus
	end

	if playerResult.official ~= true then
		return "Unofficial Run"
	end

	if playerResult.status == RaceConstants.PlayerRaceStatus.DNF then
		return "DNF"
	end

	if playerResult.status == RaceConstants.PlayerRaceStatus.Finished then
		local falls = getResultFalls(playerResult) or 0

		if falls > 0 then
			return "Finished with Falls"
		end

		return "Clean Run"
	end

	return tostring(playerResult.status or localPlayerStatus)
end

local function updateChoiceUi()
	local isRacingState = currentRaceState == RaceConstants.RaceState.Racing
	local canShowLateJoin = isRacingState
		and localPlayerStatus == RaceConstants.PlayerRaceStatus.Lobby
		and lateChoiceSubmittedRaceId ~= currentRaceId
	local canShowFinishedOptions = isRacingState
		and localPlayerStatus == RaceConstants.PlayerRaceStatus.Finished
		and finishedChoiceSubmittedRaceId ~= currentRaceId

	if lateJoinGui ~= nil then
		lateJoinGui.Enabled = canShowLateJoin
	end

	if finishedOptionsGui ~= nil then
		finishedOptionsGui.Enabled = canShowFinishedOptions
	end
end

local function updateRaceHud()
	if raceHudGui == nil then
		return
	end

	local isVisible = currentRaceState ~= nil and RELEVANT_HUD_STATES[currentRaceState] == true
	raceHudGui.Enabled = isVisible

	local localResult = findLocalPlayerResult()
	local splits = getResultSplits(localResult)
	local splitCount = if typeof(splits) == "table" then #splits else nil
	local falls = getResultFalls(localResult)
	local placement: any = nil

	if localResult ~= nil then
		placement = localResult.placement
	end

	raceHudLabels.State.Text = "State: " .. tostring(currentRaceState or "Waiting")
	raceHudLabels.Status.Text = "Status: " .. tostring(localPlayerStatus)
	raceHudLabels.Timer.Text = "Timer: " .. formatMaybeTime(currentRemainingTime)
	raceHudLabels.Checkpoints.Text = "Checkpoints: "
		.. (if splitCount ~= nil then tostring(splitCount) .. " completed" else "-")
	raceHudLabels.Falls.Text = "Falls: " .. formatMaybeNumber(falls)
	raceHudLabels.Placement.Text = "Placement: " .. formatPlacement(placement)
end

local function clearRows(frame: Instance)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function addResultRow(order: number, text: string)
	if resultsRowsFrame == nil then
		return
	end

	local row = createLabel(resultsRowsFrame, "ResultRow", text, 13, false)
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 22)
	row.TextColor3 = Color3.fromRGB(228, 232, 238)
end

local function updateResultsUi()
	if resultsGui == nil or resultsRowsFrame == nil then
		return
	end

	local shouldShow = currentRaceState == RaceConstants.RaceState.RaceEnding
		or currentRaceState == RaceConstants.RaceState.Results
	resultsGui.Enabled = shouldShow
	clearRows(resultsRowsFrame)

	if not shouldShow then
		return
	end

	local rowOrder = 1
	local hasRows = false

	if typeof(currentRaceResult) == "table" and typeof(currentRaceResult.placements) == "table" then
		for _, playerResult in ipairs(currentRaceResult.placements) do
			if typeof(playerResult) == "table" then
				addResultRow(
					rowOrder,
					string.format(
						"%s  %s  %s  Falls %s",
						formatPlacement(playerResult.placement),
						getResultDisplayName(playerResult),
						formatMaybeTime(playerResult.finishTime),
						formatMaybeNumber(playerResult.falls)
					)
				)
				rowOrder += 1
				hasRows = true
			end
		end
	end

	if typeof(currentRaceResult) == "table" and typeof(currentRaceResult.dnfs) == "table" then
		for _, playerResult in ipairs(currentRaceResult.dnfs) do
			if typeof(playerResult) == "table" then
				local reason = "DNF"

				if typeof(playerResult.dnfReason) == "string" and playerResult.dnfReason ~= "" then
					reason = playerResult.dnfReason
				end

				addResultRow(
					rowOrder,
					string.format(
						"DNF  %s  Falls %s  %s",
						getResultDisplayName(playerResult),
						formatMaybeNumber(playerResult.falls),
						reason
					)
				)
				rowOrder += 1
				hasRows = true
			end
		end
	end

	if not hasRows then
		addResultRow(1, "No official results yet.")
	end
end

local function addSummarySplitRow(order: number, text: string)
	if summarySplitsFrame == nil then
		return
	end

	local row = createLabel(summarySplitsFrame, "SplitRow", text, 12, false)
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 18)
	row.TextColor3 = Color3.fromRGB(220, 224, 230)
end

local function getSummarySplitKey(splits: any, splitCount: number): string
	if typeof(splits) ~= "table" or splitCount == 0 then
		return "empty"
	end

	local parts = {}

	for index, split in ipairs(splits) do
		if typeof(split) == "table" then
			local checkpointName = if typeof(split.checkpointName) == "string" then split.checkpointName else "Checkpoint"
			parts[index] = string.format("%s:%s", checkpointName, tostring(split.elapsedTime))
		end
	end

	return table.concat(parts, "|")
end

local function updatePersonalSummaryUi()
	if personalSummaryGui == nil or summarySplitsFrame == nil then
		return
	end

	local localResult = findLocalPlayerResult()
	local shouldShow = localResult ~= nil
		or localPlayerStatus == RaceConstants.PlayerRaceStatus.Finished
		or localPlayerStatus == RaceConstants.PlayerRaceStatus.DNF
		or currentRaceState == RaceConstants.RaceState.Results

	personalSummaryGui.Enabled = shouldShow

	if not shouldShow then
		return
	end

	local falls = getResultFalls(localResult)
	local splits = getResultSplits(localResult)
	local splitCount = if typeof(splits) == "table" then #splits else 0
	local placement: any = nil
	local finishTime: any = nil
	local dnfReason = "-"

	if localResult ~= nil then
		placement = localResult.placement
		finishTime = localResult.finishTime

		if typeof(localResult.dnfReason) == "string" and localResult.dnfReason ~= "" then
			dnfReason = localResult.dnfReason
		end
	end

	summaryLabels.Status.Text = "Status: " .. tostring(localPlayerStatus)
	summaryLabels.Note.Text = "Note: " .. getSummaryNote(localResult)
	summaryLabels.Placement.Text = "Placement: " .. formatPlacement(placement)
	summaryLabels.FinishTime.Text = "Finish: " .. formatMaybeTime(finishTime)
	summaryLabels.DnfReason.Text = "DNF: " .. dnfReason
	summaryLabels.Falls.Text = "Falls: " .. formatMaybeNumber(falls)

	local splitKey = getSummarySplitKey(splits, splitCount)

	if splitKey == renderedSummarySplitKey then
		return
	end

	renderedSummarySplitKey = splitKey
	clearRows(summarySplitsFrame)

	if splitCount == 0 then
		addSummarySplitRow(1, "Splits: -")
		return
	end

	for index, split in ipairs(splits) do
		if typeof(split) == "table" then
			local checkpointName = "Checkpoint"

			if typeof(split.checkpointName) == "string" then
				checkpointName = split.checkpointName
			end

			addSummarySplitRow(
				index,
				string.format("%s  %s", checkpointName, formatMaybeTime(split.elapsedTime))
			)
		end
	end
end

local function updateAll()
	updateChoiceUi()
	updateRaceHud()
	updateResultsUi()
	updatePersonalSummaryUi()
end

local function createButton(parent: Instance, name: string, label: string, order: number, onActivated: () -> ())
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(12, 42 + (order - 1) * 36)
	button.Size = UDim2.new(1, -24, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(55, 68, 86)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Gotham
	button.Text = label
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.Parent = parent

	button.Activated:Connect(onActivated)
end

local function createChoiceGui(guiName: string, titleText: string): ScreenGui
	local screenGui = createScreenGui(guiName, 10)

	local frame = createPanel(screenGui, "Panel", UDim2.fromScale(0.5, 0.18), UDim2.fromOffset(220, 120), Vector2.new(0.5, 0))

	local title = createLabel(frame, "Title", titleText, 15, true)
	title.Size = UDim2.new(1, -24, 0, 38)
	title.Position = UDim2.fromOffset(12, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center

	return screenGui
end

local function createRaceChoiceUis()
	local lateJoinScreenGui = createChoiceGui("LateJoinUI", "Join Current Race?")
	lateJoinGui = lateJoinScreenGui

	local lateJoinPanel = lateJoinScreenGui:FindFirstChild("Panel")

	if lateJoinPanel ~= nil then
		createButton(lateJoinPanel, "Spectate", "Spectate", 1, function()
			lateChoiceSubmittedRaceId = currentRaceId
			lateJoinScreenGui.Enabled = false

			if requestSpectateRemote ~= nil then
				requestSpectateRemote:FireServer()
			end
		end)

		createButton(lateJoinPanel, "RaceLate", "Race Late", 2, function()
			lateChoiceSubmittedRaceId = currentRaceId
			lateJoinScreenGui.Enabled = false

			if requestRaceLateRemote ~= nil then
				requestRaceLateRemote:FireServer()
			end
		end)
	end

	local finishedOptionsScreenGui = createChoiceGui("FinishedOptionsUI", "Finished")
	finishedOptionsGui = finishedOptionsScreenGui

	local finishedOptionsPanel = finishedOptionsScreenGui:FindFirstChild("Panel")

	if finishedOptionsPanel ~= nil then
		createButton(finishedOptionsPanel, "Spectate", "Spectate", 1, function()
			finishedChoiceSubmittedRaceId = currentRaceId
			finishedOptionsScreenGui.Enabled = false

			if requestSpectateRemote ~= nil then
				requestSpectateRemote:FireServer()
			end
		end)

		createButton(finishedOptionsPanel, "GhostRace", "Ghost Race", 2, function()
			finishedChoiceSubmittedRaceId = currentRaceId
			finishedOptionsScreenGui.Enabled = false

			if requestGhostRaceRemote ~= nil then
				requestGhostRaceRemote:FireServer()
			end
		end)
	end
end

local function createRaceHud()
	local screenGui = createScreenGui("RaceHUD", 3)
	raceHudGui = screenGui
	raceHudLabels = {}

	local frame = createPanel(screenGui, "Panel", UDim2.fromScale(0.015, 0.11), UDim2.fromOffset(290, 184), Vector2.zero)
	frame.ClipsDescendants = true

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	createPaddedList(frame, UDim.new(0, 2))

	local title = createLabel(frame, "Title", "Race", 15, true)
	title.LayoutOrder = 1
	title.Size = UDim2.new(1, 0, 0, 22)

	local fields = {
		{ key = "State", text = "State: -" },
		{ key = "Status", text = "Status: -" },
		{ key = "Timer", text = "Timer: -" },
		{ key = "Checkpoints", text = "Checkpoints: -" },
		{ key = "Falls", text = "Falls: -" },
		{ key = "Placement", text = "Placement: -" },
	}

	for index, field in ipairs(fields) do
		local label = createLabel(frame, field.key, field.text, 13, false)
		label.LayoutOrder = index + 1
		raceHudLabels[field.key] = label
	end
end

local function createResultsUi()
	local screenGui = createScreenGui("RaceResultsUI", 4)
	resultsGui = screenGui

	local frame = createPanel(screenGui, "Panel", UDim2.fromScale(0.985, 0.34), UDim2.fromOffset(430, 294), Vector2.new(1, 0))

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	createPaddedList(frame, UDim.new(0, 6))

	local title = createLabel(frame, "Title", "Results", 16, true)
	title.LayoutOrder = 1
	title.Size = UDim2.new(1, 0, 0, 24)

	local header = createLabel(frame, "Header", "Place  Player  Time  Falls", 12, true)
	header.LayoutOrder = 2
	header.Size = UDim2.new(1, 0, 0, 18)
	header.TextColor3 = Color3.fromRGB(188, 197, 210)

	local rowsFrame = Instance.new("Frame")
	rowsFrame.Name = "Rows"
	rowsFrame.LayoutOrder = 3
	rowsFrame.Size = UDim2.new(1, 0, 1, -54)
	rowsFrame.BackgroundTransparency = 1
	rowsFrame.ClipsDescendants = true
	rowsFrame.Parent = frame
	createPaddedList(rowsFrame, UDim.new(0, 2))
	resultsRowsFrame = rowsFrame
end

local function createPersonalSummaryUi()
	local screenGui = createScreenGui("PersonalSummaryUI", 5)
	personalSummaryGui = screenGui
	summaryLabels = {}

	local frame = createPanel(screenGui, "Panel", UDim2.fromScale(0.015, 0.46), UDim2.fromOffset(310, 238), Vector2.zero)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	createPaddedList(frame, UDim.new(0, 3))

	local title = createLabel(frame, "Title", "Personal Summary", 16, true)
	title.LayoutOrder = 1
	title.Size = UDim2.new(1, 0, 0, 24)

	local fields = {
		{ key = "Status", text = "Status: -" },
		{ key = "Note", text = "Note: -" },
		{ key = "Placement", text = "Placement: -" },
		{ key = "FinishTime", text = "Finish: -" },
		{ key = "DnfReason", text = "DNF: -" },
		{ key = "Falls", text = "Falls: -" },
	}

	for index, field in ipairs(fields) do
		local label = createLabel(frame, field.key, field.text, 13, false)
		label.LayoutOrder = index + 1
		summaryLabels[field.key] = label
	end

	local splitsFrame = Instance.new("ScrollingFrame")
	splitsFrame.Name = "Splits"
	splitsFrame.LayoutOrder = #fields + 2
	splitsFrame.Size = UDim2.new(1, 0, 1, -152)
	splitsFrame.BackgroundTransparency = 1
	splitsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	splitsFrame.CanvasSize = UDim2.fromOffset(0, 0)
	splitsFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 188, 200)
	splitsFrame.ScrollBarThickness = 6
	splitsFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	splitsFrame.Parent = frame
	createPaddedList(splitsFrame, UDim.new(0, 1))
	summarySplitsFrame = splitsFrame
end

function RaceUiController.Init(config: ControllerConfig?)
	if config ~= nil then
		if config.localPlayer ~= nil then
			localPlayer = config.localPlayer
		end

		requestSpectateRemote = config.requestSpectateRemote
		requestRaceLateRemote = config.requestRaceLateRemote
		requestGhostRaceRemote = config.requestGhostRaceRemote
	end

	createRaceHud()
	createResultsUi()
	createPersonalSummaryUi()
	createRaceChoiceUis()
	updateAll()
end

function RaceUiController.HandleRaceStateChanged(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)

	if typeof(payload.state) == "string" then
		currentRaceState = payload.state
	end

	if typeof(payload.remainingTime) == "number" then
		currentRemainingTime = payload.remainingTime
	elseif typeof(payload.duration) == "number" then
		currentRemainingTime = payload.duration
	else
		currentRemainingTime = nil
	end

	updateAll()
end

function RaceUiController.HandleRaceTimerUpdated(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)

	if typeof(payload.state) == "string" then
		currentRaceState = payload.state
	end

	if typeof(payload.remainingTime) == "number" then
		currentRemainingTime = payload.remainingTime
	else
		currentRemainingTime = nil
	end

	updateAll()
end

function RaceUiController.HandlePlayerRaceStatusChanged(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)

	if payload.userId == localPlayer.UserId and typeof(payload.status) == "string" then
		localPlayerStatus = payload.status

		if localPlayerStatus == RaceConstants.PlayerRaceStatus.Finished then
			finishedChoiceSubmittedRaceId = nil
		end

		updateAll()
	end
end

function RaceUiController.HandleRaceResultsUpdated(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)
	currentRaceResult = payload
	updateAll()
end

return RaceUiController
