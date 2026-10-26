--!nonstrict
return function(root)
 local rig=root.Obstacles.Mechanisms.GuardianPeck
 local oldBody=root.Decoration.RevisionR03:FindFirstChild("GiantGuardianBody")
 local roost=root.Decoration:FindFirstChild("ChickenRoostR04")
 local excluded={}
 for _,m in root.Decoration.RevisionR02:GetChildren() do
  if m:IsA("Model") and (m.Name=="NestRing" or m.Name=="BareRock") then
   local p=root:GetPivot():PointToObjectSpace(m:GetPivot().Position)
   if math.abs(p.X-78)<.01 and math.abs(p.Z-40)<.01 then table.insert(excluded,m) end
  end
 end
 local function skip(p)
  if p:IsDescendantOf(rig) or oldBody and p:IsDescendantOf(oldBody) or roost and p:IsDescendantOf(roost) then return true end
  for _,m in excluded do if p:IsDescendantOf(m) then return true end end
  return false
 end
 local rows={}
 for _,p in root:GetDescendants() do
  if not p:IsA("BasePart") or skip(p) then continue end
  local attrs={};local names={}
  for name in p:GetAttributes() do table.insert(names,name) end;table.sort(names)
  for _,name in names do
   local value=p:GetAttribute(name)
   if typeof(value)=="Vector3" then value={value.X,value.Y,value.Z}
   elseif typeof(value)=="CFrame" then value={value:GetComponents()} end
   table.insert(attrs,{name,value})
  end
  table.insert(rows,game.HttpService:JSONEncode({p:GetFullName():sub(#root:GetFullName()+2),p.ClassName,{p.CFrame:GetComponents()},
   {p.Size.X,p.Size.Y,p.Size.Z},{p.Color.R,p.Color.G,p.Color.B},p.Transparency,p.CanCollide,p.CanTouch,p.CanQuery,p.Anchored,tostring(p.Material),
   if p:IsA("MeshPart") then p.MeshId else "",attrs}))
 end
 table.sort(rows)
 local routes={}
 for _,name in {"RevisionNormal","RevisionExpert"} do
  local refs=root.Routes[name]:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
  local list={};for _,r in refs do table.insert(list,{r.Name,r.Value:GetFullName():sub(#root:GetFullName()+2),r:GetAttribute("WaitKind") or ""})end
  table.insert(routes,{name,list})
 end
 return game.HttpService:JSONEncode({rows,routes}),#rows
end
