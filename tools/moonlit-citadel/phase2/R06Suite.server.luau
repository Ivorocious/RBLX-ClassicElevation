--!nonstrict
local RunService, Players, HttpService = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0)
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
assert(Config.CandidateId == "MC_P2_C01_R06")
local tools = game.ReplicatedStorage:WaitForChild("MoonlitPhase2Tools")
local Control = require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local function await(test, seconds, message)
	local deadline = os.clock() + seconds
	repeat if test() then return end; task.wait(.1) until os.clock() >= deadline
	error(message)
end
local ok, reason = xpcall(function()
	local services = Control.Services()
	await(services.RaceService.IsStudioHoldingLobby, 60, "Shared lobby startup timeout")
	await(function() return #Players:GetPlayers() >= 1 end, 90, "Actual client absent")
	for _, player in Players:GetPlayers() do
		tools:SetAttribute("R06SetupPhase", "Waiting for loaded character")
		await(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return character and character:IsDescendantOf(workspace) and humanoid and humanoid.Health > 0
				and character:FindFirstChild("HumanoidRootPart") and player:HasAppearanceLoaded()
		end, 120, "Actual character appearance incomplete")
		task.wait(12)
		tools:SetAttribute("R06SetupPhase", "Existing Studio arrival preset")
		await(function() return services.OnboardingService.SetStudioPreset(player, "Returning racer") end, 30, "Studio arrival preset unavailable")
	end
	if not tools:FindFirstChild("Routes_NNN") then Control.PrepareRoutes() end
	for _, name in {"NNN", "NNE", "NEN", "NEE", "ENN", "ENE", "EEN", "EEE"} do
		local packet = HttpService:JSONDecode(assert(tools:FindFirstChild("Routes_" .. name)).Value)
		assert(packet.candidate == Config.CandidateId, "Wrong frozen route packet " .. name)
	end
	await(function()
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("ArrivalPhase") ~= "Ready" then return false end
			assert(type(player:GetAttribute("MCPhase2Progress")) == "string", "Actual ServerProbe bootstrap required")
		end
		return true
	end, 180, "Actual lobby arrival incomplete")
	task.wait(10)
	tools:SetAttribute("R06SetupPhase", "Ready")
	tools:SetAttribute("R06VerificationReady", true)
	task.wait(3)
	tools:SetAttribute("R06VerificationRestart", HttpService:JSONEncode(Control.Restart()))
end, debug.traceback)
if not ok then tools:SetAttribute("R06VerificationFailure", tostring(reason)); warn(reason) end
