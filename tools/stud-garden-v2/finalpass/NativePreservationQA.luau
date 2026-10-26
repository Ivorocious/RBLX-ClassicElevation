local root=workspace.SGV2_Phase3_F04
local http=game:GetService("HttpService")
local prior=http.HttpEnabled
local restored
local ok,result=xpcall(function()
 http.HttpEnabled=true
 restored=game:GetService("SerializationService"):DeserializeInstancesAsync(buffer.fromstring(http:GetAsync("http://127.0.0.1:8768/sgv2-before-finalpass.rbxm",true)))
 local before=restored[1]
 local function path(p,r)return p:GetFullName():sub(#r:GetFullName()+2)end
 local function signature(p)
  local nums={p.CFrame:GetComponents()}
  for _,n in {p.Size.X,p.Size.Y,p.Size.Z,p.Color.R,p.Color.G,p.Color.B,p.Transparency} do table.insert(nums,n)end
  local s={p.ClassName,tostring(p.CanCollide),tostring(p.CanTouch),tostring(p.CanQuery),tostring(p.Anchored),tostring(p.Material),tostring(p.TopSurface),tostring(p.BottomSurface)}
  for _,n in nums do table.insert(s,string.format("%.4f",if math.abs(n)<.00005 then 0 else n))end
  if p:IsA("Part") then table.insert(s,tostring(p.Shape))end
  if p:IsA("MeshPart") then table.insert(s,p.MeshId);table.insert(s,p.TextureID)end
  return table.concat(s,"|")
 end
 local current={} 
 local parts=0
 for _,p in root:GetDescendants() do if p:IsA("BasePart") then local k=path(p,root);current[k]=current[k] or {};table.insert(current[k],p);parts+=1 end end
 local report={baselineParts=0,currentParts=parts,unchanged=0,changed={},missing={},physicsChanges={}}
 for _,p in before:GetDescendants() do if p:IsA("BasePart") then
  report.baselineParts+=1
  local k=path(p,before);local list=current[k]
  if not list or #list==0 then table.insert(report.missing,k);continue end
  local selected
  for i,q in list do if signature(p)==signature(q) then selected=i;break end end
  if selected then table.remove(list,selected);report.unchanged+=1
  else
   local q=table.remove(list,1)
   table.insert(report.changed,k)
   if p.CanCollide~=q.CanCollide or p.CanTouch~=q.CanTouch or p.CanQuery~=q.CanQuery then table.insert(report.physicsChanges,k)end
   assert(k:find("GardenUnderstory.GardenerWorkyard.",1,true)==1 or k=="H1_Sprinkler.StatusBoard" or k=="H2_Fruit.StatusBoard","Unscoped geometry change: "..k)
  end
 end end
 assert(#report.missing==0 and #report.physicsChanges==0,"Original parts missing or physics changed")
 report.addedParts=parts-report.baselineParts
 report.ok=true
 return report
end,debug.traceback)
if restored then for _,x in restored do x:Destroy()end end
http.HttpEnabled=prior
assert(ok,result)
return result
