--!strict
local study=workspace.KeyboardCircuit_P1_C05.CheapWholeRouteStudy
assert(shared.KCBranchId=="X01" or shared.KCBranchId=="X02")
local path=if shared.KCBranchId=="X01" then {"H04","X01","CP2"} else {"H07","X02","CP3"}
local function surface(id)
 local node=study[id]
 return if node:IsA("Model") then node.PrimaryPart else node
end
local function insideEdge(part,direction)
 local localDirection=part.CFrame:VectorToObjectSpace(direction)
 local x=if math.abs(localDirection.X)>.001 then (part.Size.X/2-1.15)/math.abs(localDirection.X) else math.huge
 local z=if math.abs(localDirection.Z)>.001 then (part.Size.Z/2-1.15)/math.abs(localDirection.Z) else math.huge
 return part.Position+direction*math.min(x,z)
end
shared.KCStudyBranch={active=true,id=shared.KCBranchId,edges={},started=os.clock(),launchWasStaged=true,traversalUsesHumanoidMovement=true}
task.spawn(function()
 local result=shared.KCStudyBranch
 for index=1,#path-1 do
  local from,to=path[index],path[index+1]
  local connection={}
  for _,part in study.OrderedNormalConnections:GetChildren() do
   if part:GetAttribute("ConnectionFrom")==from and part:GetAttribute("ConnectionTo")==to then table.insert(connection,part) end
  end
  table.sort(connection,function(a,b)return a:GetAttribute("ConnectionIndex")<b:GetAttribute("ConnectionIndex")end)
  local surfaces={surface(from)}
  for _,part in connection do table.insert(surfaces,part) end
  table.insert(surfaces,surface(to))
  for step=1,#surfaces-1 do
   local a,b=surfaces[step],surfaces[step+1]
   local direction=Vector3.new(b.Position.X-a.Position.X,0,b.Position.Z-a.Position.Z).Unit
   result.stage=from.." to "..to.." / "..step
   local launch,landing=insideEdge(a,direction),insideEdge(b,-direction)
   local approach=shared.KCProbe.Move(result.stage.." approach",launch,false,3,.2)
   local transfer=approach and shared.KCProbe.Move(result.stage.." transfer",landing,true,3,.2)
   table.insert(result.edges,{from=from,to=to,step=step,approach=approach,transfer=transfer})
   if not transfer then result.active,result.ok=false,false;return end
  end
  if not shared.KCProbe.Move(to.." center",surface(to).Position,false,3,.2) then result.active,result.ok=false,false;return end
 end
 result.totalSeconds,result.ok,result.active=os.clock()-result.started,true,false
end)
return {started=true,id=shared.KCBranchId}
