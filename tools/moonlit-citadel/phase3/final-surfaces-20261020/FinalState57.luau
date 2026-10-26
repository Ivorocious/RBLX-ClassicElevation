local SS,H=game.ServerStorage,game:GetService("HttpService")
local rec=SS.MoonlitP3ReworkRecovery.FinalSurfaces20261020
local d=H:JSONDecode(rec.EditorBefore.Value)
local c=workspace.CurrentCamera
c.CFrame=CFrame.new(table.unpack(d.camera));c.Focus=CFrame.new(table.unpack(d.focus))
c.FieldOfView=d.fieldOfView;c.CameraType=Enum.CameraType[d.cameraType]
for key,value in d.lighting do game.Lighting[key]=if type(value)=="table" then Color3.new(table.unpack(value)) else value end
H.HttpEnabled=d.http
assert(not game:GetService("RunService"):IsRunning())
assert(c.CFrame==CFrame.new(table.unpack(d.camera)) and c.Focus==CFrame.new(table.unpack(d.focus))
 and c.FieldOfView==d.fieldOfView and c.CameraType.Name==d.cameraType)
for key,value in d.lighting do assert(game.Lighting[key]==(if type(value)=="table" then Color3.new(table.unpack(value)) else value),key) end
local function sameSequence(a,b)
 if typeof(a)~=typeof(b) then return false end
 if typeof(a)=="NumberSequence" or typeof(a)=="ColorSequence" then
  if #a.Keypoints~=#b.Keypoints then return false end
  for i,p in a.Keypoints do local q=b.Keypoints[i]
   if p.Time~=q.Time or p.Value~=q.Value then return false end
   if typeof(a)=="NumberSequence" and p.Envelope~=q.Envelope then return false end
  end;return true
 end
 return a==b
end
local pairs={{workspace.Course_MoonlitCitadel,rec.BeforeModels56.Editable},{SS.CourseLibrary.Course_MoonlitCitadel,rec.BeforeModels56.Stored}}
local reports={}
for _,pair in pairs do
 local current,before=pair[1],pair[2]
 assert(#current:GetDescendants()==#before:GetDescendants())
 local veil=current.Decoration.MoonlitDepthVeil;local old=before.Decoration.MoonlitDepthVeil;local count=0
 for _,p in veil:GetChildren() do
  local e=p:FindFirstChildOfClass("ParticleEmitter");local q=assert(old[p.Name]:FindFirstChildOfClass("ParticleEmitter"))
  for _,key in {"Texture","Orientation","EmissionDirection","Speed","SpreadAngle","Acceleration","Lifetime","Rate","Size","Transparency","Color","LightEmission","LightInfluence","Rotation","RotSpeed","ZOffset","Enabled","VelocityInheritance","Drag"} do assert(sameSequence(e[key],q[key]),key) end
  count+=1
 end
 assert(count==12)
 local floor=current.Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine
 local original=before.Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine
 local floorCount=0
 for _,p in floor:GetDescendants() do if p:IsA("MeshPart") then local q=original[p.Name];assert(p.MeshId==q.MeshId and p.CFrame==q.CFrame and p.Size==q.Size);floorCount+=1 end end
 assert(floorCount==3)
 assert(current.Finish.CFrame==before.Finish.CFrame and current.Finish.Size==before.Finish.Size)
 table.insert(reports,{path=current:GetFullName(),source=current:GetAttribute("SourceRevision"),descendants=#current:GetDescendants(),floorMeshesExact=3,veilEmittersExact=12,finishExact=true})
end
local report={pass=true,source=57,build=51,mode="Edit",clock=game.Lighting.ClockTime,http=H.HttpEnabled,cameraFocusFOVTypeExact=true,
 lightingExact=true,temporaryPreviewAbsent=not workspace:FindFirstChild("MoonlitSurfacePreview57"),ownFreshFixtureAbsent=not rec:FindFirstChild("FreshBuild57"),
 models=reports,nativeRenderEvidenceAvailable=false,renderLimit="Edit and one bounded Play preview captures were blank; no desktop foregrounding or computer input used."}
local value=Instance.new("StringValue");value.Name="EditorRestoration57";value.Value=H:JSONEncode(report);value.Parent=rec
return H:JSONEncode(report)
