--!nonstrict
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
local Gate = {}
local receiptId = "Original07BlockedArrival01"
local limits = "Diagnostic course movement/contact/lifecycle only. Actual lobby preload failed; arrival, player input, UI, camera and audio usability are excluded. No arrival attributes, UI or controls are changed."

function Gate.Capture(player)
	local encoded = player:GetAttribute("MCPhase2ArrivalScope")
	local ok, server = pcall(Http.JSONDecode, Http, encoded or "")
	local progressEncoded = player:GetAttribute("MCPhase2Progress")
	local progressOk, progress = pcall(Http.JSONDecode, Http, progressEncoded or "")
	return {at=workspace:GetServerTimeNow(), placeId=game.PlaceId, gameId=game.GameId, creatorId=game.CreatorId,
		userId=player.UserId, characterPath=player.Character and player.Character:GetFullName(),
		arrivalPhase=player:GetAttribute("ArrivalPhase"), arrivalOpen=player:GetAttribute("ArrivalOpen"),
		transitionPhase=player:GetAttribute("ArrivalTransitionPhase"), onboardingReady=player:GetAttribute("OnboardingReady"),
		server=ok and server or nil, progress=progressOk and progress or nil}
end

function Gate.Check(player, requestedReceipt)
	local snapshot = Gate.Capture(player)
	if snapshot.arrivalOpen==false then return true,{exception=false,start=snapshot} end
	local server = snapshot.server
	local permitted = requestedReceipt==receiptId and RunService:IsStudio() and RunService:IsClient()
		and game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177
		and require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId=="MC_P2_C01_R06"
		and snapshot.arrivalOpen==true and snapshot.transitionPhase=="Failed" and snapshot.arrivalPhase=="Ready" and snapshot.onboardingReady==true
		and server and server.ok==true and server.source=="actual-OnboardingService-State" and server.userId==player.UserId
		and server.phase=="Ready" and server.preset=="Returning racer" and server.studio==true
		and server.placeId==game.PlaceId and server.gameId==game.GameId and server.creatorId==game.CreatorId
		and server.arrivalPhase=="Ready" and server.onboardingReady==true and server.characterPath==snapshot.characterPath
		and type(server.observedAt)=="number" and snapshot.at-server.observedAt>=-.05 and snapshot.at-server.observedAt<=1.5
	return permitted==true,{exception=permitted==true,receiptId=requestedReceipt,
		failureEvidence="revision06/ORIGINAL07_ARRIVAL_SETUP_BLOCK.json",limits=limits,start=snapshot}
end

return Gate
