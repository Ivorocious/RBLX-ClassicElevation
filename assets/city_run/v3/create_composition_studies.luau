local root=workspace.CityRunV3AssetReview
assert(not root:FindFirstChild('CompositionStudies05'))
local group=Instance.new('Folder');group.Name='CompositionStudies05';group.Parent=root
local lib=root.CityRunV3PaintedAssetKit04
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
local a=study('Market',Vector3.new(15000,100,12000))
a('V3_CornerCafe',-25,0,0,0);a('V3_GableRoof_Wide',-25,36,0,0)
a('V3_Coral_Wide',-28,0,-34,90);a('V3_FlatRoof_Wide',-28,48,-34,90)
a('V3_ServiceRear',-14.7,0,-34,90)
a('V3_UnevenShopRow',23,0,-4,-90)
a('V3_Blue_Narrow',36,0,-9,-90);a('V3_GableRoof_Narrow',36,60,-9,-90)
a('V3_LoggiaResidence',26,0,-42,-90);a('V3_MansardRoof',26,48,-42,-90)
a('V3_CornerCafe',-24,0,-73,90);a('V3_GableRoof_Wide',-24,36,-73,90)
a('V3_SkylineCluster',0,0,-101,0)
a('V3_MarketStall',-15,0,14,0);a('V3_Crate',-20,0,18,0)
a('V3_Planter',12,0,13,0);a('V3_Lamp',13,0,-20,0);a('V3_MarketCar',2,0,-29,180)
a('V3_MuralPanel',-37.33,16,0,-90)
local b=study('Courtyard',Vector3.new(15200,100,12000))
b('V3_LoggiaResidence',-26,0,-8,90);b('V3_GableRoof_Wide',-26,48,-8,90)
b('V3_CourtyardGallery',27,0,-37,-90);b('V3_MansardRoof',27,48,-37,-90)
b('V3_CornerCafe',26,0,0,-90);b('V3_GableRoof_Wide',26,36,0,-90)
b('V3_ServiceRear',-16,0,-41,90)
b('V3_Brick_Broad',-29,0,-44,90);b('V3_FlatRoof_Broad',-29,48,-44,90)
b('V3_GardenPortal',0,0,-48,0);b('V3_SkylineCluster',-2,0,-95,0)
b('V3_CourtyardFountain',0,0,-24,0);b('V3_Bench',9,0,1,-90)
b('V3_Tree',-9,0,-27,0);b('V3_Planter',11,0,-10,0);b('V3_Lamp',-13,0,-3,0)
root:SetAttribute('Presentation','COMPOSITION_05')
return {studies=#group:GetChildren(),parts=#group:GetDescendants()}