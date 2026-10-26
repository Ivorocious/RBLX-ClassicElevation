--!nonstrict
local RS, H=game:GetService("RunService"),game.HttpService
assert(RS:IsStudio() and RS:IsClient())
local player=game.Players.LocalPlayer
local flowScript=player.PlayerScripts:WaitForChild("ERP2CloseoutFlowClient")
local report=flowScript:WaitForChild("EggRushP2FlowClientReport")
local Flow=require(player.PlayerScripts.Controllers.RaceFlowController)
local control=game.ReplicatedStorage:WaitForChild("ERP2CloseoutControl")
local seen={}
local stored=Instance.new("StringValue")
stored.Name,stored.Parent="ERP2CloseoutClientReport",script
local out={commands={},method="Existing supported client action helper; no camera/readiness flags or movement writes"}
local function waitFor(predicate,seconds)
 local deadline=os.clock()+seconds
 repeat RS.Heartbeat:Wait() until predicate() or os.clock()>=deadline
 assert(predicate(),"Closeout client action timed out")
end
local function changed()
 local phase=control:GetAttribute("Phase")
 if seen[phase] or not table.find({"ArrivalAndEntry","FinishAndRetry","BreakAfterFinish"},phase) then return end
 seen[phase]=true
 task.spawn(function()
  local ok,failure=xpcall(function()
   waitFor(function() return report:GetAttribute("State")~="Running" end,15)
   if phase=="BreakAfterFinish" then waitFor(function() return Flow.GetState().status=="Lobby" end,20) end
   local action=if phase=="BreakAfterFinish" then "Break" else phase
   table.insert(out.commands,{action=action,serverTime=workspace:GetServerTimeNow()})
   flowScript:SetAttribute("Command",H:JSONEncode({action=action,mode="Custom"}))
  end,debug.traceback)
  out.ok,out.failure=ok,if ok then nil else failure
  stored.Value=H:JSONEncode(out)
 end)
end
local connection=control:GetAttributeChangedSignal("Phase"):Connect(changed)
script.Destroying:Connect(function() connection:Disconnect() end)
changed()
