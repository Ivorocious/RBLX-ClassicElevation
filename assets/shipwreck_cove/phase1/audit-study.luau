local root=workspace.__ShipwreckCove_Phase1
local old=game.ServerStorage.__ShipwreckCove_Phase1_SC_P1_03
local function signatures(model)
 local a={}
 for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.CanCollide then
 local vals={p.Size.X,p.Size.Y,p.Size.Z,p.CFrame:GetComponents()}
 for i,v in vals do vals[i]=string.format("%.5f",v) end
 table.insert(a,table.concat(vals,",").."|"..tostring(p.CanTouch).."|"..tostring(p.CanQuery))
 end end
 table.sort(a);return a
end
local now,before=signatures(root),signatures(old);local parity=#now==#before
for i,s in now do if s~=before[i] then parity=false end end
local r={build=root:GetAttribute("Build"),kitBuild=root:GetAttribute("KitBuild"),place=game.PlaceId,groups={},colliderParityWith03=parity,colliders=#now,signature=now,descendants=#root:GetDescendants()}
for _,g in root:GetChildren() do
 local q={name=g.Name,descendants=#g:GetDescendants(),parts=0,visuals=0,colliders=0,scripts=0,lights=0,particles=0,transparentVisuals=0,visualQuery=0,visualTouch=0}
 for _,p in g:GetDescendants() do
 if p:IsA("BasePart") then q.parts+=1;if p.CanCollide then q.colliders+=1 else q.visuals+=1; if p.Transparency>0 then q.transparentVisuals+=1 end;if p.CanQuery then q.visualQuery+=1 end;if p.CanTouch then q.visualTouch+=1 end end
 elseif p:IsA("LuaSourceContainer") then q.scripts+=1 elseif p:IsA("Light") then q.lights+=1 elseif p:IsA("ParticleEmitter") then q.particles+=1 end end
 table.insert(r.groups,q)
end
return game.HttpService:JSONEncode(r)
