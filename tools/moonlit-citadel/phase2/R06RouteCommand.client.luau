--!nonstrict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsClient())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
assert(script:GetAttribute("OwnedMoonlitTest") == true and script:GetAttribute("RunRouteCommands") == true)
local player = game.Players.LocalPlayer
assert(player.UserId == 86069177)
local tools = game.ReplicatedStorage.MoonlitPhase2Tools
tools:SetAttribute("R06RouteClientReady", false)
assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId == "MC_P2_C01_R06")
local Runner = require(tools.R06CatchRouteRunner)
local Case = require(tools.R06NoJumpRepresentative)
local seen = {}
local seenIds = {}
local receipts = 0
local started = os.clock()
local history = Instance.new("Folder")
history.Name = "R06RouteClientDispatch_" .. HttpService:GenerateGUID(false):gsub("%-", "")
history:SetAttribute("OwnedMoonlitTest", true)
history.Parent = tools
local initialRaw = tools:GetAttribute("R06RouteCommand")
if type(initialRaw) == "string" then
	seen[initialRaw] = true
	local decoded, initialRequest = pcall(HttpService.JSONDecode, HttpService, initialRaw)
	if decoded and type(initialRequest) == "table" and initialRequest.side == "Client" and type(initialRequest.id) == "string" then
		seenIds[initialRequest.id] = true
	end
	local ignored = Instance.new("StringValue")
	ignored.Name, ignored.Value, ignored.Parent = "InitialCommandIgnored", initialRaw:sub(1, 12000), history
end
tools:SetAttribute("R06RouteClientReady", true)
tools:SetAttribute("R06RouteClientEvidence", history:GetFullName())
while script.Parent and tools.Parent and os.clock() - started < 2100 and receipts < 256
	and script:GetAttribute("OwnedMoonlitTest") == true and script:GetAttribute("RunRouteCommands") == true do
	local raw = tools:GetAttribute("R06RouteCommand")
	if type(raw) == "string" and not seen[raw] then
		seen[raw] = true
		local request, invoked
		local ok, value = xpcall(function()
			assert(#raw <= 12000, "Bound temporary route commands to 12000 bytes")
			request = HttpService:JSONDecode(raw)
			assert(type(request) == "table" and type(request.id) == "string" and #request.id <= 80
				and request.id:match("^%w+$") and request.candidate == "MC_P2_C01_R06")
			assert(request.side == "Server" or request.side == "Client", "Explicit execution side required")
			if request.side ~= "Client" then return end
			assert(not seenIds[request.id], "Reuse of a dispatch command ID rejected")
			seenIds[request.id] = true
			assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsClient()
				and game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177
				and player.UserId == 86069177 and script:GetAttribute("OwnedMoonlitTest") == true
				and script:GetAttribute("RunRouteCommands") == true)
			assert(request.action == "StartCatch" or request.action == "CatchState" or request.action == "RunNoJump", "Unknown client dispatch action")
			if request.action == "StartCatch" then invoked = true; return Runner.Start({authorizedCatchRoutes = true}) end
			if request.action == "CatchState" then
				invoked = true
				local current = assert(Runner.Current())
				return {state = current.state, failure = current.failure, owner = current.owner,
					evidencePath = current.evidencePath, summaries = current.summaries, currentTrial = current.currentTrial,
					waitingForTrial = current.waitingForTrial, suiteState = current.suite and current.suite.state}
			end
			assert(request.action == "RunNoJump" and type(request.owner) == "string"
				and #request.owner <= 90 and request.owner:match("^MC_P2_C01_R06_NoJump_%x+$"))
			invoked = true
			local result = Case.RunClient(request.owner)
			return {state = result.state, failure = result.failure, owner = result.owner, outcome = result.outcome,
				straightWalkingFailed = result.straightWalkingFailed, walkableFalsifier = result.walkableFalsifier,
				jumpRequests = #result.jumpRequests, samples = #result.samples}
		end, debug.traceback)
		if type(request) ~= "table" then request = nil end
		if not ok or (request and request.side == "Client") then
			receipts += 1
			local result = {id = request and request.id, action = request and request.action, ok = ok, result = value,
				invoked = invoked == true, at = workspace:GetServerTimeNow(), requestRaw = raw:sub(1, 12000), requestTruncated = #raw > 12000}
			local encoded = HttpService:JSONEncode(result)
			local entry = Instance.new("StringValue")
			entry.Name, entry.Value, entry.Parent = string.format("Command_%03d", receipts), encoded, history
			history:SetAttribute("Receipts", receipts)
			tools:SetAttribute("R06RouteClientResult", encoded)
		end
	end
	task.wait(.1)
end
tools:SetAttribute("R06RouteClientReady", false)
