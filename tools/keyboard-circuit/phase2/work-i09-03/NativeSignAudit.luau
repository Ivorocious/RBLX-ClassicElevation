--!strict
local H=game:GetService("HttpService")
local c=workspace.KeyboardCircuit_P2_I09_Experience03
assert(c:GetAttribute("PrototypeRevision")=="KC_P2_I09_03")
local function luminance(color)
 local function channel(v)return if v<=.04045 then v/12.92 else ((v+.055)/1.055)^2.4 end
 return .2126*channel(color.R)+.7152*channel(color.G)+.0722*channel(color.B)
end
local panels,labels={},{}
local minimum=math.huge
for _,v in c:GetDescendants() do
 if v:IsA("BasePart") and (v.Name:find("Sign") or v.Name=="ExpertCommitment" or v.Name=="NormalAlternative") then
  table.insert(panels,v)
  for _,gui in v:GetChildren() do if gui:IsA("SurfaceGui") then
   for _,text in gui:GetChildren() do if text:IsA("TextLabel") then
    local a,b=luminance(v.Color),luminance(text.TextColor3)
    local contrast=(math.max(a,b)+.05)/(math.min(a,b)+.05)
    assert(contrast>=4.5,"Poor sign contrast on "..v:GetFullName())
    minimum=math.min(minimum,contrast)
    table.insert(labels,{part=v:GetFullName(),text=text.Text,face=gui.Face.Name,background={v.Color.R,v.Color.G,v.Color.B},ink={text.TextColor3.R,text.TextColor3.G,text.TextColor3.B},contrast=contrast})
   end end
  end end
 end
end
local visibility={}
for _,id in {"R1","R2","R3","R4"} do
 local host=c.RecoveryPads[id].HostContact.Value
 local targets={assert(host.Parent:FindFirstChild("MidpointCheckpointSign"))}
 local normal=host.Parent.Parent:FindFirstChild("NormalAlternative")
 if normal then table.insert(targets,normal) end
 for _,branch in c.ExpertRoutes:GetChildren() do if branch:GetAttribute("RecoveryCheckpoint")==id then table.insert(targets,branch.ExpertCommitment) end end
 local eyes={host.Position+Vector3.new(0,host.Size.Y/2+.45+4.5,0)}
 for _,x in {-4.7,-1.5,1.7} do for _,z in {-3.2,0,3.2} do table.insert(eyes,host.CFrame:PointToWorldSpace(Vector3.new(x,host.Size.Y/2+.45+4.5,z))) end end
 for eyeIndex,eye in eyes do for _,target in targets do
  local tested=0
  for _,offset in {Vector3.zero,Vector3.new(-3,.75,0),Vector3.new(3,.75,0),Vector3.new(-3,-.75,0),Vector3.new(3,-.75,0)} do
   local point=target.CFrame:PointToWorldSpace(offset)
   local delta=point-eye
   for _,other in panels do if other~=target then
    local origin=other.CFrame:PointToObjectSpace(eye)
    local direction=other.CFrame:VectorToObjectSpace(delta)
    if math.abs(direction.Z)>.00001 then
     local t=-origin.Z/direction.Z
     if t>0 and t<.999 then
      local hit=origin+direction*t
      assert(math.abs(hit.X)>other.Size.X/2 or math.abs(hit.Y)>other.Size.Y/2,"Sign text occluded: "..target:GetFullName().." by "..other:GetFullName())
     end
    end
   end end
   tested+=1
  end
  table.insert(visibility,{checkpoint=id,eye=eyeIndex,target=target:GetFullName(),points=tested,passed=true})
 end end
end
return H:JSONEncode({passed=true,candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),minimumContrast=minimum,labels=labels,visibility=visibility,
 boundary="Native authored panel/text colors and geometric sign-plane visibility from bank center plus nine planned recovery-slot eye positions at 4.5studs above key top, five text-region points per target. Checks sign-to-sign occlusion; not a rendered-camera, human legibility or full scenery-occlusion claim."})
