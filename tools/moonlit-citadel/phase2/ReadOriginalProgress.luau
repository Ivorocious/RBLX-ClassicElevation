local HttpService = game:GetService("HttpService")
assert(game.RunService:IsStudio() and game.RunService:IsRunning() and game.RunService:IsClient())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
local player = game.Players.LocalPlayer
local folder = player.PlayerGui:FindFirstChild("MC_P2_C01_R06_Verification")
local out = {userId = player.UserId, arrivalOpen = player:GetAttribute("ArrivalOpen"),
	arrivalPhase = player:GetAttribute("ArrivalPhase"), report = folder and folder:GetAttributes(),
	progress = HttpService:JSONDecode(player:GetAttribute("MCPhase2Progress") or "{}")}
if folder then
	local chunks = {}
	for _, item in folder:GetChildren() do
		if item:IsA("StringValue") and item.Name:match("^Suite_%d+$") then table.insert(chunks, item) end
	end
	table.sort(chunks, function(a, b) return a.Name < b.Name end)
	local pieces = {}
	for _, item in chunks do table.insert(pieces, item.Value) end
	local ok, suite = pcall(function() return HttpService:JSONDecode(table.concat(pieces)) end)
	if ok then
		out.trials = {}
		for _, row in suite.trials or {} do
			local report = row.report or {}
			local final = report.final or {}
			local scope = report.arrivalScope or {}
			table.insert(out.trials, {name = row.name, state = report.state, complete = report.complete,
				elapsed = report.elapsed, steps = #(report.steps or {}), failure = report.failure,
				raceId = report.raceId, checkpoint = final.checkpoint, falls = final.falls, status = final.status,
				finishContact = final.finishContact, guard = report.terminalGuard and report.terminalGuard.decision,
				scopeValid = scope.endedValid, exceptionUsed = scope.exceptionUsed})
		end
		out.suiteFailure = suite.failure
	else out.decodeFailure = tostring(suite) end
end
return HttpService:JSONEncode(out)
