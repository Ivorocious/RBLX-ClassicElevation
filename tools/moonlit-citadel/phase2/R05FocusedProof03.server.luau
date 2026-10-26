--!nonstrict
assert(game.PlaceId==0 and game.GameId==0 and game.RunService:IsStudio() and game.RunService:IsServer())
local Control=require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local tools=game.ReplicatedStorage.MoonlitPhase2Tools
assert(tools:GetAttribute('R05ProofReady') and not tools:GetAttribute('R05ProofFailure'))
assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId=='MC_P2_C01_R05')
local ok,value=xpcall(Control.Restart,debug.traceback)
tools:SetAttribute('R05ProofRestart03',game.HttpService:JSONEncode({ok=ok,value=value,at=workspace:GetServerTimeNow()}))
