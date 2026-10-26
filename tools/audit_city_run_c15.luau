local Audit={}
function Audit.Capture()
 local c=workspace.Course_CityRun;assert(c:GetAttribute("ReviewBuildId")=="C15_04")
 local roots={c}
 for _,p in workspace:GetChildren() do
  if p~=c and ((p:IsA("Model") and p.Name~="Lobby" and p.Name~="AncientPillar") or (p:IsA("BasePart") and p.Position.X>=3100 and p.Position.X<=4050)) then table.insert(roots,p) end
 end
 table.sort(roots,function(a,b) return a.Name<b.Name end)
 local records={}
 local function scalar(v)
  local t=typeof(v)
  if t=="Vector3" then return {v.X,v.Y,v.Z} elseif t=="Color3" then return {v.R,v.G,v.B}
  elseif t=="CFrame" then return {v:GetComponents()} elseif t=="EnumItem" then return tostring(v)
  else return v end
 end
 local function visit(p,path)
  local row={path,p.ClassName}
  if p:IsA("BasePart") then
   table.insert(row,{p.CFrame:GetComponents()});table.insert(row,scalar(p.Size));table.insert(row,scalar(p.Color))
   table.insert(row,{p.Transparency,p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow,p.CollisionGroup,tostring(p.Material)})
   if p:IsA("MeshPart") then table.insert(row,{p.MeshId,p.TextureID,p.DoubleSided}) end
  end
  if p~=c then
   local attrs={};for k,v in p:GetAttributes() do table.insert(attrs,{k,scalar(v)}) end
   table.sort(attrs,function(a,b) return a[1]<b[1] end);table.insert(row,attrs)
  end
  if p:IsA("TextLabel") then table.insert(row,{p.Text,scalar(p.TextColor3),p.TextScaled,tostring(p.Font)}) end
  table.insert(records,row)
  for i,ch in p:GetChildren() do visit(ch,path.."/"..ch.Name.."["..i.."]") end
 end
 for i,p in roots do visit(p,p.Name.."["..i.."]") end
 local str=game:GetService("HttpService"):JSONEncode(records)
 local a,b=5381,17;for i=1,#str do local n=str:byte(i);a=(a*33+n)%4294967296;b=(b*65599+n)%4294967296 end
 return str,{build="C15_04",records=#records,roots=#roots,bytes=#str,fingerprint=string.format("%08x-%08x",a,b)}
end
return Audit
