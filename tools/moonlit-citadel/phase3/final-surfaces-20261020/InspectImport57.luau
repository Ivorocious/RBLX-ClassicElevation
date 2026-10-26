local root=game.ServerStorage.AssetImports.MoonlitCitadel_Surface_SR02Import
local rows={}
local A=game:GetService("AssetService")
for _,p in root:GetDescendants() do
 assert(not p:IsA("LuaSourceContainer"),"Unexpected imported script")
 if p:IsA("MeshPart") then
  local e=A:CreateEditableMeshAsync(Content.fromUri(p.MeshId));assert(e)
  local vertices,faces,keys,ids={},{},{},{}
  local minDot,uvInvalid=1,0
  for _,id in e:GetVertices() do
   local v=e:GetPosition(id)
   local a,b,c=math.round(v.X*1e6),math.round(v.Y*1e6),math.round(v.Z*1e6)
   local key=a..","..b..","..c
   local index=keys[key]
   if not index then table.insert(vertices,{a,b,c});index=#vertices;keys[key]=index end
   ids[id]=index
  end
  for i,id in e:GetFaces() do
   local f=e:GetFaceVertices(id);table.insert(faces,{ids[f[1]],ids[f[2]],ids[f[3]]})
   local n=(e:GetPosition(f[2])-e:GetPosition(f[1])):Cross(e:GetPosition(f[3])-e:GetPosition(f[1]))
   if n.Magnitude>1e-9 then for _,nid in e:GetFaceNormals(id) do minDot=math.min(minDot,n.Unit:Dot(e:GetNormal(nid))) end end
   for _,uid in e:GetFaceUVs(id) do local uv=e:GetUV(uid);if uv.X~=uv.X or uv.Y~=uv.Y then uvInvalid+=1 end end
   if i%300==0 then task.wait() end
  end
  table.insert(rows,{name=p.Name,meshId=p.MeshId,texture=p.TextureID,size={p.Size.X,p.Size.Y,p.Size.Z},meshSize={p.MeshSize.X,p.MeshSize.Y,p.MeshSize.Z},cframe={p.CFrame:GetComponents()},verticesMicro=vertices,faces=faces,minNormalDot=minDot,invalidUVs=uvInvalid})
  e:Destroy();task.wait()
 end
end
assert(#rows==7)
return game:GetService("HttpService"):JSONEncode({kit="SR02",meshes=rows})
