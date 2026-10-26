--!nonstrict
assert(game.PlaceId == 0 and game.GameId == 0 and game.RunService:IsStudio() and game.RunService:IsClient())
local H = game.HttpService
local tools = game.ReplicatedStorage.MoonlitPhase2Tools
local player = game.Players.LocalPlayer
local Suite = require(tools.ClientSuite)
local Probe = require(tools.ClientProbe)
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "MC_P2_C01_R05_FocusedRouteProof", player.PlayerGui
folder:SetAttribute("OwnedMoonlitTest", true)
local function save(name, value)
 local text = H:JSONEncode(value)
 local count = math.ceil(#text/140000)
 for i=1,count do
  local key = name..string.format("_%03d",i)
  local v = folder:FindFirstChild(key) or Instance.new("StringValue")
  v.Name, v.Value, v.Parent = key, text:sub((i-1)*140000+1,i*140000), folder
 end
 folder:SetAttribute(name.."Chunks",count)
 folder:SetAttribute(name.."Bytes",#text)
end
local ok,err=xpcall(function()
 local deadline=os.clock()+100
 repeat
  assert(not tools:GetAttribute("R05ProofFailure"),tools:GetAttribute("R05ProofFailure"))
  assert(os.clock()<deadline,"Focused native readiness timeout")
  task.wait(.1)
 until tools:GetAttribute("R05ProofReady") and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("ArrivalOpen")==false
 Suite.Start({{name="EEE"}},{crownLaneOffset=2.5})
 while true do
  local s,t=Suite.Current(),Probe.Current()
  save("Suite",s)
  if t then save("Trial",t) end
  folder:SetAttribute("State",s.state)
  folder:SetAttribute("CurrentTrial",s.currentTrial)
  folder:SetAttribute("TrialNode",t and t.nodeIndex)
  if s.state=="Complete" or s.state=="Failed" then break end
  task.wait(1)
 end
end,debug.traceback)
if not ok then folder:SetAttribute("Failure",tostring(err)) Suite.Stop(tostring(err)) end
