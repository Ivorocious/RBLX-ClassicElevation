--!nonstrict
local RS, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId == 85558151074819)
local testArgs = game:GetService("StudioTestService"):GetTestArgs()
local ownedTag = script:GetAttribute("OwnedTestTag")
assert((typeof(testArgs) == "table" and testArgs.tag == ownedTag)
 or (testArgs == nil and ownedTag == "EggRush_P2_C05_Solo"))
local Course = require(game.ServerScriptService.Services.CourseService)
local Runtime = require(game.ServerScriptService.Services.EggRushService)
local value = Instance.new("StringValue")
value.Name, value.Parent = "ERP2ContactTrace", Storage
local report = {method="Passive production RespawnService log plus recent physical frames; no service, avatar, geometry or clock writes", recoveries={}}
local recent, nextSample = {}, 0
local bodies = {Head=true,UpperTorso=true,LowerTorso=true,LeftHand=true,RightHand=true,LeftFoot=true,RightFoot=true}
local function vector(v) return {v.X,v.Y,v.Z} end
RS.PreSimulation:Connect(function()
 if os.clock() < nextSample then return end
 nextSample = os.clock()+.05
 local course = Course.GetActiveCourse()
 if not course or course:GetAttribute("CourseId")~="egg_rush_circuit" then return end
 local player = game.Players:GetPlayers()[1]
 local char = player and player.Character
 if not char then return end
 local root = char:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local row={clock=Runtime.GetDiagnostics().elapsed,root=vector(root.Position),velocity=vector(root.AssemblyLinearVelocity),body={},touches={},tail={course.Obstacles.Mechanisms.GuardianTail:GetPivot():GetComponents()}}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={char}
 for _,part in char:GetChildren()do if part:IsA("BasePart") and bodies[part.Name]then row.body[part.Name]={cf={part.CFrame:GetComponents()},size=vector(part.Size)}end end
 for _,part in course:GetDescendants()do
  if part:IsA("BasePart") and part:GetAttribute("ERLethal") and part.Transparency<1 then
   for _,body in workspace:GetPartsInPart(part,params)do
    if body.Transparency<1 and body.Name~="HumanoidRootPart"then table.insert(row.touches,{part=part:GetFullName(),body=body.Name})end
   end
  end
 end
 table.insert(recent,row)
 if #recent>24 then table.remove(recent,1)end
end)
game:GetService("LogService").MessageOut:Connect(function(message)
 if not message:match("^%[RespawnService%] Respawned") or #report.recoveries>=3 then return end
 table.insert(report.recoveries,{message=message,frames=table.clone(recent),serverTime=workspace:GetServerTimeNow()})
 value.Value=Http:JSONEncode(report)
end)
value.Value=Http:JSONEncode(report)
