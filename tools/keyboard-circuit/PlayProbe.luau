--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local controls = require(player.PlayerScripts.PlayerModule):GetControls()
local character = player.Character
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character:FindFirstChild("HumanoidRootPart")
local candidate = workspace.KeyboardCircuit_P1_C05
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {candidate}
local records = {}
local function ground()
 local hit = workspace:Raycast(root.Position, Vector3.new(0,-6,0), ray)
 return {floor=humanoid.FloorMaterial.Name,part=hit and hit.Instance:GetFullName(),distance=hit and hit.Distance}
end
local function point(v) return {x=v.X,y=v.Y,z=v.Z} end
local Probe = {}
function Probe.Move(label: string, target: Vector3, jumping: boolean?, limit: number?, tolerance: number?)
 controls:Disable()
 local entry={label=label,jump=jumping==true,start=point(root.Position),groundStart=ground(),samples={}}
 table.insert(records,entry)
 local started, lastSample = os.clock(), 0
 local jumped, airborne = false, false
 local arrived = false
 while os.clock()-started < (limit or 4) do
  local delta = Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
  if delta.Magnitude < (tolerance or .5) and humanoid.FloorMaterial ~= Enum.Material.Air and (not jumping or airborne) then arrived=true; break end
  humanoid:Move(if delta.Magnitude>.02 then delta.Unit*math.min(1,delta.Magnitude/.8) else Vector3.zero,false)
  if jumping and not jumped then humanoid.Jump=true; jumped=true end
  if humanoid.FloorMaterial==Enum.Material.Air then airborne=true end
  if os.clock()-lastSample>.1 then
   lastSample=os.clock()
   table.insert(entry.samples,{t=os.clock()-started,p=point(root.Position),floor=humanoid.FloorMaterial.Name})
  end
  RunService.RenderStepped:Wait()
 end
 humanoid:Move(Vector3.zero,false)
 entry.finish,entry.groundFinish,entry.arrived,entry.elapsed=point(root.Position),ground(),arrived,os.clock()-started
 return arrived
end
function Probe.Records() return records end
function Probe.Stop() humanoid:Move(Vector3.zero,false); controls:Enable() end
return Probe
