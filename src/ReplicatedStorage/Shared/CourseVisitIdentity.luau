--!strict
local Module = {}
function Module.Read(model: Model?,info: any): any
 local result=table.clone(info)
 local revision=model and (model:GetAttribute("SourcePacketHash") or model:GetAttribute("SourceRevision") or model:GetAttribute("CourseRevision"))
 local variant=model and model:GetAttribute("CourseVariant")
 if revision == nil and model then
  local rows={}
  for _,part in model:GetDescendants() do
   if part:IsA("BasePart") and part.CanCollide then
    local components={part.CFrame:GetComponents()}
    local values={part.Name,part.Size.X,part.Size.Y,part.Size.Z}
    for _,value in components do table.insert(values,string.format("%.4f",value)) end
    table.insert(rows,table.concat(values,","))
   end
  end
  table.sort(rows)
  local hash=5381
  for _,row in rows do for index=1,#row do hash=(hash*33+string.byte(row,index))%4294967296 end end
  revision="native-"..tostring(hash)
 end
 result.sourceRevision=tostring(revision or "unknown")
 result.route=tostring(variant or "Official")
 result.variant=table.concat({result.courseId or "",result.sourceRevision,result.route,result.raceFormat or "PointToPoint",
  tostring(result.lapCount or 1),tostring(result.checkpointCount or 0)},":")
 result.fallsSupported=true
 return result
end
return Module
