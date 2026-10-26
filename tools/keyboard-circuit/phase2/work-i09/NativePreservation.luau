--!strict
local RunService,Http=game:GetService("RunService"),game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning())
local current=workspace.KeyboardCircuit_P2_I09_Experience02
local previous=game.ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses.KeyboardCircuit_P2_I08_TwoLaps01
assert(current:GetAttribute("PrototypeRevision")=="KC_P2_I09_02" and previous:GetAttribute("PrototypeRevision")=="KC_P2_I08_01")
local counts,failures,omitted={}, {}, {}
local function signature(item)
 local row=item.ClassName
 if item:IsA("BasePart") then
  for _,v in {item.CFrame:GetComponents()} do row ..= "|"..string.format("%.3f",if math.abs(v)<.0005 then 0 else v) end
  for _,v in {item.Size.X,item.Size.Y,item.Size.Z,item.Color.R,item.Color.G,item.Color.B} do row ..= "|"..string.format("%.3f",v) end
  row ..= "|"..item.Material.Name.."|"..tostring(item.CanCollide).."|"..tostring(item.CanTouch).."|"..tostring(item.CanQuery).."|"..item.CollisionGroup
  if item:IsA("MeshPart") then row ..= "|"..item.MeshId.."|"..item.TextureID.."|"..item.CollisionFidelity.Name end
 elseif item:IsA("TextLabel") then row ..= "|"..item.Text.."|"..tostring(item.Visible)
 elseif item:IsA("SurfaceGui") then row ..= "|"..tostring(item.Enabled) end
 return row
end
local function rows(model,folderName)
 local folder,bag,count=model[folderName],{},0
 for _,item in folder:GetDescendants() do
  if not item:IsA("BasePart") and not item:IsA("TextLabel") and not item:IsA("SurfaceGui") then continue end
  local relative=item:GetFullName():sub(#folder:GetFullName()+2)
  if relative:find("NormalAlternative",1,true) then continue end
  if item:IsA("TextLabel") and (relative:find("RecoveryMarker",1,true) or relative:find("RecoverySign",1,true)) then
   if model==previous then table.insert(omitted,folderName.."."..relative) end
   continue
  end
  local key=relative.."|"..signature(item)
  bag[key]=(bag[key] or 0)+1
  count+=1
 end
 return bag,count
end
for _,folderName in {"Districts","RouteLinks","CheckpointBays","RoughSurroundings"} do
 local original,count=rows(previous,folderName)
 local revised=rows(current,folderName)
 for key,quantity in original do
  if (revised[key] or 0)<quantity then table.insert(failures,{row=key,expected=quantity,found=revised[key] or 0}) end
 end
 counts[folderName]=count
end
local result={passed=#failures==0,candidate=current.Name,revision=current:GetAttribute("PrototypeRevision"),baseline=previous.Name,checked=counts,failures=failures,changedRecoveryLabels=omitted,
 boundary="Baseline main-route, connector, checkpoint-bank and surroundings physical parts and key legends persist as multisets at .001 precision, including duplicate sibling names. Relocated Normal branch signs and updated recovery label text are intentionally excluded. Added midpoint flags and changed Expert geometry are outside this comparison. Native Edit-mode proof, not FPS or subjective art proof."}
return Http:JSONEncode(result)
