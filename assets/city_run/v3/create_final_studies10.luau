local root=workspace.CityRunV3AssetReview
assert(not root:FindFirstChild('FinalStudies10'))
local group=Instance.new('Folder');group.Name='FinalStudies10';group.Parent=root
local lib=root.CityRunV3PaintedAssetKit05
local function copy(source,name,offset)
 local m=source:Clone();m.Name=name;m.Parent=group;m:PivotTo(m:GetPivot()+offset);return m
end
local function add(m,id,base,x,y,z,rot)
 local p=lib:FindFirstChild(id,true):Clone();p:PivotTo(CFrame.new(base+Vector3.new(x,y,z))*CFrame.Angles(0,math.rad(rot or 0),0));p.Parent=m;return p
end
local service=copy(root.DistrictStudies09.Service,'Service',Vector3.new(400,0,0))
local sb=Vector3.new(21600,100,12000)
add(service,'V3_Brick_Broad',sb,0,0,-81)
add(service,'V3_FlatRoof_Broad',sb,0,48,-81)
add(service,'V3_ServiceRear',sb,0,0,-67.55)
service.V3_SkylineCluster:PivotTo(CFrame.new(sb+Vector3.new(0,0,-109)))
local market=copy(root.CompositionStudies07.Market,'Market',Vector3.new(1800,0,0))
local mb=Vector3.new(21800,100,12000)
add(market,'V3_Shopfront',mb,-14.4,0,-34,90)
add(market,'V3_Awning_12',mb,-10.85,10,-34,90)
add(market,'V3_Balcony',mb,-12.35,20,-34,90)
add(market,'V3_Planter',mb,-12,0,-42,90)
root:SetAttribute('Presentation','FINAL_STUDIES_10')
return {studies=#group:GetChildren(),descendants=#group:GetDescendants()}
