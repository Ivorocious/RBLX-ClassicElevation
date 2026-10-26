--!strict
local Http=game:GetService("HttpService")
local c=workspace.KeyboardCircuit_P2_I09_Experience02
assert(c:GetAttribute("PrototypeRevision")=="KC_P2_I09_02")
local ray=RaycastParams.new()
ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{c},true
local parts,caps,mechanisms,special=0,0,0,0
local legends,branches={},{}
for _,item in c:GetDescendants() do
 if item:IsA("BasePart") then parts+=1 end
 if item:GetAttribute("MechanismId") then mechanisms+=1 end
 if item:IsA("MeshPart") and item:GetAttribute("Pressable") then
  caps+=1
  local legend=item:GetAttribute("KeyLegend")
  assert(type(legend)=="string" and utf8.len(legend)==1,"Multiple symbols on "..item:GetFullName())
  if item.Name=="KeyTop" then special+=1 end
 end
 if item:IsA("TextLabel") and item.Parent:IsA("SurfaceGui") and item.Parent.Parent.Name:find("Sign") then table.insert(legends,{part=item.Parent.Parent:GetFullName(),text=item.Text}) end
end
for _,branch in c.ExpertRoutes:GetChildren() do
 local rows={}
 for _,marker in branch.TraversalPoints:GetChildren() do
  local contact=branch["PrecisionLanding"..marker.Name].KeyContact
  local hit=workspace:Raycast(contact.Position+Vector3.new(0,3,0),Vector3.new(0,-8,0),ray)
  assert(hit and hit.Instance==contact,"Expert center masked by another support")
  local cornerRays=0
  for _,x in {-.35,0,.35} do for _,z in {-.35,0,.35} do
   local p=contact.CFrame:PointToWorldSpace(Vector3.new(x,3,z))
   local corner=workspace:Raycast(p,Vector3.new(0,-8,0),ray)
   assert(corner and corner.Instance==contact,"Expert center footprint masked")
   cornerRays+=1
  end end
  table.insert(rows,{ordinal=marker:GetAttribute("Ordinal"),size={contact.Size.X,contact.Size.Y,contact.Size.Z},rays=cornerRays+1})
 end
 table.insert(branches,{id=branch:GetAttribute("ExpertId"),from=branch:GetAttribute("BranchAfter"),before=branch:GetAttribute("MergeBefore"),recovery=branch:GetAttribute("RecoveryCheckpoint"),skips=branch:GetAttribute("Skips"),landings=#rows,contacts=rows})
end
assert(#branches==2 and mechanisms==8 and special==9)
local recoveryCount=0
for _,pad in c.RecoveryPads:GetChildren() do
 recoveryCount+=1
 assert(not pad.BankContact.CanCollide and not pad.BankContact.CanQuery and pad.BankContact.Transparency==1)
 local ref=pad:FindFirstChild("HostContact")
 if ref then assert(ref.Value.Anchored and ref.Value.CanCollide and ref.Value:GetAttribute("RetryCheckpoint")) end
end
assert(recoveryCount==8 and c:GetAttribute("CheckpointCount")==7)
return Http:JSONEncode({passed=true,candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),parts=parts,caps=caps,specialCaps=special,mechanisms=mechanisms,branches=branches,recoveryPads=recoveryCount,checkpointCount=7,signs=legends,boundary="Native support rays, exact current attributes and visible text strings. No rendered screenshot, visual satisfaction, human difficulty or FPS claim."})
