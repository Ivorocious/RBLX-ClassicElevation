--!strict
assert(game:GetService("RunService"):IsClient(), "Client fixture required")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_I07_Final"))
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
local records, current = {}, nil
local binding = "KCPhase2NativeTraversalFixture"
local Probe = {}
local function vector(p) return {p.X, p.Y, p.Z} end
local function body()
 local character = player.Character
 return character, character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end
local function ground(root)
 return workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
end
RunService:BindToRenderStep(binding, Enum.RenderPriority.Character.Value + 10, function()
 local _, root, humanoid = body()
 if not current or not root or not humanoid then return end
 local delta = Vector3.new(current.target.X-root.Position.X, 0, current.target.Z-root.Position.Z)
 humanoid:Move(if delta.Magnitude>.02 then delta.Unit*math.min(1,delta.Magnitude/.8) else Vector3.zero,false)
 if current.jump and not current.jumped then
  humanoid.Jump=true
  if humanoid.FloorMaterial==Enum.Material.Air and root.AssemblyLinearVelocity.Y>1 then current.jumped=true end
 end
end)
function Probe.Move(label, target, jumping, expected, limit, tolerance)
 local _, root, humanoid = body()
 assert(root and humanoid, "Living character required")
 local first = ground(root)
 local entry={label=label,jump=jumping==true,target=vector(target),expectedSupport=expected and expected:GetFullName(),start=vector(root.Position),startSupport=first and first.Instance:GetFullName(),samples={}}
 table.insert(records, entry)
 local started, sampled = os.clock(), 0
 current={target=target,jump=jumping==true,jumped=false}
 local airborne, arrived = false, false
 while os.clock()-started < (limit or 4) do
  if player.Character ~= root.Parent or humanoid.Health<=0 then break end
  local hit = ground(root)
  local distance = Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z).Magnitude
  if humanoid.FloorMaterial==Enum.Material.Air then airborne=true end
  if distance < (tolerance or .6) and humanoid.FloorMaterial~=Enum.Material.Air and (not jumping or airborne) and (not expected or hit and hit.Instance==expected) then arrived=true; break end
  if os.clock()-sampled>.1 then sampled=os.clock(); table.insert(entry.samples,{t=os.clock()-started,p=vector(root.Position),floor=humanoid.FloorMaterial.Name,support=hit and hit.Instance:GetFullName()}) end
  RunService.RenderStepped:Wait()
 end
 current=nil
 humanoid:Move(Vector3.zero,false)
 local last=ground(root)
 entry.finish,entry.finishSupport,entry.arrived,entry.elapsed=vector(root.Position),last and last.Instance:GetFullName(),arrived,os.clock()-started
 return arrived
end
function Probe.Edge(part, direction, margin)
 local localDirection = part.CFrame:VectorToObjectSpace(direction)
 local x = if math.abs(localDirection.X)>.001 then (part.Size.X/2-(margin or .9))/math.abs(localDirection.X) else math.huge
 local z = if math.abs(localDirection.Z)>.001 then (part.Size.Z/2-(margin or .9))/math.abs(localDirection.Z) else math.huge
 return part.Position + direction*math.min(x,z)
end
function Probe.Cross(label, from, to)
 local delta=Vector3.new(to.Position.X-from.Position.X,0,to.Position.Z-from.Position.Z)
 if delta.Magnitude<.001 then return false end
 local direction=delta.Unit
 local takeoff=Probe.Edge(from,direction,.9)
 local landing=Probe.Edge(to,-direction,.9)
 if not Probe.Move(label.." takeoff",takeoff,false,from,4,.5) then return false end
 if not Probe.Move(label.." jump",landing,true,to,3,.8) then return false end
 return Probe.Move(label.." center",to.Position,false,to,4,.7)
end
function Probe.Place(part, point)
 local character,root,humanoid=body()
 local setupRay=RaycastParams.new()
 setupRay.FilterType,setupRay.FilterDescendantsInstances,setupRay.RespectCanCollide=Enum.RaycastFilterType.Include,{part},true
 local height=humanoid.HipHeight+root.Size.Y/2
 local top=part.Position+part.CFrame.UpVector*part.Size.Y/2
 if point then
  local localPoint=part.CFrame:PointToObjectSpace(point)
  assert(math.abs(localPoint.X)<part.Size.X/2-.8 and math.abs(localPoint.Z)<part.Size.Z/2-.8,"Staged point must remain inside the bank")
  top=Vector3.new(point.X,top.Y,point.Z)
 end
 current=nil
 humanoid:Move(Vector3.zero,false)
 for attempt=1,3 do
  character:PivotTo(CFrame.lookAt(top+Vector3.new(0,height+.1,0),top+Vector3.new(0,height+.1,0)+part.CFrame.RightVector))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  task.wait(.5)
  local hit=workspace:Raycast(root.Position,Vector3.new(0,-7,0),setupRay)
  local offset=Vector3.new(top.X-root.Position.X,0,top.Z-root.Position.Z).Magnitude
  if hit and hit.Instance==part and humanoid.FloorMaterial~=Enum.Material.Air and offset<.8 then
   return {attempts=attempt,support=hit.Instance:GetFullName(),root=vector(root.Position)}
  end
 end
 error("Staged departure did not settle on "..part:GetFullName())
end
function Probe.Records() return records end
function Probe.Stop()
 current=nil
 RunService:UnbindFromRenderStep(binding)
 local _,_,humanoid=body()
 if humanoid then humanoid:Move(Vector3.zero,false) end
end
shared.KCP2I07TraversalProbe=Probe
return {installed=true,binding=binding,boundary="Owned native traversal fixture; staged positioning between tests, continuous humanoid movement within each test; no global movement settings or foreign control changes"}
