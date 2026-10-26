local sources=game.ServerStorage.CityRunInspectionSources
local a,b=sources.Optimized.RaceCourse,sources.Rebuilt.RaceCourse
local differences={};local compared=0;local parts=0
local properties={"CFrame","Size","CanCollide","CanTouch","CanQuery","Anchored","Transparency","Color","Material","CastShadow","CollisionGroup","PivotOffset"}
local function diff(path,key,x,y)
 if x~=y then table.insert(differences,{path=path,property=key,before=tostring(x),after=tostring(y)})end
end
local function compare(x,y,path)
 compared+=1;diff(path,'ClassName',x.ClassName,y.ClassName)
 for k,v in x:GetAttributes() do diff(path,'Attribute.'..k,v,y:GetAttribute(k))end
 for k,v in y:GetAttributes() do if k~='CityRunV3Build' then diff(path,'Attribute.'..k,x:GetAttribute(k),v)end end
 if x:IsA('BasePart') then parts+=1;for _,key in properties do diff(path,key,x[key],y[key])end
 if x:IsA('MeshPart')then diff(path,'MeshId',x.MeshId,y.MeshId);diff(path,'TextureID',x.TextureID,y.TextureID)end
 elseif x:IsA('Model')then diff(path,'Pivot',x:GetPivot(),y:GetPivot())end
 local ys={};for _,v in y:GetChildren()do local key=v.Name..'|'..v.ClassName;ys[key]=ys[key]or{};table.insert(ys[key],v)end
 for _,v in x:GetChildren()do if not(x==a and v.Name=='Decoration')then
 local key=v.Name..'|'..v.ClassName;local list=ys[key];local target=list and table.remove(list,1)
 if target then compare(v,target,path..'.'..v.Name)else table.insert(differences,{path=path..'.'..v.Name,property='missing'})end
 end end
end
compare(a,b,'RaceCourse')
local visuals=b.Decoration.V3Scenery:GetChildren();for _,p in b.Decoration.V3Accents:GetChildren()do table.insert(visuals,p)end
local overlaps={};local floors=0
for _,f in b:GetDescendants()do
 if f:IsA('BasePart')and f.CanCollide and not f:IsDescendantOf(b.Decoration)and f.Size.Y<4 and f.Size.X>2 and f.Size.Z>2 and not string.find(f.Name,'Kill')then
 floors+=1;local point=f.Position+Vector3.new(0,f.Size.Y/2+3,0)
 for _,p in visuals do local v=p.CFrame:PointToObjectSpace(point);local h=p.Size/2
 if math.abs(v.X)<h.X+1.2 and math.abs(v.Z)<h.Z+1.2 and math.abs(v.Y)<h.Y+2.5 then table.insert(overlaps,{floor=f:GetFullName(),skin=p.Name,point={point.X,point.Y,point.Z}})end end end end
local invalid={};local meshIds={};local tris=0
for _,p in visuals do
 if not p.Anchored or p.CanCollide or p.CanTouch or p.CanQuery then table.insert(invalid,p.Name)end;if p:IsA('MeshPart') then meshIds[p.MeshId]=true end
end
local count=0;for _ in meshIds do count+=1 end
local function metric(m)local out={instances=#m:GetDescendants(),parts=0,meshes=0,colliders=0,touch=0,query=0};local ids={}
for _,p in m:GetDescendants()do if p:IsA('BasePart')then out.parts+=1;if p.CanCollide then out.colliders+=1 end;if p.CanTouch then out.touch+=1 end;if p.CanQuery then out.query+=1 end;if p:IsA('MeshPart')then out.meshes+=1;ids[p.MeshId]=true end end end
local n=0;for _ in ids do n+=1 end;out.uniqueMeshes=n;return out end
return game.HttpService:JSONEncode({build=b:GetAttribute('CityRunV3Build'),comparedInstances=compared,gameplayParts=parts,differences=differences,clearance={testedFloorCenters=floors,overlaps=overlaps,limitation='Box test at landing centers; not a swept avatar or live hazard test'},visualFlagsInvalid=invalid,visualMeshIds=count,original=metric(sources.Original),optimized=metric(sources.Optimized),rebuilt=metric(sources.Rebuilt)})

