--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Config.OnboardingConfig)
local View = require(script.Parent.ArrivalView)
local Screen = require(script.Parent.ArrivalScreen)
local Transition = require(script.Parent.ArrivalTransition)
local Controller = {}
local openRacer: (() -> ())? = nil
local canOpenRacer: (() -> boolean)? = nil

function Controller.OpenRacer()
	if openRacer then openRacer() end
end

function Controller.CanOpenRacer(): boolean
	return canOpenRacer ~= nil and canOpenRacer()
end

function Controller.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = View.Make("ScreenGui", "Arrival", playerGui, {ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 80, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	local ui = Screen.Create(gui)
	local backdrop = ui.Backdrop
	local brand = ui.Brand
	local choice = ui.Choice
	local stage = ui.Stage
	local create = ui.Create
	local useAvatar = ui.UseAvatar
	local dialog = ui.Dialog
	local reward = ui.Reward
	local status = ui.Status
	local soundButton = ui.SoundButton
	local motionButton = ui.MotionButton
	local retry = ui.Retry
	local editor = ui.Editor
	local save = ui.Save
	local back = ui.Back
	local editBonus = ui.EditBonus
	local reopen = ui.Reopen
	local cancel = ui.Cancel
	local look = ui.Look
	local highlight = ui.Highlight
	local reducedMotion, muted, active = false, false, false
	local music = View.Make("Sound", "ArrivalAmbient", SoundService, {SoundId = Config.AmbientSoundId, Looped = true, Volume = Config.AmbientVolume})
	local transition = Transition.Create(gui,music,brand)
	local remote, changed
	local serverState: any = {phase = "Loading"}
	local raceStatus = "Lobby"
	local busy, inEditor = false, false
	local stateVersion = 0
	local pendingOperation, pendingSignature
	local lastFocus: GuiObject? = nil
	local controls: any = nil
	local presentedReady = false
	local freshVisitChoice = false
	local function focus(button)
		if UserInputService.GamepadEnabled then GuiService.SelectedObject = button end
	end
	local function setActive(value)
		if active == value then return end
		active = value
		player:SetAttribute("ArrivalOpen", value)
		backdrop.Visible = value
		if value then
			lastFocus = GuiService.SelectedObject
			ContextActionService:BindActionAtPriority("ArrivalMovement", function() return Enum.ContextActionResult.Sink end, false, 3000,
				Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
			if controls then controls:Disable() end
			if not muted and music.SoundId ~= "" then music:Play() end
			focus(create)
		else
			ContextActionService:UnbindAction("ArrivalMovement")
			if controls then controls:Enable() end
			music:Stop()
			if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject = lastFocus end
		end
	end
	local showState
	local function entranceOptions(delivery)
		return {
			delivery=delivery,motion=not reducedMotion,
			volume=function() return if muted then 0 else Config.AmbientVolume end,
			covered=function() backdrop.Visible=false end,
			acknowledge=function(token) return remote:InvokeServer({action="Arrived",token=token}) end,
			completed=function(result) presentedReady=true; showState(result or serverState) end,
		}
	end
	showState = function(state)
		if type(state) ~= "table" or not state.phase then return end
		if state.phase=="Loading" or (state.phase=="Choice" and state.profile and state.profile.completed==true) then
			freshVisitChoice=false; player:SetAttribute("VisitIntroAvailable",false)
		elseif state.phase=="Choice" and (not state.profile or state.profile.completed~=true) then
			freshVisitChoice=true; player:SetAttribute("VisitIntroAvailable",true)
		elseif state.phase=="Ready" and not freshVisitChoice then player:SetAttribute("VisitIntroAvailable",false) end
		if transition.IsRunning() and state.phase~="Ready" and state.phase~="Entering" then transition.Cancel() end
		if state.phase=="Entering" and transition.IsRunning() and transition.Token()~=state.delivery.token then transition.Cancel() end
		serverState = state
		if state.delivery then transition.Preload(state.delivery) end
		if state.phase == "Entering" then
			if not transition.IsRunning() then
				setActive(true)
				dialog.Close()
				reopen.Visible = false
				status.Text = ""
				transition.Run(state.delivery,entranceOptions(state.delivery))
			end
			return
		end
		if state.phase == "Ready" and transition.IsRunning() then return end
		if state.phase=="Ready" and active and not presentedReady then
			dialog.Close()
			transition.RunReturned(entranceOptions(nil))
			return
		end
		local ready = state.phase == "Ready"
		setActive(not ready)
		backdrop.Visible = not ready
		reopen.Visible = false
		if ready then
			dialog.Close()
			inEditor = false
		end
		choice.Visible = state.phase == "Choice" and not inEditor
		editor.Visible = state.phase == "Choice" and inEditor
		brand.Visible = not inEditor
		retry.Visible = state.phase == "LoadError"
		cancel.Visible = state.profile ~= nil and state.profile.completed == true
		reward.Visible = not (state.profile and state.profile.bonusClaimed)
		reward.Text = "+" .. Config.CreationBonus .. " coins"
		editBonus.Text = if state.profile and state.profile.bonusClaimed then "Bonus already claimed" else "+" .. Config.CreationBonus .. " coins · one time"
		if state.message then status.Text = state.message
		elseif state.phase == "Loading" then status.Text = "Loading your profile…"
		elseif state.phase == "LoadError" then status.Text = "Could not load your profile. Please retry."
		else status.Text = "" end
		if retry.Visible then focus(retry) end
	end
	local request
	request = function(payload)
		if busy or not remote then return end
		busy = true
		status.Text = if payload.action == "Save" then "Saving your look…" else "One moment…"
		save.Text, useAvatar.Text = if payload.action == "Save" then "Saving…" else "Save & play", "Use my avatar"
		local observedVersion = stateVersion
		local observedPreset = serverState.preset
		local ok, result = pcall(function() return remote:InvokeServer(payload) end)
		busy = false
		save.Text = "Save & play"
		if serverState.preset ~= observedPreset and payload.action ~= "State" then return end
		if stateVersion~=observedVersion and type(result)=="table" and result.delivery and serverState.delivery
			and result.delivery.token~=serverState.delivery.token then return end
		-- An initial snapshot can arrive after a newer profile-loaded event.
		if payload.action == "State" and stateVersion ~= observedVersion then return end
		if ok and type(result) == "table" then
			showState(result)
			if result.ok and result.phase == "Ready" then pendingOperation, pendingSignature = nil, nil end
		end
		if payload.action == "Save" then
			if ok and type(result) == "table" and result.ok then dialog.Close()
			else
				status.Text = ""
				dialog.Show(if ok and type(result) == "table" then result.message or "Please try again." else "Couldn’t confirm your save. Your look is still here. Retry safely.", "Retry save →", "Back", function() request(payload) end, true)
			end
		elseif not ok then
			status.Text = "Connection interrupted. Please try again."
		end
	end
	local function saveChoice(mode)
		local signature = mode .. HttpService:JSONEncode(look)
		if signature ~= pendingSignature then pendingSignature, pendingOperation = signature, HttpService:GenerateGUID(false) end
		request({action = "Save", mode = mode, look = if mode == "Custom" then table.clone(look) else nil, operationId = pendingOperation})
	end
	local function createRacer()
		if busy or dialog.IsOpen() then return end
		highlight(1)
		inEditor = true
		ui.SetLook(if serverState.profile and serverState.profile.look then serverState.profile.look else Config.DefaultLook)
		showState(serverState); focus(save)
	end
	create.Activated:Connect(createRacer)
	stage.HitTargets[1].Activated:Connect(createRacer)
	back.Activated:Connect(function() if not busy then inEditor = false; showState(serverState); focus(create) end end)
	local function chooseAvatar()
		if busy or dialog.IsOpen() then return end
		highlight(2)
		dialog.Show("Ready to join with this look?", "Let’s play →", "Go back", function() saveChoice("Avatar") end)
	end
	useAvatar.Activated:Connect(chooseAvatar)
	stage.HitTargets[2].Activated:Connect(chooseAvatar)
	save.Activated:Connect(function()
		if busy or dialog.IsOpen() then return end
		dialog.Show("Save your racer and head to the lobby?", "Save & play →", "Keep editing", function() saveChoice("Custom") end)
	end)
	cancel.Activated:Connect(function() request({action = "Cancel"}) end)
	canOpenRacer = function()
		return not busy and not dialog.IsOpen() and serverState.phase == "Ready" and raceStatus == "Lobby"
			and player:GetAttribute("ArrivalOpen") ~= true and player:GetAttribute("TournamentPresentation") ~= true
			and player:GetAttribute("TournamentCourseReady") ~= false
	end
	openRacer = function()
		if canOpenRacer and canOpenRacer() then request({action = "Edit"}) end
	end
	reopen.Visible = false
	retry.Activated:Connect(function() request({action = "Retry"}) end)
	soundButton.Activated:Connect(function()
		muted = not muted; soundButton.Text = if muted then "Sound off" else "Sound on"
		player:SetAttribute("SoundMuted",muted)
		music.Volume = if muted then 0 else Config.AmbientVolume
		if not muted and active and music.SoundId ~= "" and not music.IsPlaying then music:Play() end
	end)
	motionButton.Activated:Connect(function()
		reducedMotion = not reducedMotion
		player:SetAttribute("ReducedMotion",reducedMotion)
		motionButton.Text = if reducedMotion then "Motion off" else "Motion on"
		stage.SetMotion(not reducedMotion)
		dialog.SetMotion(not reducedMotion)
	end)
	player:GetAttributeChangedSignal("ReducedMotion"):Connect(function()
		reducedMotion=player:GetAttribute("ReducedMotion")==true
		motionButton.Text=if reducedMotion then "Motion off" else "Motion on"
		stage.SetMotion(not reducedMotion); dialog.SetMotion(not reducedMotion)
	end)
	setActive(true)
	local boot = playerGui:FindFirstChild("ArrivalBoot")
	if boot then boot:Destroy() end
	RunService.RenderStepped:Connect(function(dt)
		if active then ui.Update(dt, reducedMotion) end
	end)
	task.spawn(function()
		local module = player.PlayerScripts:WaitForChild("PlayerModule", 15)
		if module then controls = require(module):GetControls(); if active then controls:Disable() end end
	end)
	task.spawn(function()
		local ok, description = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId) end)
		if ok then stage.SetDescription(description) end
	end)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		while not remote do
			remote = remotes:WaitForChild("ArrivalControl", 15)
			if not remote then status.Text = "Still connecting to the server…" end
		end
		changed = remotes:WaitForChild("ArrivalChanged")
		remotes:WaitForChild("PlayerRaceStatusChanged").OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.userId == player.UserId then
				raceStatus = payload.status
			reopen.Visible = false
			end
		end)
		changed.OnClientEvent:Connect(function(state)
			stateVersion += 1
			if state.preset ~= serverState.preset then
				transition.Cancel(); dialog.Close(); highlight(0)
				inEditor,presentedReady = false,false
				pendingOperation,pendingSignature = nil,nil
				if state.phase=="Ready" then setActive(true) end
			end
			showState(state)
		end)
		request({action = "State"})
	end)
end

return Controller
