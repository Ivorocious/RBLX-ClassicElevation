--!strict

local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(), "Studio server only")
assert(game.PlaceId == 85558151074819 and workspace:GetAttribute("StudGardenTestEnabled") == true, "Explicit owned test required")
local bridge = game.ServerStorage.StudGardenTestSession
assert(bridge:GetAttribute("Ready") and not bridge:FindFirstChild("CrowdBatchReports"), "Preserve existing batch")
local value = Instance.new("StringValue")
value.Name, value.Parent = "CrowdBatchReports", bridge
local cases = {"H01_Clear", "H02_Clear", "K1_Merge", "K2_Merge", "R1_Returns", "R2_Returns", "R3_Returns", "R4_Returns"}
local reports = {}
local began = os.clock()
local ok, failure = xpcall(function()
	for _, id in cases do
		assert(os.clock() - began < 200, "Batch deadline")
		assert(bridge:GetAttribute("CrowdBusy") ~= true, "Existing crowd case is busy")
		bridge:SetAttribute("CrowdBatchCase", id)
		local hazardId = id:match("^(H0[12])_Clear$")
		if hazardId then
			local hazard = workspace.RaceCourse.Art.HazardVisuals[hazardId]
			local started = os.clock()
			local sawNonClear = hazard:GetAttribute("HazardPhase") ~= "Clear"
			repeat
				if hazard:GetAttribute("HazardPhase") ~= "Clear" then sawNonClear = true end
				assert(os.clock() - started < 20, "Fresh Clear transition unavailable")
				task.wait(0.02)
			until sawNonClear and hazard:GetAttribute("HazardPhase") == "Clear"
		end
		bridge.Command:Invoke("StartCrowd", {caseId=id})
		local started = os.clock()
		while bridge:GetAttribute("CrowdBusy") == true do
			assert(os.clock() - started < 22, "Case did not stop within its total deadline")
			task.wait(0.1)
		end
		table.insert(reports, Http:JSONDecode(bridge.Command:Invoke("CrowdReport")))
		value.Value = Http:JSONEncode(reports)
	end
end, function(message) return debug.traceback(tostring(message), 2) end)
if not ok then
	bridge.Command:Invoke("StopCrowd")
	bridge:SetAttribute("CrowdBatchError", failure)
end
bridge:SetAttribute("CrowdBatchComplete", true)
bridge:SetAttribute("CrowdBatchElapsed", os.clock() - began)
value.Value = Http:JSONEncode(reports)
