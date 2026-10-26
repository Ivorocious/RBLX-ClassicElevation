--!strict
local RunService,Http=game:GetService("RunService"),game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer())
local c=assert(workspace:FindFirstChild("KeyboardCircuit_P2_I07_Final"))
assert(c:GetAttribute("PrototypeRevision")=="KC_P2_I07_03")
local ray=RaycastParams.new()
ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{c},true
local rows,failures={},{}
local count,minMargin=0,math.huge
for _,id in {"F00","CP1","CP2","CP3"} do
 local contact=c.CheckpointBays[id].BankContact
 local spawn=c.RecoveryPads[id].BankContact:GetAttribute("SpawnCFrame")
 assert(typeof(spawn)=="CFrame")
 for row=1,4 do for column=1,5 do
  local slot=spawn*CFrame.new((column-3)*4.5,0,(row-2.5)*4)
  local localPoint=contact.CFrame:PointToObjectSpace(slot.Position)
  local margin=math.min(contact.Size.X/2-math.abs(localPoint.X),contact.Size.Z/2-math.abs(localPoint.Z))
  minMargin=math.min(minMargin,margin)
  local hits=0
  for _,x in {-1.2,0,1.2} do for _,z in {-1.2,0,1.2} do
   local origin=slot:PointToWorldSpace(Vector3.new(x,0,z))
   local hit=workspace:Raycast(origin+Vector3.new(0,5,0),Vector3.new(0,-15,0),ray)
   count+=1
   if hit and hit.Instance==contact and hit.Normal.Y>.65 then hits+=1 else
    table.insert(failures,{gate=id,row=row,column=column,offset={x,z},hit=hit and hit.Instance:GetFullName() or "NONE"})
   end
  end end
  if localPoint.X>=-1.2 or margin<1.2 then table.insert(failures,{gate=id,row=row,column=column,reason="footprint not upstream or outside bank"}) end
  table.insert(rows,{gate=id,row=row,column=column,bayLocal={localPoint.X,localPoint.Y,localPoint.Z},margin=margin,correctFootprintRays=hits})
 end end
end
local result={revision="KC_P2_I07_03",candidate=c.Name,passed=#failures==0,slotCount=#rows,rayCount=count,minEdgeMarginStuds=minMargin,footprintStuds={2.4,2.4},slots=rows,failures=failures,
 boundary="Native exact permanent support rays at center and eight footprint offsets for all twenty spawn slots per checkpoint. No avatar movement, recovery, crowd or device performance claim."}
return Http:JSONEncode(result)
