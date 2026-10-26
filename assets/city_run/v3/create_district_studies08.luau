local root=workspace.CityRunV3AssetReview
assert(not root:FindFirstChild('DistrictStudies08'))
local group=Instance.new('Folder');group.Name='DistrictStudies08';group.Parent=root
local lib=root.CityRunV3PaintedAssetKit05
local function part(name,size,pos,parent,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos;p.Color=color or Color3.fromRGB(144,156,149);p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function study(name,base)
 local m=Instance.new('Model');m.Name=name;m:SetAttribute('ReviewOnly',true);m.Parent=group
 part('ReviewFloor',Vector3.new(100,1,180),base+Vector3.new(0,-.5,-30),m)
 for _,r in {{Vector3.new(-3,2.9,12),Vector3.new(1.5,2.5,.7)},{Vector3.new(-3,4.9,12),Vector3.new(1.2,1.2,1.1)},{Vector3.new(-3.45,.825,12),Vector3.new(.45,1.65,.6)},{Vector3.new(-2.55,.825,12),Vector3.new(.45,1.65,.6)}}do part('ScaleMarker',r[2],base+r[1],m,Color3.fromRGB(208,183,121)) end
 local function add(id,x,y,z,rot)
  local p=lib:FindFirstChild(id,true):Clone();p:PivotTo(CFrame.new(base+Vector3.new(x,y,z))*CFrame.Angles(0,math.rad(rot or 0),0));p.Parent=m;return p
 end
 return add
end

local c=study('Construction',Vector3.new(20600,100,12000))
c('V3_AtelierHall',-25,0,-28,90)
c('V3_Brick_Broad',27,0,-29,-90);c('V3_FlatRoof_Broad',27,48,-29,-90)
c('V3_ServiceRear',13.7,0,-29,-90)
c('V3_SkylineCluster',-5,0,-78,0)
c('V3_Coral_Wide',26,0,-70,-90);c('V3_GableRoof_Wide',26,48,-70,-90)
for _,y in {0,12} do
 c('V3_ScaffoldBay',-12,y,-20,0);c('V3_ScaffoldBay',-12,y,-31,0)
end
c('V3_CraneTruss',0,24,-20,0);c('V3_WreckingBallSkin',-5,9,-20,0)
c('V3_WaterTank',9,0,-47,0)
for _,r in {{-10,0,8},{-6,0,8},{-8,4,8},{10,0,-10}} do c('V3_Crate',table.unpack(r)) end
c('V3_IBeam',-7,0,-7,0);c('V3_IBeam',-7,.7,-5,0)
c('V3_Fence',9,0,10,90)
local cf=group.Construction
part('ReviewOnlyCable',Vector3.new(.14,3.8,.14),Vector3.new(20595,122.1,11980),cf,Color3.fromRGB(32,42,49))
local s=study('Service',Vector3.new(20800,100,12000))
s('V3_Brick_Broad',26,0,-25,-90);s('V3_FlatRoof_Broad',26,48,-25,-90)
s('V3_ServiceRear',12.7,0,-25,-90)
s('V3_AtelierHall',-25,0,-29,90)
s('V3_ShopBase',16,0,-52,0)
s('V3_DepotCanopy',0,0,-48,0);s('V3_DeliveryVan',0,0,-47,0)
s('V3_Arcade',-13,0,4,90)
s('V3_SkylineCluster',-5,0,-82,0)
s('V3_CornerCafe',27,0,-73,-90);s('V3_GableRoof_Wide',27,36,-73,-90)
s('V3_Crate',9,0,9,0);s('V3_Crate',9,4,9,0);s('V3_Crate',9,0,14,0)
s('V3_Lamp',-12,0,14,0);s('V3_Fence',-9,0,-7,90)
root:SetAttribute('Presentation','DISTRICTS_08')
return {studies=#group:GetChildren(),descendants=#group:GetDescendants()}
