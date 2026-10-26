local root=workspace.CityRunV3AssetReview
assert(not root:FindFirstChild('DistrictStudies09'))
local group=Instance.new('Folder');group.Name='DistrictStudies09';group.Parent=root
local lib=root.CityRunV3PaintedAssetKit05
local addon=root.CityRunV3DistrictAddon01
local function part(name,size,pos,parent,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos;p.Color=color or Color3.fromRGB(144,156,149);p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function study(name,base)
 local m=Instance.new('Model');m.Name=name;m:SetAttribute('ReviewOnly',true);m.Parent=group
 part('ReviewFloor',Vector3.new(100,1,180),base+Vector3.new(0,-.5,-30),m)
 for _,r in {{Vector3.new(-3,2.9,12),Vector3.new(1.5,2.5,.7)},{Vector3.new(-3,4.9,12),Vector3.new(1.2,1.2,1.1)},{Vector3.new(-3.45,.825,12),Vector3.new(.45,1.65,.6)},{Vector3.new(-2.55,.825,12),Vector3.new(.45,1.65,.6)}}do part('ScaleMarker',r[2],base+r[1],m,Color3.fromRGB(208,183,121)) end
 local function add(id,x,y,z,rot)
  local p=(addon:FindFirstChild(id,true) or lib:FindFirstChild(id,true)):Clone();p:PivotTo(CFrame.new(base+Vector3.new(x,y,z))*CFrame.Angles(0,math.rad(rot or 0),0));p.Parent=m;return p
 end
 return add,m
end
local c,cm=study('Construction',Vector3.new(21000,100,12000))
for _,r in {
 {'V3_AtelierHall',-25,0,-29,90},{'V3_Brick_Broad',27,0,-29,-90},{'V3_FlatRoof_Broad',27,48,-29,-90},
 {'V3_SkylineCluster',0,0,-82},{'V3_ServiceRear',13.7,0,-34,-90},{'V3_LoadingFacade',12.4,0,-20,-90},
 {'V3_WorksiteHoarding',-11,0,0,90},{'V3_MaterialsStock',-10,0,11,90},{'V3_MaterialsStock',9,0,-5},
 {'V3_WaterTank',9,0,-48},{'V3_CraneTruss',0,24,-25},{'V3_WreckingBallSkin',0,11,-25}
} do c(table.unpack(r)) end
for _,z in {-22,-33} do for _,y in {0,12} do c('V3_ScaffoldBay',-12,y,z) end end
part('ReviewOnlyCable',Vector3.new(.14,4.975,.14),Vector3.new(21000,125.5125,11975),cm,Color3.fromRGB(32,42,49))
part('ReviewOnlyCableCrossbeam',Vector3.new(.22,.22,4.2),Vector3.new(21000,128,11975),cm,Color3.fromRGB(32,42,49))
local s=study('Service',Vector3.new(21200,100,12000))
for _,r in {
 {'V3_AtelierHall',-25,0,-29,90},{'V3_Brick_Broad',27,0,-25,-90},{'V3_FlatRoof_Broad',27,48,-25,-90},
 {'V3_SkylineCluster',0,0,-82},{'V3_ServiceRear',13.7,0,-30,-90},{'V3_LoadingFacade',12.4,0,-18,-90},
 {'V3_ServiceStock',9,0,6,90},{'V3_MaterialsStock',-10,0,4,90},{'V3_ServiceCanopy',0,0,-49},
 {'V3_DeliveryVan',5,0,-54},{'V3_ShopBase',27,0,-61},{'V3_Lamp',-12,0,13}
} do s(table.unpack(r)) end
root:SetAttribute('Presentation','DISTRICTS_09')
root:SetAttribute('CombinedBuild','V3_KIT_05+V3_DISTRICT_ADDON_01')
return {studies=#group:GetChildren(),descendants=#group:GetDescendants()}
