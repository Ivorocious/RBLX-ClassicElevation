--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0 and game.GameId == 0, "Owned native fixture only")
local player = Players.LocalPlayer
local tools = game.ReplicatedStorage:WaitForChild("MoonlitPhase2Tools")
local Suite = require(tools:WaitForChild("ClientSuite"))
local Probe = require(tools.ClientProbe)
local folder = Instance.new("Folder")
folder.Name = "MCPhase2NativeSuite"
folder:SetAttribute("OwnedMoonlitTest", true)
folder.Parent = player:WaitForChild("PlayerGui")
local function save(name, value)
	local encoded = HttpService:JSONEncode(value)
	local count = math.ceil(#encoded / 140000)
	for index = 1, count do
		local key = name .. string.format("_%03d", index)
		local row = folder:FindFirstChild(key) or Instance.new("StringValue")
		row.Name, row.Value, row.Parent = key, encoded:sub((index-1)*140000+1,index*140000), folder
	end
	folder:SetAttribute(name .. "Chunks", count)
	folder:SetAttribute(name .. "Bytes", #encoded)
end
local ok, reason = xpcall(function()
	local deadline = os.clock() + 180
	repeat
		assert(os.clock() < deadline, "Native suite readiness timed out")
		assert(not tools:GetAttribute("NativeSuiteFailure"), tools:GetAttribute("NativeSuiteFailure"))
		task.wait(.1)
	until tools:GetAttribute("NativeSuiteReady") and player:GetAttribute("ArrivalPhase") == "Ready" and player:GetAttribute("ArrivalOpen") == false
	local first = player.UserId == -1
	assert(first or player.UserId == -2, "Expected the two actual native test users")
	local schedule = if first then {{name="NNN"},{name="NNE"},{name="NEN"},{name="NEE"},{name="NNN",catch="Arch"}}
		else {{name="EEE"},{name="EEN"},{name="ENE"},{name="ENN"},{name="EEE",catch="Upper"}}
	folder:SetAttribute("ClientProbeSHA256", "a1cc914081d30427710d886bd405156bd6f5004e60b6766854c1f95125b617ea")
	folder:SetAttribute("ReadyAt", workspace:GetServerTimeNow())
	Suite.Start(schedule, {crownLaneOffset=if first then -2.5 else 2.5})
	while true do
		local suite, trial = Suite.Current(), Probe.Current()
		save("Suite", suite)
		if trial then save("Trial", trial) end
		folder:SetAttribute("State", suite.state)
		folder:SetAttribute("CurrentTrial", suite.currentTrial)
		folder:SetAttribute("CompletedTrials", #suite.trials)
		folder:SetAttribute("TrialState", if trial then trial.state else nil)
		folder:SetAttribute("TrialNode", if trial then trial.nodeIndex else nil)
		if suite.state == "Complete" or suite.state == "Failed" then break end
		task.wait(1)
	end
end, debug.traceback)
if not ok then folder:SetAttribute("Failure", tostring(reason)); Suite.Stop(tostring(reason)); warn(reason) end
