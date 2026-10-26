local storage=game.ServerStorage
local history=storage.HeartwoodBuildHistory
local original=workspace.Course_HeartwoodAscent
assert(original:GetAttribute('HeartwoodBuild')=='HA_V1_03')
assert(not history:FindFirstChild('HeartwoodHA03BeforeHA04'))
local candidate=original:Clone()
original.Name='HeartwoodHA03BeforeHA04';original.Parent=history
candidate.Name='Course_HeartwoodAscent';candidate.Parent=workspace
candidate:SetAttribute('RepresentativeOnly',true)
local archive=Instance.new('Folder');archive.Name='HA04RepresentativeReplacedClones';archive.Parent=history
local manifest=loadstring(storage.CourseBuilders.HeartwoodAscent.ArtManifest.Source)()
local library=storage.AssetLibraries.HeartwoodV1HA04
assert(library:GetAttribute('State')=='Complete')
local origin=Vector3.new(4200,80,0)
local art=candidate.Decoration.HeartwoodArt
local swapped=0
for _,p in candidate:GetDescendants() do
 if p:IsA('MeshPart') then
  local asset=p:GetAttribute('ArtAsset')
  local localPoint=p.Position-origin
  local shell=asset and asset:match('^HA_Hollow_(%d%d)_')
  local selected=shell and (shell=='00' or shell=='01' or shell=='14' or shell=='15')
  local green=asset and asset:match('Mass') and localPoint.X>8 and localPoint.Y<105
  local top=p.Name=='Top' and p.Parent.Parent.Name=='S02_LivingHeartwood'
  if selected then
   local data=manifest[asset];local new=library[asset]:Clone()
   new.Name=p.Name;new.Size=data.size
   new.CFrame=CFrame.new(origin+(p:GetAttribute('AssemblyOffset') or Vector3.zero)+data.center)*CFrame.Angles(0,math.pi,0)
   new.TextureID=data.texture;new.CanCollide=p.CanCollide;new.CanQuery=p.CanQuery;new.CanTouch=false
   new.CustomPhysicalProperties=p.CurrentPhysicalProperties;new.Material=Enum.Material.Wood
   for k,v in p:GetAttributes() do new:SetAttribute(k,v) end
   new:SetAttribute('ArtTriangles',data.triangles);new.Parent=p.Parent
   if p.Parent:IsA('Model') and p.Parent.PrimaryPart==p then p.Parent.PrimaryPart=new end
   p.Parent=archive;swapped+=1
  elseif green or top then
   local target=if top then 'HA_ShelfWideB' else asset
   if manifest[target] and library:FindFirstChild(target) then
    local size,frame=p.Size,p.CFrame;p:ApplyMesh(library[target]);p.Size=size;p.CFrame=frame;p.TextureID=manifest[target].texture
    p:SetAttribute('ArtAsset',target);p:SetAttribute('ArtTriangles',manifest[target].triangles);swapped+=1
   end
  end
 end
end
local forest=Instance.new('Model');forest.Name='RepresentativeForest';forest.Parent=art
local function clone(asset,frame)
 local data=manifest[asset];local p=library[asset]:Clone();p.Name=asset
 p.Size=data.size;p.CFrame=frame*CFrame.new(data.center)*CFrame.Angles(0,math.pi,0)
 p.TextureID=data.texture;p.CanCollide=true;p.CanQuery=true;p.CanTouch=false;p.Anchored=true
 p.Material=Enum.Material.Wood;p:SetAttribute('ArtAsset',asset);p:SetAttribute('ArtTriangles',data.triangles)
 p:SetAttribute('Scenery',true);p.Parent=forest;return p
end
local ground=clone('HA_ForestGround',CFrame.new(origin));ground.Material=Enum.Material.Ground
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={ground};params.RespectCanCollide=true
for i,data in {{'HA_ForestNearA',290,-145},{'HA_ForestNearB',280,155},{'HA_ForestNearA',325,15},
 {'HA_ForestMid',430,-175},{'HA_ForestMid',440,45},{'HA_ForestMid',430,225},
 {'HA_ForestFar',580,-220},{'HA_ForestFar',570,-85},{'HA_ForestFar',595,100},{'HA_ForestFar',570,260}} do
 local asset,x,z=table.unpack(data);local hit=workspace:Raycast(origin+Vector3.new(x,-25,z),Vector3.new(0,-250,0),params)
 assert(hit,'Forest ground must support roots')
 local m=manifest[asset];local bottom=m.center.Y-m.size.Y/2
 local frame=CFrame.new(origin+Vector3.new(x,hit.Position.Y-origin.Y-bottom-1.5,z))*CFrame.Angles(0,i*.63,0)
 local p=clone(asset,frame);p.Name='Tree_'..i
end
return {candidate=candidate.Name,replaced=swapped,representative=true,forestUnits=10,preserved=original:GetFullName()}
