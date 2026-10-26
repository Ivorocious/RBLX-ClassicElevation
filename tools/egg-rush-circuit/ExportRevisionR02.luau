local c=workspace:FindFirstChild("Course_EggRush")
if not c or c:GetAttribute("RouteRevision")~="R02" then c=game.ServerStorage.EggRushRevision_20261026.Candidate_R02 end
local pivot=c:GetPivot()
local out={candidate=c:GetAttribute("CandidateId"),parts={},routes={},mechanisms={}}
local ids={}
for _,p in ipairs(c:GetDescendants()) do
 if p:IsA("BasePart") and (p.CanCollide or typeof(p:GetAttribute("ERTop"))=="Vector3") then
  ids[p]=#out.parts+1
  local m=p:FindFirstAncestorWhichIsA("Model")
  while m and not m:GetAttribute("ERMechanism") and m~=c do m=m.Parent;if not m:IsA("Model") then m=m:FindFirstAncestorWhichIsA("Model") end end
  table.insert(out.parts,{name=p.Name,path=p:GetFullName():sub(#c:GetFullName()+2),cf={pivot:ToObjectSpace(p.CFrame):GetComponents()},
   size={p.Size.X,p.Size.Y,p.Size.Z},route=p:GetAttribute("ERRoute"),collide=p.CanCollide,moving=m and m~=c and m.Name or nil})
 end
end
for _,name in ipairs({"RevisionNormal","RevisionExpert"}) do
 local refs=c.Routes[name]:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
 local list={}
 for _,r in ipairs(refs) do table.insert(list,{id=ids[r.Value],name=r.Value.Name,waitKind=r:GetAttribute("WaitKind")}) end
 out.routes[name]=list
end
for _,m in ipairs(c.Obstacles.Mechanisms:GetChildren()) do
 local attributes={}
 for k,v in pairs(m:GetAttributes()) do attributes[k]=if typeof(v)=="Vector3" then {v.X,v.Y,v.Z} else v end
 table.insert(out.mechanisms,{name=m.Name,pivot={pivot:ToObjectSpace(m:GetPivot()):GetComponents()},attributes=attributes})
end
return game.HttpService:JSONEncode(out)
