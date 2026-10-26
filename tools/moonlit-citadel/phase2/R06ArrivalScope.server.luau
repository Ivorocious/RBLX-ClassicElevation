--!nonstrict
local RunService, Http, Players = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId=="MC_P2_C01_R06")
local Onboarding = require(game.ServerScriptService.Services.OnboardingService)
while script.Parent do
	for _, player in Players:GetPlayers() do
		local ok, state = pcall(Onboarding.HandleRequest, player, {action="State"})
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		player:SetAttribute("MCPhase2ArrivalScope", Http:JSONEncode({
			source="actual-OnboardingService-State", userId=player.UserId, observedAt=workspace:GetServerTimeNow(),
			placeId=game.PlaceId, gameId=game.GameId, creatorId=game.CreatorId, ok=ok,
			phase=ok and state.phase or nil, preset=ok and state.preset or nil, studio=ok and state.studio or nil,
			arrivalPhase=player:GetAttribute("ArrivalPhase"), onboardingReady=player:GetAttribute("OnboardingReady"),
			characterPath=character and character:GetFullName(), root=root and {root.Position.X,root.Position.Y,root.Position.Z},
		}))
	end
	task.wait(.2)
end
