--!nonstrict
assert(game.PlaceId==0 and game.GameId==0 and game.RunService:IsStudio() and game.RunService:IsServer())
local H=game.HttpService
local tools=game.ReplicatedStorage.MoonlitPhase2Tools
local Control=require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local Config=require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
assert(Config.CandidateId=="MC_P2_C01_R05")
local ok,err=xpcall(function()
 local services=Control.Services()
 local players=game.Players:GetPlayers()
 assert(#players==1 and players[1]:GetAttribute("ArrivalPhase")=="Ready")
 assert(H:JSONDecode(tools.Routes_EEE.Value).candidate==Config.CandidateId)
 assert(services.RaceService.IsStudioHoldingLobby())
 tools:SetAttribute("R05ProofFailure",nil)
 tools:SetAttribute("R05ProofSetup",H:JSONEncode({candidate=Config.CandidateId,actualPlayers=1,userId=players[1].UserId,method="Actual server Script with shared inspection flow; server arrival Ready, client independently verifies local ArrivalOpen=false; existing observer/payloads preserved"}))
 tools:SetAttribute("R05ProofReady",true)
 task.wait(3)
 tools:SetAttribute("R05ProofRestart",H:JSONEncode(Control.Restart()))
end,debug.traceback)
if not ok then tools:SetAttribute("R05ProofFailure",tostring(err)) end
