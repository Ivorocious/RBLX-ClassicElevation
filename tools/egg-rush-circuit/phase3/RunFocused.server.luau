--!nonstrict
local RunService, ServerStorage = game:GetService("RunService"), game:GetService("ServerStorage")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server required")
local kind = script:GetAttribute("Kind") or "Peck"
assert(kind == "Peck" or kind == "Normal", "Focused Peck or Normal only")
local expected = script:GetAttribute("ExpectedCandidateId") or "ER_P2_R05_C01"
local laps = script:GetAttribute("Laps") or 1
local reportName = script:GetAttribute("ReportName") or ("EggRushPhase3" .. kind .. "Report")
assert(not ServerStorage:FindFirstChild(reportName), "Preserve the previous test receipt")
local report = Instance.new("StringValue")
report.Name, report.Parent = reportName, ServerStorage
report:SetAttribute("State", "Ready")
local used = false
report:GetAttributeChangedSignal("Run"):Connect(function()
 if used or report:GetAttribute("Run") ~= true then return end
 used = true
 task.spawn(function()
  report:SetAttribute("State", "Running")
  local ok, value = xpcall(function()
   local folder = assert(ServerStorage:FindFirstChild("EggRushPhase3Tests"), "Install only the two preparation ModuleScripts in EggRushPhase3Tests")
   return require(folder["EggRushPhase3" .. kind]).Run(expected, laps)
  end, debug.traceback)
  local result = if ok then value else {ok=false,failure=tostring(value),complete=false}
  local encoded = game.HttpService:JSONEncode(result)
  if #encoded <= 190000 then report.Value = encoded
  else
   local chunks = math.ceil(#encoded / 150000)
   for index=1,chunks do
    local child=Instance.new("StringValue"); child.Name=string.format("Payload_%02d",index)
    child.Value=encoded:sub((index-1)*150000+1,index*150000); child.Parent=report
   end
   report.Value=game.HttpService:JSONEncode({ok=result.ok,complete=result.complete,format="OrderedPayloadChunks",chunks=chunks,bytes=#encoded})
  end
  report:SetAttribute("State", if result.ok then "Complete" else "Failed")
 end)
end)
