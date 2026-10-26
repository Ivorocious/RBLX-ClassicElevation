--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config.OnboardingConfig)
local Profile = require(ReplicatedStorage.Shared.ArrivalProfile)
local Appearance = require(ReplicatedStorage.Shared.RacerAppearance)
local Delivery = require(script.Parent.ArrivalDelivery)
local Service = {}
local sessions: {[Player]: any} = {}
local services: any
local changed: RemoteEvent
local store: any = nil

local function snapshot(session, ok: boolean?, message: string?)
	return {ok = ok ~= false, message = message, phase = session.phase,
		profile = session.profile, studio = RunService:IsStudio(), preset = session.preset, delivery = session.delivery}
end

local function notify(player, session)
	if player.Parent == Players then
		player:SetAttribute("Gold", if session.profile then session.profile.gold else nil)
		player:SetAttribute("ArrivalPhase", session.phase)
		changed:FireClient(player, snapshot(session))
	end
end

local function hold(player, session)
	player:SetAttribute("OnboardingReady", false)
	local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		if not session.lock or session.lock.root ~= root then session.lock = {root = root, anchored = root.Anchored} end
		root.Anchored = true
	end
end

local function release(player, session)
	Delivery.Release(player)
	session.delivery, session.introRequired = nil, false
	local lock = session.lock
	if lock and lock.root.Parent then lock.root.Anchored = lock.anchored end
	session.lock = nil
	session.phase = "Ready"
	player:SetAttribute("OnboardingReady", true)
	notify(player, session)
end

local function applyAppearance(player, session): boolean
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	local ok, err = pcall(function()
		local description
		if session.profile.mode == "Custom" then
			description = Appearance.Description(session.profile.look)
		else
			if not session.original then session.original = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId) end
			description = session.original:Clone()
		end
		if sessions[player] ~= session or player.Character ~= character then description:Destroy(); return end
		description.UseAvatarSettings = true
		humanoid:ApplyDescriptionResetAsync(description)
		description:Destroy()
	end)
	if not ok then warn("[Arrival] Appearance unavailable: " .. tostring(err)) end
	return ok and player.Character == character and sessions[player] == session
end

local function finish(player, session)
	-- A saved choice survives an appearance delivery failure; retry never grants another bonus.
	if not applyAppearance(player, session) then
		session.phase = "Choice"
		notify(player, session)
		return snapshot(session, false, "Look saved. Your avatar is still loading — try again.")
	end
	if sessions[player] == session then
		if session.introRequired then
			session.delivery = session.delivery or Delivery.Prepare(player,session.preset)
			session.phase = "Entering"
			hold(player, session)
			notify(player, session)
		else release(player, session) end
	end
	return snapshot(session)
end

local function load(player, session)
	if session.loading or session.busy then return end
	session.loading, session.phase = true, "Loading"
	hold(player, session)
	notify(player, session)
	if session.preset == "Slow loading" then task.wait(8) end
	local ok, result = pcall(function()
		if session.preset == "Load failure" then error("Simulated read failure") end
		return Profile.Read(if RunService:IsStudio() then session.profile else store:GetAsync("Player_" .. player.UserId), Config)
	end)
	session.loading = false
	if sessions[player] ~= session or player.Parent ~= Players then return end
	if not ok then
		session.phase = "LoadError"
		notify(player, session)
		return
	end
	session.profile = result
	session.introRequired = not result.completed or session.preset == "Lobby entrance" or session.preset == "Slow lobby delivery" or session.preset == "Lobby delivery failure"
	if session.introRequired then session.delivery = Delivery.Prepare(player,session.preset) end
	if result.completed then
		session.busy = true
		finish(player, session)
		session.busy = false
	else
		session.phase = "Choice"
		notify(player, session)
	end
end

function Service.Init(context)
	services = context.Services
end

function Service.HandleRequest(player, payload)
	local session = sessions[player]
	if not session or type(payload) ~= "table" then return {ok = false, message = "Arrival is loading."} end
	if payload.action == "State" then return snapshot(session) end
	if session.busy or session.loading then return snapshot(session, false, "Please wait a moment.") end
	if os.clock() - (session.lastRequest or 0) < 0.4 then return snapshot(session, false, "Please wait a moment.") end
	session.lastRequest = os.clock()
	if payload.action == "Retry" and session.phase == "LoadError" then
		-- A simulated failure clears on Retry; real failures continue to protect the saved profile.
		if RunService:IsStudio() then session.preset = nil end
		task.spawn(load, player, session)
		return snapshot(session)
	end
	if not session.profile or session.phase == "LoadError" then return snapshot(session, false, "Your saved data is not ready. Please retry.") end
	if payload.action == "Arrived" then
		if session.phase == "Ready" then return snapshot(session) end
		if not Delivery.CanEnter(player,payload,session) then return snapshot(session,false,"Lobby is not ready. Please retry.") end
		release(player,session)
		return snapshot(session)
	end
	if payload.action == "Edit" then
		if session.phase ~= "Ready" or services.PlayerRaceService.GetPlayerStatus(player) ~= "Lobby"
			or player:GetAttribute("TournamentCourseReady") == false then
			return snapshot(session, false, "Change your look when you are back in the lobby.")
		end
		session.phase = "Choice"
		hold(player, session)
		notify(player, session)
		return snapshot(session)
	end
	if payload.action == "Cancel" and session.profile.completed and session.phase == "Choice" then
		session.busy = true
		local result = finish(player, session)
		session.busy = false
		return result
	end
	if payload.action ~= "Save" or session.phase ~= "Choice" then return snapshot(session, false, "Choose your look first.") end
	if payload.mode ~= "Avatar" and payload.mode ~= "Custom" then return snapshot(session, false, "Choose a valid avatar.") end
	if payload.mode == "Custom" and not Profile.ValidLook(payload.look, Config) then return snapshot(session, false, "Choose an available style.") end
	if type(payload.operationId) ~= "string" or #payload.operationId < 8 or #payload.operationId > 64 or not payload.operationId:match("^[%w%-]+$") then
		return snapshot(session, false, "Please retry your choice.")
	end
	session.busy = true
	local observed
	local ok, result = pcall(function()
		if session.preset == "Save failure" then session.preset = nil; error("Simulated write failure") end
		local function transform(current)
			local latest = Profile.Read(current, Config)
			if latest.lastOperationId == payload.operationId then return latest end
			if latest.revision ~= session.profile.revision then observed = latest; return nil end
			return Profile.Commit(latest, payload.mode, payload.look, payload.operationId, Config)
		end
		if RunService:IsStudio() then return transform(session.profile) end
		return store:UpdateAsync("Player_" .. player.UserId, transform)
	end)
	if sessions[player] ~= session then return {ok = false, message = "Session changed. Please retry."} end
	if not ok or not result then
		session.busy = false
		if observed then session.profile = observed end
		return snapshot(session, false, if observed then "Your saved look changed. Review and save again." else "Could not save. Your choice is still here — try again.")
	end
	session.profile = result
	local response = finish(player, session)
	session.busy = false
	return response
end

function Service.SetStudioPreset(player, preset)
	if not RunService:IsStudio() or not table.find(Config.StudioPresets, preset) then return false, "Unknown arrival preset." end
	local previous = sessions[player]
	if previous and (previous.busy or previous.loading) then return false, "Wait for the current arrival request." end
	Delivery.Release(player)
	if previous and previous.lock and previous.lock.root.Parent then previous.lock.root.Anchored = previous.lock.anchored end
	local profile = Profile.New()
	if preset == "Returning avatar" or preset == "Bonus available" or preset == "Lobby entrance" or preset == "Slow lobby delivery" or preset == "Lobby delivery failure" then profile = Profile.Commit(profile, "Avatar", nil, "studio-avatar", Config) end
	if preset == "Returning racer" or preset == "Bonus claimed" then profile = Profile.Commit(profile, "Custom", Config.DefaultLook, "studio-custom", Config) end
	local session = {phase = "Loading", profile = profile, preset = preset, original = if previous then previous.original else nil}
	sessions[player] = session
	hold(player, session)
	services.PlayerRaceService.SetPlayerStatus(player, "Lobby", "Arrival test preset")
	services.StagingService.ReturnPlayersToLobby({player}, "Arrival test preset")
	if preset == "Bonus available" or preset == "Bonus claimed" then session.phase = "Choice"; notify(player, session)
	else task.spawn(load, player, session) end
	return true, preset .. " (temporary Studio data)."
end

local function added(player)
	if sessions[player] then return end
	local session = {phase = "Loading"}
	sessions[player] = session
	hold(player, session)
	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			local root = character:WaitForChild("HumanoidRootPart", 15)
			if root and player.Character == character then
				local current = sessions[player]
				if current and current.phase ~= "Ready" then hold(player, current) end
			end
		end)
	end)
	player.CharacterAppearanceLoaded:Connect(function()
		local current = sessions[player]
		if current and current.profile and current.profile.completed and not current.busy then
			current.busy = true
			task.spawn(function()
				applyAppearance(player, current)
				current.busy = false
			end)
		end
	end)
	task.spawn(function()
		if not player.Character then player.CharacterAdded:Wait() end
		if player.Character then player.Character:WaitForChild("Humanoid", 15) end
		load(player, session)
	end)
end

function Service.Start()
	if not RunService:IsStudio() then store = DataStoreService:GetDataStore(Config.DataStoreName) end
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	changed = Instance.new("RemoteEvent")
	changed.Name, changed.Parent = "ArrivalChanged", folder
	local remote = Instance.new("RemoteFunction")
	remote.Name = "ArrivalControl"
	remote.OnServerInvoke = function(player, payload)
		local ok, result = pcall(Service.HandleRequest, player, payload)
		if ok then return result end
		warn("[Arrival] Request failed: " .. tostring(result))
		local session = sessions[player]
		if session then session.busy = false; return snapshot(session, false, "Could not finish. Please try again.") end
		return {ok = false, message = "Please reconnect."}
	end
	remote.Parent = folder
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(player)
		Delivery.Release(player)
		local session = sessions[player]
		if session and session.original then session.original:Destroy() end
		sessions[player] = nil
	end)
	for _, player in Players:GetPlayers() do added(player) end
end

return Service
